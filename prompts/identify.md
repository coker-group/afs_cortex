# Identify filing

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
- Return JSON only — no prose, no markdown fences.
