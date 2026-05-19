---
name: opportunity-analysis
description: Use when analyzing an organization's financial health, building a consulting pitch, identifying pain points, or producing a strategic assessment from AFS data. Covers multi-year IS/BS/CF ratio analysis, footnote intelligence, payer mix, covenant review, and consulting opportunity sizing. Produces a SQL file and a markdown briefing.
---

# Opportunity Analysis — Workspace Skill

## Purpose
Produce a consulting-grade financial assessment of any organization in the AUDITED_FINANCIALS database.
Outputs two files into a per-health-system folder structure:
1. `clients/{ORG_CODE}/analysis/opportunity_analysis.sql` — all executed SQL, annotated with section headers
2. `clients/{ORG_CODE}/analysis/opportunity_briefing.md` — the analyst's briefing document

## Output Directory Convention
All client deliverables live under `clients/{ORG_CODE}/`. Each engagement type gets
its own subfolder so that analysis and future presentation assets stay organized:
```
clients/
└── {ORG_CODE}/
    ├── analysis/              ← this skill writes here
    │   ├── opportunity_analysis.sql
    │   └── opportunity_briefing.md
    └── presentations/         ← reserved for presentation-development skill
        └── ...
```
Create the directory path if it does not already exist. Never overwrite a prior
brief without confirming with the user — append a date suffix if re-running
(e.g., `opportunity_briefing_2026-05-15.md`).

## When to Use
- User asks to analyze an organization's financials
- User wants a consulting pitch, opportunity assessment, or strategic briefing
- User asks about pain points, margin pressure, or where to "move the needle"
- User references a specific ORG_CODE or legal name in the registry

## Prerequisites
- The target organization must exist in `AUDITED_FINANCIALS.COMMON.ORG_REGISTRY`
- At least one filing must be fully parsed (check `COMMON.FILINGS`)
- Per-org schema must exist with NOTES table populated (e.g., `AUDITED_FINANCIALS.{ORG_CODE}.NOTES`)

---

## Execution Workflow

### Step 0 — Identify the Target
```sql
SELECT ORG_ID, ORG_CODE, LEGAL_NAME, SECTOR, HQ_STATE
  FROM AUDITED_FINANCIALS.COMMON.ORG_REGISTRY
 ORDER BY LEGAL_NAME;
```
If the user names an organization, match it. If ambiguous, ask. Store `ORG_ID` and `ORG_CODE` for all subsequent queries.

### Step 1 — Execute Analysis SQL

Run each SQL template from `templates/` in order, substituting `{ORG_ID}` and `{ORG_CODE}`.
Capture results for each section. Accumulate all executed SQL into a single `.sql` output file
with section-header comments.

**Template execution order:**
1. `01_org_profile.sql` — Filing inventory, audit opinions, year coverage
2. `02_income_statement.sql` — Revenue & expense decomposition, multi-year
3. `03_balance_sheet.sql` — Asset/liability structure, capital position
4. `04_cash_flow.sql` — Operating CF, investing, financing, free cash flow
5. `05_notes_qualitative.sql` — Footnote prose + structured callouts
6. `06_payer_mix.sql` — Revenue and AR concentration from note callouts
7. `07_key_ratios.sql` — Computed financial ratios and trend analysis
8. `08_existing_findings.sql` — Pipeline-generated findings

### Step 2 — Interpret Like an Expert

After collecting all data, synthesize the briefing. You are an expert hospital finance
consultant who reads audited financial statements for a living. Your interpretation must go
beyond surface metrics.

#### Quantitative Interpretation (from IS/BS/CF/ratios)

**Margin Analysis:**
- Operating margin trajectory — is it improving, stable, or eroding?
- EBIDA margin vs. Moody's A-rated health system median (~8-10%)
- Is revenue growth masking expense problems? Compare revenue CAGR vs. expense CAGR
- What is the operating leverage? How much incremental revenue flows to the bottom line?

