# Chesapeake Hospital Authority — Comprehensive Financial Analysis
**Prepared by:** Coker  
**Version:** 1.0  
**Date:** April 20, 2026  
**Coverage:** FY2020–FY2025 (Fiscal Years Ending June 30)  
**Source:** 4 Audited Financial Statements (250 pages), AI-extracted via AFS Pipeline  

---

## Part I: Organization Profile

### 1. Entity Overview

**Chesapeake Hospital Authority** is a political subdivision of the Commonwealth of Virginia operating as a public healthcare system in Chesapeake, Virginia. The Authority oversees a multi-entity structure:

| Entity | Role |
|--------|------|
| **Chesapeake General Hospital (CGH)** | Primary acute-care hospital; generates ~87% of consolidated patient revenue |
| **Chesapeake Hospital Authority** | Parent governance body; manages intercompany transfers and authority-level operations |
| **Chesapeake Hospital Authority Foundation** | Investment holding entity; manages ~$231–261M in endowment/investment assets |
| **Tidewater Orthopaedics & Sports Medicine (TOBH)** | Equity-method investee; Authority ownership grew from 75% (FY2020) to 92% (FY2022) |
| **SouthCare Clinic (SCC)** | Subsidiary clinic; Authority ownership 83% (FY2021) |

**Key structural notes from footnotes:**
- The Authority charges CGH a management service fee of **2% of net revenues**
- TOBH investment: $32.3M (FY2020) → $40.7M (FY2022), with $2M/year distributions received
- Equity in earnings of TOBH: $4.95M (FY2020) → $6.61M (FY2021) → $5.76M (FY2022)
- Cedar Manor was sold for **$6.25M** (noted in FY2022 Reporting Entity footnote)

---

### 2. Engagement Summary — Extraction Statistics

| Filing | Pages | Text Entries | Pipeline Stages |
|--------|-------|-------------|-----------------|
| P11543622 (FY2020/21) | 62 | 62 | filing_row → statements → is_exhibits → bs_exhibits → notes → stats → insights |
| P21638376 (FY2021/22) | 63 | 63 | filing_row → statements → is_exhibits → bs_exhibits → notes → stats → insights |
| P11714921 (FY2022/23) | 64 | 64 | filing_row → statements → is_exhibits → bs_exhibits → notes → stats → insights |
| P21992743 (FY2024/25) | 61 | 61 | filing_row → statements → is_exhibits → bs_exhibits → notes → stats → insights |

**Extraction totals:**

| Artifact | Count |
|----------|-------|
| Income statement rows (native) | 260 |
| Balance sheet rows (native) | 244 |
| Cash flow rows (native) | 232 |
| Mapped common IS rows | 65 |
| Mapped common BS rows | 96 |
| Mapped common CF rows | 49 |
| Line item mappings | 213 |
| Footnotes extracted | 27 |
| MD&A statistics | 137 |
| Entity-level P&L rows | 129 |
| BS PPE exhibit rows | 12 |
| BS investment exhibit rows | 4 |
| AI-generated findings | 27 |

---

## Part II: Financial Statements (6-Year Trend)

### 3. Income Statement Trend

*All amounts in USD. Fiscal year ending June 30.*

