"""Write extracted data into per-org NATIVE tables and COMMON.* standardized tables."""
from __future__ import annotations

import uuid
from typing import Iterable

from . import config as C
from .common_map import map_label, norm_label, review_flag
from .schemas import StatementExtract


_STATEMENT_TO_COMMON = {
    "is": ("income_statement", "INCOME_STATEMENT", "IS_NATIVE"),
    "bs": ("balance_sheet", "BALANCE_SHEET", "BS_NATIVE"),
    "cf": ("cash_flow", "CASH_FLOW", "CF_NATIVE"),
}


def write_statement(
    cur,
    *,
    org_id: str,
    org_code: str,
    filing_id: str,
    fye_by_year: dict[str, str],
    extract: StatementExtract,
) -> dict:
    """Write one primary statement's rows to per-org NATIVE + COMMON (if IS/BS/CF)."""
    stmt_code = extract.statement
    if stmt_code == "equity":
        _write_equity_native(cur, org_code, filing_id, fye_by_year, extract)
        return {"native_rows": len(extract.lines), "common_rows": 0, "review_rows": 0}

    common_stmt_name, common_table, native_table = _STATEMENT_TO_COMMON[stmt_code]

    native_rows = []
    common_rows: list[dict] = []
    review_rows: list[dict] = []

    for line in extract.lines:
        for amt in line.amounts:
            native_rows.append(
                {
                    "FILING_ID": filing_id,
                    "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "LINE_ORDER": line.line_order,
                    "NATIVE_LABEL": line.native_label,
                    "AMOUNT": amt.amount,
                    "IS_SUBTOTAL": line.is_subtotal,
                    "PARENT_LABEL": line.parent_label,
                    "SOURCE_PAGE": line.source_page,
                    "CONFIDENCE": amt.confidence,
                }
                if stmt_code != "cf"
                else {
                    "FILING_ID": filing_id,
                    "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "LINE_ORDER": line.line_order,
                    "SECTION": line.section,
                    "NATIVE_LABEL": line.native_label,
                    "AMOUNT": amt.amount,
                    "IS_SUBTOTAL": line.is_subtotal,
                    "SOURCE_PAGE": line.source_page,
                    "CONFIDENCE": amt.confidence,
                }
            )

            # low-confidence goes to review queue, not final tables
            if amt.amount is None or amt.confidence < C.MIN_NUMERIC_CONFIDENCE:
                if amt.amount is not None:
                    review_rows.append(
                        _review_row(
                            filing_id=filing_id,
                            org_id=org_id,
                            statement=stmt_code.upper(),
                            native_label=line.native_label,
                            fy_label=amt.fy_label,
                            amount=amt.amount,
                            confidence=amt.confidence,
                            reason="low_confidence",
                            source_page=line.source_page,
                        )
                    )
                continue

            # subtotals skipped in COMMON (we keep only leaf line items there)
            if line.is_subtotal:
                continue

            proposal = map_label(cur, org_id, common_stmt_name, line.native_label)
            if review_flag(proposal):
                review_rows.append(
                    _review_row(
                        filing_id=filing_id,
                        org_id=org_id,
                        statement=stmt_code.upper(),
                        native_label=line.native_label,
                        fy_label=amt.fy_label,
                        amount=amt.amount,
                        confidence=proposal.confidence,
                        reason="mapping_low_conf",
                        source_page=line.source_page,
                        payload={"rationale": proposal.rationale, "proposed_concept": proposal.concept},
                    )
                )
                continue

            common_rows.append(
                {
                    "FILING_ID": filing_id,
                    "ORG_ID": org_id,
                    "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "CONCEPT": proposal.concept,
                    "AMOUNT": amt.amount,
                    "NATIVE_LABEL": line.native_label,
                    "SOURCE_PAGE": line.source_page,
                    "CONFIDENCE": amt.confidence,
                }
            )

    _bulk_insert(cur, f"{org_code}.{native_table}", native_rows)
    _merge_common(cur, common_table, common_rows)
    _write_review(cur, review_rows)
    return {
        "native_rows": len(native_rows),
        "common_rows": len(common_rows),
        "review_rows": len(review_rows),
    }


def _write_equity_native(cur, org_code, filing_id, fye_by_year, extract: StatementExtract) -> None:
    rows = []
    for line in extract.lines:
        for amt in line.amounts:
            rows.append(
                {
                    "FILING_ID": filing_id,
                    "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "LINE_ORDER": line.line_order,
                    "NATIVE_LABEL": line.native_label,
                    "AMOUNT": amt.amount,
                    "COLUMN_LABEL": line.parent_label,
                    "SOURCE_PAGE": line.source_page,
                    "CONFIDENCE": amt.confidence,
                }
            )
    _bulk_insert(cur, f"{org_code}.EQUITY_NATIVE", rows)