**Cost Structure Diagnosis:**
- Labor as % of revenue — benchmark is 50-55% for health systems; above 56% is a red flag
- Supplies as % of revenue — benchmark is 15-18%; rising trend signals procurement weakness
- Purchased services as % of opex — benchmark 10-12%; above 14% = outsourcing dependency
- Depreciation trend — rising faster than revenue suggests capital intensity without return
- Interest burden — rising interest with flat/declining margins = debt servicing pressure

**Balance Sheet Health:**
- Days cash on hand — Moody's A-rated median ~200-250 days; below 150 is concerning
- Days in A/R — target <50 days; >55 means revenue cycle friction
- Debt-to-capitalization — A-rated ceiling ~33-35%; above 40% limits strategic flexibility
- Debt/EBIDA — below 3.0x is healthy; above 4.5x is constrained
- Net asset growth vs. revenue growth — divergence signals capital consumption
- Pension funded status trajectory — improving or a looming cliff?

**Cash Flow Dynamics:**
- Operating CF margin — healthy systems sustain 5-8% of revenue
- Capex-to-depreciation — below 100% for 3+ years = facility aging / deferred maintenance
- Free cash flow (CF ops - capex) — negative trend = strategic investment deficit
- Cash flow volatility — coefficient of variation across years signals operating model risk

#### Qualitative Intelligence (from notes and callouts)

**Read Between the Lines:**
- Debt covenants: What are the actual coverage ratios vs. required minimums?
  Tight headroom (<1.25x cushion) means management is constrained.
- Subsequent events: Any mentions of acquisitions, divestitures, refinancing, or litigation?
  These signal what management is prioritizing.
- Related-party transactions: University affiliations, joint ventures, foundation transfers.
  These create both opportunities (academic margin) and obligations (mission spending).
- Self-insurance trends: Rising retention levels and accrued liabilities signal
  increasing risk exposure and potential future cash drains.
- Payer mix: Heavy Medicare/Medicaid (>55% combined) limits pricing power.
  High commercial concentration in one payer = negotiation vulnerability.
- Charity care and community benefit: What % of revenue? Increasing burden
  compresses operating margin from the top line.
- Lease obligations: Large operating lease portfolio = off-balance-sheet leverage
  that rating agencies now scrutinize.
- Pension/OPEB: Discount rate assumptions, funded status, plan freezes.
  A frozen plan with improving funded status is positive; an open plan with
  declining funded status is a ticking bomb.
- Contingencies: Litigation reserves, regulatory actions, environmental liabilities.
  Quantify the disclosed ranges.

#### Diagnostic Patterns to Watch For
- **Revenue-expense scissors**: Revenue growing 4-5% but expenses growing 6-7% = margin will
  eventually collapse even if margins look OK today
- **Cash flow masking**: Large non-recurring items (CARES Act, third-party settlements, investment
  gains) hiding weak operating performance
- **Balance sheet decay**: Net assets growing only because of investment returns, not operating
  surplus — unsustainable if markets turn
- **Deferred maintenance**: Low capex-to-depreciation + aging plant = future capital cliff
- **Working capital squeeze**: Rising AR + rising payables = supply chain and payer friction
- **Covenant tightening**: If actual coverage ratios are trending toward covenant minimums,
  management's strategic options are narrowing

### Step 3 — Produce the Briefing

Write the markdown briefing using the template structure from `templates/report_template.md`.

**Critical rules for the briefing:**
- Every claim must be anchored to specific numbers and fiscal years from the SQL results
- Size every opportunity in dollar ranges using the org's own financial base
- Distinguish between structural issues (multi-year trends) and cyclical blips (one-year anomalies)
- Note data quality caveats — if early years have extraction anomalies, flag them
- Cross-reference quantitative findings with qualitative evidence from notes
- Include both strengths and pain points — a pitch that only shows problems lacks credibility
- Prioritize findings by a combination of dollar magnitude and solvability
- Frame recommendations in engagement phases (quick wins → core transformation → strategic)

### Step 4 — Write Output Files

