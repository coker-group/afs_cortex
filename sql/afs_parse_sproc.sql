CREATE OR REPLACE PROCEDURE AUDITED_FINANCIALS.COMMON.PROCESS_PENDING_FILINGS(
    STAGING_ID_FILTER STRING DEFAULT NULL,
    ORG_HINT_JSON STRING DEFAULT NULL,
    REPARSE BOOLEAN DEFAULT FALSE
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'pydantic>=2.0', 'rapidfuzz>=3.0')
-- NOTE: All SQL bind params use ? (qmark) format, not %s (pyformat)
HANDLER = 'run'
EXECUTE AS CALLER
AS
$$
import json
import re
import uuid
import hashlib
import logging
from datetime import datetime
from typing import Any, Optional, Literal

from pydantic import BaseModel, Field
from rapidfuzz import fuzz, process as rfprocess


logging.basicConfig(level=logging.INFO, format='%(levelname)s %(name)s %(message)s')
log = logging.getLogger("afs.sproc")

EXTRACTOR_VERSION = "0.2.0"
MODEL_ID       = "mistral-large2"
MODEL_CLASSIFY = "mistral-large2"
MODEL_MAP      = "mistral-large2"
MIN_NUMERIC_CONFIDENCE = 0.85
MIN_MAPPING_CONFIDENCE = 0.90
SNOWFLAKE_DATABASE = "AUDITED_FINANCIALS"

_SAFE_IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]{0,254}$')

def _validate_identifier(name, label="identifier"):
    if not _SAFE_IDENT_RE.match(name):
        raise ValueError(f"Unsafe Snowflake {label}: {name!r}")
    return name


# ═══════════════════════════════════════════════════════════════════════
# PROMPTS (embedded)
# ═══════════════════════════════════════════════════════════════════════

PROMPT_IDENTIFY = r"""# Identify filing

You are reading extracted text from the first several pages (cover, independent auditor's letter, table of contents) of a US health system **audited financial statement** PDF.

Extract the filing's identity and structure. Return a single JSON object with this exact shape:

```json
{
  "legal_name": "string — full legal entity name as stated",
  "dba": "string or null",
  "ein": "string or null — if shown anywhere",
  "hq_state": "2-letter state code or null",
  "fye_month": 1-12,
  "sector": "health_system | hospital | amc | clinic | payer_provider | other",
  "audit_firm": "string or null",
  "audit_opinion": "unqualified | qualified | adverse | disclaimer | unknown",
  "years_shown": ["FY2024", "FY2023"],
  "fye_by_year": {"FY2024": "2024-06-30", "FY2023": "2023-06-30"},
  "table_of_contents": [
     {"section": "Consolidated Balance Sheets", "page": 3},
     {"section": "Consolidated Statements of Operations", "page": 4}
  ],
  "confidence": 0.0-1.0
}
```

Rules:
- `years_shown` must list every fiscal year that appears as a column in the comparative statements, ordered newest first. Use the `FY{YYYY}` convention where `YYYY` is the calendar year in which the fiscal year ends.
- `fye_by_year` maps each of those `FY` labels to the actual fiscal year-end date (ISO format).
- `table_of_contents` should reflect the TOC if one is present in the text; otherwise leave it empty.
- Page numbers in `table_of_contents` are the page numbers as printed or listed in the TOC, not text extraction sequence numbers.
- If you cannot determine a value with high confidence, use `null`. Do not guess EINs.
- Return JSON only — no prose, no markdown fences."""

PROMPT_CLASSIFY = r"""# Classify pages

You will receive extracted text from consecutive pages of a US health system audited financial statement. Each page's text is delimited by `=== PAGE N ===`. Classify **each page** with one label from this list:

- `cover` — title / front matter
- `toc` — table of contents
- `auditor_letter` — independent auditor's report
- `is` — primary consolidated statement of operations / activities / income
- `bs` — primary consolidated balance sheet / statement of financial position
- `cf` — primary consolidated statement of cash flows
- `equity` — primary consolidated statement of changes in net assets / equity
- `is_exhibit` — supplementary income statement schedule (segment/entity P&L, revenue mix, expense detail, functional expense)
- `bs_exhibit` — supplementary balance sheet schedule (debt, investments, PP&E, lease rollforward)
- `note` — a footnote page (policies, commitments, pension, related party, subsequent events, etc.)
- `mdna` — management's discussion / letter / operating highlights narrative
- `stats` — operating statistics, volumes, FTEs, ratios (often a supplementary schedule)
- `other` — anything else (blank, divider, signature, etc.)

Return JSON with this shape:

```json
{
  "pages": [
    {"page": 1, "label": "cover", "topic": null, "note_num": null, "confidence": 0.99},
    {"page": 2, "label": "note", "topic": "long-term debt", "note_num": "7", "confidence": 0.97}
  ]
}
```

Rules:
- `topic` is a short phrase for `is_exhibit`, `bs_exhibit`, `note`, `mdna`, `stats`; else `null`.
- `note_num` is only filled for `note` pages when the note number is clearly stated in the text.
- The page numbers you emit MUST match the page numbers in the `=== PAGE N ===` delimiters.
- If a page has no text (blank or image-only), classify it as `other` with confidence 0.5.
- Return JSON only — no prose, no markdown fences."""

PROMPT_STATEMENTS = r"""# Extract primary financial statement

You are extracting a **{STATEMENT_NAME}** (`{STATEMENT_CODE}`) from extracted text of one or more pages of a health system audit. The PDF's comparative columns are: **{FY_LABELS}** (newest first).

Return a JSON object:

```json
{
  "statement": "{STATEMENT_CODE}",
  "lines": [
    {
      "line_order": 1,
      "native_label": "Net patient service revenue",
      "is_subtotal": false,
      "parent_label": null,
      "section": null,
      "amounts": [
        {"fy_label": "FY2024", "amount": 1234567.0, "confidence": 0.99},
        {"fy_label": "FY2023", "amount": 1100000.0, "confidence": 0.99}
      ],
      "source_page": 4
    }
  ]
}
```

Rules:
- `line_order` is a strictly increasing integer reflecting presentation order in the document.
- `native_label` is the line caption **exactly as it appears in the text** (preserve capitalization, strip leading/trailing whitespace).
- `is_subtotal` is true for totals and subtotals (e.g., "Total operating expenses", "Operating income (loss)").
- `parent_label` is the immediate parent subtotal/section header if the item is indented under it; otherwise null.
- For cash flow statements, set `section` to one of `operating`, `investing`, `financing`, or `reconciliation`. For other statements, leave `section` null.
- `amounts[].amount` is the raw number in **dollars**, with sign as stated (parentheses mean negative). If a cell is blank or contains `—`/`-`, use null. Do not include the thousands/millions divisor — if the header says "(in thousands)", multiply by 1,000 to return whole dollars. If "(in millions)", multiply by 1,000,000.
- Amounts per line MUST include one entry per FY label, even if null.
- `source_page` is the page number from the `=== PAGE N ===` delimiter where the line appears.
- Include subtotals and totals so footing can be verified.
- Return JSON only — no prose, no markdown fences."""

PROMPT_IS_EXHIBIT = r"""# Extract income statement supplementary exhibit

You are extracting a supplementary schedule from a health system audit. Fiscal year columns present: **{FY_LABELS}**. Pages are delimited by `=== PAGE N ===` in the document text.

Identify the schedule type, then extract rows.

Return JSON:

```json
{
  "exhibit_type": "entity | revenue_mix | expense_detail | functional_expense | other",
  "dimension": "payer | service_line | entity | natural_account | functional | other",
  "rows": [
    {
      "entity": "Main Hospital",
      "dimension": "entity",
      "category": "Net patient service revenue",
      "fy_label": "FY2024",
      "amount": 1234567.0,
      "source_page": 34,
      "confidence": 0.97
    }
  ]
}
```

Rules:
- For **entity P&L** exhibits: `dimension = "entity"`, `entity` is the subsidiary/segment, `category` is the line item. Emit one row per entity x category x fy.
- For **revenue mix** exhibits: `dimension = "payer"` or `"service_line"`, `category` is the payer/service name.
- For **expense detail/functional** exhibits: `dimension = "natural_account"` or `"functional"`, `category` is the expense type.
- Amounts in dollars, sign-preserved, multiplied by the column-header scale (thousands -> 1000x, millions -> 1000000x).
- `source_page` is the page number from the `=== PAGE N ===` delimiter.
- Each visible cell becomes a row. Omit subtotal rows unless the schedule contains no detail rows.
- Return JSON only — no prose, no markdown fences."""

