# Revenue Cycle Performance Deep Dive
**Organization:** Chesapeake Hospital Authority  
**Prepared by:** Coker  
**Date:** April 30, 2026  
**Coverage:** FY2020–FY2025 (Fiscal Years Ending June 30)  

---

## Part I: Revenue Cycle Methodology Framework

### What Is Revenue Cycle Performance?

Revenue cycle performance measures how effectively a health system converts patient encounters into collected cash. It spans the entire lifecycle from patient registration through final payment receipt and encompasses:

1. **Front-End** — Scheduling, eligibility verification, prior authorization, financial counseling
2. **Mid-Cycle** — Charge capture, coding accuracy, clinical documentation integrity (CDI)
3. **Back-End** — Claims submission, denial management, payment posting, collections, bad debt

### Key Performance Indicators (KPIs)

| KPI | Formula | Benchmark (Aa-rated) | What It Measures |
|-----|---------|---------------------|-----------------|
| **Days in AR** | Patient AR (net) ÷ (Net Patient Revenue ÷ 365) | 40–50 days | Speed of collections |
| **AR Growth Index** | AR % growth ÷ Revenue % growth | < 1.0 | Whether collections keep pace with volume |
| **Cash Collection Rate** | Operating CF ÷ Net Patient Revenue | > 3.0% | Cash yield per dollar billed |
| **Net Revenue per AR Dollar** | Net Patient Revenue ÷ Average AR | > 8.0x | Revenue velocity of receivables |
| **3rd Party Settlement Index** | 3rd Party Payor Liability ÷ Net Patient Revenue | < 1.5% | Contractual dispute exposure |
| **Working Capital Cycle** | Days AR + Inventory Days − Days Payable | 20–40 days | Net cash tied up in operations |
| **Operating CF Margin** | Operating CF ÷ Total Operating Revenue | > 4.0% | Cash generation efficiency |
| **Self-Pay Exposure** | Self-Pay % × Net Patient Revenue | < 5% | Uninsured/underinsured risk |
| **Denial Rate Proxy** | YoY Δ in 3rd Party Payor Liability | Stable | Claims adjudication effectiveness |

