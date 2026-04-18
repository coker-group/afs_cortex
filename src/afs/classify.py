"""Page-by-page classification using extracted text."""
from __future__ import annotations

from . import config as C
from .cortex_llm import call_text_json, load_prompt
from .pdf_ingest import get_page_texts
from .schemas import PageClassification

PAGES_PER_BATCH = 4


def classify_pages(page_texts: list[dict], total_pages: int) -> list[PageClassification]:
    results: list[PageClassification] = []
    prompt_template = load_prompt("classify")
    for start in range(1, total_pages + 1, PAGES_PER_BATCH):
        end = min(start + PAGES_PER_BATCH - 1, total_pages)
        batch_pages = list(range(start, end + 1))
        text = get_page_texts(page_texts, pages=batch_pages)
        page_map = ", ".join(f"page {p}" for p in batch_pages)
        prompt = f"{prompt_template}\n\nPages in this batch: {page_map}"
        data = call_text_json(prompt, text, max_tokens=4000, model=C.MODEL_CLASSIFY)
        for row in data.get("pages", []):
            results.append(PageClassification(**row))
    by_page: dict[int, PageClassification] = {}
    for r in results:
        by_page[r.page] = r
    return [by_page[p] for p in sorted(by_page)]


def group_by_label(classifications: list[PageClassification]) -> dict[str, list[int]]:
    out: dict[str, list[int]] = {}
    for c in classifications:
        out.setdefault(c.label, []).append(c.page)
    return out
