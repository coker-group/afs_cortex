# Extract operating statistics / MD&A metrics

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
- Emit one row per stat × fiscal year.
- `uom` is one of `"count"`, `"days"`, `"ratio"`, `"pct"`, `"usd"`, `"fte"`, `"bed"`, `"years"`.
- For percentages, return as a percent number (3.2 means 3.2%, not 0.032).
- `source_page` is the page number from the `=== PAGE N ===` delimiter.
- Skip rows whose value is blank or `n/a`.
- Return JSON only — no prose, no markdown fences.