PROMPT_BS_EXHIBIT = r"""# Extract balance sheet supplementary exhibit

You are extracting a supplementary balance sheet schedule. Fiscal year columns present: **{FY_LABELS}**. Pages are delimited by `=== PAGE N ===` in the document text.

Identify the schedule type (`debt`, `investments`, `ppe`, `lease`, `other`) and return the relevant JSON structure.

## If `debt` schedule:

```json
{
  "exhibit_type": "debt",
  "rows": [
    {
      "instrument": "Series 2020A Revenue Bonds",
      "outstanding_by_fy": {"FY2024": 150000000.0, "FY2023": 155000000.0},
      "rate": 0.045,
      "maturity_year": 2045,
      "secured": true,
      "covenants_text": "Debt service coverage ratio >= 1.10x; days cash >= 75",
      "source_page": 45,
      "confidence": 0.95
    }
  ]
}
```

## If `investments` schedule:

```json
{
  "exhibit_type": "investments",
  "rows": [
    {
      "fv_level": "1 | 2 | 3 | nav",
      "category": "US equities",
      "fair_value_by_fy": {"FY2024": 250000000.0, "FY2023": 220000000.0},
      "source_page": 38,
      "confidence": 0.97
    }
  ]
}
```

## If `ppe` schedule:

```json
{
  "exhibit_type": "ppe",
  "rows": [
    {
      "category": "Buildings and improvements",
      "by_fy": {
        "FY2024": {"cost": 500000000.0, "accum_depr": -220000000.0, "net": 280000000.0},
        "FY2023": {"cost": 480000000.0, "accum_depr": -205000000.0, "net": 275000000.0}
      },
      "source_page": 40,
      "confidence": 0.96
    }
  ]
}
```

Rules:
- Amounts in dollars with column-scale applied.
- `rate` expressed as a decimal (0.045 = 4.5%) or null.
- `source_page` is the page number from the `=== PAGE N ===` delimiter.
- If you cannot identify the schedule type, set `exhibit_type = "other"` and return `{ "exhibit_type": "other", "rows": [] }`.
- Return JSON only — no prose, no markdown fences."""

PROMPT_NOTES = r"""# Extract footnote

You are extracting a footnote / note to the financial statements from a health system audit. Fiscal year columns present: **{FY_LABELS}**. Pages are delimited by `=== PAGE N ===` in the document text.

Return JSON:

```json
{
  "note_num": "7",
  "title": "Long-term debt",
  "body_text": "Verbatim prose of the note, excluding embedded tables. Preserve paragraph breaks with \\n\\n.",
  "callouts": [
    {"concept": "days_cash_covenant", "fy_label": "FY2024", "amount": 75, "uom": "days", "context": "required minimum"},
    {"concept": "dscr_actual", "fy_label": "FY2024", "amount": 2.4, "uom": "ratio"}
  ],
  "source_page_start": 44,
  "source_page_end": 46
}
```

Rules:
- `body_text` is the narrative prose. Summarize embedded tables briefly in prose; do NOT reproduce large tables verbatim.
- `callouts` captures specific numeric facts useful for insight generation: covenant thresholds, actual compliance values, pension funded status, discount rate assumptions, related-party amounts, subsequent events, contingency reserves, etc. Use concept names in snake_case. `uom` is one of `"days"`, `"ratio"`, `"pct"`, `"usd"`, or `"count"`.
- `source_page_start` and `source_page_end` are page numbers from the `=== PAGE N ===` delimiters.
- If multiple notes appear on the provided pages, return the FIRST note and omit the rest.
- Return JSON only — no prose, no markdown fences."""

PROMPT_MDNA_STATS = r"""# Extract operating statistics / MD&A metrics

You are extracting quantitative operating and financial statistics from MD&A or supplementary stats pages. Fiscal year columns present: **{FY_LABELS}**. Pages are delimited by `=== PAGE N ===` in the document text.

Return JSON:

```json
{
  "rows": [
    {"native_label": "Adjusted admissions", "fy_label": "FY2024", "amount": 54230, "uom": "count", "source_page": 80, "confidence": 0.98},
    {"native_label": "Operating margin", "fy_label": "FY2024", "amount": 3.2, "uom": "pct", "source_page": 80, "confidence": 0.97},
    {"native_label": "Days cash on hand", "fy_label": "FY2024", "amount": 215, "uom": "days", "source_page": 80, "confidence": 0.97}
  ]
}
```

Rules:
- Emit one row per stat x fiscal year.
- `uom` is one of `"count"`, `"days"`, `"ratio"`, `"pct"`, `"usd"`, `"fte"`, `"bed"`, `"years"`.
- For percentages, return as a percent number (3.2 means 3.2%, not 0.032).
- `source_page` is the page number from the `=== PAGE N ===` delimiter.
- Skip rows whose value is blank or `n/a`.
- Return JSON only — no prose, no markdown fences."""

PROMPT_MAP_CONCEPT = r"""# Map native label to standard concept

You are mapping a health system's native financial statement line label to one concept from a controlled taxonomy.

**Native label:** `{NATIVE_LABEL}`
**Statement:** `{STATEMENT}`  (`income_statement` | `balance_sheet` | `cash_flow` | `stat`)
**Allowed concepts** (concept — definition):
{CANDIDATES}

Return JSON:

```json
{
  "native_label": "{NATIVE_LABEL}",
  "statement": "{STATEMENT}",
  "concept": "net_patient_service_revenue",
  "confidence": 0.95,
  "rationale": "One sentence explaining the match (or why none fits)."
}
```

Rules:
- Pick the **single** best concept from the list above. If no concept fits, return `"concept": null` and explain in `rationale`.
- Common gotchas:
  - Many orgs roll several items into a single caption — use the closest parent concept and note this in `rationale`.
  - "Provision for bad debts" presented as a contra-revenue item is part of `net_patient_service_revenue`, not a separate concept (unless the list explicitly contains one).
  - "Research and grant revenue" is usually `other_operating_revenue`.
  - "Medical supplies and drugs" combined -> use `supplies` unless `pharmaceuticals` is separately listed.
- `confidence` reflects how certain you are the mapping is correct given the label and statement context.
- Return JSON only."""

PROMPT_INSIGHTS = r"""# Generate consulting findings

You are a healthcare financial-performance consultant. Given a health system's computed ratios, trends, and notable facts, draft 3-8 actionable findings Coker could pursue in a client engagement. Focus on realistic improvement opportunities with sized dollar impact anchored to the org's own revenue/expense base.

Input (JSON):
```
{INPUT}
```

For each finding, produce:

```json
{
  "findings": [
    {
      "category": "margin | revenue_cycle | labor | supply_chain | purchased_services | capital | liquidity | debt | pension | other",
      "severity": "high | medium | low",
      "title": "One-line headline (<=90 chars)",
      "narrative": "2-4 sentences: what you see, why it matters, what typically drives improvement. Reference specific numbers and years from the input.",
      "est_impact_low": 0,
      "est_impact_high": 0,
      "impact_unit": "usd_annualized",
      "supporting_concepts": [
        {"concept": "purchased_services", "fy_label": "FY2024", "amount": 0, "basis": "actual"},
        {"concept": "total_operating_expense", "fy_label": "FY2024", "amount": 0, "basis": "actual"}
      ],
      "playbook_hint": "Coker service line most relevant (e.g., Revenue Cycle, Provider Compensation, Physician Alignment, Strategy & Transactions)"
    }
  ]
}
```

Rules:
- Tie each finding to at least two `supporting_concepts` drawn from the input.
- Be specific with sizing.
- Use ranges (`est_impact_low` to `est_impact_high`) rather than point estimates.
- If a finding has no credible $ impact, set both to null.
- Return JSON only — no prose, no markdown fences."""


# ═══════════════════════════════════════════════════════════════════════
# PYDANTIC SCHEMAS
# ═══════════════════════════════════════════════════════════════════════