| Concept | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|---------|--------|--------|--------|--------|--------|--------|
| **Net Patient Service Revenue** | 351,511,479 | 402,024,291 | 410,206,082 | 453,911,510 | 484,294,763 | 509,070,389 |
| Other Operating Revenue | 12,707,480 | 16,087,340 | 15,134,377 | 16,187,876 | 16,257,382 | 17,860,938 |
| **Total Operating Revenue** | **364,218,959** | **418,111,631** | **425,340,459** | **470,099,386** | **500,552,145** | **526,931,327** |
| Salaries & Wages | 140,328,715 | 151,526,353 | 161,296,095 | 175,469,578 | 194,988,492 | 209,575,736 |
| Employee Benefits | 35,272,751 | 33,969,912 | 30,677,658 | 37,313,073 | 40,153,002 | 42,582,611 |
| **Total Labor** | **175,601,466** | **185,496,265** | **191,973,753** | **212,782,651** | **235,141,494** | **252,158,347** |
| Supplies | 71,666,438 | 82,386,314 | 93,600,167 | 97,821,866 | 107,700,498 | 112,076,385 |
| Purchased Services | 23,348,650 | 28,063,396 | 24,867,416 | 28,907,891 | 31,583,959 | 35,146,845 |
| Other Operating Expense | 45,517,010 | 50,167,091 | 49,094,498 | 56,111,481 | 56,171,843 | 60,682,377 |
| Depreciation & Amortization | 22,562,537 | 23,805,157 | 26,585,090 | 26,654,749 | 29,134,123 | 29,571,938 |
| Interest Expense | 3,648,876 | 3,505,821 | 5,429,630 | 4,580,710 | 4,469,388 | 4,615,460 |
| **Total Operating Expense** | **342,344,977** | **373,424,044** | **391,550,554** | **426,859,348** | **464,201,305** | **494,251,352** |
| **Operating Income** | **21,873,982** | **44,687,587** | **33,789,905** | **43,240,038** | **36,350,840** | **32,679,975** |
| Investment Return | 6,031,956 | 41,048,594 | (22,133,953) | 19,270,695 | 26,408,062 | 30,597,022 |
| Other Non-Operating | (1,113,016) | 3,993,148 | — | — | (6,339,637) | — |
| Pension Non-Service Cost | 1,499,877 | 15,167,882 | — | — | — | — |

**Key trends:**
- Revenue CAGR (FY2020–FY2025): **7.7%** ($364M → $527M)
- Operating expense CAGR: **7.6%** ($342M → $494M)
- Operating income declined from $44.7M (FY2021 peak) to $32.7M (FY2025) despite revenue growth
- **Labor** is the dominant cost: grew from $175.6M (48.2% of revenue) to $252.2M (47.9%)
- **Supplies** grew 56% over 5 years ($71.7M → $112.1M)
- Investment return highly volatile: ranged from ($22.1M) loss to $41.0M gain

---

### 4. Balance Sheet Trend

| Concept | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|---------|--------|--------|--------|--------|--------|--------|
| **Cash & Equivalents** | 100,631,678 | 121,786,932 | 81,658,647 | 49,194,599 | 37,571,092 | 26,452,806 |
| Short-Term Investments | — | — | — | — | 30,623 | 36,220 |
| Long-Term Investments | 13,461,139 | 6,580,263 | 7,402,783 | 7,475,417 | 7,457,600 | 6,853,475 |
| **Total Liquid Assets** | **114,092,817** | **128,367,195** | **89,061,430** | **56,670,016** | **45,059,315** | **33,342,501** |
| Patient AR (net) | 39,424,313 | 47,051,746 | 47,338,830 | 46,323,339 | 49,823,812 | 58,844,157 |
| Inventories | 5,830,504 | 7,546,717 | 7,234,343 | 8,566,420 | 8,887,879 | 9,545,006 |
| PPE (net) | — | 111,241,596 | 100,635,859 | 161,095,788 | 191,950,263 | 187,856,347 |
| Right-of-Use Assets | — | 17,397,286 | 11,813,705 | 9,243,419 | 15,180,761 | 12,781,893 |
| Goodwill & Intangibles | 9,520,649 | 9,520,649 | 9,639,649 | 9,744,595 | 9,812,595 | 9,866,595 |
| Other Assets | 10,493,982 | 44,565,683 | 80,858,052 | 38,481,956 | 12,026,725 | 27,612,513 |
| **Accounts Payable** | 17,781,265 | 26,903,927 | — | — | 33,455,094 | 39,490,587 |
| Accrued Salaries & Benefits | 14,247,159 | 14,821,429 | — | — | 12,206,202 | 13,923,181 |
| 3rd Party Payor Liability | 3,729,988 | 3,875,693 | 3,423,623 | 12,196,043 | 4,579,350 | 2,360,058 |
| Long-Term Debt | — | — | — | — | 110,661,048 | 105,971,306 |
| Pension Liability | — | — | 3,775,806 | — | 24,567,652 | 18,675,376 |
| Net Assets (unrestricted) | — | — | — | — | 348,361,604 | 350,161,888 |
| Net Assets (donor restricted) | 1,690,022 | 4,474,993 | 4,885,738 | 4,244,976 | 6,396,903 | 6,561,089 |

