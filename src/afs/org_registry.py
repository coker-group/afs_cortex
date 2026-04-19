"""Resolve org identity: fuzzy match existing registry, else propose + persist."""
from __future__ import annotations

import re
import uuid
from typing import Optional

import difflib

from .schemas import IdentifyResult


def _norm(s: str | None) -> str:
    if not s:
        return ""
    s = re.sub(r"[^a-z0-9 ]+", " ", s.lower())
    s = re.sub(r"\b(the|inc|llc|corp|corporation|company|co|system|systems|health|healthcare|hospital|hospitals|medical|center|centers)\b", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def suggest_org_code(legal_name: str) -> str:
    """Snowflake-safe schema name: uppercase, underscores, trim to 40 chars."""
    raw = re.sub(r"[^A-Za-z0-9]+", "_", legal_name).upper().strip("_")
    if raw and raw[0].isdigit():
        raw = "ORG_" + raw
    return raw[:40] if raw else "UNNAMED_ORG"


def find_existing(cur, ident: IdentifyResult) -> Optional[dict]:
    """Return {ORG_ID, ORG_CODE, LEGAL_NAME, EIN} if a match exists, else None."""
    # Exact EIN match first
    if ident.ein:
        cur.execute(
            "SELECT ORG_ID, ORG_CODE, LEGAL_NAME, EIN FROM COMMON.ORG_REGISTRY WHERE EIN = %s",
            (ident.ein,),
        )
        row = cur.fetchone()
        if row:
            return {"ORG_ID": row[0], "ORG_CODE": row[1], "LEGAL_NAME": row[2], "EIN": row[3]}
    # Fuzzy name match
    cur.execute("SELECT ORG_ID, ORG_CODE, LEGAL_NAME, EIN FROM COMMON.ORG_REGISTRY")
    rows = cur.fetchall()
    if not rows:
        return None
    candidates = {_norm(r[2]): r for r in rows}
    query = _norm(ident.legal_name)
    matches = difflib.get_close_matches(query, list(candidates.keys()), n=1, cutoff=0.9)
    if matches:
        r = candidates[matches[0]]
        return {"ORG_ID": r[0], "ORG_CODE": r[1], "LEGAL_NAME": r[2], "EIN": r[3]}
    return None


def insert_org(
    cur,
    org_id: str,
    org_code: str,
    ident: IdentifyResult,
    notes: str | None = None,
) -> None:
    cur.execute(
        """
        INSERT INTO COMMON.ORG_REGISTRY
          (ORG_ID, ORG_CODE, LEGAL_NAME, DBA, EIN, HQ_STATE, FYE_MONTH, SECTOR, NOTES)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """,
        (
            org_id,
            org_code,
            ident.legal_name,
            ident.dba,
            ident.ein,
            ident.hq_state,
            ident.fye_month,
            ident.sector,
            notes,
        ),
    )


def new_org_id() -> str:
    return str(uuid.uuid4())