class IdentifyResult(BaseModel):
    legal_name: str
    dba: Optional[str] = None
    ein: Optional[str] = None
    hq_state: Optional[str] = None
    fye_month: Optional[int] = Field(default=None, ge=1, le=12)
    sector: Optional[str] = None
    audit_firm: Optional[str] = None
    audit_opinion: Optional[str] = None
    years_shown: list = Field(default_factory=list)
    fye_by_year: dict = Field(default_factory=dict)
    table_of_contents: list = Field(default_factory=list)
    confidence: float = 1.0

PageLabel = Literal[
    "cover", "toc", "auditor_letter", "is", "bs", "cf", "equity",
    "is_exhibit", "bs_exhibit", "note", "mdna", "stats", "other",
]

class PageClassification(BaseModel):
    page: int
    label: str
    topic: Optional[str] = None
    note_num: Optional[str] = None
    confidence: float = 1.0

class StatementAmount(BaseModel):
    fy_label: str
    amount: Optional[float] = None
    confidence: float = 1.0

class StatementLine(BaseModel):
    line_order: int
    native_label: str
    is_subtotal: bool = False
    parent_label: Optional[str] = None
    section: Optional[str] = None
    amounts: list = Field(default_factory=list)
    source_page: int

class StatementExtract(BaseModel):
    statement: str
    lines: list = Field(default_factory=list)

class MappingProposal(BaseModel):
    native_label: str
    statement: str
    concept: Optional[str] = None
    confidence: float = 0.0
    rationale: str = ""

class NoteExtract(BaseModel):
    note_num: Optional[str] = None
    title: Optional[str] = None
    body_text: str = ""
    callouts: list = Field(default_factory=list)
    source_page_start: int = 0
    source_page_end: int = 0


# ═══════════════════════════════════════════════════════════════════════
# LLM HELPERS
# ═══════════════════════════════════════════════════════════════════════

_SESSION = None

def _parse_json_text(text):
    text = text.strip()
    fence = re.match(r"^```(?:json)?\s*(.*?)\s*```$", text, re.DOTALL)
    if fence:
        text = fence.group(1)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        i, j = text.find("{"), text.rfind("}")
        if i != -1 and j != -1 and j > i:
            return json.loads(text[i : j + 1])
        raise

def _cortex_complete(model, prompt):
    conn = _SESSION._conn._conn
    c = conn.cursor()
    c.execute("SELECT SNOWFLAKE.CORTEX.COMPLETE(%s, %s)", (model, prompt))
    row = c.fetchone()
    c.close()
    return row[0]

def _repair_json(text, error, model):
    repair_prompt = (
        "The following text should be a single JSON object, but parsing failed with: "
        f"{error}\n\n"
        "Return ONLY a corrected, strictly valid JSON object with no prose, no markdown fences. "
        "Preserve every field and value. If the input was truncated mid-row, drop the partial "
        "trailing row/record so the overall structure becomes valid. Do not invent new values.\n\n"
        "----- INPUT -----\n"
        f"{text}\n"
        "----- END INPUT -----"
    )
    return _cortex_complete(model, repair_prompt)

def call_text_json(prompt, context_text, max_tokens=8000, model=None, retries=3):
    model = model or MODEL_ID
    sys_block = (
        "You are a meticulous financial statement extractor. "
        "Return ONLY a valid JSON object matching the requested schema. "
        "Do not include any prose before or after the JSON. "
        "If a value is missing or illegible, use null rather than guessing."
    )
    full_prompt = (
        f"{sys_block}\n\n{prompt}\n\n"
        "--- DOCUMENT TEXT ---\n"
        f"{context_text}\n"
        "--- END DOCUMENT TEXT ---"
    )
    last_err = None
    for attempt in range(retries + 1):
        try:
            response = _cortex_complete(model, full_prompt)
            try:
                return _parse_json_text(response)
            except (json.JSONDecodeError, ValueError) as e:
                repaired = _repair_json(response, str(e), model)
                return _parse_json_text(repaired)
        except Exception as e:
            last_err = e
            log.warning("attempt %d/%d failed: %s", attempt + 1, retries + 1, e)
    raise RuntimeError(f"CORTEX.COMPLETE failed after {retries + 1} attempts: {last_err}")

def call_text_json_no_context(prompt, model=None, retries=3):
    model = model or MODEL_ID
    last_err = None
    for attempt in range(retries + 1):
        try:
            response = _cortex_complete(model, prompt)
            try:
                return _parse_json_text(response)
            except (json.JSONDecodeError, ValueError) as e:
                repaired = _repair_json(response, str(e), model)
                return _parse_json_text(repaired)
        except Exception as e:
            last_err = e
    raise RuntimeError(f"CORTEX.COMPLETE failed after {retries + 1} attempts: {last_err}")


# ═══════════════════════════════════════════════════════════════════════
# PDF TEXT HELPERS
# ═══════════════════════════════════════════════════════════════════════

def get_page_texts(page_texts, pages=None):
    by_page = {int(p["page"]): p["text"] for p in page_texts}
    if len(by_page) == 1 and 1 in by_page:
        return f"=== PAGE 1 ===\n{by_page[1]}"
    target = pages if pages is not None else sorted(by_page)
    parts = []
    for pg in sorted(target):
        text = by_page.get(pg, "")
        parts.append(f"=== PAGE {pg} ===\n{text}")
    return "\n\n".join(parts)

def pages_are_empty(page_texts, pages):
    by_page = {int(p["page"]): p["text"] for p in page_texts}
    if len(by_page) == 1 and 1 in by_page:
        return not (by_page[1] or "").strip()
    return all(not (by_page.get(pg) or "").strip() for pg in pages)


# ═══════════════════════════════════════════════════════════════════════
# IDENTIFY
# ═══════════════════════════════════════════════════════════════════════

def identify_filing(page_texts, scan_pages=6):
    pages = list(range(1, scan_pages + 1))
    text = get_page_texts(page_texts, pages=pages)
    data = call_text_json(PROMPT_IDENTIFY, text, max_tokens=2500)
    return IdentifyResult(**data)


# ═══════════════════════════════════════════════════════════════════════
# CLASSIFY
# ═══════════════════════════════════════════════════════════════════════

PAGES_PER_BATCH = 4

def classify_pages(page_texts, total_pages):
    results = []
    is_single_blob = len(page_texts) == 1 and int(page_texts[0].get("page", 1)) == 1
    if is_single_blob:
        text = get_page_texts(page_texts)
        page_map = f"pages 1 through {total_pages}"
        prompt = (
            f"{PROMPT_CLASSIFY}\n\n"
            f"This document has {total_pages} pages. The full text is provided as a single block "
            f"(page boundaries are not marked). Infer page breaks from layout cues such as headers, "
            f"footers, page numbers, and section transitions. Classify all {total_pages} pages."
            f"\n\nPages in this batch: {page_map}"
        )
        data = call_text_json(prompt, text, max_tokens=16000, model=MODEL_CLASSIFY)
        for row in data.get("pages", []):
            results.append(PageClassification(**row))
    else:
        for start in range(1, total_pages + 1, PAGES_PER_BATCH):
            end = min(start + PAGES_PER_BATCH - 1, total_pages)
            batch_pages = list(range(start, end + 1))
            text = get_page_texts(page_texts, pages=batch_pages)
            page_map = ", ".join(f"page {p}" for p in batch_pages)
            prompt = f"{PROMPT_CLASSIFY}\n\nPages in this batch: {page_map}"
            data = call_text_json(prompt, text, max_tokens=4000, model=MODEL_CLASSIFY)
            for row in data.get("pages", []):
                results.append(PageClassification(**row))

    by_page = {}
    for r in results:
        by_page[r.page] = r
    return [by_page[p] for p in sorted(by_page)]

def group_by_label(classifications):
    out = {}
    for c in classifications:
        out.setdefault(c.label, []).append(c.page)
    return out


# ═══════════════════════════════════════════════════════════════════════
# EXTRACTORS
# ═══════════════════════════════════════════════════════════════════════