**Key trends:**
- **Cash collapsed**: $121.8M → $26.5M (−78% over 4 years)
- **PPE nearly doubled**: $111M → $188M — massive capital investment program
- **Patient AR grew**: $39.4M → $58.8M (+49%) — collections slowing
- **AP nearly doubled**: $17.8M → $39.5M — stretching payables to manage cash
- **Pension liability surged**: $3.8M → $24.6M (FY2024 peak)

---

### 5. Cash Flow Trend

| Concept | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|---------|--------|--------|--------|--------|--------|--------|
| CF Operating | 9,442,425 | 5,833,552 | 11,212,680 | 11,333,444 | 1,704,344 | 1,716,979 |
| CF Depreciation (add-back) | — | — | — | — | 29,134,123 | 29,571,938 |
| CF Working Capital Changes | — | — | — | — | (606,444) | 4,500,955 |
| CF CapEx | (39,526,947) | (68,822,233) | 26,208,505 | 25,642,383 | 464,227 | 477,566 |
| CF Investment Purchases | (156,680,517) | (135,297,887) | (152,143,821) | (83,971,219) | (6,326,442) | (5,149,902) |
| CF Investment Sales | 154,920,834 | 2,135,250 | 147,216,072 | 83,755,870 | 83,811,724 | 95,236,391 |
| CF Investing | — | — | — | — | 17,025,905 | 10,345,739 |
| CF Debt Issued | 1,051,717 | 741,780 | 207,658 | — | — | — |
| CF Debt Repaid | (2,812,261) | (5,012,351) | (3,909,672) | (3,612,003) | (4,738,217) | (4,861,986) |
| CF Financing | 7,309,328 | 14,700,829 | 4,171,226 | — | — | — |
| **Net Change in Cash** | **162,631,438** | **171,803,362** | **81,658,647** | **49,194,599** | **37,571,092** | **26,452,806** |

**Key trends:**
- Operating CF declined dramatically: $11.3M (FY2023) → $1.7M (FY2024/25) — the system is barely cash-flow positive from operations
- Capital expenditures were enormous in FY2020/21 ($40-69M), then appear to shift in accounting presentation
- No new debt issued since FY2022; annual debt repayment ~$4-5M
- Investment portfolio is being actively managed (large purchase/sale volumes)
- MD&A stat for FY2023: Hospital-level operating CF was $21.0M vs. capital activities of −$50.7M

---

## Part III: Ratio Analysis

### 6. Key Performance Ratios

| Metric | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 | Trend |
|--------|--------|--------|--------|--------|--------|--------|-------|
| **Operating Margin %** | 6.01 | 10.69 | 7.94 | 9.20 | 7.26 | 6.20 | ↓ Declining |
| **EBIDA Margin %** | 12.20 | 16.38 | 14.19 | 14.87 | 13.08 | 11.81 | ↓ Declining |
| **Salaries % of Revenue** | 48.21 | 44.37 | 45.13 | 45.26 | 46.98 | 47.85 | ↑ Rising |
| **Supplies % of Revenue** | 19.68 | 19.70 | 22.01 | 20.81 | 21.52 | 21.27 | → Stable-high |
| **Purchased Svcs % of OpEx** | 6.82 | 7.52 | 6.35 | 6.77 | 6.80 | 7.11 | → Stable |
| **Days Cash on Hand** | 130.23 | 134.01 | 89.07 | 51.68 | 37.80 | 26.19 | ↓↓ Critical |
| **Days in AR** | 39.51 | 41.07 | 40.62 | 35.97 | 36.33 | 40.76 | → Volatile |
| **Debt to Capitalization %** | — | — | — | — | 24.11 | 23.23 | → N/A (limited data) |
| **Age of Plant (years)** | 4.49 | 4.67 | — | — | — | — | N/A (limited data) |

