"""Extract BS supplementary exhibits (debt, investments, PP&E)."""
from __future__ import annotations

from typing import Any

from ..cortex_llm import call_text_json, load_prompt
from ..pdf_ingest import get_page_texts


def extract_bs_exhibit(page_texts: list[dict], pages: list[int], fy_labels: list[str]) -> dict[str, Any]:
    tmpl = load_prompt("bs_exhibit").replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    return call_text_json(tmpl, text, max_tokens=16000)