_STATEMENT_NAMES = {
    "is":     ("Consolidated Statement of Operations / Activities", "is"),
    "bs":     ("Consolidated Balance Sheet / Statement of Financial Position", "bs"),
    "cf":     ("Consolidated Statement of Cash Flows", "cf"),
    "equity": ("Consolidated Statement of Changes in Net Assets / Equity", "equity"),
}

def extract_statement(page_texts, statement_code, pages, fy_labels):
    if statement_code not in _STATEMENT_NAMES:
        raise ValueError(f"Unknown statement code {statement_code}")
    name, code = _STATEMENT_NAMES[statement_code]
    prompt = (
        PROMPT_STATEMENTS
            .replace("{STATEMENT_NAME}", name)
            .replace("{STATEMENT_CODE}", code)
            .replace("{FY_LABELS}", ", ".join(fy_labels))
    )
    text = get_page_texts(page_texts, pages=pages)
    data = call_text_json(prompt, text, max_tokens=8000)
    return StatementExtract(**data)

def extract_is_exhibit(page_texts, pages, fy_labels):
    tmpl = PROMPT_IS_EXHIBIT.replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    return call_text_json(tmpl, text, max_tokens=16000)

def extract_bs_exhibit(page_texts, pages, fy_labels):
    tmpl = PROMPT_BS_EXHIBIT.replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    return call_text_json(tmpl, text, max_tokens=16000)

def extract_note(page_texts, pages, fy_labels):
    tmpl = PROMPT_NOTES.replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    data = call_text_json(tmpl, text, max_tokens=6000)
    return NoteExtract(**data)

def extract_stats(page_texts, pages, fy_labels):
    tmpl = PROMPT_MDNA_STATS.replace("{FY_LABELS}", ", ".join(fy_labels))
    text = get_page_texts(page_texts, pages=pages)
    return call_text_json(tmpl, text, max_tokens=6000)


# ═══════════════════════════════════════════════════════════════════════
# ORG REGISTRY
# ═══════════════════════════════════════════════════════════════════════

def _norm(s):
    if not s:
        return ""
    s = re.sub(r"[^a-z0-9 ]+", " ", s.lower())
    s = re.sub(r"\b(the|inc|llc|corp|corporation|company|co|system|systems|health|healthcare|hospital|hospitals|medical|center|centers)\b", " ", s)
    return re.sub(r"\s+", " ", s).strip()

def suggest_org_code(legal_name):
    raw = re.sub(r"[^A-Za-z0-9]+", "_", legal_name).upper().strip("_")
    if raw and raw[0].isdigit():
        raw = "ORG_" + raw
    return raw[:40] if raw else "UNNAMED_ORG"

def find_existing(cur, ident):
    if ident.ein:
        cur.execute(
            "SELECT ORG_ID, ORG_CODE, LEGAL_NAME, EIN FROM COMMON.ORG_REGISTRY WHERE EIN = %s",
            (ident.ein,),
        )
        row = cur.fetchone()
        if row:
            return {"ORG_ID": row[0], "ORG_CODE": row[1], "LEGAL_NAME": row[2], "EIN": row[3]}
    cur.execute("SELECT ORG_ID, ORG_CODE, LEGAL_NAME, EIN FROM COMMON.ORG_REGISTRY")
    rows = cur.fetchall()
    if not rows:
        return None
    candidates = {_norm(r[2]): r for r in rows}
    match = rfprocess.extractOne(_norm(ident.legal_name), list(candidates.keys()), scorer=fuzz.token_sort_ratio)
    if match and match[1] >= 90:
        r = candidates[match[0]]
        return {"ORG_ID": r[0], "ORG_CODE": r[1], "LEGAL_NAME": r[2], "EIN": r[3]}
    return None

def insert_org(cur, org_id, org_code, ident, notes=None):
    cur.execute(
        """
        INSERT INTO COMMON.ORG_REGISTRY
          (ORG_ID, ORG_CODE, LEGAL_NAME, DBA, EIN, HQ_STATE, FYE_MONTH, SECTOR, NOTES)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """,
        (org_id, org_code, ident.legal_name, ident.dba, ident.ein,
         ident.hq_state, ident.fye_month, ident.sector, notes),
    )


# ═══════════════════════════════════════════════════════════════════════
# COMMON MAP
# ═══════════════════════════════════════════════════════════════════════

def norm_label(label):
    s = re.sub(r"[^a-z0-9 ]+", " ", label.lower())
    return re.sub(r"\s+", " ", s).strip()

def _fetch_taxonomy(cur, statement):
    cur.execute(
        "SELECT CONCEPT, DEFINITION FROM COMMON.STANDARD_TAXONOMY WHERE STATEMENT = %s ORDER BY CONCEPT",
        (statement,),
    )
    return [(r[0], r[1]) for r in cur.fetchall()]

def _cached_map(cur, org_id, statement, label_norm):
    cur.execute(
        """
        SELECT CONCEPT, CONFIDENCE, RATIONALE
          FROM COMMON.LINE_ITEM_MAP
         WHERE ORG_ID = %s AND STATEMENT = %s AND NATIVE_LABEL_NORM = %s
        """,
        (org_id, statement, label_norm),
    )
    row = cur.fetchone()
    return {"concept": row[0], "confidence": row[1], "rationale": row[2]} if row else None

def _persist_map(cur, org_id, statement, native_label, proposal, source="auto"):
    cur.execute(
        """
        MERGE INTO COMMON.LINE_ITEM_MAP t
        USING (SELECT %s ORG_ID, %s NATIVE_LABEL_NORM, %s NATIVE_LABEL,
                      %s STATEMENT, %s CONCEPT, %s CONFIDENCE, %s RATIONALE, %s SOURCE) s
        ON t.ORG_ID=s.ORG_ID AND t.NATIVE_LABEL_NORM=s.NATIVE_LABEL_NORM AND t.STATEMENT=s.STATEMENT
        WHEN MATCHED THEN UPDATE SET
          NATIVE_LABEL=s.NATIVE_LABEL, CONCEPT=s.CONCEPT,
          CONFIDENCE=s.CONFIDENCE, RATIONALE=s.RATIONALE, SOURCE=s.SOURCE
        WHEN NOT MATCHED THEN INSERT
          (ORG_ID, NATIVE_LABEL_NORM, NATIVE_LABEL, STATEMENT, CONCEPT, CONFIDENCE, RATIONALE, SOURCE)
          VALUES (s.ORG_ID, s.NATIVE_LABEL_NORM, s.NATIVE_LABEL, s.STATEMENT, s.CONCEPT,
                  s.CONFIDENCE, s.RATIONALE, s.SOURCE)
        """,
        (org_id, norm_label(native_label), native_label, statement,
         proposal.concept, proposal.confidence, proposal.rationale, source),
    )

def map_label(cur, org_id, statement, native_label):
    label_norm = norm_label(native_label)
    cached = _cached_map(cur, org_id, statement, label_norm)
    if cached is not None:
        return MappingProposal(
            native_label=native_label, statement=statement,
            concept=cached["concept"],
            confidence=float(cached["confidence"] or 0.0),
            rationale=cached["rationale"] or "cached",
        )
    taxonomy = _fetch_taxonomy(cur, statement)
    candidates_block = "\n".join(f"- `{c}` — {d or ''}" for c, d in taxonomy)
    prompt = (
        PROMPT_MAP_CONCEPT
        .replace("{NATIVE_LABEL}", native_label)
        .replace("{STATEMENT}", statement)
        .replace("{CANDIDATES}", candidates_block)
    )
    data = call_text_json_no_context(prompt, model=MODEL_MAP)
    proposal = MappingProposal(**data)
    _persist_map(cur, org_id, statement, native_label, proposal)
    return proposal

def review_flag(proposal):
    return proposal.concept is None or proposal.confidence < MIN_MAPPING_CONFIDENCE


# ═══════════════════════════════════════════════════════════════════════
# SNOWFLAKE I/O
# ═══════════════════════════════════════════════════════════════════════