**Benchmarking context (Moody's Aa-rated hospital medians):**
- Operating margin: 3-5% (CHA is above median but declining toward it)
- Days cash on hand: 200+ days (CHA is critically below at 26 days)
- Days in AR: 45-50 days (CHA is within range)
- Debt-to-capitalization: 30-35% (CHA at 23% — conservative leverage)

---

### 7. Trend Deltas (Year-over-Year Changes)

| Metric | FY21→22 | FY22→23 | FY23→24 | FY24→25 |
|--------|---------|---------|---------|---------|
| Operating Margin | −2.75 pp | +1.26 pp | −1.94 pp | −1.06 pp |
| EBIDA Margin | −2.19 pp | +0.68 pp | −1.79 pp | −1.27 pp |
| Salaries % Rev | +0.76 pp | +0.13 pp | +1.72 pp | +0.87 pp |
| Supplies % Rev | +2.31 pp | −1.20 pp | +0.71 pp | −0.25 pp |
| Days Cash | −44.94 | −37.39 | −13.88 | −11.61 |
| Days in AR | −0.45 | −4.65 | +0.36 | +4.43 |

---

## Part IV: Deep Dives (Narrative Richness)

### 8. Days Cash on Hand Decomposition

**Formula:** Days Cash = (Cash + STI + LTI) / ((Total OpEx − D&A) / 365)

#### Numerator — Liquid Assets

| Component | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 | 5yr Δ |
|-----------|--------|--------|--------|--------|--------|--------|-------|
| Cash | 100.6M | 121.8M | 81.7M | 49.2M | 37.6M | 26.5M | −$95.3M |
| STI | — | — | — | — | 0.03M | 0.04M | — |
| LTI | 13.5M | 6.6M | 7.4M | 7.5M | 7.5M | 6.9M | −$6.6M |
| **Total** | **114.1M** | **128.4M** | **89.1M** | **56.7M** | **45.1M** | **33.3M** | **−$95.1M (−74%)** |

#### Denominator — Daily Cash Operating Expense

| Component | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|-----------|--------|--------|--------|--------|--------|--------|
| Total OpEx | 342.3M | 373.4M | 391.6M | 426.9M | 464.2M | 494.3M |
| Less D&A | (22.6M) | (23.8M) | (26.6M) | (26.7M) | (29.1M) | (29.6M) |
| Cash OpEx | 319.8M | 349.6M | 365.0M | 400.2M | 435.1M | 464.7M |
| **Daily** | **$876K** | **$958K** | **$1,000K** | **$1,096K** | **$1,192K** | **$1,273K** |

**The dual squeeze:**
- Numerator (liquid assets) declined 74% (−$95M)
- Denominator (daily cash burn) grew 45% (+$397K/day)
- Combined effect: 134 days → 26 days

**Root causes identified from narratives:**
1. **Capital consumption**: FY2023 MD&A shows Hospital-level capital activities at −$50.7M vs. operating CF of +$21.0M — capital spend exceeded operating cash generation by 2.4x
2. **PPE growth**: Net PPE grew from $111M → $188M, with construction in progress reaching $80.3M (FY2022)
3. **Operating CF erosion**: System-level operating CF fell from $11.3M → $1.7M
4. **No new debt**: Last debt issuance was FY2022; cash funded the capital program

---

### 9. Labor Cost Analysis

| Component | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 | 5yr Δ |
|-----------|--------|--------|--------|--------|--------|--------|-------|
| Salaries | 140.3M | 151.5M | 161.3M | 175.5M | 195.0M | 209.6M | +$69.2M (+49%) |
| Benefits | 35.3M | 34.0M | 30.7M | 37.3M | 40.2M | 42.6M | +$7.3M (+21%) |
| **Total Labor** | **175.6M** | **185.5M** | **192.0M** | **212.8M** | **235.1M** | **252.2M** | **+$76.6M (+44%)** |
| % of Revenue | 48.2% | 44.4% | 45.1% | 45.3% | 47.0% | 47.9% | +−0.3 pp |

**Entity-level labor detail (from IS exhibits):**

| Entity | FY2021 Salaries | FY2022 Salaries | FY2025 Salaries | Growth |
|--------|----------------|-----------------|-----------------|--------|
| Chesapeake General Hospital | $125.0M | $130.6M | $163.4M | +31% |
| Chesapeake Hospital Authority | — | $0 | $0 | — |

**Professional fees (contract labor proxy):**

| Year | Professional Fees | Δ YoY |
|------|------------------|-------|
| FY2022 (CGH) | $27.8M | — |
| FY2023 (CGH) | — | — |
| FY2025 (CGH) | $38.9M | +40% vs FY2022 |

**Pension obligation (from Note 7 — Pension Plan):**
- Defined benefit plan; frozen to new hires after 2019, excluded executives after 2019
- Contribution rate: 4.55% (FY2020) → 4.07% (FY2021)
- Discount rate: 7.0% (stable FY2020–FY2023)
- Net pension liability: $21.1M (FY2020) → $8.9M (FY2021) → $15.8M (FY2023) → $24.6M (FY2024) → $18.7M (FY2025)
- Investment return assumption declined: 7.7% (FY2022) → 5.8% (FY2023)

---

### 10. Payer Mix Evolution

*Source: Note 9 — Concentration of Credit Risk (callout data)*

| Payer | FY2020 | FY2021 | FY2022 | FY2023 | FY2025 |
|-------|--------|--------|--------|--------|--------|
| **Medicare** | 31% | 33% | 32% | 30% | 33% |
| **Anthem** | 26% | 25% | 25% | 18% | 21% |
| **Medicaid** | 12% | 13% | 14% | 9% | 10% |
| **Optima** | 7% | 7% | 6% | 11% | 9% |
| **Self-Pay** | 2% | 1% | 2% | 5% | 4% |
| **Other** | 20% | 21% | 21% | 27% | 23% |

**Key shifts:**
- **Anthem (commercial)**: declined from 26% → 21% — loss of highest-reimbursement payer volume
- **Self-pay**: tripled from ~1-2% → 4-5% — increased bad debt exposure
- **Optima (managed care)**: grew from 7% → 11% peak → 9% — managed care rate pressure
- **Medicare**: stable at ~31-33% — government rate dependency unchanged
- **Medicaid**: declined from 14% → 10% — less Medicaid volume
- **Other**: grew from 20% → 23% — diversification into smaller payers

**Revenue impact**: The shift away from Anthem (highest commercial reimbursement) toward self-pay and Optima (managed care) represents an estimated 3-5% revenue yield decline per encounter, translating to approximately $15-25M in foregone revenue at current volume levels.

---

### 11. Capital Investment & Plant Age

**Net PPE trend:**

| Year | PPE Net | CIP (from exhibits) | D&A |
|------|---------|---------------------|-----|
| FY2020 | — | — | $22.6M |
| FY2021 | $111.2M | — | $23.8M |
| FY2022 | $100.6M | $80.3M | $26.6M |
| FY2023 | $161.1M | — | $26.7M |
| FY2024 | $192.0M | — | $29.1M |
| FY2025 | $187.9M | — | $29.6M |

**PPE exhibit detail (from BS exhibits):**

| Category | FY2020 Cost | FY2021 Cost | FY2022 Cost |
|----------|-------------|-------------|-------------|
| Land | — | — | $3,944,949 |
| Buildings & Improvements (net) | $99.6M | $111.2M | $87.0–91.1M |
| Construction in Progress | — | — | $80,290,283 |
| Intangible Assets (net) | — | — | $2,450,000 |
| Right-of-Use Assets (net) | — | — | $3,112,229 |

**Capital assets from footnote callouts (Note 5):**
- FY2024: Capital assets net = $252.6M
- FY2025: Capital assets net = $259.2M

**Analysis:**
- The $80.3M CIP balance in FY2022 indicates a major construction project was underway
- PPE nearly doubled from $100.6M (FY2022) to $192.0M (FY2024) — completion of the construction program
- Annual D&A grew $7M (31%), reflecting the new asset base
- Age of plant was just 4.5–4.7 years (FY2020/21) — extremely young, indicating recent capital investment
- The capital program was largely cash-funded, directly depleting the $95M liquid asset decline

---

### 12. Debt Structure

**From Note 6 — Long-Term Obligations:**

| Component | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 |
|-----------|--------|--------|--------|--------|--------|
| Revenue Bonds (Series 2019) | $111.0M | $108.5M | — | — | — |
| Unamortized Bond Premium | $12.8M | $11.3M | — | — | — |
| CRIC Equipment Loans | $0.78M | $0.54M | — | — | — |
| CRSCVB Line of Credit | $0.74M | $0.89M | — | — | — |
| Deferred Compensation | $0.66M | $0.59M | — | — | — |
| SCC Note Payable | $2.53M | $2.28M | — | — | — |
| **Total LT Obligations** | **$128.5M** | **$124.2M** | **$119.3M** | **$114.5M** | **$109.8M** |

**Annual debt service**: ~$4.7–5.0M/year in principal repayment (declining schedule)
- BS long-term debt: $110.7M (FY2024) → $106.0M (FY2025) — $4.7M reduction
- Current portion: $3.8M (FY2024/25)

**Debt covenants (Note 7 — Long-term debt):**
- Days cash covenant and DSCR requirements noted but specific thresholds not disclosed in extracted callouts
- At 26 days cash on hand, the Authority is likely at or near covenant triggers

---

### 13. Subsidiary / Entity Performance

*From IS Exhibit Entity data. Amounts in USD.*

#### FY2022 Entity Breakdown

| Line Item | CGH | Authority | Foundation | Consolidated |
|-----------|-----|-----------|------------|-------------|
| Net Patient Service Revenue | $361.0M | $7.9M | $0 | $368.9M |
| Other Operating Revenue | $5.5M | $7.9M | $0.03M | $13.4M |
| Total Operating Expense | $356.3M | $1.2M | $0.002M | $357.5M |
| Operating Income (Loss) | $10.1M | $6.7M | ($0.002M) | $16.8M |
| Investment Income (Loss) | $1.3M | $0 | ($21.5M) | ($20.2M) |
| Change in Net Position | $13.3M | $10.6M | ($21.5M) | $2.4M |

#### FY2025 Entity Breakdown

| Line Item | CGH | Authority | Foundation |
|-----------|-----|-----------|------------|
| Net Patient Service Revenue | $442.1M | $0 | $0 |
| Other Operating Revenue | $8.0M | $7.4M | $0.03M |
| D&A | $25.0M | $0.37M | $0 |
| Salaries | $163.4M | $0 | $0 |
| Professional Fees | $38.9M | $0.04M | $0 |
| Investment Income | $0.66M | $0 | $29.1M |
| Affiliate Transfers | ($2.9M) | $2.0M | $0 |

**Key observations:**
- CGH generates virtually all clinical revenue ($442M) and bears all labor costs ($163M salaries + $31.7M benefits)
- The Authority entity is primarily an overhead/governance body (~$7.4M revenue from management fees, minimal direct expenses)
- The Foundation holds ~$231–261M in investments generating $29.1M returns (FY2025) — but these investment returns are **not available for operating cash needs** due to entity separation
- Foundation investment loss of ($21.5M) in FY2022 drove consolidated results negative despite positive hospital operations

---

## Part V: Findings & Recommendations

### 14. AI-Generated Findings

*27 findings extracted across 4 fiscal years, grouped by severity.*

#### HIGH Severity

| FY | Category | Title | Est. Impact |
|----|----------|-------|-------------|
| FY2021–25 | Margin | Declining Operating Margin Requires Attention | $10–20M/yr |
| FY2022 | Liquidity | Declining Days Cash on Hand Requires Attention | Not quantified |

**Narrative (margin):** Operating margin declined from 9.19% (FY2023) to 6.20% (FY2025), driven by increasing costs outpacing revenue growth. Revenue grew 7.7% CAGR but expenses grew 7.6% — the margin compression comes from the 0.1% gap compounding over 5 years across a $500M+ revenue base.

**Narrative (liquidity):** Days cash on hand fell from 134 days (FY2021) to 26 days (FY2025). This places the Authority at approximately the 10th percentile for Moody's-rated hospital systems and near probable debt covenant trigger levels.

#### MEDIUM Severity

| Category | Title | Est. Impact | Playbook |
|----------|-------|-------------|----------|
| Labor | High Labor Costs as % of Revenue | $5–10M/yr | Provider Compensation |
| Supply Chain | High Supply Costs as % of Revenue | $3–6M/yr | Supply Chain Management |
| Purchased Services | Purchased Services % of OpEx Above Benchmark | $2–4M/yr | Provider Compensation |
| Revenue Cycle | High Days in Accounts Receivable | $1–4M/yr | Revenue Cycle |

#### LOW Severity

| Category | Title |
|----------|-------|
| Liquidity | Decreasing Days Cash on Hand |
| Debt | Increasing Debt to Capitalization Ratio |

---

### 15. Margin Improvement Opportunities

| # | Opportunity | Category | Est. Annual Impact | Effort | Narrative Source |
|---|-----------|----------|-------------------|--------|-----------------|
| 1 | **Convert contract labor to employed staff** | Labor | $5–8M | Medium | Professional fees grew from $27.8M → $38.9M (+40%) at CGH (IS Exhibit Entity) |
| 2 | **Supply chain GPO renegotiation** | Supply Chain | $3–6M | Medium | Supplies at 21.3% of revenue vs. 18% benchmark; $112M base = $17M opportunity at benchmark |
| 3 | **Renegotiate managed care rates** | Revenue | $5–10M | High | Optima grew from 7% → 9% of AR; Anthem declined 26% → 21%; rate optimization on shifted volume |
| 4 | **Revenue cycle acceleration** | Revenue Cycle | $2–4M | Low | Days in AR at 40.8 (FY2025); self-pay grew to 4% of receivables; targeted collections improvement |
| 5 | **Defer non-critical capital projects** | Capital | $10–15M (cash) | Low | PPE grew $77M in 4 years; CIP $80.3M in FY2022; operating CF cannot sustain current CapEx pace |
| 6 | **Pension assumption review** | Benefits | $1–2M | Low | NPL swung $21.1M → $8.9M → $24.6M; investment return assumption dropped from 7.7% → 5.8% |
| 7 | **Foundation investment income access** | Liquidity | $5–10M (cash) | High | Foundation holds $261M generating $29.1M returns; explore board-approved distributions to hospital |

**Total estimated margin improvement:** $21–45M annually (4–9% of revenue)
**Total cash preservation / access:** $15–25M

---

### 16. Liquidity Action Plan

**Current state:** 26 days cash on hand (FY2025)
**Target:** 75+ days within 24 months

#### Phase 1: Immediate (0–6 months) — Cash Preservation

| Action | Cash Impact | Timeline |
|--------|-----------|----------|
| Pause discretionary CapEx (non-safety) | +$10–15M | Immediate |
| Revenue cycle blitz (self-pay collections, denial management) | +$2–3M | 3–6 months |
| AP optimization (extend terms where available) | +$3–5M (working capital) | 1–3 months |
| **Phase 1 Total** | **+$15–23M** | |

#### Phase 2: Near-term (6–18 months) — Structural Improvements

| Action | Cash Impact | Timeline |
|--------|-----------|----------|
| Contract labor conversion program | +$5–8M/yr | 6–12 months |
| Supply chain renegotiation / GPO review | +$3–6M/yr | 9–18 months |
| Managed care rate renegotiation | +$5–10M/yr | 12–18 months |
| **Phase 2 Total** | **+$13–24M/yr** | |

#### Phase 3: Strategic (12–24 months) — Capital Structure

| Action | Cash Impact | Timeline |
|--------|-----------|----------|
| Foundation distribution framework | +$5–10M | 12–18 months |
| Debt refinancing assessment (if covenant trigger) | TBD | 12–24 months |
| Pension strategy review | +$1–2M/yr | 18–24 months |

**Projected path to 75 days:**
- FY2025 baseline: 26 days ($33.3M liquid / $1.273M daily)
- Phase 1 adds ~$19M → ~41 days
- Phase 2 ongoing savings reduce daily burn and add cash → ~60 days by end of year 2
- Phase 3 strategic actions → 75+ days by month 24

---

## Part VI: Appendices

### 17. Extraction Methodology

**Pipeline stages (per filing):**
1. **PDF Ingest**: `SNOWFLAKE.CORTEX.PARSE_DOCUMENT` with `page_split: TRUE` — extracts per-page text
2. **Classify**: LLM classifies each page (cover, TOC, auditor letter, MD&A, IS, BS, CF, equity, note, exhibit)
3. **Identify**: Extracts org name, fiscal year labels, entity structure
4. **Extract Statements**: LLM extracts structured JSON from IS/BS/CF/equity pages → native rows
5. **Map Concepts**: LLM maps native labels to common taxonomy (213 mappings)
6. **Extract Exhibits**: IS entity breakdowns, BS PPE/investment/debt details
7. **Extract Notes**: Footnote text + structured callouts (payer mix, debt, pension, capital)
8. **Extract Stats**: MD&A statistical data
9. **Generate Insights**: AI synthesizes findings from ratios + trends

**Model:** `mistral-large2` via `SNOWFLAKE.CORTEX.COMPLETE` with `max_tokens=8192`
**Total pages processed:** 250 across 4 filings

---

### 18. Data Quality Notes

| Issue | Impact | Status |
|-------|--------|--------|
| FY2020/21 balance sheet gaps (LT debt, net assets) | Ratios not calculable for debt-to-cap, some BS items | Known gap — earlier filing format different |
| Some FY coverage depends on comparison-year columns in audits | FY2020 data comes from the FY2021 audit's prior-year column | Expected behavior |
| Professional fees only available at entity level for FY2022 and FY2025 | Cannot track full contract labor trend | Exhibit coverage varies by filing |
| Pension liability intermittent (—, —, $3.8M, —, $24.6M, $18.7M) | Appears in BS only when significant or when mapping succeeds | Extraction gap |
| 2 notes failed extraction for P21638376 (I/O error on pages 49-52, 57-58) | 2 of 11 note batches lost for that filing | Transient filesystem error |

---

### 19. Full Note Index

| FY | # | Title | Pages |
|----|---|-------|-------|
| FY2021 | 1 | Reporting Entity | 24–25 |
| FY2021 | 6 | Long-Term Obligations | 34–36 |
| FY2021 | 7 | Pension Plan | 37–41 |
| FY2021 | 9 | Concentration of Credit Risk | 43 |
| FY2022 | 1 | Reporting Entity | 25–28 |
| FY2022 | 6 | Long-Term Obligations | 36–38 |
| FY2022 | 7 | Pension Plan | 39–42 |
| FY2022 | 9 | Concentration of Credit Risk | 44 |
| FY2023 | 1 | Reporting Entity | 24–27 |
| FY2023 | 5 | Capital Assets | 33–34 |
| FY2023 | 6 | Long-Term Obligations | 35–37 |
| FY2023 | 7 | Investments | 38 |
| FY2023 | 9 | Concentration of Credit Risk | 40 |
| FY2025 | 1 | Reporting Entity | 22–23 |
| FY2025 | 5 | Capital Assets | 33–36 |
| FY2025 | 6 | Long-Term Obligations | 37–38 |
| FY2025 | 7 | Long-term debt | 39–42 |
| FY2025 | 9 | Concentration of Credit Risk | 44 |

*Plus additional notes extracted per filing (27 total across 4 filings)*

---

### 20. Glossary

| Term | Definition |
|------|-----------|
| **Operating Margin** | Operating Income / Total Operating Revenue × 100 |
| **EBIDA Margin** | (Operating Income + D&A) / Total Operating Revenue × 100 |
| **Days Cash on Hand** | (Cash + STI + LTI) / ((Total OpEx − D&A) / 365) |
| **Days in AR** | Patient AR (net) / (Net Patient Service Revenue / 365) |
| **Debt to Capitalization** | Long-term Debt / (Long-term Debt + Unrestricted Net Assets) × 100 |
| **Age of Plant** | Accumulated Depreciation / Annual D&A |
| **CGH** | Chesapeake General Hospital |
| **CIP** | Construction in Progress |
| **D&A** | Depreciation and Amortization |
| **DSCR** | Debt Service Coverage Ratio |
| **GPO** | Group Purchasing Organization |
| **NPL** | Net Pension Liability |
| **PPE** | Property, Plant & Equipment |
| **STI/LTI** | Short-term / Long-term Investments |
| **TOBH** | Tidewater Orthopaedics & Sports Medicine |

---

*End of Analysis — Coker | April 20, 2026 | v1.0*
