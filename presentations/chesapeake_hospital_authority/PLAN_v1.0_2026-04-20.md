# Presentation Plan — Chesapeake Hospital Authority
**Version:** 1.0  
**Date:** 2026-04-20  
**Brand:** Coker  
**Audience:** Consulting team  
**Style:** Light consulting (white background, blue/gray palette, section headers)  
**Format:** Self-contained HTML with CDN references (Chart.js, Google Fonts)  
**Navigation:** Sticky section sidebar  

---

## Data Inventory

| Source Table | Records | Coverage |
|---|---|---|
| `COMMON.INCOME_STATEMENT` (mapped) | 65 rows | FY2020–FY2025 (6 years) |
| `COMMON.BALANCE_SHEET` (mapped) | 96 rows | FY2020–FY2025 |
| `COMMON.CASH_FLOW` (mapped) | 49 rows | FY2020–FY2025 |
| `COMMON.LINE_ITEM_MAP` | 213 mappings | IS/BS/CF/stat |
| `COMMON.FINDINGS` | 27 findings | FY2021–FY2025 |
| `ORG.IS_NATIVE` | 260 rows | Raw extracted IS lines |
| `ORG.BS_NATIVE` | 244 rows | Raw extracted BS lines |
| `ORG.CF_NATIVE` | 232 rows | Raw extracted CF lines |
| `ORG.NOTES` | 27 notes | Footnote text + callouts |
| `ORG.STATS` | 137 rows | MD&A statistical tables |
| `ORG.IS_EXHIBIT_ENTITY` | 129 rows | Entity-level P&L breakdown |
| `ORG.BS_EXHIBIT_PPE` | 12 rows | Capital asset detail |
| `ORG.BS_EXHIBIT_INVESTMENTS` | 4 rows | Investment fair value |

---

## Deliverables

### 1. Analysis Markdown (`ANALYSIS_v1.0_2026-04-20.md`)
Full narrative analysis document with all data tables, findings, and recommendations.
Serves as the content source for the HTML build.

### 2. HTML Presentation (`presentation_v1.0_2026-04-20.html`)
Interactive single-file HTML with CDN Chart.js charts and sticky sidebar navigation.

---

## Analysis Markdown — Section Plan

### Part I: Organization Profile
1. **Entity Overview** — Legal structure, subsidiaries, service area, tax status
   - Source: Notes (title="Reporting Entity") across all FYs
2. **Engagement Summary** — Filings processed, page counts, extraction stats
   - Source: `PDF_STAGING`, pipeline output metadata

### Part II: Financial Statements (6-Year Trend)
3. **Income Statement Trend** — All mapped IS concepts FY2020–FY2025
   - Revenue growth, expense growth, operating margin trajectory
   - Source: `COMMON.INCOME_STATEMENT` joined to `LINE_ITEM_MAP`
4. **Balance Sheet Trend** — Key BS positions FY2020–FY2025
   - Liquidity, capital assets, debt, net assets
   - Source: `COMMON.BALANCE_SHEET` joined to `LINE_ITEM_MAP`
5. **Cash Flow Trend** — Operating, investing, financing activities
   - Source: `COMMON.CASH_FLOW` joined to `LINE_ITEM_MAP`

### Part III: Ratio Analysis
6. **Key Performance Ratios** — 9 computed ratios across 6 FYs
   - Operating margin, EBIDA margin, labor %, supplies %, days cash, days AR, etc.
   - Source: Computed from `compute_ratios()` / underlying statements
7. **Trend Deltas & YoY Changes** — Period-over-period ratio movements
   - Source: `compute_trends()`

### Part IV: Deep Dives (Narrative Richness)
8. **Days Cash on Hand Decomposition** — Numerator (cash+investments) vs. denominator (daily opex)
   - Waterfall from 134 to 26 days
   - Source: BS cash/investment lines + IS opex lines
9. **Labor Cost Analysis** — Salaries, benefits, pension obligation, contract labor
   - Source: IS labor lines + Notes (Pension Plan) callouts
10. **Payer Mix Evolution** — AR concentration by payer FY2020–FY2025
    - Source: Notes (Concentration of Credit Risk) callouts
