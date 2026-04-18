"""Extract the four primary statements (IS, BS, CF, equity)."""
from __future__ import annotations

from ..cortex_llm import call_text_json, load_prompt
from ..pdf_ingest import get_page_texts
from ..schemas import StatementExtract

_STATEMENT_NAMES = {
    "is":     ("Consolidated Statement of Operations / Activities", "is"),
    "bs":     ("Consolidated Balance Sheet / Statement of Financial Position", "bs"),
    "cf":     ("Consolidated Statement of Cash Flows", "cf"),
    "equity": ("Consolidated Statement of Changes in Net Assets / Equity", "equity"),
}


def extract_statement(
    page_texts: list[dict],
    statement_code: str,
    pages: list[int],
    fy_labels: list[str],
) -> StatementExtract:
    if statement_code not in _STATEMENT_NAMES:
        raise ValueError(f"Unknown statement code {statement_code}")
    name, code = _STATEMENT_NAMES[statement_code]
    tmpl = load_prompt("statements")
    prompt = (
        tmpl.replace("{STATEMENT_NAME}", name)
            .replace("{STATEMENT_CODE}", code)
            .replace("{FY_LABELS}", ", ".join(fy_labels))
    )
    text = get_page_texts(page_texts, pages=pages)
    data = call_text_json(prompt, text, max_tokens=8000)
    return StatementExtract(**data)
