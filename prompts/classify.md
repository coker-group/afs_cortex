# Classify pages

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
- Return JSON only — no prose, no markdown fences.
