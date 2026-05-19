-- =============================================================================
-- Chart Data Queries — Executive Summary Presentation
-- =============================================================================
-- Substitution: {ORG_ID}, {ORG_CODE}
-- Each query is labeled with the slide and chart it supports.

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 01: Revenue Trajectory with Margin Overlay (Slide 3)
-- Type: Combo — bar (revenue) + line (operating margin %)
-- ─────────────────────────────────────────────────────────────────────────────
WITH is_data AS (
    SELECT FY_LABEL,
           COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0) AS total_revenue,
           COALESCE(SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END),0) AS total_opex
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       ROUND(total_revenue / 1e9, 2)                                AS revenue_billions,
       ROUND((total_revenue - total_opex) / NULLIF(total_revenue, 0) * 100, 2) AS operating_margin_pct
  FROM is_data
 WHERE FY_LABEL >= 'FY2018'
 ORDER BY FY_LABEL;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 02: Cost Structure as % of Revenue (Slide 6)
-- Type: Multi-line — labor%, supply%, purchased% over time
-- ─────────────────────────────────────────────────────────────────────────────
WITH is_data AS (
    SELECT FY_LABEL,
           COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0) AS rev,
           SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END) AS labor,
           SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END) AS supplies,
           SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END) AS purchased,
           COALESCE(SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END),0) AS opex
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       ROUND(labor / NULLIF(rev, 0) * 100, 1)     AS labor_pct_rev,
       ROUND(supplies / NULLIF(rev, 0) * 100, 1)   AS supplies_pct_rev,
       ROUND(purchased / NULLIF(opex, 0) * 100, 1) AS purchased_pct_opex
  FROM is_data
 WHERE FY_LABEL >= 'FY2018'
 ORDER BY FY_LABEL;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 03: Key Ratios vs. A-Rated Benchmarks (Slide 7)
-- Type: Bullet chart or grouped bar with benchmark reference lines
-- ─────────────────────────────────────────────────────────────────────────────
WITH latest AS (
    SELECT MAX(FY_LABEL) AS fy FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
),
is_d AS (
    SELECT COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0) AS rev,
           COALESCE(SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END),0) AS opex,
           SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END) AS da
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}' AND FY_LABEL = (SELECT fy FROM latest)
),
bs_d AS (
    SELECT SUM(CASE WHEN CONCEPT='cash_and_equivalents' THEN AMOUNT END) AS cash,
           SUM(CASE WHEN CONCEPT='long_term_investments' THEN AMOUNT END) AS lt_inv,
           SUM(CASE WHEN CONCEPT='patient_ar_net' THEN AMOUNT END) AS ar,
           SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END) AS lt_debt,
           SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END) AS na
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '{ORG_ID}' AND FY_LABEL = (SELECT fy FROM latest)
),
cf_d AS (
    SELECT SUM(CASE WHEN CONCEPT='cf_operating' THEN AMOUNT END) AS cf_ops,
           SUM(CASE WHEN CONCEPT='cf_capex' THEN AMOUNT END) AS capex
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '{ORG_ID}' AND FY_LABEL = (SELECT fy FROM latest)
)
SELECT 'Operating Margin' AS metric,
       ROUND((i.rev - i.opex) / NULLIF(i.rev, 0) * 100, 1) AS actual,
       3.5 AS benchmark, '%' AS unit
  FROM is_d i
UNION ALL
SELECT 'EBIDA Margin',
       ROUND((i.rev - i.opex + i.da) / NULLIF(i.rev, 0) * 100, 1), 9.0, '%'
  FROM is_d i
UNION ALL
SELECT 'Days Cash on Hand',
       ROUND((COALESCE(b.cash,0) + COALESCE(b.lt_inv,0)) / NULLIF((i.opex - COALESCE(i.da,0)) / 365.0, 0), 0),
       225, 'days'
  FROM is_d i, bs_d b
