# Map native label to standard concept

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
  - "Medical supplies and drugs" combined → use `supplies` unless `pharmaceuticals` is separately listed.
- `confidence` reflects how certain you are the mapping is correct given the label and statement context.
- Return JSON only.
