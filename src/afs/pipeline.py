"""End-to-end orchestration: one staged PDF → Snowflake.

Cortex edition: takes pre-extracted page_texts from COMMON.PDF_STAGING rather
than a local PDF file path. No pypdfium2, no Anthropic SDK.
"""
from __future__ import annotations

import json as _json
import logging
import sys
import uuid
from datetime import datetime
from typing import Any

from . import config as C
from .classify import classify_pages, group_by_label
from .cortex_llm import init as llm_init
from .exhibits import write_bs_exhibit, write_is_exhibit, write_notes
from .extract.bs_exhibits import extract_bs_exhibit
from .extract.is_exhibits import extract_is_exhibit
from .extract.mdna_stats import extract_stats
from .extract.notes import extract_note
from .extract.statements import extract_statement
from .identify import identify_filing
from .insights import compute_ratios, compute_trends, synthesize_findings, write_findings
from .normalize import write_statement, write_stats
from .org_registry import find_existing, insert_org, new_org_id, suggest_org_code
from .pdf_ingest import pages_are_empty
from .schemas import IdentifyResult
from .snowflake_io import (
    _QmarkCursorWrapper,
    ensure_org_schema,
    filing_already_loaded,
    get_completed_stages,
    get_connection,
    mark_stage_completed,
    reset_stages,
)

log = logging.getLogger("afs.pipeline")


def init(session) -> None:
    """Must be called once per notebook session before process_filing."""
    llm_init(session)


# ---------- org resolution ----------
def _resolve_org(cur, ident: IdentifyResult, org_hint: dict | None = None) -> dict:
    existing = find_existing(cur, ident)
    if existing:
        return existing
    if org_hint:
        org_id = new_org_id()
        org_code = org_hint.get("org_code") or suggest_org_code(org_hint.get("legal_name") or ident.legal_name)
        ident2 = ident.model_copy(update={"legal_name": org_hint.get("legal_name") or ident.legal_name})
        insert_org(cur, org_id, org_code, ident2)
        return {"ORG_ID": org_id, "ORG_CODE": org_code, "LEGAL_NAME": ident2.legal_name, "EIN": ident.ein}
    raise RuntimeError(
        "New organization detected but no org_hint provided. "
        "Pass org_hint={'org_code': '...', 'legal_name': '...'} to process_filing()."
    )


