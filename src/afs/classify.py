"""Page-by-page classification using extracted text."""
from __future__ import annotations

import re
from collections import Counter

from . import config as C
from .cortex_llm import call_text_json, load_prompt
from .pdf_ingest import get_page_texts
from .schemas import PageClassification

PAGES_PER_BATCH = 4


def _find_repeated_header(text: str, min_occurrences: int = 5) -> str | None:
    lines = text.split('\n')
    short_lines = [l.strip() for l in lines if 10 < len(l.strip()) < 80]
    counts = Counter(short_lines)
    for line, cnt in counts.most_common(5):
        if cnt >= min_occurrences:
            return line
    return None


def _split_blob_into_pages(text: str, total_pages: int) -> list[str]:
    header = _find_repeated_header(text, min_occurrences=max(3, total_pages // 4))
    if header:
        parts = text.split(header)
        chunks = [parts[0]] if parts[0].strip() else []
        for i in range(1, len(parts)):
            chunks.append(header + parts[i])
    else:
        candidates: list[int] = []
        for m in re.finditer(
            r'(?:(?:^|\n)#{1,2}\s+[A-Z]|(?:^|\n)\d{1,3}\n|(?:^|\n)\x0c)', text
        ):
            candidates.append(m.start())
        if len(candidates) >= total_pages * 0.5:
            candidates = sorted(set(candidates))
            if candidates[0] != 0:
                candidates.insert(0, 0)
            chunks = []
            for i in range(len(candidates)):
                start = candidates[i]
                end = candidates[i + 1] if i + 1 < len(candidates) else len(text)
                chunks.append(text[start:end])
        else:
            chunk_size = max(1, len(text) // total_pages)
            chunks = [text[i * chunk_size : (i + 1) * chunk_size] for i in range(total_pages)]

    while len(chunks) > total_pages:
        min_len = float('inf')
        min_idx = 1
        for i in range(1, len(chunks)):
            if len(chunks[i]) < min_len:
                min_len = len(chunks[i])
                min_idx = i
        chunks[min_idx - 1] += chunks[min_idx]
        chunks.pop(min_idx)

    while len(chunks) < total_pages:
        max_len = 0
        max_idx = 0
        for i, p in enumerate(chunks):
            if len(p) > max_len:
                max_len = len(p)
                max_idx = i
        mid = len(chunks[max_idx]) // 2
        chunks.insert(max_idx + 1, chunks[max_idx][mid:])
        chunks[max_idx] = chunks[max_idx][:mid]

    return chunks


def classify_pages(page_texts: list[dict], total_pages: int) -> list[PageClassification]:
    results: list[PageClassification] = []
    prompt_template = load_prompt("classify")
    is_single_blob = len(page_texts) == 1 and int(page_texts[0].get("page", 1)) == 1

    if is_single_blob:
        raw_text = page_texts[0].get("text", "")
        chunks = _split_blob_into_pages(raw_text, total_pages)

        for start_idx in range(0, total_pages, PAGES_PER_BATCH):
            end_idx = min(start_idx + PAGES_PER_BATCH, total_pages)
            batch_text_parts = []
            batch_page_nums = []
            for i in range(start_idx, end_idx):
                pg = i + 1
                batch_page_nums.append(pg)
                batch_text_parts.append(f"=== PAGE {pg} ===\n{chunks[i]}")
            text = "\n\n".join(batch_text_parts)
            page_map = ", ".join(f"page {p}" for p in batch_page_nums)
            prompt = f"{prompt_template}\n\nPages in this batch: {page_map}"
            data = call_text_json(prompt, text, max_tokens=4000, model=C.MODEL_CLASSIFY)
            for row in data.get("pages", []):
                results.append(PageClassification(**row))
    else:
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
    ordered = [by_page[p] for p in sorted(by_page)]
    _sanity_check(ordered)
    return ordered


import logging as _logging
_log = _logging.getLogger(__name__)

_EXPECTED_LABELS = {"is", "bs", "cf"}


def _sanity_check(classifications: list[PageClassification]) -> None:
    labels_present = {c.label for c in classifications}
    missing = _EXPECTED_LABELS - labels_present
    if missing:
        _log.warning(
            "Classification sanity check: missing expected labels %s. "
            "Low-confidence 'other' pages may be misclassified.",
            missing,
        )
    if "bs" not in labels_present and "is" in labels_present:
        _log.warning(
            "No 'bs' pages found but 'is' exists — balance sheet pages may "
            "be mislabeled as 'is' or 'other'. Check governmental naming "
            "(Statement of Net Position vs Statement of Revenues/Expenses)."
        )


def group_by_label(classifications: list[PageClassification]) -> dict[str, list[int]]:
    out: dict[str, list[int]] = {}
    for c in classifications:
        out.setdefault(c.label, []).append(c.page)
    return out