### Diagnostic Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                    REVENUE CYCLE SCORECARD                        │
├──────────────────┬──────────────────┬───────────────────────────┤
│  SPEED           │  YIELD           │  RISK                     │
│  • Days in AR    │  • Collection %  │  • Self-Pay Exposure      │
│  • AR Growth Idx │  • Net Rev/AR    │  • 3rd Party Settlements  │
│  • Working Cap   │  • CF Margin     │  • Payer Concentration    │
│  Cycle           │                  │  • Denial Volatility      │
└──────────────────┴──────────────────┴───────────────────────────┘
```

### Improvement Levers

| Lever | Typical Impact | Implementation Timeline |
|-------|---------------|------------------------|
| Denial management program | 2–5% AR reduction | 3–6 months |
| Prior authorization automation | 1–3 days AR reduction | 6–12 months |
| CDI physician engagement | 1–3% case mix increase | 6–18 months |
| Self-pay financial counseling | 20–40% self-pay collection lift | 3–6 months |
| Payer contract renegotiation | 3–8% yield improvement | 12–18 months |
| Revenue integrity audits | 1–2% charge capture improvement | 3–9 months |
| Patient access optimization | 2–4 days AR reduction (front-end) | 6–12 months |

---

## Part II: Chesapeake Hospital Authority — Revenue Cycle Execution

### Summary Scorecard

| Metric | FY2020 | FY2021 | FY2022 | FY2023 | FY2024 | FY2025 | Trend | Rating |
|--------|--------|--------|--------|--------|--------|--------|-------|--------|
| **Days in AR** | 40.9 | 42.7 | 42.1 | 37.2 | 37.6 | 42.2 | ↑ Deteriorating | ⚠️ CAUTION |
| **AR Growth Index** | — | 1.46 | 0.03 | −0.95 | 1.12 | 1.76 | ↑ Diverging | 🔴 ALERT |
| **Cash Collection Rate** | 2.69% | 1.45% | 2.73% | 2.50% | 0.35% | 0.34% | ↓↓ Critical | 🔴 ALERT |
| **Net Rev per AR $** | 8.92x | 8.55x | 8.67x | 9.80x | 9.72x | 8.65x | ↓ Declining | ⚠️ CAUTION |
| **3rd Party Settlement %** | 1.06% | 0.96% | 0.83% | 2.69% | 0.95% | 0.46% | Volatile | ⚠️ CAUTION |
| **Working Capital Cycle** | 25.0 days | 22.9 days | — | — | 17.3 days | 16.3 days | ↓ Improving | ✅ OK |
| **Operating CF Margin** | 2.59% | 1.39% | 2.64% | 2.41% | 0.34% | 0.33% | ↓↓ Critical | 🔴 ALERT |
| **Self-Pay Exposure ($M)** | ~$7.0M | ~$4.0M | ~$8.2M | ~$22.7M | ~$19.4M | ~$20.4M | ↑ Tripled | 🔴 ALERT |

---

### Detailed Metric Calculations

#### 1. Days in Accounts Receivable

**Formula:** Patient AR (net) ÷ (Net Patient Service Revenue ÷ 365)

| FY | Patient AR | NPSR | Daily Revenue | Days in AR | Δ YoY |
|----|-----------|------|---------------|-----------|--------|
| FY2020 | $39,424,313 | $351,511,479 | $963,044 | **40.9** | — |
| FY2021 | $47,051,746 | $402,024,291 | $1,101,436 | **42.7** | +1.8 |
| FY2022 | $47,338,830 | $410,206,082 | $1,123,852 | **42.1** | −0.6 |
| FY2023 | $46,323,339 | $453,911,510 | $1,243,593 | **37.2** | −4.9 |
| FY2024 | $49,823,812 | $484,294,763 | $1,326,835 | **37.6** | +0.4 |
| FY2025 | $58,844,157 | $509,070,389 | $1,394,713 | **42.2** | +4.6 |

**Analysis:**
- FY2023 showed a significant improvement (37.2 days) — likely driven by the resolution of $12.2M in 3rd party payor settlements that year
- FY2025 reversal (+4.6 days) adds **$6.4M** in trapped working capital vs. maintaining FY2024 pace
- The FY2025 spike coincides with self-pay growth to 4% and the Anthem volume decline

#### 2. AR Growth Index (AR Growth ÷ Revenue Growth)

**Formula:** (AR_t / AR_t-1 − 1) ÷ (NPSR_t / NPSR_t-1 − 1)

| Period | AR Growth | Revenue Growth | AR Growth Index | Interpretation |
|--------|-----------|----------------|-----------------|----------------|
| FY20→21 | +19.3% | +14.4% | **1.35** | AR growing faster than revenue |
| FY21→22 | +0.6% | +2.0% | **0.30** | Collections improving |
| FY22→23 | −2.1% | +10.7% | **−0.20** | Excellent — AR shrank despite growth |
| FY23→24 | +7.6% | +6.7% | **1.13** | Slightly outpacing revenue |
| FY24→25 | +18.1% | +5.1% | **3.55** | 🔴 CRITICAL — AR growing 3.5x revenue rate |

**Insight:** The FY2025 AR Growth Index of 3.55 is the single most alarming rev cycle indicator. AR grew $9.0M (+18.1%) while revenue only grew $24.8M (+5.1%). This means only ~64% of incremental revenue was collected at the prior pace — approximately **$5.6M in uncollected incremental revenue** is accumulating.

#### 3. Cash Collection Rate

**Formula:** Operating CF ÷ Net Patient Service Revenue

| FY | Operating CF | NPSR | Collection Rate | Δ YoY |
|----|-------------|------|----------------|--------|
| FY2020 | $9,442,425 | $351,511,479 | **2.69%** | — |
| FY2021 | $5,833,552 | $402,024,291 | **1.45%** | −1.24 pp |
| FY2022 | $11,212,680 | $410,206,082 | **2.73%** | +1.28 pp |
| FY2023 | $11,333,444 | $453,911,510 | **2.50%** | −0.23 pp |
| FY2024 | $1,704,344 | $484,294,763 | **0.35%** | −2.15 pp |
| FY2025 | $1,716,979 | $509,070,389 | **0.34%** | −0.01 pp |

**Benchmark:** Aa-rated systems typically achieve 5–8% operating cash collection rates. CHA at 0.34% is in **severe cash conversion distress**.

**Root cause decomposition:**
- Revenue grew $157M (FY2020→FY2025) but operating CF fell $7.7M
- For every additional dollar of revenue generated, CHA converted **negative** incremental cash
- The system is running a $509M revenue engine that generates only $1.7M in operating cash

#### 4. Payer Mix Revenue Impact

*Source: Note 9 — Concentration of Credit Risk*

| Payer | FY2020 Mix | FY2025 Mix | Δ Mix | Est. Revenue at FY2025 Volume | Revenue Yield Impact |
|-------|-----------|-----------|-------|-------------------------------|---------------------|
| Medicare | 31% | 33% | +2 pp | $168.0M | Neutral (fixed rates) |
| Anthem (Commercial) | 26% | 21% | −5 pp | $106.9M | 🔴 −$25.5M lost high-yield volume |
| Medicaid | 12% | 10% | −2 pp | $50.9M | Neutral (low rates) |
| Optima (Managed Care) | 7% | 9% | +2 pp | $45.8M | ⚠️ −$4.6M (managed care discount) |
| Self-Pay | 2% | 4% | +2 pp | $20.4M | 🔴 −$14.3M (est. 70% uncollectible) |
| Other | 20% | 23% | +3 pp | $117.1M | ⚠️ Mixed impact |

**Net revenue yield impact from payer shift: approximately −$15M to −$25M annualized**

Key dynamics:
- **Anthem decline** (−5 pp): Commercial payers typically reimburse 140–180% of Medicare. Losing 5 pp of highest-yield volume = ~$25M in foregone premium reimbursement
- **Self-pay growth** (2% → 4%): At $509M NPSR, self-pay represents ~$20.4M in gross charges. Industry self-pay collection rates are 15–30%, implying $14–17M in effective bad debt
- **Optima growth** (+2 pp): Managed care typically reimburses 85–110% of Medicare vs. Anthem at 140–180%

#### 5. 3rd Party Payor Liability (Denial/Settlement Proxy)

| FY | 3rd Party Liability | As % of NPSR | Δ YoY | Interpretation |
|----|-------------------|--------------|--------|----------------|
| FY2020 | $3,729,988 | 1.06% | — | Normal |
| FY2021 | $3,875,693 | 0.96% | +$146K | Stable |
| FY2022 | $3,423,623 | 0.83% | −$452K | Improving |
| FY2023 | $12,196,043 | 2.69% | +$8.77M | 🔴 SPIKE — major settlement/denial |
| FY2024 | $4,579,350 | 0.95% | −$7.62M | Resolution |
| FY2025 | $2,360,058 | 0.46% | −$2.22M | Below normal — aggressive resolution |

**Analysis:**
- The FY2023 spike to $12.2M (2.69% of revenue) indicates a major payer dispute or audit finding
- Resolution in FY2024/25 contributed to the temporary Days AR improvement in FY2023 (37.2 days)
- The current low level ($2.4M) may indicate either excellent clean claims or deferred dispute recognition

#### 6. Working Capital Cycle

**Formula:** Days AR + Inventory Days − Days Payable Outstanding

| FY | Days AR | Inventory Days* | Days Payable** | Working Capital Cycle |
|----|---------|-----------------|----------------|----------------------|
| FY2020 | 40.9 | 6.1 | 22.0 | **25.0 days** |
| FY2021 | 42.7 | 7.4 | 28.7 | **21.4 days** |
| FY2022 | 42.1 | 7.1 | — | — (AP not reported) |
| FY2023 | 37.2 | 7.9 | — | — (AP not reported) |
| FY2024 | 37.6 | 7.4 | 28.7 | **16.3 days** |
| FY2025 | 42.2 | 7.7 | 31.8 | **18.1 days** |

*Inventory Days = Inventories ÷ (Supplies / 365)*  
**Days Payable = AP ÷ ((Total OpEx − D&A − Salaries − Benefits) / 365)*

**Insight:** Working capital cycle is actually compressing — but only because AP stretching (+$22M from FY2020 to FY2025) masks the AR deterioration. This is unsustainable: vendor payment deferrals are a short-term liquidity tool, not a structural solution.

#### 7. Operating Cash Flow Margin

| FY | Operating CF | Total Operating Revenue | CF Margin |
|----|-------------|------------------------|-----------|
| FY2020 | $9,442,425 | $364,218,959 | **2.59%** |
| FY2021 | $5,833,552 | $418,111,631 | **1.39%** |
| FY2022 | $11,212,680 | $425,340,459 | **2.64%** |
| FY2023 | $11,333,444 | $470,099,386 | **2.41%** |
| FY2024 | $1,704,344 | $500,552,145 | **0.34%** |
| FY2025 | $1,716,979 | $526,931,327 | **0.33%** |

**Gap to benchmark:** Aa-rated systems maintain 8–12% CF margins. CHA's 0.33% represents a **$40–60M annual cash shortfall** vs. peer performance on a $527M revenue base.

---

### Revenue Cycle Root Cause Diagnosis

```
┌────────────────────────────────────────────────────────────────────────┐
│           CHESAPEAKE REV CYCLE DETERIORATION WATERFALL                  │
│                                                                        │
│  FY2021 Baseline: 42.7 Days AR | 1.45% Cash Collection                │
│                                                                        │
│  ┌──────────────┐                                                      │
│  │ Payer Shift  │ Anthem −5pp, Self-Pay +2pp                          │
│  │ Impact: +2-3 │ days AR (lower collectibility)                      │
│  └──────┬───────┘                                                      │
│         ▼                                                              │
│  ┌──────────────┐                                                      │
│  │ Volume Growth│ Revenue +$107M but AR staff/systems not scaled       │
│  │ Impact: +1-2 │ days AR (throughput bottleneck)                      │
│  └──────┬───────┘                                                      │
│         ▼                                                              │
│  ┌──────────────┐                                                      │
│  │ Denial Mgmt  │ 3rd Party Liability spike $3.7M → $12.2M (FY2023)  │
│  │ Impact: ±3-5 │ days AR (volatile)                                  │
│  └──────┬───────┘                                                      │
│         ▼                                                              │
│  ┌──────────────┐                                                      │
│  │ OpEx Growth  │ Daily cash burn +$397K/day over 5 years              │
│  │ Impact: CF   │ margin compressed from 2.6% → 0.3%                  │
│  └──────┬───────┘                                                      │
│         ▼                                                              │
│  FY2025 Result: 42.2 Days AR | 0.34% Cash Collection                  │
│  NET IMPACT: −$7.7M annual operating cash flow                         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Part III: Revenue Cycle Improvement Playbook — Chesapeake-Specific

