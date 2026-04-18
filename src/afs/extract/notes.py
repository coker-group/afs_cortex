"""Extract a single footnote from a range of pages."""
from __future__ import annotations

from ..cortex_llm import call_text_json, load_prompt
from ..pdf_ingest import get_page_texts
from ..schemas import NoteExtract


def extract_note(page_texts: list[dict], pages: list[int], fy_labels: list[str]) -> NoteExtract:
    tmpl = load_prompt("notes").replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    data = call_text_json(tmpl, text, max_tokens=6000)
    return NoteExtract(**data)
