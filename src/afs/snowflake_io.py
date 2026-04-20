"""Snowflake connection + idempotent DDL + MERGE helpers.

Cortex edition: `get_connection(session)` extracts the underlying
snowflake.connector.Connection from a live Snowpark session so all
cursor-based code runs unchanged inside Snowflake Notebooks.

Connection strategy:
  - The Snowpark ``session`` is used for Cortex LLM calls
    (``snowflake.cortex.Complete``) and notebook-level Snowpark DataFrame
    operations (status updates, display queries).
  - A raw ``snowflake.connector`` cursor is used by library modules
    (``org_registry``, ``common_map``, ``normalize``, ``insights``,
    ``exhibits``) for parameterised DML. The cursor is obtained from the
    same underlying connection that backs the Snowpark session, so they
    share the same transaction context.
  - ``cursor_from_session(session)`` is the preferred entry-point for
    notebooks and callers that need a cursor with automatic cleanup.
"""
from __future__ import annotations

import json
import re
from typing import Any, Iterable, Mapping, Sequence

import snowflake.connector
from contextlib import contextmanager

from . import config as C


_SAFE_IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]{0,254}$')

_PYFORMAT_RE = re.compile(r'%s')


class _QmarkCursorWrapper:
    """Wraps a qmark-style cursor so callers can use %s (pyformat) placeholders."""

    def __init__(self, cursor):
        self._cur = cursor

    def execute(self, sql, params=None, **kwargs):
        if params and '%s' in sql:
            sql = _PYFORMAT_RE.sub('?', sql)
        return self._cur.execute(sql, params, **kwargs)

    def executemany(self, sql, seqparams, **kwargs):
        if '%s' in sql:
            sql = _PYFORMAT_RE.sub('?', sql)
        return self._cur.executemany(sql, seqparams, **kwargs)

    def __getattr__(self, name):
        return getattr(self._cur, name)


def _validate_identifier(name: str, label: str = "identifier") -> str:
    if not _SAFE_IDENT_RE.match(name):
        raise ValueError(f"Unsafe Snowflake {label}: {name!r}")
    return name


def get_connection(session=None):
    """Return a snowflake.connector.Connection.

    Inside Snowflake Notebooks pass the active `session` object;
    the underlying connector connection is extracted from it.
    Outside Snowflake (local testing), `session` is None and a new
    connection is opened using the environment variables in config.py.
    """
    if session is not None:
        conn = session._conn._conn
        conn.cursor().execute(f"USE DATABASE {C.SNOWFLAKE_DATABASE}")
        return conn

    # Local / CI fallback — requires SNOWFLAKE_* env vars
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    import os

    key_path = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH")
    if not key_path:
        raise RuntimeError(
            "SNOWFLAKE_PRIVATE_KEY_PATH env var is required for local connections. "
            "Set SNOWFLAKE_PRIVATE_KEY_PATH and optionally SNOWFLAKE_PRIVATE_KEY_PASSPHRASE."
        )
    passphrase_str = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE")
    passphrase = passphrase_str.encode() if passphrase_str else None
    with open(key_path, "rb") as f:
        pkey = load_pem_private_key(f.read(), password=passphrase, backend=default_backend())
    account = os.environ.get("SNOWFLAKE_ACCOUNT")
    user = os.environ.get("SNOWFLAKE_USER")
    if not account or not user:
        raise RuntimeError("SNOWFLAKE_ACCOUNT and SNOWFLAKE_USER env vars are required for local connections.")
    return snowflake.connector.connect(
        account=account,
        user=user,
        private_key=pkey,
        warehouse=C.SNOWFLAKE_WAREHOUSE,
        database=C.SNOWFLAKE_DATABASE,
        autocommit=False,
    )


@contextmanager
def cursor_from_session(session, *, commit_on_exit: bool = True):
    """Context manager yielding a raw cursor from a Snowpark session.

    Usage::

        with cursor_from_session(session) as cur:
            cur.execute('SELECT ...')

    On clean exit the connection is committed (unless ``commit_on_exit``
    is False). On exception the connection is rolled back. The cursor is
    always closed.
    """
    conn = get_connection(session)
    raw_cur = conn.cursor()
    cur = _QmarkCursorWrapper(raw_cur) if session is not None else raw_cur
    try:
        yield cur
        if commit_on_exit:
            conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()


