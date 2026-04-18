"""Snowflake connection + idempotent DDL + MERGE helpers.

Cortex edition: `get_connection(session)` extracts the underlying
snowflake.connector.Connection from a live Snowpark session so all
cursor-based code runs unchanged inside Snowflake Notebooks.
"""
from __future__ import annotations

import json
from typing import Any, Iterable, Mapping, Sequence

import snowflake.connector

from . import config as C


def get_connection(session=None):
    """Return a snowflake.connector.Connection.

    Inside Snowflake Notebooks pass the active `session` object;
    the underlying connector connection is extracted from it.
    Outside Snowflake (local testing), `session` is None and a new
    connection is opened using the environment variables in config.py.
    """
    if session is not None:
        # session._conn._conn is the SnowflakeConnection backing Snowpark.
        # This is a stable internal pattern used widely in Snowflake community.
        return session._conn._conn

    # Local / CI fallback — requires SNOWFLAKE_* env vars or config.toml
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    import os

    key_path = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH", r"C:\snowflake_keys\snowflake_key.p8")
    passphrase = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE", "coker2026").encode()
    with open(key_path, "rb") as f:
        pkey = load_pem_private_key(f.read(), password=passphrase, backend=default_backend())
    return snowflake.connector.connect(
        account=os.environ.get("SNOWFLAKE_ACCOUNT", C.SNOWFLAKE_DATABASE),
        user=os.environ.get("SNOWFLAKE_USER", "NATHANCOHEN"),
        private_key=pkey,
        warehouse=C.SNOWFLAKE_WAREHOUSE,
        database=C.SNOWFLAKE_DATABASE,
        autocommit=False,
    )


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
    PRIMARY KEY (FY_LABEL, SECTION, NATIVE_LABEL, LINE_ORDER)
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
    cols = list(rows[0].keys())
    placeholders = ",".join(["%s"] * len(cols))
    sql = f"INSERT INTO {fq_table} ({','.join(cols)}) VALUES ({placeholders})"
    cur.executemany(sql, [tuple(r.get(c) for c in cols) for r in rows])
    return cur.rowcount or len(rows)


def insert_variant_row(cur, fq_table: str, row: Mapping[str, Any], variant_cols: Iterable[str]) -> None:
    variant_cols = set(variant_cols)
    cols = list(row.keys())
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


def merge_rows(cur, fq_table, rows, key_cols, update_cols=None) -> int:
    if not rows:
        return 0
    cols = list(rows[0].keys())
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