_PER_ORG_DDL = """
CREATE SCHEMA IF NOT EXISTS {schema};
USE SCHEMA {schema};

CREATE TABLE IF NOT EXISTS RAW_FILING_JSON (
    FILING_ID STRING PRIMARY KEY,
    SOURCE_FILENAME STRING,
    EXTRACTOR_VERSION STRING,
    BLOB VARIANT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS IS_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    IS_SUBTOTAL BOOLEAN, PARENT_LABEL STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FY_LABEL, NATIVE_LABEL, LINE_ORDER)
);

CREATE TABLE IF NOT EXISTS BS_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    IS_SUBTOTAL BOOLEAN, PARENT_LABEL STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FY_LABEL, NATIVE_LABEL, LINE_ORDER)
);

CREATE TABLE IF NOT EXISTS CF_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, SECTION STRING, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    IS_SUBTOTAL BOOLEAN,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FY_LABEL, SECTION, NATIVE_LABEL, LINE_ORDER)
);

CREATE TABLE IF NOT EXISTS EQUITY_NATIVE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    LINE_ORDER NUMBER, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    COLUMN_LABEL STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS IS_EXHIBIT_ENTITY (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    ENTITY STRING, NATIVE_LABEL STRING, AMOUNT NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS IS_EXHIBIT_REVENUE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    DIMENSION STRING, CATEGORY STRING, AMOUNT NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS IS_EXHIBIT_EXPENSE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    DIMENSION STRING, CATEGORY STRING, AMOUNT NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS BS_EXHIBIT_DEBT (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    INSTRUMENT STRING, OUTSTANDING NUMBER(38,2), RATE FLOAT, MATURITY_YEAR NUMBER,
    SECURED BOOLEAN, COVENANTS_TEXT STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS BS_EXHIBIT_INVESTMENTS (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    FV_LEVEL STRING, CATEGORY STRING, FAIR_VALUE NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS BS_EXHIBIT_PPE (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    CATEGORY STRING, COST NUMBER(38,2), ACCUM_DEPR NUMBER(38,2), NET NUMBER(38,2),
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);

CREATE TABLE IF NOT EXISTS NOTES (
    FILING_ID STRING, NOTE_NUM STRING, TITLE STRING,
    BODY_TEXT STRING, CALLOUTS VARIANT,
    SOURCE_PAGE_START NUMBER, SOURCE_PAGE_END NUMBER,
    LOADED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (FILING_ID, NOTE_NUM)
);

CREATE TABLE IF NOT EXISTS STATS (
    FILING_ID STRING, FY_LABEL STRING, FISCAL_YEAR_END DATE,
    NATIVE_LABEL STRING, AMOUNT NUMBER(38,4), UOM STRING,
    SOURCE_PAGE NUMBER, CONFIDENCE FLOAT
);
"""

def ensure_org_schema(cur, org_code):
    _validate_identifier(org_code, "org_code")
    cur.execute(f"USE DATABASE {SNOWFLAKE_DATABASE}")
    for stmt in _PER_ORG_DDL.format(schema=org_code).split(";"):
        s = stmt.strip()
        if s:
            cur.execute(s)

def filing_already_loaded(cur, filing_id):
    cur.execute("SELECT 1 FROM COMMON.FILINGS WHERE FILING_ID = %s", (filing_id,))
    return cur.fetchone() is not None

def get_completed_stages(cur, staging_id):
    cur.execute(
        "SELECT STAGES_COMPLETED FROM COMMON.PDF_STAGING WHERE STAGING_ID = %s",
        (staging_id,),
    )
    row = cur.fetchone()
    if not row or row[0] is None:
        return set()
    raw = row[0]
    if isinstance(raw, str):
        raw = json.loads(raw)
    return set(raw) if raw else set()

def mark_stage_completed(cur, staging_id, stage_name):
    cur.execute(
        """
        UPDATE COMMON.PDF_STAGING
           SET STAGES_COMPLETED = ARRAY_APPEND(
               COALESCE(STAGES_COMPLETED, PARSE_JSON('[]')),
               %s::VARIANT
           )
         WHERE STAGING_ID = %s
        """,
        (stage_name, staging_id),
    )

def update_staging_status(cur, staging_id, status):
    cur.execute(
        "UPDATE COMMON.PDF_STAGING SET STATUS = %s WHERE STAGING_ID = %s",
        (status, staging_id),
    )


# ═══════════════════════════════════════════════════════════════════════
# NORMALIZE / WRITE
# ═══════════════════════════════════════════════════════════════════════

_STATEMENT_TO_COMMON = {
    "is": ("income_statement", "INCOME_STATEMENT", "IS_NATIVE"),
    "bs": ("balance_sheet", "BALANCE_SHEET", "BS_NATIVE"),
    "cf": ("cash_flow", "CASH_FLOW", "CF_NATIVE"),
}

def _bulk_insert(cur, fq_table, rows):
    if not rows:
        return
    cols = list(rows[0].keys())
    placeholders = ",".join(["%s"] * len(cols))
    sql = f"INSERT INTO {fq_table} ({','.join(cols)}) VALUES ({placeholders})"
    cur.executemany(sql, [tuple(r.get(c) for c in cols) for r in rows])

def _merge_common(cur, table, rows):
    if not rows:
        return
    cols = list(rows[0].keys())
    keys = ["ORG_ID", "FY_LABEL", "CONCEPT"]
    update_cols = [c for c in cols if c not in keys]
    select_clause = ", ".join(f"%s AS {c}" for c in cols)
    key_match = " AND ".join(f"t.{k}=s.{k}" for k in keys)
    update_set = ", ".join(f"t.{c}=s.{c}" for c in update_cols)
    insert_vals = ", ".join(f"s.{c}" for c in cols)
    sql = f"""
        MERGE INTO COMMON.{table} t USING (SELECT {select_clause}) s
        ON {key_match}
        WHEN MATCHED THEN UPDATE SET {update_set}
        WHEN NOT MATCHED THEN INSERT ({','.join(cols)}) VALUES ({insert_vals})
    """
    for r in rows:
        cur.execute(sql, tuple(r.get(c) for c in cols))

def _review_row(**kwargs):
    payload = kwargs.pop("payload", None)
    return {
        "REVIEW_ID": str(uuid.uuid4()),
        "FILING_ID": kwargs["filing_id"],
        "ORG_ID": kwargs["org_id"],
        "STATEMENT": kwargs["statement"],
        "NATIVE_LABEL": kwargs["native_label"],
        "FY_LABEL": kwargs.get("fy_label"),
        "AMOUNT": kwargs.get("amount"),
        "CONFIDENCE": kwargs.get("confidence"),
        "REASON": kwargs["reason"],
        "SOURCE_PAGE": kwargs.get("source_page"),
        "PAYLOAD": payload,
    }

def _write_review(cur, rows):
    if not rows:
        return
    sql = """
        INSERT INTO COMMON.REVIEW_QUEUE
          (REVIEW_ID, FILING_ID, ORG_ID, STATEMENT, NATIVE_LABEL, FY_LABEL,
           AMOUNT, CONFIDENCE, REASON, SOURCE_PAGE, PAYLOAD)
        SELECT %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,PARSE_JSON(%s)
    """
    for r in rows:
        cur.execute(sql, (
            r["REVIEW_ID"], r["FILING_ID"], r["ORG_ID"], r["STATEMENT"],
            r["NATIVE_LABEL"], r["FY_LABEL"], r["AMOUNT"], r["CONFIDENCE"],
            r["REASON"], r["SOURCE_PAGE"], json.dumps(r["PAYLOAD"] or {}),
        ))

