# Extract income statement supplementary exhibit

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
- For **entity P&L** exhibits: `dimension = "entity"`, `entity` is the subsidiary/segment, `category` is the line item. Emit one row per entity × category × fy.
- For **revenue mix** exhibits: `dimension = "payer"` or `"service_line"`, `category` is the payer/service name.
- For **expense detail/functional** exhibits: `dimension = "natural_account"` or `"functional"`, `category` is the expense type.
- Amounts in dollars, sign-preserved, multiplied by the column-header scale (thousands → 1000x, millions → 1000000x).
- `source_page` is the page number from the `=== PAGE N ===` delimiter.
- Each visible cell becomes a row. Omit subtotal rows unless the schedule contains no detail rows.
- Return JSON only — no prose, no markdown fences.