1. Check if `clients/{ORG_CODE}/analysis/` already contains a prior briefing.
   - If yes, confirm with the user before overwriting, or append a date suffix.
2. Write accumulated SQL to `clients/{ORG_CODE}/analysis/opportunity_analysis.sql`
3. Write briefing to `clients/{ORG_CODE}/analysis/opportunity_briefing.md`
4. Report the full file paths to the user so they can navigate to them.

---

## Database Reference

### COMMON Schema (cross-org)
| Table | Key Columns | Purpose |
|---|---|---|
| ORG_REGISTRY | ORG_ID, ORG_CODE, LEGAL_NAME, SECTOR, HQ_STATE | Organization master |
| FILINGS | FILING_ID, ORG_ID, FY_LABEL, FISCAL_YEAR_END, AUDIT_OPINION, YEARS_PRESENT | Filing inventory |
| INCOME_STATEMENT | ORG_ID, FY_LABEL, CONCEPT, AMOUNT | Standardized IS line items |
| BALANCE_SHEET | ORG_ID, FY_LABEL, CONCEPT, AMOUNT | Standardized BS line items |
| CASH_FLOW | ORG_ID, FY_LABEL, CONCEPT, AMOUNT | Standardized CF line items |
| OPERATING_STATS | ORG_ID, FY_LABEL, CONCEPT, AMOUNT, UOM | Operational metrics (if extracted) |
| FINDINGS | ORG_ID, FY_LABEL, SEVERITY, CATEGORY, TITLE, NARRATIVE, EST_IMPACT_LOW/HIGH, PLAYBOOK_HINT | Pipeline findings |
| LINE_ITEM_MAP | ORG_ID, NATIVE_LABEL, CONCEPT, STATEMENT | Label → taxonomy mapping |
| REVIEW_QUEUE | ORG_ID, FILING_ID, STATEMENT, NATIVE_LABEL, AMOUNT, CONFIDENCE, REASON | Low-confidence extractions |
| PDF_STAGING | FILING_ID, FILENAME, PAGE_TEXTS, STAGES_COMPLETED | Raw parsed PDFs |

### Per-Org Schema (`AUDITED_FINANCIALS.{ORG_CODE}`)
| Table | Purpose |
|---|---|
| IS_NATIVE | Native-label IS with line order, subtotal flags, parent labels |
| BS_NATIVE | Native-label BS |
| CF_NATIVE | Native-label CF |
| NOTES | Footnote prose (BODY_TEXT) + structured callouts (CALLOUTS variant) |
| IS_EXHIBIT_REVENUE | Revenue mix detail |
| IS_EXHIBIT_EXPENSE | Expense detail |
| IS_EXHIBIT_ENTITY | Entity-level P&L |
| BS_EXHIBIT_DEBT | Debt schedule |
| BS_EXHIBIT_INVESTMENTS | Investment portfolio detail |
| BS_EXHIBIT_PPE | PP&E schedule |
| STATS | MD&A / operating statistics |
| RAW_FILING_JSON | Complete extraction JSON per filing |

### Key IS Concepts
net_patient_service_revenue, other_operating_revenue, premium_revenue,
total_salaries_and_benefits, supplies, purchased_services,
depreciation_amortization, interest_expense, other_operating_expense,
investment_return, change_in_net_assets

### Key BS Concepts
cash_and_equivalents, patient_ar_net, long_term_investments,
assets_limited_use_noncurrent, ppe_net, goodwill_and_intangibles,
long_term_debt, current_portion_long_term_debt, pension_and_postretirement_liability,
self_insurance_reserves, net_assets_without_donor_restrictions, net_assets_with_donor_restrictions

### Key CF Concepts
cf_operating, cf_investing, cf_financing, cf_capex, cf_debt_issued, cf_debt_repaid,
cf_depreciation_amortization, cf_working_capital_changes, cf_third_party_settlements

