# {LEGAL_NAME} — Financial Performance & Strategic Opportunity Assessment

**Prepared:** {DATE}
**Organization:** {LEGAL_NAME} ({ORG_CODE}) | {HQ_STATE}
**Sector:** {SECTOR}
**Filing Coverage:** {EARLIEST_FY} – {LATEST_FY} | Audit Opinions: {OPINIONS}

---

## Executive Summary

{EXECUTIVE_SUMMARY}

---

## 1. Organization & Data Profile

{ORG_PROFILE_NARRATIVE}

### Filing Inventory
| FY | Fiscal Year End | Audit Opinion | Pages | Notes Extracted |
|----|----------------|---------------|-------|-----------------|
{FILING_TABLE_ROWS}

### Data Quality Notes
{DATA_QUALITY_NOTES}

---

## 2. Revenue Analysis

### Revenue Trajectory
| FY | Net Patient Rev | Other Operating Rev | Premium Rev | Total Revenue | YoY Growth |
|----|----------------|--------------------:|------------:|--------------:|-----------:|
{REVENUE_TABLE_ROWS}

### Revenue Interpretation
{REVENUE_INTERPRETATION}

---

## 3. Expense Structure & Cost Pressure

### Cost Decomposition
| FY | Labor | Supplies | Purchased Svcs | D&A | Interest | Other OpEx | Total OpEx |
|----|------:|---------:|---------------:|----:|---------:|-----------:|-----------:|
{EXPENSE_TABLE_ROWS}

### Cost Ratios
| FY | Labor % Rev | Supplies % Rev | Purchased % OpEx | Interest % Rev |
|----|------------:|---------------:|-----------------:|---------------:|
{COST_RATIO_ROWS}

### Expense Interpretation
{EXPENSE_INTERPRETATION}

---

## 4. Margin Analysis

### Margin Trends
| FY | Operating Income | Operating Margin | EBIDA | EBIDA Margin |
|----|----------------:|-----------------:|------:|-------------:|
{MARGIN_TABLE_ROWS}

### Margin Interpretation
{MARGIN_INTERPRETATION}

---

## 5. Balance Sheet Health

### Capital Structure
| FY | Cash | LT Investments | Patient AR | LT Debt | Total Debt | Net Assets (Unrestricted) |
|----|-----:|---------------:|-----------:|--------:|-----------:|--------------------------:|
{BS_TABLE_ROWS}

### Balance Sheet Ratios
| FY | Days Cash | Days AR | Debt/Cap % | Debt/EBIDA |
|----|----------:|--------:|-----------:|-----------:|
{BS_RATIO_ROWS}

### Balance Sheet Interpretation
{BS_INTERPRETATION}

---

## 6. Cash Flow Dynamics

### Cash Flow Summary
| FY | CF from Ops | CF Investing | CF Financing | CapEx | Free Cash Flow | CF Margin % |
|----|------------:|-------------:|-------------:|------:|---------------:|------------:|
{CF_TABLE_ROWS}

### Cash Flow Interpretation
{CF_INTERPRETATION}

---

## 7. Qualitative Intelligence from Footnotes

### Key Footnote Findings
{NOTES_FINDINGS}

### Payer Mix & Revenue Concentration
{PAYER_MIX_ANALYSIS}

### Debt Covenants & Compliance
{COVENANT_ANALYSIS}

### Pension & Post-Retirement Obligations
{PENSION_ANALYSIS}

### Self-Insurance & Contingencies
{INSURANCE_CONTINGENCY_ANALYSIS}

### Related-Party & Strategic Relationships
{RELATED_PARTY_ANALYSIS}

---

## 8. Diagnostic Patterns

{DIAGNOSTIC_PATTERNS}

---

## 9. Pain Points & Consulting Opportunities

### Identified Opportunities

{OPPORTUNITY_LIST}

### Opportunity Sizing Summary
| Opportunity | Severity | Est. Annual Impact | Consulting Service Line |
|-------------|----------|-------------------:|------------------------|
{OPPORTUNITY_TABLE_ROWS}

### Total Addressable Opportunity
{TOTAL_OPPORTUNITY}

---

## 10. Recommended Engagement Approach

### Phase 1 — Quick Wins (0–6 months)
{PHASE_1}

### Phase 2 — Core Transformation (6–18 months)
{PHASE_2}

### Phase 3 — Strategic Initiatives (18–36 months)
{PHASE_3}

---

## Appendix A: Rating Agency Benchmark Comparison

| Metric | {ORG_CODE} Latest | A-Rated Median | Assessment |
|--------|------------------:|---------------:|------------|
{BENCHMARK_TABLE_ROWS}

## Appendix B: Pipeline-Generated Findings (most recent 2 FYs)

{PIPELINE_FINDINGS}

---

*Analysis produced from audited financial statement data in AUDITED_FINANCIALS database.*
*SQL queries used: `clients/{ORG_CODE}/analysis/opportunity_analysis.sql`*