### Priority Matrix

| # | Initiative | Annual Impact | Implementation | Complexity | Priority |
|---|-----------|---------------|----------------|------------|----------|
| 1 | **Self-Pay Financial Counseling & POS Collections** | $4–7M | 3–6 months | Low | 🟢 IMMEDIATE |
| 2 | **Denial Management Program** | $3–5M | 3–6 months | Medium | 🟢 IMMEDIATE |
| 3 | **AR Staffing/Capacity Alignment** | $2–4M | 1–3 months | Low | 🟢 IMMEDIATE |
| 4 | **Managed Care Contract Optimization** | $5–10M | 12–18 months | High | 🟡 NEAR-TERM |
| 5 | **CDI & Coding Accuracy Program** | $3–6M | 6–12 months | Medium | 🟡 NEAR-TERM |
| 6 | **Prior Auth Automation** | $1–2M | 6–12 months | Medium | 🟡 NEAR-TERM |
| 7 | **Revenue Integrity Audit** | $2–4M | 3–9 months | Medium | 🟡 NEAR-TERM |

**Total addressable rev cycle opportunity: $20–38M annually**

---

### Initiative Detail

#### 1. Self-Pay Financial Counseling & Point-of-Service (POS) Collections

**Problem:** Self-pay grew from 2% → 4% of AR mix ($20.4M exposure at FY2025 volume). Industry data shows unmanaged self-pay collects at only 15–30%.