### Note Callout Concepts (from NOTES.CALLOUTS variant)
medicare_revenue_pct, medicaid_revenue_pct, blue_cross_revenue_pct,
self_pay_revenue_pct, medicare_ar_pct, medicaid_ar_pct,
professional_liability_retention, pension_assets, endowment_funds_perpetuity,
shared_services_expenses, gain_sharing_payment, permitted_encumbrance

### Rating Agency Benchmarks (Moody's A-rated health system medians)
| Metric | A-Rated Median | Watch Level |
|---|---|---|
| Operating margin | 3.0-4.0% | < 1.5% |
| EBIDA margin | 8.0-10.0% | < 6.0% |
| Days cash on hand | 200-250 | < 150 |
| Days in A/R | 45-50 | > 55 |
| Debt-to-capitalization | 30-35% | > 40% |
| Debt/EBIDA | 2.5-3.5x | > 4.5x |
| Capex-to-depreciation | 100-120% | < 80% |
| Labor % of revenue | 50-55% | > 57% |
| Operating CF margin | 6-8% | < 3% |

---

## Data Quality & Known Extraction Issues

### Mandatory Pre-Analysis Checks

Before interpreting ratios, the agent MUST run these validation checks and flag issues
in the briefing's "Data Quality Notes" section.

**1. Bad-debt / contra-revenue mis-mapping (affects early filings)**
Pre-2018 filings may map "Provision for bad debts" to `net_patient_service_revenue`,
producing a negative NPSR (e.g., -$225M instead of +$4.6B). This makes revenue totals,
margins, and all revenue-based ratios invalid for affected years.

Detection:
```sql
SELECT FY_LABEL, CONCEPT, AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = '{ORG_ID}'
   AND CONCEPT = 'net_patient_service_revenue'
   AND AMOUNT < 0;
```
If rows are returned, cross-check against `{ORG_CODE}.IS_NATIVE` to find the true
gross NPSR. Exclude affected FY years from ratio calculations and note the caveat.

**2. Duplicate IS/BS/CF rows from overlapping filings**
A filing for FY2018 contains comparative FY2017 columns; the FY2017 filing also contains
FY2017. This can produce duplicate rows in per-org native tables. The COMMON standardized
tables should be de-duplicated, but verify by checking for unexpected row counts:
```sql
SELECT FY_LABEL, CONCEPT, COUNT(*) AS n
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = '{ORG_ID}'
 GROUP BY FY_LABEL, CONCEPT
HAVING COUNT(*) > 1;
```

**3. Callout fy_label vs. filing FY_LABEL mismatch**
Note callouts carry their own `fy_label` field which is the year the data describes.
This frequently differs from the filing's FY_LABEL. For example, the FY2025 filing's
"Business and Credit Concentrations" note may disclose FY2024 payer mix percentages,
with callout fy_label = 'FY2024'.

Template 06 uses `COALESCE(c.value:fy_label::STRING, f.FY_LABEL)` to attribute
callout data to the correct fiscal year. When interpreting payer mix results, always
note which filing the data came from vs. which year it describes.

**4. Callout coverage sparsity**
Not all filings have the same notes extracted, and callout density varies significantly
(e.g., 88 callouts in one filing vs. 25 in another). Before building multi-year callout
trends, run the note coverage summary from template 05:
```sql
SELECT f.FY_LABEL, COUNT(*) AS note_count,
       SUM(ARRAY_SIZE(n.CALLOUTS)) AS total_callouts
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID
 WHERE f.ORG_ID = '{ORG_ID}'
 GROUP BY f.FY_LABEL ORDER BY f.FY_LABEL;
```
If a specific callout concept (e.g., `medicare_revenue_pct`) only appears in 1-2 filings,
do NOT claim it as a multi-year trend. Instead, note it as a point-in-time observation
and recommend the client provide supplementary data for trend analysis.

**5. Missing balance sheet data for early years**
Some BS concepts (e.g., `patient_ar_net`, `net_assets_without_donor_restrictions`) may
not be extracted for the earliest filings due to format differences. This causes NULL
values in liquidity and leverage ratios. Check which years have NULLs before interpreting
trends, and start trend analysis from the first year with complete data.