def write_statement(cur, org_id, org_code, filing_id, fye_by_year, extract):
    stmt_code = extract.statement
    if stmt_code == "equity":
        rows = []
        for line in extract.lines:
            l = StatementLine(**line) if isinstance(line, dict) else line
            for amt_raw in l.amounts:
                amt = StatementAmount(**amt_raw) if isinstance(amt_raw, dict) else amt_raw
                rows.append({
                    "FILING_ID": filing_id, "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "LINE_ORDER": l.line_order, "NATIVE_LABEL": l.native_label,
                    "AMOUNT": amt.amount, "COLUMN_LABEL": l.parent_label,
                    "SOURCE_PAGE": l.source_page, "CONFIDENCE": amt.confidence,
                })
        _bulk_insert(cur, f"{org_code}.EQUITY_NATIVE", rows)
        return {"native_rows": len(rows), "common_rows": 0, "review_rows": 0}

    common_stmt_name, common_table, native_table = _STATEMENT_TO_COMMON[stmt_code]
    native_rows = []
    common_rows = []
    review_rows = []

    for line_raw in extract.lines:
        line = StatementLine(**line_raw) if isinstance(line_raw, dict) else line_raw
        for amt_raw in line.amounts:
            amt = StatementAmount(**amt_raw) if isinstance(amt_raw, dict) else amt_raw
            if stmt_code != "cf":
                native_rows.append({
                    "FILING_ID": filing_id, "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "LINE_ORDER": line.line_order, "NATIVE_LABEL": line.native_label,
                    "AMOUNT": amt.amount, "IS_SUBTOTAL": line.is_subtotal,
                    "PARENT_LABEL": line.parent_label,
                    "SOURCE_PAGE": line.source_page, "CONFIDENCE": amt.confidence,
                })
            else:
                native_rows.append({
                    "FILING_ID": filing_id, "FY_LABEL": amt.fy_label,
                    "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                    "LINE_ORDER": line.line_order, "SECTION": line.section,
                    "NATIVE_LABEL": line.native_label, "AMOUNT": amt.amount,
                    "IS_SUBTOTAL": line.is_subtotal,
                    "SOURCE_PAGE": line.source_page, "CONFIDENCE": amt.confidence,
                })

            if amt.amount is None or amt.confidence < MIN_NUMERIC_CONFIDENCE:
                if amt.amount is not None:
                    review_rows.append(_review_row(
                        filing_id=filing_id, org_id=org_id, statement=stmt_code.upper(),
                        native_label=line.native_label, fy_label=amt.fy_label,
                        amount=amt.amount, confidence=amt.confidence,
                        reason="low_confidence", source_page=line.source_page,
                    ))
                continue

            if line.is_subtotal:
                continue

            proposal = map_label(cur, org_id, common_stmt_name, line.native_label)
            if review_flag(proposal):
                review_rows.append(_review_row(
                    filing_id=filing_id, org_id=org_id, statement=stmt_code.upper(),
                    native_label=line.native_label, fy_label=amt.fy_label,
                    amount=amt.amount, confidence=proposal.confidence,
                    reason="mapping_low_conf", source_page=line.source_page,
                    payload={"rationale": proposal.rationale, "proposed_concept": proposal.concept},
                ))
                continue

            common_rows.append({
                "FILING_ID": filing_id, "ORG_ID": org_id,
                "FY_LABEL": amt.fy_label,
                "FISCAL_YEAR_END": fye_by_year.get(amt.fy_label),
                "CONCEPT": proposal.concept, "AMOUNT": amt.amount,
                "NATIVE_LABEL": line.native_label,
                "SOURCE_PAGE": line.source_page, "CONFIDENCE": amt.confidence,
            })

    _bulk_insert(cur, f"{org_code}.{native_table}", native_rows)
    _merge_common(cur, common_table, common_rows)
    _write_review(cur, review_rows)
    return {"native_rows": len(native_rows), "common_rows": len(common_rows), "review_rows": len(review_rows)}

def write_stats(cur, org_id, org_code, filing_id, fye_by_year, stat_rows):
    native_rows = []
    common_rows = []
    review_rows_list = []
    for r in stat_rows:
        amount = r.get("amount")
        conf = r.get("confidence", 1.0)
        fy = r.get("fy_label")
        label = r.get("native_label")
        page = r.get("source_page")
        uom = r.get("uom")
        native_rows.append({
            "FILING_ID": filing_id, "FY_LABEL": fy,
            "FISCAL_YEAR_END": fye_by_year.get(fy),
            "NATIVE_LABEL": label, "AMOUNT": amount, "UOM": uom,
            "SOURCE_PAGE": page, "CONFIDENCE": conf,
        })
        if amount is None or conf < MIN_NUMERIC_CONFIDENCE or not label:
            continue
        proposal = map_label(cur, org_id, "stat", label)
        if review_flag(proposal):
            review_rows_list.append(_review_row(
                filing_id=filing_id, org_id=org_id, statement="STATS",
                native_label=label, fy_label=fy, amount=amount,
                confidence=proposal.confidence, reason="mapping_low_conf",
                source_page=page,
                payload={"rationale": proposal.rationale, "proposed_concept": proposal.concept},
            ))
            continue
        common_rows.append({
            "FILING_ID": filing_id, "ORG_ID": org_id, "FY_LABEL": fy,
            "FISCAL_YEAR_END": fye_by_year.get(fy),
            "CONCEPT": proposal.concept, "AMOUNT": amount, "UOM": uom,
            "NATIVE_LABEL": label, "SOURCE_PAGE": page, "CONFIDENCE": conf,
        })
    _bulk_insert(cur, f"{org_code}.STATS", native_rows)
    _merge_common(cur, "OPERATING_STATS", common_rows)
    _write_review(cur, review_rows_list)
    return {"native_rows": len(native_rows), "common_rows": len(common_rows), "review_rows": len(review_rows_list)}


# ═══════════════════════════════════════════════════════════════════════
# EXHIBITS
# ═══════════════════════════════════════════════════════════════════════

def write_is_exhibit(cur, org_code, filing_id, fye_by_year, payload):
    rows_data = payload.get("rows") or []
    out_rows = []
    for r in rows_data:
        fy = r.get("fy_label")
        amt = r.get("amount")
        dim = r.get("dimension") or payload.get("dimension")
        cat = r.get("category")
        page = r.get("source_page")
        conf = r.get("confidence", 1.0)
        if r.get("entity"):
            out_rows.append({"table": "IS_EXHIBIT_ENTITY", "row": {
                "FILING_ID": filing_id, "FY_LABEL": fy,
                "FISCAL_YEAR_END": fye_by_year.get(fy),
                "ENTITY": r.get("entity"), "NATIVE_LABEL": cat,
                "AMOUNT": amt, "SOURCE_PAGE": page, "CONFIDENCE": conf,
            }})
        elif dim in ("payer", "service_line"):
            out_rows.append({"table": "IS_EXHIBIT_REVENUE", "row": {
                "FILING_ID": filing_id, "FY_LABEL": fy,
                "FISCAL_YEAR_END": fye_by_year.get(fy),
                "DIMENSION": dim, "CATEGORY": cat, "AMOUNT": amt,
                "SOURCE_PAGE": page, "CONFIDENCE": conf,
            }})
        elif dim in ("natural_account", "functional"):
            out_rows.append({"table": "IS_EXHIBIT_EXPENSE", "row": {
                "FILING_ID": filing_id, "FY_LABEL": fy,
                "FISCAL_YEAR_END": fye_by_year.get(fy),
                "DIMENSION": dim, "CATEGORY": cat, "AMOUNT": amt,
                "SOURCE_PAGE": page, "CONFIDENCE": conf,
            }})
    _exhibit_bulk(cur, org_code, out_rows)
    return len(out_rows)

def write_bs_exhibit(cur, org_code, filing_id, fye_by_year, payload):
    kind = payload.get("exhibit_type")
    rows_data = payload.get("rows") or []
    out_rows = []
    if kind == "debt":
        for r in rows_data:
            for fy, amt in (r.get("outstanding_by_fy") or {}).items():
                out_rows.append({"table": "BS_EXHIBIT_DEBT", "row": {
                    "FILING_ID": filing_id, "FY_LABEL": fy,
                    "FISCAL_YEAR_END": fye_by_year.get(fy),
                    "INSTRUMENT": r.get("instrument"), "OUTSTANDING": amt,
                    "RATE": r.get("rate"), "MATURITY_YEAR": r.get("maturity_year"),
                    "SECURED": r.get("secured"), "COVENANTS_TEXT": r.get("covenants_text"),
                    "SOURCE_PAGE": r.get("source_page"), "CONFIDENCE": r.get("confidence", 1.0),
                }})
    elif kind == "investments":
        for r in rows_data:
            for fy, amt in (r.get("fair_value_by_fy") or {}).items():
                out_rows.append({"table": "BS_EXHIBIT_INVESTMENTS", "row": {
                    "FILING_ID": filing_id, "FY_LABEL": fy,
                    "FISCAL_YEAR_END": fye_by_year.get(fy),
                    "FV_LEVEL": r.get("fv_level"), "CATEGORY": r.get("category"),
                    "FAIR_VALUE": amt, "SOURCE_PAGE": r.get("source_page"),
                    "CONFIDENCE": r.get("confidence", 1.0),
                }})
    elif kind == "ppe":
        for r in rows_data:
            for fy, detail in (r.get("by_fy") or {}).items():
                out_rows.append({"table": "BS_EXHIBIT_PPE", "row": {
                    "FILING_ID": filing_id, "FY_LABEL": fy,
                    "FISCAL_YEAR_END": fye_by_year.get(fy),
                    "CATEGORY": r.get("category"),
                    "COST": (detail or {}).get("cost"),
                    "ACCUM_DEPR": (detail or {}).get("accum_depr"),
                    "NET": (detail or {}).get("net"),
                    "SOURCE_PAGE": r.get("source_page"),
                    "CONFIDENCE": r.get("confidence", 1.0),
                }})
    _exhibit_bulk(cur, org_code, out_rows)
    return len(out_rows)

