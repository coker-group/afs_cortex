# Extract primary financial statement

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
- Return JSON only — no prose, no markdown fences.