# ---------- main pipeline ----------
def process_filing(
    session,
    filename: str,
    filing_id: str,
    page_texts: list[dict],
    total_pages: int,
    *,
    org_hint: dict | None = None,
    reparse: bool = False,
    staging_id: str | None = None,
) -> dict[str, Any]:
    """Process one filing from pre-extracted page texts.

    Args:
        session:     Snowpark session (used for Cortex LLM calls)
        filename:    Original PDF filename (for provenance)
        filing_id:   SHA-256 from PDF_STAGING (idempotency key)
        page_texts:  List of {"page": N, "text": "..."} from PDF_STAGING
        total_pages: Total page count
        org_hint:    {"org_code": "...", "legal_name": "..."} for new orgs
        reparse:     Re-extract even if filing already loaded
        staging_id:  STAGING_ID for checkpoint tracking (enables resume on retry)
    """
    init(session)

    report: dict[str, Any] = {
        "source_filename": filename,
        "filing_id": filing_id,
        "page_count": total_pages,
        "started_at": datetime.utcnow().isoformat(),
        "stages": {},
    }

    conn = get_connection(session)
    try:
        cur = _QmarkCursorWrapper(conn.cursor()) if session is not None else conn.cursor()
        try:
            done = get_completed_stages(cur, staging_id) if staging_id else set()

            def _checkpoint(stage: str) -> None:
                if staging_id:
                    mark_stage_completed(cur, staging_id, stage)
                    conn.commit()

            # ---- 1. identify ----
            ident = identify_filing(page_texts)
            report["identify"] = ident.model_dump()

            # ---- 2. resolve org ----
            org = _resolve_org(cur, ident, org_hint=org_hint)
            report["org"] = org

            # ---- 3. skip if already loaded ----
            if not reparse and filing_already_loaded(cur, filing_id):
                report["skipped"] = "already_loaded"
                return report

            ensure_org_schema(cur, org["ORG_CODE"])

            # ---- 4. classify pages ----
            classifications = classify_pages(page_texts, total_pages)
            groups = group_by_label(classifications)
            report["stages"]["classify"] = {k: len(v) for k, v in groups.items()}

            all_pages = list(range(1, total_pages + 1))
            if pages_are_empty(page_texts, all_pages):
                report["stages"]["warning"] = "all_pages_empty_text_possible_scanned_pdf"
                log.warning("[%s] All pages have empty text — PDF may be scanned/image-only", filename)

            fy_labels = ident.years_shown
            fye_by_year = ident.fye_by_year
            primary_fy = fy_labels[0] if fy_labels else None
            primary_fye = fye_by_year.get(primary_fy) if primary_fy else None

            # ---- 5. record filing row ----
            if "filing_row" not in done:
                cur.execute(
                    """
                    INSERT INTO COMMON.FILINGS
                      (FILING_ID, ORG_ID, FISCAL_YEAR_END, FY_LABEL, YEARS_PRESENT, AUDIT_FIRM,
                       AUDIT_OPINION, SOURCE_FILENAME, PAGE_COUNT, EXTRACTOR_VERSION, EXTRACTION_BLOB)
                    SELECT %s,%s,%s,%s,PARSE_JSON(%s),%s,%s,%s,%s,%s,PARSE_JSON(%s)
                    """,
                    (filing_id, org["ORG_ID"], primary_fye, primary_fy,
                     _json.dumps(fy_labels), ident.audit_firm, ident.audit_opinion,
                     filename, total_pages, C.EXTRACTOR_VERSION,
                     _json.dumps({"identify": ident.model_dump(),
                                  "classify": [c.model_dump() for c in classifications]})),
                )
                cur.execute(
                    f"""
                    INSERT INTO {org["ORG_CODE"]}.RAW_FILING_JSON
                      (FILING_ID, SOURCE_FILENAME, EXTRACTOR_VERSION, BLOB)
                    SELECT %s,%s,%s,PARSE_JSON(%s)
                    """,
                    (filing_id, filename, C.EXTRACTOR_VERSION,
                     _json.dumps({"identify": ident.model_dump(),
                                  "classify": [c.model_dump() for c in classifications]})),
                )
                _checkpoint("filing_row")
            else:
                log.info("[resume] skipping filing_row (already completed)")

            # ---- 6. primary statements ----
            if "statements" not in done:
                stmt_stats: dict[str, Any] = {}
                for stmt_code in ("is", "bs", "cf", "equity"):
                    pages = groups.get(stmt_code, [])
                    if not pages:
                        continue
                    extract = extract_statement(page_texts, stmt_code, pages, fy_labels)
                    stmt_stats[stmt_code] = write_statement(
                        cur, org_id=org["ORG_ID"], org_code=org["ORG_CODE"],
                        filing_id=filing_id, fye_by_year=fye_by_year, extract=extract,
                    )
                report["stages"]["statements"] = stmt_stats
                _checkpoint("statements")
            else:
                log.info("[resume] skipping statements (already completed)")

            # ---- 7. IS exhibits ----
            if "is_exhibits" not in done:
                is_exh_rows = 0
                for page_run in _contiguous_runs(groups.get("is_exhibit", [])):
                    payload = extract_is_exhibit(page_texts, page_run, fy_labels)
                    is_exh_rows += write_is_exhibit(cur, org["ORG_CODE"], filing_id, fye_by_year, payload)
                report["stages"]["is_exhibit_rows"] = is_exh_rows
                _checkpoint("is_exhibits")
            else:
                log.info("[resume] skipping is_exhibits (already completed)")

            # ---- 8. BS exhibits ----
            if "bs_exhibits" not in done:
                bs_exh_rows = 0
                for page_run in _contiguous_runs(groups.get("bs_exhibit", [])):
                    payload = extract_bs_exhibit(page_texts, page_run, fy_labels)
                    bs_exh_rows += write_bs_exhibit(cur, org["ORG_CODE"], filing_id, fye_by_year, payload)
                report["stages"]["bs_exhibit_rows"] = bs_exh_rows
                _checkpoint("bs_exhibits")
            else:
                log.info("[resume] skipping bs_exhibits (already completed)")

            # ---- 9. notes ----
            if "notes" not in done:
                note_count = 0
                note_errors: list[str] = []
                for page_run in _notes_grouped(classifications):
                    try:
                        note = extract_note(page_texts, page_run, fy_labels)
                        write_notes(cur, org["ORG_CODE"], filing_id, note.model_dump())
                        note_count += 1
                    except Exception as e:
                        note_errors.append(f"pages {page_run}: {type(e).__name__}: {e}")
                        log.warning("note extract failed for pages %s: %s", page_run, e)
                report["stages"]["notes"] = note_count
                if note_errors:
                    report["stages"]["note_errors"] = note_errors
                _checkpoint("notes")
            else:
                log.info("[resume] skipping notes (already completed)")

            # ---- 10. stats ----
            if "stats" not in done:
                stat_pages = sorted(set(groups.get("stats", []) + groups.get("mdna", [])))
                stat_stats = {"native_rows": 0, "common_rows": 0, "review_rows": 0}
                if stat_pages:
                    try:
                        payload = extract_stats(page_texts, stat_pages, fy_labels)
                        stat_stats = write_stats(
                            cur, org_id=org["ORG_ID"], org_code=org["ORG_CODE"],
                            filing_id=filing_id, fye_by_year=fye_by_year,
                            stat_rows=payload.get("rows", []),
                        )
                    except Exception as e:
                        log.warning("stats stage failed: %s", e)
                        report["stages"]["stats_error"] = f"{type(e).__name__}: {e}"
                report["stages"]["stats"] = stat_stats
                _checkpoint("stats")
            else:
                log.info("[resume] skipping stats (already completed)")

            # ---- 11. insights ----
            if "insights" not in done:
                try:
                    ratios = compute_ratios(cur, org["ORG_ID"])
                    trends = compute_trends(ratios)
                    findings = synthesize_findings(ratios, trends, org["ORG_CODE"])
                    n_findings = write_findings(cur, org["ORG_ID"], filing_id, primary_fy, findings)
                    report["stages"]["findings"] = n_findings
                except Exception as e:
                    log.warning("insights stage failed: %s", e)
                    report["stages"]["findings"] = 0
                    report["stages"]["insights_error"] = f"{type(e).__name__}: {e}"
                _checkpoint("insights")
            else:
                log.info("[resume] skipping insights (already completed)")

            conn.commit()
        finally:
            cur.close()
    except Exception:
        conn.rollback()
        raise

    report["finished_at"] = datetime.utcnow().isoformat()
    return report


def _contiguous_runs(pages: list[int]) -> list[list[int]]:
    if not pages:
        return []
    pages = sorted(pages)
    runs = [[pages[0]]]
    for p in pages[1:]:
        if p == runs[-1][-1] + 1:
            runs[-1].append(p)
        else:
            runs.append([p])
    out = []
    for r in runs:
        for i in range(0, len(r), 6):
            out.append(r[i : i + 6])
    return out


def _notes_grouped(classifications) -> list[list[int]]:
    note_pages = [(c.page, c.note_num) for c in classifications if c.label == "note"]
    if not note_pages:
        return []
    groups: dict[str, list[int]] = {}
    contig: list[list[int]] = []
    for page, note_num in sorted(note_pages):
        if note_num:
            groups.setdefault(note_num, []).append(page)
        else:
            if contig and page == contig[-1][-1] + 1:
                contig[-1].append(page)
            else:
                contig.append([page])
    return list(groups.values()) + contig
