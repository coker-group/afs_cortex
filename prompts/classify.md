# Classify pages

You will receive extracted text from consecutive pages of a US health system audited financial statement. Each page's text is delimited by `=== PAGE N ===`. Classify **each page** with one label from this list:

- `cover` — title / front matter
- `toc` — table of contents
- `auditor_letter` — independent auditor's report
- `is` — primary consolidated statement of operations / activities / income. For governmental entities: "Statement of Revenues, Expenses, and Changes in Net Position" (note: this title contains revenue/expense line items, NOT asset/liability data)
- `bs` — primary consolidated balance sheet / statement of financial position. For governmental entities: "Statement of Net Position" (contains assets, liabilities, and net position balances — NOT revenue/expense line items)
- `cf` — primary consolidated statement of cash flows
- `equity` — primary consolidated statement of changes in net assets / equity. For governmental entities this may be titled "Statement of Changes in Net Position" (a rollforward of net position balances, distinct from the BS)
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
- IMPORTANT: For governmental hospitals, distinguish carefully between "Statement of Net Position" (label `bs` — shows assets, liabilities, net position balances) and "Statement of Revenues, Expenses, and Changes in Net Position" (label `is` — shows operating revenues, expenses, and the change/increase/decrease in net position). The shorter title with only "Net Position" is the balance sheet.
- Return JSON only — no prose, no markdown fences.