11. **Capital Investment & Plant Age** — PPE detail, CIP, accumulated depreciation
    - Source: Notes (Capital Assets) + `BS_EXHIBIT_PPE` + BS lines
12. **Debt Structure** — Long-term obligations, bond detail, maturity profile
    - Source: Notes (Long-Term Obligations) callouts + BS debt lines
13. **Subsidiary / Entity Performance** — Entity-level P&L breakdown
    - Source: `IS_EXHIBIT_ENTITY`

### Part V: Findings & Recommendations
14. **AI-Generated Findings** — All 27 findings grouped by severity and category
    - Source: `COMMON.FINDINGS`
15. **Margin Improvement Opportunities** — Actionable recommendations with estimated impact
    - Cross-referenced from findings + narrative callouts
16. **Liquidity Action Plan** — Specific interventions for days cash recovery
    - Derived from capital, payer, and operating cost analysis

### Part VI: Appendices
17. **Extraction Methodology** — Parser pipeline stages, models used, page counts
18. **Data Quality Notes** — Coverage gaps, unmapped items, confidence scores
19. **Full Note Index** — All 27 footnotes with titles and page references
20. **Glossary** — Ratio definitions, abbreviations

---

## HTML Presentation — Information Flow

### Navigation
- Sticky left sidebar with section groups (collapsible)
- "Coker" logo + document title at top
- Print-aware CSS (hide sidebar, page breaks)

### Visual Language
- **Colors:** Navy (#1B2A4A), Steel Blue (#4A7FB5), Light Gray (#F4F6F8), Accent Orange (#E8833A)
- **Typography:** Inter (headings), Source Sans Pro (body) via Google Fonts
- **Charts:** Chart.js via CDN — line charts for trends, bar charts for comparisons, doughnut for payer mix
- **Tables:** Zebra-striped, right-aligned numbers, color-coded deltas (green=good, red=bad)

### Section-by-Section Layout

| # | Section | Primary Visual | Data Source |
|---|---------|---------------|-------------|
| 1 | Org Profile | Info card + subsidiary diagram | Notes |
| 2 | Engagement Stats | Metric tiles (pages parsed, notes extracted, etc.) | Pipeline metadata |
| 3 | IS Trend | Multi-line chart (revenue vs. expense) + table | IS mapped |
| 4 | BS Trend | Stacked bar (assets) + line (net assets) | BS mapped |
| 5 | CF Trend | Grouped bar (operating/investing/financing) | CF mapped |
| 6 | Ratios | Heat-mapped table (6 FY columns) + sparklines | Computed |
| 7 | Trends | Arrow indicators + delta table | Computed |
| 8 | Days Cash Deep Dive | Waterfall chart + dual-axis (cash vs. daily opex) | BS+IS |
| 9 | Labor Analysis | Stacked area (salary+benefits+pension) | IS+Notes |
| 10 | Payer Mix | Doughnut comparison (FY2021 vs FY2025) | Notes callouts |
| 11 | Capital & PPE | Grouped bar (gross/depr/net) + CIP line | BS+PPE exhibit |
| 12 | Debt Structure | Amortization schedule table + balance line | Notes callouts |
| 13 | Entity P&L | Table with entity columns | IS exhibit |
| 14 | Findings | Severity-coded cards with filtering | FINDINGS |
| 15 | Recommendations | Priority matrix (impact vs. effort) | Synthesized |
| 16 | Liquidity Plan | Timeline/roadmap visual | Synthesized |
| 17-20 | Appendices | Collapsible detail tables | Various |

---

## Execution Order

1. Create `ANALYSIS_v1.0_2026-04-20.md` — query all data, build narrative
2. Create `presentation_v1.0_2026-04-20.html` — translate analysis into visual HTML
3. Verify HTML renders correctly, all charts populated, navigation works

---

## Open Decisions (Resolved)
- **Audience:** Consulting team ✓
- **Style:** Light consulting ✓
- **Branding:** Coker ✓
- **CDN OK:** Yes ✓
- **Navigation:** Sticky sidebar ✓
- **Depth:** Comprehensive 15+ sections ✓
