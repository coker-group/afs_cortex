"""Writers for IS/BS exhibit extractor output into per-org exhibit tables."""
from __future__ import annotations

import json as _json
from typing import Any, Iterable


def write_is_exhibit(cur, org_code: str, filing_id: str, fye_by_year: dict[str, str], payload: dict[str, Any]) -> int:
    rows = payload.get("rows") or []
    out_rows = []
    for r in rows:
        fy = r.get("fy_label")
        amt = r.get("amount")
        dim = r.get("dimension") or payload.get("dimension")
        cat = r.get("category")
        page = r.get("source_page")
        conf = r.get("confidence", 1.0)
        if r.get("entity"):
            out_rows.append(
                {
                    "table": "IS_EXHIBIT_ENTITY",
                    "row": {
                        "FILING_ID": filing_id,
                        "FY_LABEL": fy,
                        "FISCAL_YEAR_END": fye_by_year.get(fy),
                        "ENTITY": r.get("entity"),
                        "NATIVE_LABEL": cat,
                        "AMOUNT": amt,
                        "SOURCE_PAGE": page,
                        "CONFIDENCE": conf,
                    },
                }
            )
        elif dim in ("payer", "service_line"):
            out_rows.append(
                {
                    "table": "IS_EXHIBIT_REVENUE",
                    "row": {
                        "FILING_ID": filing_id,
                        "FY_LABEL": fy,
                        "FISCAL_YEAR_END": fye_by_year.get(fy),
                        "DIMENSION": dim,
                        "CATEGORY": cat,
                        "AMOUNT": amt,
                        "SOURCE_PAGE": page,
                        "CONFIDENCE": conf,
                    },
                }
            )
        elif dim in ("natural_account", "functional"):
            out_rows.append(
                {
                    "table": "IS_EXHIBIT_EXPENSE",
                    "row": {
                        "FILING_ID": filing_id,
                        "FY_LABEL": fy,
                        "FISCAL_YEAR_END": fye_by_year.get(fy),
                        "DIMENSION": dim,
                        "CATEGORY": cat,
                        "AMOUNT": amt,
                        "SOURCE_PAGE": page,
                        "CONFIDENCE": conf,
                    },
                }
            )
    _bulk_by_table(cur, org_code, out_rows)
    return len(out_rows)


def write_bs_exhibit(cur, org_code: str, filing_id: str, fye_by_year: dict[str, str], payload: dict[str, Any]) -> int:
    kind = payload.get("exhibit_type")
    rows = payload.get("rows") or []
    out_rows: list[dict] = []
    if kind == "debt":
        for r in rows:
            for fy, amt in (r.get("outstanding_by_fy") or {}).items():
                out_rows.append(
                    {
                        "table": "BS_EXHIBIT_DEBT",
                        "row": {
                            "FILING_ID": filing_id,
                            "FY_LABEL": fy,
                            "FISCAL_YEAR_END": fye_by_year.get(fy),
                            "INSTRUMENT": r.get("instrument"),
                            "OUTSTANDING": amt,
                            "RATE": r.get("rate"),
                            "MATURITY_YEAR": r.get("maturity_year"),
                            "SECURED": r.get("secured"),
                            "COVENANTS_TEXT": r.get("covenants_text"),
                            "SOURCE_PAGE": r.get("source_page"),
                            "CONFIDENCE": r.get("confidence", 1.0),
                        },
                    }
                )
    elif kind == "investments":
        for r in rows:
            for fy, amt in (r.get("fair_value_by_fy") or {}).items():
                out_rows.append(
                    {
                        "table": "BS_EXHIBIT_INVESTMENTS",
                        "row": {
                            "FILING_ID": filing_id,
                            "FY_LABEL": fy,
                            "FISCAL_YEAR_END": fye_by_year.get(fy),
                            "FV_LEVEL": r.get("fv_level"),
                            "CATEGORY": r.get("category"),
                            "FAIR_VALUE": amt,
                            "SOURCE_PAGE": r.get("source_page"),
                            "CONFIDENCE": r.get("confidence", 1.0),
                        },
                    }
                )
    elif kind == "ppe":
        for r in rows:
            for fy, detail in (r.get("by_fy") or {}).items():
                out_rows.append(
                    {
                        "table": "BS_EXHIBIT_PPE",
                        "row": {
                            "FILING_ID": filing_id,
                            "FY_LABEL": fy,
                            "FISCAL_YEAR_END": fye_by_year.get(fy),
                            "CATEGORY": r.get("category"),
                            "COST": (detail or {}).get("cost"),
                            "ACCUM_DEPR": (detail or {}).get("accum_depr"),
                            "NET": (detail or {}).get("net"),
                            "SOURCE_PAGE": r.get("source_page"),
                            "CONFIDENCE": r.get("confidence", 1.0),
                        },
                    }
                )
    _bulk_by_table(cur, org_code, out_rows)
    return len(out_rows)


def _bulk_by_table(cur, org_code: str, rows: Iterable[dict]) -> None:
    by_table: dict[str, list[dict]] = {}
    for r in rows:
        by_table.setdefault(r["table"], []).append(r["row"])
    for table, batch in by_table.items():
        if not batch:
            continue
        cols = list(batch[0].keys())
        placeholders = ",".join(["%s"] * len(cols))
        sql = f"INSERT INTO {org_code}.{table} ({','.join(cols)}) VALUES ({placeholders})"
        cur.executemany(sql, [tuple(r.get(c) for c in cols) for r in batch])


def write_notes(cur, org_code: str, filing_id: str, note: dict[str, Any]) -> None:
    # NOTES primary key is (FILING_ID, NOTE_NUM). If the model didn't supply a number
    # (common for multi-page note continuations or unnumbered schedules), synthesize a
    # stable key from the page range so MERGE doesn't collide across unnumbered notes.
    note_num = note.get("note_num")
    if not note_num:
        start = note.get("source_page_start")
        end = note.get("source_page_end")
        note_num = f"p{start}-{end}" if start and end else f"p{start or 'x'}"
    cur.execute(
        f"""
        MERGE INTO {org_code}.NOTES t
        USING (SELECT %s FILING_ID, %s NOTE_NUM, %s TITLE,
                      %s BODY_TEXT, PARSE_JSON(%s) CALLOUTS,
                      %s SOURCE_PAGE_START, %s SOURCE_PAGE_END) s
        ON t.FILING_ID=s.FILING_ID AND t.NOTE_NUM=s.NOTE_NUM
        WHEN MATCHED THEN UPDATE SET
          TITLE=s.TITLE, BODY_TEXT=s.BODY_TEXT, CALLOUTS=s.CALLOUTS,
          SOURCE_PAGE_START=s.SOURCE_PAGE_START, SOURCE_PAGE_END=s.SOURCE_PAGE_END
        WHEN NOT MATCHED THEN INSERT
          (FILING_ID, NOTE_NUM, TITLE, BODY_TEXT, CALLOUTS, SOURCE_PAGE_START, SOURCE_PAGE_END)
          VALUES (s.FILING_ID, s.NOTE_NUM, s.TITLE, s.BODY_TEXT, s.CALLOUTS,
                  s.SOURCE_PAGE_START, s.SOURCE_PAGE_END)
        """,
        (
            filing_id,
            note_num,
            note.get("title"),
            note.get("body_text"),
            _json.dumps(note.get("callouts") or []),
            note.get("source_page_start"),
            note.get("source_page_end"),
        ),
    )