def write_stats(
    cur,
    *,
    org_id: str,
    org_code: str,
    filing_id: str,
    fye_by_year: dict[str, str],
    stat_rows: Iterable[dict],
) -> dict:
    native_rows = []
    common_rows = []
    review_rows = []
    for r in stat_rows:
        amount = r.get("amount")
        conf = r.get("confidence", 1.0)
        fy = r.get("fy_label")
        label = r.get("native_label")
        page = r.get("source_page")
        uom = r.get("uom")
        native_rows.append(
            {
                "FILING_ID": filing_id,
                "FY_LABEL": fy,
                "FISCAL_YEAR_END": fye_by_year.get(fy),
                "NATIVE_LABEL": label,
                "AMOUNT": amount,
                "UOM": uom,
                "SOURCE_PAGE": page,
                "CONFIDENCE": conf,
            }
        )
        if amount is None or conf < C.MIN_NUMERIC_CONFIDENCE or not label:
            continue
        proposal = map_label(cur, org_id, "stat", label)
        if review_flag(proposal):
            review_rows.append(
                _review_row(
                    filing_id=filing_id,
                    org_id=org_id,
                    statement="STATS",
                    native_label=label,
                    fy_label=fy,
                    amount=amount,
                    confidence=proposal.confidence,
                    reason="mapping_low_conf",
                    source_page=page,
                    payload={"rationale": proposal.rationale, "proposed_concept": proposal.concept},
                )
            )
            continue
        common_rows.append(
            {
                "FILING_ID": filing_id,
                "ORG_ID": org_id,
                "FY_LABEL": fy,
                "FISCAL_YEAR_END": fye_by_year.get(fy),
                "CONCEPT": proposal.concept,
                "AMOUNT": amount,
                "UOM": uom,
                "NATIVE_LABEL": label,
                "SOURCE_PAGE": page,
                "CONFIDENCE": conf,
            }
        )

    _bulk_insert(cur, f"{org_code}.STATS", native_rows)
    _merge_common(cur, "OPERATING_STATS", common_rows)
    _write_review(cur, review_rows)
    return {
        "native_rows": len(native_rows),
        "common_rows": len(common_rows),
        "review_rows": len(review_rows),
    }


# ---------- internals ----------
def _bulk_insert(cur, fq_table: str, rows: list[dict]) -> None:
    if not rows:
        return
    cols = list(rows[0].keys())
    placeholders = ",".join(["%s"] * len(cols))
    sql = f"INSERT INTO {fq_table} ({','.join(cols)}) VALUES ({placeholders})"
    cur.executemany(sql, [tuple(r.get(c) for c in cols) for r in rows])


def _merge_common(cur, table: str, rows: list[dict]) -> None:
    if not rows:
        return
    cols = list(rows[0].keys())
    keys = ["ORG_ID", "FY_LABEL", "CONCEPT"]
    update_cols = [c for c in cols if c not in keys]
    select_clause = ", ".join(f"%s AS {c}" for c in cols)
    key_match = " AND ".join(f"t.{k}=s.{k}" for k in keys)
    update_set = ", ".join(f"t.{c}=s.{c}" for c in update_cols)
    insert_vals = ", ".join(f"s.{c}" for c in cols)
    sql = f"""
        MERGE INTO COMMON.{table} t USING (SELECT {select_clause}) s
        ON {key_match}
        WHEN MATCHED THEN UPDATE SET {update_set}
        WHEN NOT MATCHED THEN INSERT ({','.join(cols)}) VALUES ({insert_vals})
    """
    for r in rows:
        cur.execute(sql, tuple(r.get(c) for c in cols))


def _review_row(**kwargs) -> dict:
    payload = kwargs.pop("payload", None)
    return {
        "REVIEW_ID": str(uuid.uuid4()),
        "FILING_ID": kwargs["filing_id"],
        "ORG_ID": kwargs["org_id"],
        "STATEMENT": kwargs["statement"],
        "NATIVE_LABEL": kwargs["native_label"],
        "FY_LABEL": kwargs.get("fy_label"),
        "AMOUNT": kwargs.get("amount"),
        "CONFIDENCE": kwargs.get("confidence"),
        "REASON": kwargs["reason"],
        "SOURCE_PAGE": kwargs.get("source_page"),
        "PAYLOAD": payload,
    }


def _write_review(cur, rows: list[dict]) -> None:
    if not rows:
        return
    import json as _json

    sql = """
        INSERT INTO COMMON.REVIEW_QUEUE
          (REVIEW_ID, FILING_ID, ORG_ID, STATEMENT, NATIVE_LABEL, FY_LABEL,
           AMOUNT, CONFIDENCE, REASON, SOURCE_PAGE, PAYLOAD)
        SELECT %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,PARSE_JSON(%s)
    """
    for r in rows:
        cur.execute(
            sql,
            (
                r["REVIEW_ID"],
                r["FILING_ID"],
                r["ORG_ID"],
                r["STATEMENT"],
                r["NATIVE_LABEL"],
                r["FY_LABEL"],
                r["AMOUNT"],
                r["CONFIDENCE"],
                r["REASON"],
                r["SOURCE_PAGE"],
                _json.dumps(r["PAYLOAD"] or {}),
            ),
        )