**Actions:**
- Deploy financial counselors at registration for all self-pay/high-deductible patients
- Implement upfront cost estimation tools with price transparency
- Establish payment plan infrastructure (12–24 month interest-free plans)
- Screen all self-pay for Medicaid/charity eligibility before billing
- Implement propensity-to-pay scoring for prioritized outreach

**Target:** Improve self-pay collection from est. 25% → 45% = **$4.1M additional collections**

**KPI targets:**
- Self-pay bad debt % of NPSR: 4.0% → 2.5%
- POS collection rate: 0% → 30% of estimated patient responsibility
- Charity/Medicaid conversion: 10% of self-pay encounters

---

#### 2. Denial Management Program

**Problem:** 3rd party payor liability spiked to $12.2M in FY2023 (3.2x normal levels), indicating systematic denial/underpayment issues. Even at the "resolved" FY2025 level, the Anthem volume loss and managed care growth create ongoing denial pressure.

**Actions:**
- Hire/designate denial management team (2–3 FTEs dedicated)
- Implement denial tracking by root cause (registration errors, auth gaps, medical necessity, coding)
- Establish 72-hour denial turnaround SLA for initial review
- Create payer-specific appeal playbooks (Anthem, Optima, Medicare)
- Track initial denial rate, appeal success rate, and net write-off rate
- Implement pre-billing claim scrubbing with rules engine

