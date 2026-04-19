"""Post-extraction validation: flag YoY swings and digit-count mismatches.

Writes flagged rows to COMMON.REVIEW_QUEUE with reason codes:
  - yoy_swing      — absolute YoY change exceeds threshold (default 10 %)
  - digit_mismatch — digit count differs between consecutive FY amounts
                     for the same line item (strong indicator of OCR/LLM misread)
"""
from __future__ import annotations

import math
import uuid
from typing import Optional


_STATEMENT_TABLES = {
    "income_statement": "COMMON.INCOME_STATEMENT",
    "balance_sheet": "COMMON.BALANCE_SHEET",
    "cash_flow": "COMMON.CASH_FLOW",
    "operating_stats": "COMMON.OPERATING_STATS",
}

_INSERT_REVIEW = """
    INSERT INTO COMMON.REVIEW_QUEUE
      (REVIEW_ID, FILING_ID, ORG_ID, STATEMENT, NATIVE_LABEL,
       FY_LABEL, AMOUNT, CONFIDENCE, REASON, SOURCE_PAGE, PAYLOAD)
    SELECT %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, PARSE_JSON(%s)
"""


def _digit_count(v: float) -> int:
    return len(str(abs(int(v)))) if v and not math.isnan(v) else 0


def validate_org(
    cur,
    org_id: str,
    *,
    yoy_threshold: float = 0.10,
    digit_gap: int = 1,
    statements: Optional[list[str]] = None,
) -> list[dict]:
    """Run all validation checks for an org. Returns list of flag dicts."""
    targets = statements or list(_STATEMENT_TABLES)
    flags: list[dict] = []
    for stmt in targets:
        table = _STATEMENT_TABLES.get(stmt)
        if not table:
            continue
        flags.extend(_check_statement(cur, org_id, stmt, table, yoy_threshold, digit_gap))
    return flags


def _check_statement(cur, org_id, stmt_name, table, threshold, digit_gap):
    cur.execute(
        f"SELECT FILING_ID, FY_LABEL, CONCEPT, AMOUNT, CONFIDENCE, SOURCE_PAGE, NATIVE_LABEL "
        f"FROM {table} WHERE ORG_ID = %s ORDER BY CONCEPT, FY_LABEL",
        (org_id,),
    )
    rows = cur.fetchall()

    by_concept: dict[str, list] = {}
    for filing_id, fy, concept, amt, conf, page, native in rows:
        by_concept.setdefault(concept, []).append({
            "filing_id": filing_id, "fy": fy, "concept": concept,
            "amount": float(amt) if amt is not None else None,
            "confidence": conf, "page": page, "native": native,
            "statement": stmt_name,
        })

    flags = []
    for concept, entries in by_concept.items():
        sorted_entries = sorted(entries, key=lambda e: e["fy"])
        for i in range(1, len(sorted_entries)):
            prev, curr = sorted_entries[i - 1], sorted_entries[i]
            pa, ca = prev["amount"], curr["amount"]
            if pa is None or ca is None:
                continue

            if pa != 0:
                pct_change = abs((ca - pa) / pa)
                if pct_change > threshold:
                    flags.append(_make_flag(
                        curr, "yoy_swing",
                        f"{curr['fy']} vs {prev['fy']}: "
                        f"{pa:,.0f} -> {ca:,.0f} ({pct_change:+.1%})",
                        prev,
                    ))

            d_prev, d_curr = _digit_count(pa), _digit_count(ca)
            if d_prev and d_curr and abs(d_prev - d_curr) >= digit_gap:
                flags.append(_make_flag(
                    curr, "digit_mismatch",
                    f"{prev['fy']}={pa:,.0f} ({d_prev} digits) vs "
                    f"{curr['fy']}={ca:,.0f} ({d_curr} digits)",
                    prev,
                ))

    return flags


def _make_flag(entry, reason, detail, prev_entry):
    return {
        "filing_id": entry["filing_id"],
        "org_id": None,
        "statement": entry["statement"],
        "native_label": entry["native"] or entry["concept"],
        "fy_label": entry["fy"],
        "amount": entry["amount"],
        "confidence": entry["confidence"],
        "reason": reason,
        "source_page": entry["page"],
        "detail": detail,
        "prev_amount": prev_entry["amount"],
        "prev_fy": prev_entry["fy"],
    }


def write_flags_to_review_queue(cur, org_id: str, flags: list[dict]) -> int:
    """Insert flags into REVIEW_QUEUE. Returns count written."""
    import json as _json
    n = 0
    for f in flags:
        payload = _json.dumps({
            "detail": f["detail"],
            "prev_amount": f["prev_amount"],
            "prev_fy": f["prev_fy"],
        })
        cur.execute(_INSERT_REVIEW, (
            str(uuid.uuid4()),
            f["filing_id"],
            org_id,
            f["statement"],
            f["native_label"],
            f["fy_label"],
            f["amount"],
            f["confidence"],
            f["reason"],
            f["source_page"],
            payload,
        ))
        n += 1
    return n


def summarize_flags(flags: list[dict]) -> str:
    """Return a human-readable summary grouped by reason."""
    by_reason: dict[str, list] = {}
    for f in flags:
        by_reason.setdefault(f["reason"], []).append(f)
    lines = [f"Total flags: {len(flags)}"]
    for reason, items in sorted(by_reason.items()):
        lines.append(f"\n  [{reason}] ({len(items)} flags)")
        for item in items:
            sev = "***" if item["reason"] == "digit_mismatch" else " * "
            lines.append(f"    {sev} {item['statement']}.{item['native_label']} "
                         f"| {item['detail']}")
    return "\n".join(lines)
