"""Cover-page / auditor-letter / TOC scan to identify the filing."""
from __future__ import annotations

from .cortex_llm import call_text_json, load_prompt
from .pdf_ingest import get_page_texts
from .schemas import IdentifyResult


def identify_filing(page_texts: list[dict], scan_pages: int = 6) -> IdentifyResult:
    """Use first N pages of extracted text to identify the filing."""
    pages = list(range(1, scan_pages + 1))
    text = get_page_texts(page_texts, pages=pages)
    prompt = load_prompt("identify")
    data = call_text_json(prompt, text, max_tokens=2500)
    return IdentifyResult(**data)
