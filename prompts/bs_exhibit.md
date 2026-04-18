# Extract balance sheet supplementary exhibit

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
- Return JSON only — no prose, no markdown fences.
