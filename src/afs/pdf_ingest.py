"""PDF text extraction via SNOWFLAKE.CORTEX.PARSE_DOCUMENT.

Replaces pdf_utils.py (pypdfium2 + image rendering) from the original package.
PDFs must be uploaded to @AFS_STAGE before calling these functions.

PARSE_DOCUMENT returns a VARIANT with structure:
  { "content": [{"page": 1, "text": "..."}, ...] }

The extracted text is stored in COMMON.PDF_STAGING so re-parsing a filing does not
require a second PARSE_DOCUMENT call (which consumes Cortex credits).
"""
from __future__ import annotations

import hashlib
import json
from typing import Any


def extract_and_stage(session, filename: str) -> dict[str, Any]:
    """Run PARSE_DOCUMENT on a staged PDF and return the staging row dict.

    Args:
        session: active Snowpark session
        filename: bare filename as it appears in @AFS_STAGE (e.g. "acme_fy2024.pdf")

    Returns:
        dict with keys: filename, filing_id, total_pages, page_texts (list of dicts)
    """
    sql = f"""
        SELECT
            SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
                @AUDITED_FINANCIALS.COMMON.AFS_STAGE/{filename},
                OBJECT_CONSTRUCT('mode', 'LAYOUT')
            )
    """
    row = session.sql(sql).collect()[0][0]
    parsed = json.loads(row) if isinstance(row, str) else row

    pages: list[dict] = parsed.get("content", [])
    # Normalise: ensure every item has {page, text}
    page_texts = [
        {"page": int(p.get("page", i + 1)), "text": str(p.get("text", ""))}
        for i, p in enumerate(pages)
    ]
    total_pages = len(page_texts)

    # filing_id: sha256 of concatenated text (stable across re-runs for same PDF)
    blob = json.dumps(page_texts, sort_keys=True, ensure_ascii=False).encode()
    filing_id = hashlib.sha256(blob).hexdigest()

    return {
        "filename": filename,
        "filing_id": filing_id,
        "total_pages": total_pages,
        "page_texts": page_texts,
    }


def get_page_texts(page_texts: list[dict], pages: list[int] | None = None) -> str:
    """Return concatenated text for the requested page numbers.

    Handles two formats:
      - Per-page array: [{"page": 1, "text": "..."}, {"page": 2, "text": "..."}, ...]
      - Single-blob (current PARSE_DOCUMENT): [{"page": 1, "text": "<entire document>"}]

    When only a single blob is stored (page count == 1 but total_pages > 1),
    the full text is returned regardless of the requested page numbers since
    page boundaries are not available.
    """
    by_page = {int(p["page"]): p["text"] for p in page_texts}
    if len(by_page) == 1 and 1 in by_page:
        return f"=== PAGE 1 ===\n{by_page[1]}"
    target = pages if pages is not None else sorted(by_page)
    parts = []
    for pg in sorted(target):
        text = by_page.get(pg, "")
        parts.append(f"=== PAGE {pg} ===\n{text}")
    return "\n\n".join(parts)


def pages_are_empty(page_texts: list[dict], pages: list[int]) -> bool:
    """Return True if all requested pages have no extractable text."""
    by_page = {int(p["page"]): p["text"] for p in page_texts}
    if len(by_page) == 1 and 1 in by_page:
        return not (by_page[1] or "").strip()
    return all(not (by_page.get(pg) or "").strip() for pg in pages)