UNION ALL
SELECT 'Days in A/R',
       ROUND(b.ar / NULLIF(i.rev / 365.0, 0), 0), 48, 'days'
  FROM is_d i, bs_d b
UNION ALL
SELECT 'Debt-to-Capitalization',
       ROUND(b.lt_debt / NULLIF(COALESCE(b.lt_debt,0) + COALESCE(b.na,0), 0) * 100, 1), 33, '%'
  FROM bs_d b
UNION ALL
SELECT 'CF Margin',
       ROUND(c.cf_ops / NULLIF(i.rev, 0) * 100, 1), 7.0, '%'
  FROM is_d i, cf_d c
UNION ALL
SELECT 'Capex / Depreciation',
       ROUND(c.capex / NULLIF(i.da, 0) * 100, 0), 110, '%'
  FROM is_d i, cf_d c;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 04: Opportunity Sizing Waterfall (Slide 9)
-- Type: Horizontal bar — opportunity categories with dollar ranges
-- NOTE: Values come from the briefing analysis, not raw SQL.
-- This query provides the underlying cost base for validation.
-- ─────────────────────────────────────────────────────────────────────────────
WITH latest_costs AS (
    SELECT SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END) AS supplies,
           SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END) AS purchased,
           COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0) AS revenue,
           SUM(CASE WHEN CONCEPT='patient_ar_net' THEN b.AMOUNT END) AS ar
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT i
      LEFT JOIN AUDITED_FINANCIALS.COMMON.BALANCE_SHEET b
        ON b.ORG_ID = i.ORG_ID AND b.FY_LABEL = i.FY_LABEL AND b.CONCEPT = 'patient_ar_net'
     WHERE i.ORG_ID = '{ORG_ID}'
       AND i.FY_LABEL = (SELECT MAX(FY_LABEL) FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT WHERE ORG_ID = '{ORG_ID}')
)
SELECT 'Supply Chain' AS opportunity, ROUND(supplies / 1e6, 0) AS current_spend_M,
       '16.9%' AS current_pct, '14.4–16.0%' AS target_pct, '$80–225M' AS est_impact
  FROM latest_costs
UNION ALL
SELECT 'Purchased Services', ROUND(purchased / 1e6, 0),
       '14.6% of opex', '12–13.5% of opex', '$120–228M'
  FROM latest_costs
UNION ALL
SELECT 'Revenue Cycle', ROUND(ar / 1e6, 0),
       '50.7 days', '45 days', '$25–50M + $140M one-time'
  FROM latest_costs
UNION ALL
SELECT 'Operating Efficiency', NULL,
       '2.44% margin', '3.5–4.0%', '$90–135M per point'
  FROM latest_costs;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 05: Payer Mix Donut (Slide 8 — Qualitative Intelligence)
-- Type: Donut/pie — revenue concentration by payer
-- ─────────────────────────────────────────────────────────────────────────────
SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
       c.value:concept::STRING AS metric,
       c.value:amount::NUMBER AS pct
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '{ORG_ID}'
   AND c.value:concept::STRING LIKE '%_revenue_pct'
 ORDER BY pct DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 06: Pension Liability Trajectory (Deep Dive — BS slide)
-- Type: Area chart — pension liability declining over time
-- ─────────────────────────────────────────────────────────────────────────────
SELECT FY_LABEL,
       ROUND(AMOUNT / 1e6, 1) AS pension_liability_M
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID = '{ORG_ID}'
   AND CONCEPT = 'pension_and_postretirement_liability'
 ORDER BY FY_LABEL;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 07: Cash Flow Bridge (Deep Dive — CF slide)
