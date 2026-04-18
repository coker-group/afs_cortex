"""Extract MD&A / operating-stats numeric facts from narrative + schedule pages."""
from __future__ import annotations

from typing import Any

from ..cortex_llm import call_text_json, load_prompt
from ..pdf_ingest import get_page_texts


def extract_stats(page_texts: list[dict], pages: list[int], fy_labels: list[str]) -> dict[str, Any]:
    tmpl = load_prompt("mdna_stats").replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    return call_text_json(tmpl, text, max_tokens=6000)
