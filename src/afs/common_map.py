"""Map native financial statement labels to STANDARD_TAXONOMY concepts.
Cache mappings in COMMON.LINE_ITEM_MAP, scoped by ORG_ID."""
from __future__ import annotations

import re
from typing import Literal

from . import config as C
from .cortex_llm import call_text_json_no_context, load_prompt
from .schemas import MappingProposal


StmtCode = Literal["income_statement", "balance_sheet", "cash_flow", "stat"]


def norm_label(label: str) -> str:
    s = re.sub(r"[^a-z0-9 ]+", " ", label.lower())
    return re.sub(r"\s+", " ", s).strip()


def _fetch_taxonomy(cur, statement: StmtCode) -> list[tuple[str, str | None]]:
    cur.execute(
        "SELECT CONCEPT, DEFINITION FROM COMMON.STANDARD_TAXONOMY WHERE STATEMENT = %s ORDER BY CONCEPT",
        (statement,),
    )
    return [(r[0], r[1]) for r in cur.fetchall()]


def _cached(cur, org_id: str, statement: StmtCode, label_norm: str) -> dict | None:
    cur.execute(
        """
        SELECT CONCEPT, CONFIDENCE, RATIONALE
          FROM COMMON.LINE_ITEM_MAP
         WHERE ORG_ID = %s AND STATEMENT = %s AND NATIVE_LABEL_NORM = %s
        """,
        (org_id, statement, label_norm),
    )
    row = cur.fetchone()
    return {"concept": row[0], "confidence": row[1], "rationale": row[2]} if row else None


def _persist(cur, org_id, statement, native_label, proposal: MappingProposal, source="auto"):
    cur.execute(
        """
        MERGE INTO COMMON.LINE_ITEM_MAP t
        USING (SELECT %s ORG_ID, %s NATIVE_LABEL_NORM, %s NATIVE_LABEL,
                      %s STATEMENT, %s CONCEPT, %s CONFIDENCE, %s RATIONALE, %s SOURCE) s
        ON t.ORG_ID=s.ORG_ID AND t.NATIVE_LABEL_NORM=s.NATIVE_LABEL_NORM AND t.STATEMENT=s.STATEMENT
        WHEN MATCHED THEN UPDATE SET
          NATIVE_LABEL=s.NATIVE_LABEL, CONCEPT=s.CONCEPT,
          CONFIDENCE=s.CONFIDENCE, RATIONALE=s.RATIONALE, SOURCE=s.SOURCE
        WHEN NOT MATCHED THEN INSERT
          (ORG_ID, NATIVE_LABEL_NORM, NATIVE_LABEL, STATEMENT, CONCEPT, CONFIDENCE, RATIONALE, SOURCE)
          VALUES (s.ORG_ID, s.NATIVE_LABEL_NORM, s.NATIVE_LABEL, s.STATEMENT, s.CONCEPT,
                  s.CONFIDENCE, s.RATIONALE, s.SOURCE)
        """,
        (org_id, norm_label(native_label), native_label, statement,
         proposal.concept, proposal.confidence, proposal.rationale, source),
    )


def map_label(cur, org_id: str, statement: StmtCode, native_label: str) -> MappingProposal:
    label_norm = norm_label(native_label)
    cached = _cached(cur, org_id, statement, label_norm)
    if cached is not None:
        return MappingProposal(
            native_label=native_label,
            statement=statement,
            concept=cached["concept"],
            confidence=float(cached["confidence"] or 0.0),
            rationale=cached["rationale"] or "cached",
        )
    taxonomy = _fetch_taxonomy(cur, statement)
    candidates_block = "\n".join(f"- `{c}` — {d or ''}" for c, d in taxonomy)
    prompt = (
        load_prompt("map_concept")
        .replace("{NATIVE_LABEL}", native_label)
        .replace("{STATEMENT}", statement)
        .replace("{CANDIDATES}", candidates_block)
    )
    data = call_text_json_no_context(prompt, model=C.MODEL_MAP)
    proposal = MappingProposal(**data)
    _persist(cur, org_id, statement, native_label, proposal)
    return proposal


def review_flag(proposal: MappingProposal) -> bool:
    return proposal.concept is None or proposal.confidence < C.MIN_MAPPING_CONFIDENCE