-- Type: Waterfall — from operating income to free cash flow
-- ─────────────────────────────────────────────────────────────────────────────
WITH latest AS (
    SELECT MAX(FY_LABEL) AS fy FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '{ORG_ID}'
)
SELECT CONCEPT, AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
 WHERE ORG_ID = '{ORG_ID}'
   AND FY_LABEL = (SELECT fy FROM latest)
   AND CONCEPT IN ('cf_operating','cf_investing','cf_financing','cf_capex')
 ORDER BY CONCEPT;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 08: Revenue vs. Expense CAGR Comparison (Deep Dive — Margin slide)
-- Type: Grouped bar — revenue CAGR vs. opex CAGR vs. component CAGRs
-- ─────────────────────────────────────────────────────────────────────────────
WITH endpoints AS (
    SELECT FY_LABEL,
           COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0) AS rev,
           SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END) AS labor,
           SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END) AS supplies,
           SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END) AS purchased,
           COALESCE(SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END),0) AS opex
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
       AND FY_LABEL IN ('FY2018','FY2025')
     GROUP BY FY_LABEL
)
SELECT 'Revenue' AS category,
       ROUND((POWER(MAX(CASE WHEN FY_LABEL='FY2025' THEN rev END)
                   / NULLIF(MAX(CASE WHEN FY_LABEL='FY2018' THEN rev END), 0), 1.0/7) - 1) * 100, 1) AS cagr_pct
  FROM endpoints
UNION ALL
SELECT 'Total OpEx',
       ROUND((POWER(MAX(CASE WHEN FY_LABEL='FY2025' THEN opex END)
                   / NULLIF(MAX(CASE WHEN FY_LABEL='FY2018' THEN opex END), 0), 1.0/7) - 1) * 100, 1)
  FROM endpoints
UNION ALL
SELECT 'Labor',
       ROUND((POWER(MAX(CASE WHEN FY_LABEL='FY2025' THEN labor END)
                   / NULLIF(MAX(CASE WHEN FY_LABEL='FY2018' THEN labor END), 0), 1.0/7) - 1) * 100, 1)
  FROM endpoints
UNION ALL
SELECT 'Supplies',
       ROUND((POWER(MAX(CASE WHEN FY_LABEL='FY2025' THEN supplies END)
                   / NULLIF(MAX(CASE WHEN FY_LABEL='FY2018' THEN supplies END), 0), 1.0/7) - 1) * 100, 1)
  FROM endpoints
UNION ALL
SELECT 'Purchased Services',
       ROUND((POWER(MAX(CASE WHEN FY_LABEL='FY2025' THEN purchased END)
                   / NULLIF(MAX(CASE WHEN FY_LABEL='FY2018' THEN purchased END), 0), 1.0/7) - 1) * 100, 1)
  FROM endpoints;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 09: Days in A/R Trend (Deep Dive — Revenue Cycle)
-- Type: Bar chart with benchmark reference line at 50 days
-- ─────────────────────────────────────────────────────────────────────────────
WITH rev AS (
    SELECT FY_LABEL,
           COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0) AS total_rev
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}' GROUP BY FY_LABEL
),
ar AS (
    SELECT FY_LABEL, AMOUNT AS patient_ar
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '{ORG_ID}' AND CONCEPT = 'patient_ar_net'
)
SELECT a.FY_LABEL,
       ROUND(a.patient_ar / NULLIF(r.total_rev / 365.0, 0), 1) AS days_in_ar
  FROM ar a JOIN rev r ON r.FY_LABEL = a.FY_LABEL
 WHERE a.FY_LABEL >= 'FY2018'
 ORDER BY a.FY_LABEL;

-- ─────────────────────────────────────────────────────────────────────────────
-- CHART 10: Self-Insurance Reserve Trend (Deep Dive — Qualitative)
-- Type: Bar chart — self-insurance reserves over time
-- ─────────────────────────────────────────────────────────────────────────────
SELECT FY_LABEL,
       ROUND(AMOUNT / 1e6, 1) AS self_insurance_M
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID = '{ORG_ID}'
   AND CONCEPT = 'self_insurance_reserves'
 ORDER BY FY_LABEL;
