# Extract footnote

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
- Return JSON only — no prose, no markdown fences.