# ---------- per-org schema DDL ----------
_PER_ORG_DDL = """
CREATE SCHEMA IF NOT EXISTS {schema};
USE SCHEMA {schema};

CREATE TABLE IF NOT EXISTS RAW_FILING_JSON (
    FILING_ID STRING PRIMARY KEY,
    SOURCE_FILENAME STRING,
    EXTRACTOR_VERSION STRING,
    BLOB VARIANT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS IS_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    IS_SUBTOTAL BOOLEAN, PARENT_LABEL STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FY_LABEL, NATIVE_LABEL, LINE_ORDER)
);

CREATE TABLE IF NOT EXISTS BS_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    IS_SUBTOTAL BOOLEAN, PARENT_LABEL STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FY_LABEL, NATIVE_LABEL, LINE_ORDER)
);

CREATE TABLE IF NOT EXISTS CF_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, SECTION STRING, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    IS_SUBTOTAL BOOLEAN,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FY_LABEL, NATIVE_LABEL, LINE_ORDER)
);

CREATE TABLE IF NOT EXISTS EQUITY_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    COLUMN_LABEL STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS IS_EXHIBIT_ENTITY (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    ENTITY STRING, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS IS_EXHIBIT_REVENUE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    DIMENSION STRING, CATEGORY STRING, AMOUNT NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS IS_EXHIBIT_EXPENSE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    DIMENSION STRING, CATEGORY STRING, AMOUNT NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS BS_EXHIBIT_DEBT (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    INSTRUMENT STRING, OUTSTANDING NUMBER(38,2), RATE FLOAT, MATURITY_YEAR NUMBER,
    SECURED BOOLEAN, COVENANTS_TEXT STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS BS_EXHIBIT_INVESTMENTS (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    FV_LEVEL STRING, CATEGORY STRING, FAIR_VALUE NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS BS_EXHIBIT_PPE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    CATEGORY STRING, COST NUMBER(38,2), ACCUM_DEPR NUMBER(38,2), NET NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS NOTES (
    FILING_ID STRING, NOTE_NUM STRING, TITLE STRING,
    BODY_TEXT STRING, CALLOUTS VARIANT,
    SOURCE_PAGE_START NUMBER, SOURCE_PAGE_END NUMBER,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FILING_ID, NOTE_NUM)
);

CREATE TABLE IF NOT EXISTS STATS (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    NATIVE_LABEL STRING, AMOUNT NUMBER(38,4), UOM STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);
"""


def ensure_org_schema(cur, org_code: str) -> None:
    _validate_identifier(org_code, "org_code")
    cur.execute(f"USE DATABASE {C.SNOWFLAKE_DATABASE}")
    for stmt in _PER_ORG_DDL.format(schema=org_code).split(";"):
        s = stmt.strip()
        if s:
            cur.execute(s)


def filing_already_loaded(cur, filing_id: str) -> bool:
    cur.execute("SELECT 1 FROM COMMON.FILINGS WHERE FILING_ID = %s", (filing_id,))
    return cur.fetchone() is not None


def insert_rows(cur, fq_table: str, rows: Sequence[Mapping[str, Any]]) -> int:
    if not rows:
        return 0
    for part in fq_table.split("."):
        _validate_identifier(part, "table path component")
    cols = list(rows[0].keys())
    for c in cols:
        _validate_identifier(c, "column name")
    placeholders = ",".join(["%s"] * len(cols))
    sql = f"INSERT INTO {fq_table} ({','.join(cols)}) VALUES ({placeholders})"
    cur.executemany(sql, [tuple(r.get(c) for c in cols) for r in rows])
    return cur.rowcount or len(rows)


def insert_variant_row(cur, fq_table: str, row: Mapping[str, Any], variant_cols: Iterable[str]) -> None:
    for part in fq_table.split("."):
        _validate_identifier(part, "table path component")
    variant_cols = set(variant_cols)
    cols = list(row.keys())
    for c in cols:
        _validate_identifier(c, "column name")
    values_clause, params = [], []
    for c in cols:
        if c in variant_cols:
            values_clause.append("PARSE_JSON(%s)")
            params.append(json.dumps(row[c]))
        else:
            values_clause.append("%s")
            params.append(row[c])
    sql = f"INSERT INTO {fq_table} ({','.join(cols)}) SELECT {','.join(values_clause)}"
    cur.execute(sql, params)


def get_completed_stages(cur, staging_id: str) -> set[str]:
    cur.execute(
        "SELECT STAGES_COMPLETED FROM COMMON.PDF_STAGING WHERE STAGING_ID = %s",
        (staging_id,),
    )
    row = cur.fetchone()
    if not row or row[0] is None:
        return set()
    raw = row[0]
    if isinstance(raw, str):
        import json as _json
        raw = _json.loads(raw)
    return set(raw) if raw else set()


def mark_stage_completed(cur, staging_id: str, stage_name: str) -> None:
    cur.execute(
        """
        UPDATE COMMON.PDF_STAGING
           SET STAGES_COMPLETED = ARRAY_APPEND(
               COALESCE(STAGES_COMPLETED, PARSE_JSON('[]')),
               %s::VARIANT
           )
         WHERE STAGING_ID = %s
        """,
        (stage_name, staging_id),
    )


def reset_stages(cur, staging_id: str) -> None:
    cur.execute(
        "UPDATE COMMON.PDF_STAGING SET STAGES_COMPLETED = PARSE_JSON('[]') WHERE STAGING_ID = %s",
        (staging_id,),
    )


def merge_rows(cur, fq_table, rows, key_cols, update_cols=None) -> int:
    if not rows:
        return 0
    for part in fq_table.split("."):
        _validate_identifier(part, "table path component")
    cols = list(rows[0].keys())
    for c in cols:
        _validate_identifier(c, "column name")
    for k in key_cols:
        _validate_identifier(k, "key column")
    update_cols = update_cols or [c for c in cols if c not in key_cols]
    key_match = " AND ".join(f"t.{k}=s.{k}" for k in key_cols)
    update_set = ", ".join(f"t.{c}=s.{c}" for c in update_cols)
    src_cols = ", ".join(f"%s AS {c}" for c in cols)
    insert_vals = ", ".join(f"s.{c}" for c in cols)
    sql = f"""
        MERGE INTO {fq_table} t USING (SELECT {src_cols}) s
        ON {key_match}
        WHEN MATCHED THEN UPDATE SET {update_set}
        WHEN NOT MATCHED THEN INSERT ({','.join(cols)}) VALUES ({insert_vals})
    """
    count = 0
    for r in rows:
        cur.execute(sql, tuple(r.get(c) for c in cols))
        count += 1
    return count