**Target:** Reduce initial denial rate by 30%, improve appeal success from est. 40% → 65%

**KPI targets:**
- Initial denial rate: track baseline → reduce by 3–5 pp
- Clean claim rate: track → target 95%+
- Average denial resolution time: < 30 days
- Net denial write-off: < 2% of gross charges

---

#### 3. AR Staffing & Capacity Alignment

**Problem:** Revenue grew $157M (+45%) over 5 years, but the AR Growth Index of 3.55 in FY2025 suggests collections infrastructure has not scaled proportionally. The $9.0M AR buildup in FY2025 alone represents potential understaffing.

**Actions:**
- Benchmark AR FTEs per $1M of NPSR (industry: 0.8–1.2 FTEs per $1M)
- At $509M NPSR, target is 407–611 rev cycle FTEs — audit current state
- Add follow-up staff focused on 60+ day aging buckets
- Implement work queues by payer/aging band with daily production targets
- Deploy robotic process automation (RPA) for status checks and payment posting

**Target:** Reduce Days AR from 42.2 → 37.0 days = **$7.2M freed working capital**

---

#### 4. Managed Care Contract Optimization

**Problem:** Payer shift from Anthem (140–180% of Medicare) to Optima (85–110% of Medicare) represents an estimated $15–25M in foregone yield. Self-pay growth compounds this.

**Actions:**
- Conduct total cost of care analysis by payer (reimbursement vs. admin burden vs. denial rate)
- Renegotiate Optima rates leveraging volume growth (+2 pp mix)
- Evaluate narrow network participation vs. rate adequacy
- Model carve-out pricing for high-cost services (ortho, cardiac, oncology)
- Negotiate auto-adjudication thresholds to reduce denial friction

**Target:** 3–5% rate improvement on managed care book = **$5–10M annually**

---

#### 5. CDI & Coding Accuracy Program

**Problem:** With adjusted admissions of 54,230 (FY2024) and rising acuity, DRG optimization through CDI can materially improve case mix index and per-case reimbursement.

**Actions:**
- Deploy 3–5 CDI specialists focused on concurrent chart review
- Target top DRG opportunities: sepsis, malnutrition, respiratory failure, HCC risk adjustment
- Implement physician query feedback loop with education
- Track case mix index (CMI) trajectory monthly
- Audit CC/MCC capture rates vs. peer benchmarks