def _exhibit_bulk(cur, org_code, rows):
    _validate_identifier(org_code, "org_code")
    by_table = {}
    for r in rows:
        by_table.setdefault(r["table"], []).append(r["row"])
    for table, batch in by_table.items():
        if not batch:
            continue
        _validate_identifier(table, "table name")
        cols = list(batch[0].keys())
        for c in cols:
            _validate_identifier(c, "column name")
        placeholders = ",".join(["%s"] * len(cols))
        sql = f"INSERT INTO {org_code}.{table} ({','.join(cols)}) VALUES ({placeholders})"
        cur.executemany(sql, [tuple(r.get(c) for c in cols) for r in batch])

def write_notes(cur, org_code, filing_id, note):
    _validate_identifier(org_code, "org_code")
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
        (filing_id, note_num, note.get("title"), note.get("body_text"),
         json.dumps(note.get("callouts") or []),
         note.get("source_page_start"), note.get("source_page_end")),
    )


# ═══════════════════════════════════════════════════════════════════════
# INSIGHTS
# ═══════════════════════════════════════════════════════════════════════

def _fetch_common_is(cur, org_id):
    cur.execute("SELECT FY_LABEL, CONCEPT, AMOUNT FROM COMMON.INCOME_STATEMENT WHERE ORG_ID = %s", (org_id,))
    out = {}
    for fy, concept, amt in cur.fetchall():
        out.setdefault(fy, {})[concept] = float(amt) if amt is not None else None
    return out

def _fetch_common_bs(cur, org_id):
    cur.execute("SELECT FY_LABEL, CONCEPT, AMOUNT FROM COMMON.BALANCE_SHEET WHERE ORG_ID = %s", (org_id,))
    out = {}
    for fy, concept, amt in cur.fetchall():
        out.setdefault(fy, {})[concept] = float(amt) if amt is not None else None
    return out

def _fetch_common_cf(cur, org_id):
    cur.execute("SELECT FY_LABEL, CONCEPT, AMOUNT FROM COMMON.CASH_FLOW WHERE ORG_ID = %s", (org_id,))
    out = {}
    for fy, concept, amt in cur.fetchall():
        out.setdefault(fy, {})[concept] = float(amt) if amt is not None else None
    return out

def _safe_ratio(num, den):
    if num is None or den is None or den == 0:
        return None
    return num / den

def compute_ratios(cur, org_id):
    is_data = _fetch_common_is(cur, org_id)
    bs_data = _fetch_common_bs(cur, org_id)
    cf_data = _fetch_common_cf(cur, org_id)
    years = sorted(set(is_data) | set(bs_data) | set(cf_data), reverse=True)
    ratios_by_fy = {}
    for fy in years:
        i = is_data.get(fy, {})
        b = bs_data.get(fy, {})
        rev = i.get("total_operating_revenue")
        opex = i.get("total_operating_expense")
        op_income = i.get("operating_income")
        if op_income is None and rev is not None and opex is not None:
            op_income = rev - opex
        da = i.get("depreciation_amortization")
        salaries = i.get("total_salaries_and_benefits") or (
            (i.get("salaries_and_wages") or 0) + (i.get("employee_benefits") or 0)
            if i.get("salaries_and_wages") is not None or i.get("employee_benefits") is not None
            else None
        )
        supplies = i.get("supplies")
        purchased = i.get("purchased_services")
        cash = b.get("cash_and_equivalents")
        sti = b.get("short_term_investments")
        lti = b.get("long_term_investments")
        ar = b.get("patient_ar_net")
        lt_debt = b.get("long_term_debt")
        accum_depr = b.get("accumulated_depreciation")
        net_assets = b.get("net_assets_without_donor_restrictions")
        daily_opex = ((opex or 0) - (da or 0)) / 365 if opex else None
        ratios_by_fy[fy] = {
            "operating_margin_pct": (op_income / rev * 100) if op_income is not None and rev else None,
            "ebida_margin_pct": ((op_income or 0) + (da or 0)) / rev * 100 if rev else None,
            "salaries_pct_of_revenue": salaries / rev * 100 if salaries and rev else None,
            "supplies_pct_of_revenue": supplies / rev * 100 if supplies and rev else None,
            "purchased_services_pct_of_opex": purchased / opex * 100 if purchased and opex else None,
            "days_cash_on_hand": _safe_ratio((cash or 0) + (sti or 0) + (lti or 0), daily_opex),
            "days_in_ar": _safe_ratio(ar, (rev / 365) if rev else None),
            "debt_to_capitalization_pct": lt_debt / ((lt_debt or 0) + (net_assets or 0)) * 100
                if lt_debt and ((lt_debt or 0) + (net_assets or 0)) else None,
            "age_of_plant_years": _safe_ratio(
                -accum_depr if accum_depr is not None and accum_depr < 0 else accum_depr, da
            ),
        }
    return {"years": years, "ratios_by_fy": ratios_by_fy,
            "income_statement": is_data, "balance_sheet": bs_data, "cash_flow": cf_data}

def compute_trends(ratios):
    years = ratios["years"]
    trends = {}
    for metric in next(iter(ratios["ratios_by_fy"].values()), {}):
        trends[metric] = {}
        for idx, fy in enumerate(years[:-1]):
            cur_val = ratios["ratios_by_fy"][fy].get(metric)
            prev_val = ratios["ratios_by_fy"][years[idx + 1]].get(metric)
            trends[metric][f"{fy}_vs_{years[idx + 1]}"] = (
                None if cur_val is None or prev_val is None else cur_val - prev_val
            )
    return trends

def synthesize_findings(ratios, trends, org_code):
    input_obj = {"org_code": org_code, "ratios": ratios, "trends": trends}
    prompt = PROMPT_INSIGHTS.replace("{INPUT}", json.dumps(input_obj, default=str))
    data = call_text_json_no_context(prompt, max_tokens=6000)
    return data.get("findings", [])

def write_findings(cur, org_id, filing_id, fy_label, findings):
    sql = """
        INSERT INTO COMMON.FINDINGS
          (FINDING_ID, ORG_ID, FILING_ID, FY_LABEL, CATEGORY, SEVERITY, TITLE, NARRATIVE,
           EST_IMPACT_LOW, EST_IMPACT_HIGH, IMPACT_UNIT, SUPPORTING_CONCEPTS, PLAYBOOK_HINT)
        SELECT %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,PARSE_JSON(%s),%s
    """
    n = 0
    for f in findings:
        cur.execute(sql, (
            str(uuid.uuid4()), org_id, filing_id, fy_label,
            f.get("category"), f.get("severity"), f.get("title"), f.get("narrative"),
            f.get("est_impact_low"), f.get("est_impact_high"),
            f.get("impact_unit") or "usd_annualized",
            json.dumps(f.get("supporting_concepts") or []),
            f.get("playbook_hint"),
        ))
        n += 1
    return n


# ═══════════════════════════════════════════════════════════════════════
# PIPELINE HELPERS
# ═══════════════════════════════════════════════════════════════════════

def _contiguous_runs(pages):
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

def _notes_grouped(classifications):
    note_pages = [(c.page, c.note_num) for c in classifications if c.label == "note"]
    if not note_pages:
        return []
    groups = {}
    contig = []
    for page, note_num in sorted(note_pages):
        if note_num:
            groups.setdefault(note_num, []).append(page)
        else:
            if contig and page == contig[-1][-1] + 1:
                contig[-1].append(page)
            else:
                contig.append([page])
    return list(groups.values()) + contig

def _resolve_org(cur, ident, org_hint=None):
    existing = find_existing(cur, ident)
    if existing:
        return existing
    if org_hint:
        org_id = str(uuid.uuid4())
        org_code = org_hint.get("org_code") or suggest_org_code(org_hint.get("legal_name") or ident.legal_name)
        ident2 = ident.model_copy(update={"legal_name": org_hint.get("legal_name") or ident.legal_name})
        insert_org(cur, org_id, org_code, ident2)
        return {"ORG_ID": org_id, "ORG_CODE": org_code, "LEGAL_NAME": ident2.legal_name, "EIN": ident.ein}
    raise RuntimeError(
        "New organization detected but no org_hint provided. "
        "Pass ORG_HINT_JSON to the procedure."
    )


# ═══════════════════════════════════════════════════════════════════════
# PROCESS ONE FILING
# ═══════════════════════════════════════════════════════════════════════

def process_filing(session, filename, filing_id, page_texts, total_pages,
                   org_hint=None, reparse=False, staging_id=None):
    global _SESSION
    _SESSION = session

    report = {
        "source_filename": filename,
        "filing_id": filing_id,
        "page_count": total_pages,
        "started_at": datetime.utcnow().isoformat(),
        "stages": {},
    }

    conn = session._conn._conn
    try:
        cur = conn.cursor()
        try:
            done = get_completed_stages(cur, staging_id) if staging_id else set()

            def _checkpoint(stage):
                if staging_id:
                    mark_stage_completed(cur, staging_id, stage)
                    conn.commit()

            ident = identify_filing(page_texts)
            report["identify"] = ident.model_dump()

            org = _resolve_org(cur, ident, org_hint=org_hint)
            report["org"] = org

            if not reparse and filing_already_loaded(cur, filing_id):
                report["skipped"] = "already_loaded"
                return report

            ensure_org_schema(cur, org["ORG_CODE"])

            classifications = classify_pages(page_texts, total_pages)
            groups = group_by_label(classifications)
            report["stages"]["classify"] = {k: len(v) for k, v in groups.items()}

            all_pages = list(range(1, total_pages + 1))
            if pages_are_empty(page_texts, all_pages):
                report["stages"]["warning"] = "all_pages_empty_text_possible_scanned_pdf"

            fy_labels = ident.years_shown
            fye_by_year = ident.fye_by_year
            primary_fy = fy_labels[0] if fy_labels else None
            primary_fye = fye_by_year.get(primary_fy) if primary_fy else None

            if "filing_row" not in done:
                cur.execute(
                    """
                    INSERT INTO COMMON.FILINGS
                      (FILING_ID, ORG_ID, FISCAL_YEAR_END, FY_LABEL, YEARS_PRESENT, AUDIT_FIRM,
                       AUDIT_OPINION, SOURCE_FILENAME, PAGE_COUNT, EXTRACTOR_VERSION, EXTRACTION_BLOB)
                    SELECT %s,%s,%s,%s,PARSE_JSON(%s),%s,%s,%s,%s,%s,PARSE_JSON(%s)
                    """,
                    (filing_id, org["ORG_ID"], primary_fye, primary_fy,
                     json.dumps(fy_labels), ident.audit_firm, ident.audit_opinion,
                     filename, total_pages, EXTRACTOR_VERSION,
                     json.dumps({"identify": ident.model_dump(),
                                 "classify": [c.model_dump() for c in classifications]})),
                )
                cur.execute(
                    f"""
                    INSERT INTO {org["ORG_CODE"]}.RAW_FILING_JSON
                      (FILING_ID, SOURCE_FILENAME, EXTRACTOR_VERSION, BLOB)
                    SELECT %s,%s,%s,PARSE_JSON(%s)
                    """,
                    (filing_id, filename, EXTRACTOR_VERSION,
                     json.dumps({"identify": ident.model_dump(),
                                 "classify": [c.model_dump() for c in classifications]})),
                )
                _checkpoint("filing_row")
            else:
                log.info("[resume] skipping filing_row")

            if "statements" not in done:
                stmt_stats = {}
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
                log.info("[resume] skipping statements")

            if "is_exhibits" not in done:
                is_exh_rows = 0
                for page_run in _contiguous_runs(groups.get("is_exhibit", [])):
                    payload = extract_is_exhibit(page_texts, page_run, fy_labels)
                    is_exh_rows += write_is_exhibit(cur, org["ORG_CODE"], filing_id, fye_by_year, payload)
                report["stages"]["is_exhibit_rows"] = is_exh_rows
                _checkpoint("is_exhibits")
            else:
                log.info("[resume] skipping is_exhibits")

            if "bs_exhibits" not in done:
                bs_exh_rows = 0
                for page_run in _contiguous_runs(groups.get("bs_exhibit", [])):
                    payload = extract_bs_exhibit(page_texts, page_run, fy_labels)
                    bs_exh_rows += write_bs_exhibit(cur, org["ORG_CODE"], filing_id, fye_by_year, payload)
                report["stages"]["bs_exhibit_rows"] = bs_exh_rows
                _checkpoint("bs_exhibits")
            else:
                log.info("[resume] skipping bs_exhibits")

            if "notes" not in done:
                note_count = 0
                note_errors = []
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
                log.info("[resume] skipping notes")

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
                log.info("[resume] skipping stats")

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
                log.info("[resume] skipping insights")

            conn.commit()
        finally:
            cur.close()
    except Exception:
        conn.rollback()
        raise

    report["finished_at"] = datetime.utcnow().isoformat()
    return report


# ═══════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════

def run(session, staging_id_filter, org_hint_json, reparse):
    global _SESSION
    _SESSION = session

    org_hint = json.loads(org_hint_json) if org_hint_json else None

    conn = session._conn._conn
    cur = conn.cursor()

    if staging_id_filter:
        cur.execute(
            """
            SELECT STAGING_ID, FILENAME, FILING_ID, TOTAL_PAGES, PAGE_TEXTS::STRING
              FROM AUDITED_FINANCIALS.COMMON.PDF_STAGING
             WHERE STAGING_ID = %s
             ORDER BY EXTRACTED_AT
            """,
            (staging_id_filter,),
        )
    else:
        cur.execute(
            """
            SELECT STAGING_ID, FILENAME, FILING_ID, TOTAL_PAGES, PAGE_TEXTS::STRING
              FROM AUDITED_FINANCIALS.COMMON.PDF_STAGING
             WHERE STATUS IN ('pending', 'failed')
             ORDER BY EXTRACTED_AT
            """
        )

    rows = cur.fetchall()
    cur.close()

    if not rows:
        return json.dumps({"message": "No pending filings found.", "processed": 0})

    results = []
    for row in rows:
        staging_id  = row[0]
        filename    = row[1]
        filing_id   = row[2]
        total_pages = row[3]
        page_texts  = json.loads(row[4])

        log.info("=== %s (%d pages) ===", filename, total_pages)

        cur2 = conn.cursor()
        update_staging_status(cur2, staging_id, "processing")
        conn.commit()
        cur2.close()

        try:
            report = process_filing(
                session,
                filename=filename,
                filing_id=filing_id,
                page_texts=page_texts,
                total_pages=total_pages,
                org_hint=org_hint,
                reparse=reparse,
                staging_id=staging_id,
            )
            cur3 = conn.cursor()
            update_staging_status(cur3, staging_id, "done")
            conn.commit()
            cur3.close()

            results.append({
                "staging_id": staging_id,
                "filename": filename,
                "status": "done",
                "stages": report.get("stages", {}),
            })
        except Exception as exc:
            cur4 = conn.cursor()
            update_staging_status(cur4, staging_id, "failed")
            conn.commit()
            cur4.close()

            results.append({
                "staging_id": staging_id,
                "filename": filename,
                "status": "failed",
                "error": f"{type(exc).__name__}: {exc}",
            })
            log.error("Filing %s failed: %s", filename, exc)

    return json.dumps({"processed": len(results), "results": results}, indent=2, default=str)
$$;