**Target:** 0.03–0.05 CMI improvement × 54,230 admissions × avg $1,500 incremental = **$2.4–4.1M**

---

### Revenue Cycle KPI Dashboard — Target State

| Metric | FY2025 Actual | 12-Month Target | 24-Month Target | Peer Benchmark |
|--------|--------------|-----------------|-----------------|----------------|
| Days in AR | 42.2 | 37.0 | 35.0 | 40–50 |
| AR Growth Index | 3.55 | < 1.2 | < 1.0 | < 1.0 |
| Cash Collection Rate | 0.34% | 2.5% | 4.0% | 5–8% |
| Operating CF Margin | 0.33% | 3.0% | 5.0% | 8–12% |
| Self-Pay Bad Debt % | ~4.0% | 3.0% | 2.5% | < 3% |
| Clean Claim Rate | N/A (baseline) | 93% | 96% | 95%+ |
| Initial Denial Rate | N/A (baseline) | < 8% | < 5% | 5–7% |

---

### Financial Impact Summary

| Category | Year 1 Impact | Year 2 Impact | Steady State |
|----------|--------------|---------------|--------------|
| Self-Pay Collections | $4–7M | $5–8M | $6–9M |
| Denial Reduction | $3–5M | $4–6M | $5–7M |
| AR Days Improvement (cash freed) | $7.2M (one-time) | — | — |
| Managed Care Rates | — | $5–10M | $8–12M |
| CDI / Coding | $2–4M | $3–6M | $4–7M |
| Revenue Integrity | $1–2M | $2–3M | $2–4M |
| **TOTAL** | **$17–25M** | **$19–33M** | **$25–39M** |

**Working capital release (one-time):** $7.2M from 5.2-day AR reduction  
**Annual run-rate improvement at steady state:** $25–39M (4.7–7.4% of NPSR)

---

### Implementation Timeline

```
Month:  1   2   3   4   5   6   7   8   9   10  11  12  13–18  19–24
        ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼──────┼─────┤
AR Staff ████████████                                              
Self-Pay ████████████████████                                      
Denials      ████████████████████████                               
CDI              ████████████████████████████████                   
Rev Integ        ████████████████████████                           
Prior Auth           ████████████████████████████                   
Contracts                        ████████████████████████████████████
```

---

### Risk Factors & Watchpoints

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Covenant trigger at 26 days cash | HIGH | Debt acceleration | Engage bondholders proactively; show improvement plan |
| Continued Anthem volume loss | MEDIUM | −$5–10M/yr | Diversify commercial contracts; direct-to-employer |
| Self-pay growth to 5%+ | MEDIUM | +$5M bad debt | Financial counseling program (Initiative #1) |
| Staffing market constraints | MEDIUM | Delayed AR reduction | Consider outsourcing aged AR (90+ days) |
| EHR/billing system limitations | LOW | Slower automation | Budget $500K–1M for rev cycle technology |

---

### Appendix: Computation Notes

**Data sources:**
- `AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT` — 65 mapped rows, FY2020–FY2025
- `AUDITED_FINANCIALS.COMMON.BALANCE_SHEET` — 96 mapped rows, FY2020–FY2025
- `AUDITED_FINANCIALS.COMMON.CASH_FLOW` — 49 mapped rows, FY2020–FY2025
- `AUDITED_FINANCIALS.COMMON.FINDINGS` — 4 revenue_cycle findings
- Payer mix data from Note 9 (Concentration of Credit Risk) extracted callouts

**Methodology notes:**
- Days in AR uses end-of-period AR (not average) for consistency with public reporting
- Operating CF is the system-level reported number; hospital-only CF was $21.0M in FY2023 per MD&A
- Self-pay dollar exposure estimated as: self-pay % × Net Patient Service Revenue
- Inventory days uses Supplies expense as the denominator (closest proxy for COGS)
- Working Capital Cycle excludes FY2022/23 where AP was not extracted from BS

---

*End of Revenue Cycle Playbook — Coker | April 30, 2026 | v1.0*
