-- =============================================================================
-- MedStar Health — Executive Summary Presentation Data Queries
-- Generated: 2026-05-15
-- ORG_ID: 8ae0219f-5a4d-47e1-a379-74c5b44e08c1
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────
-- SLIDE 3: Revenue Trajectory + Margin Combo Chart
-- ─────────────────────────────────────────────────────────────────
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
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       ROUND(total_revenue / 1e9, 2) AS revenue_B,
       ROUND((total_revenue - total_opex) / NULLIF(total_revenue, 0) * 100, 2) AS op_margin_pct
  FROM is_data
 WHERE FY_LABEL >= 'FY2018'
 ORDER BY FY_LABEL;

-- ─────────────────────────────────────────────────────────────────
-- SLIDE 6: Cost Structure Trend Lines
-- ─────────────────────────────────────────────────────────────────
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
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       ROUND(labor / NULLIF(rev, 0) * 100, 1) AS labor_pct_rev,
       ROUND(supplies / NULLIF(rev, 0) * 100, 1) AS supplies_pct_rev,
       ROUND(purchased / NULLIF(opex, 0) * 100, 1) AS purchased_pct_opex
  FROM is_data
 WHERE FY_LABEL >= 'FY2018'
 ORDER BY FY_LABEL;

-- ─────────────────────────────────────────────────────────────────
-- SLIDE 7: Key Ratios vs A-Rated Benchmarks (FY2025)
-- ─────────────────────────────────────────────────────────────────
WITH is_d AS (
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
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL = 'FY2025'
),
bs_d AS (
    SELECT SUM(CASE WHEN CONCEPT='cash_and_equivalents' THEN AMOUNT END) AS cash,
           SUM(CASE WHEN CONCEPT='long_term_investments' THEN AMOUNT END) AS lt_inv,
           SUM(CASE WHEN CONCEPT='patient_ar_net' THEN AMOUNT END) AS ar,
           SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END) AS lt_debt,
           SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END) AS na
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL = 'FY2025'
),
cf_d AS (
    SELECT SUM(CASE WHEN CONCEPT='cf_operating' THEN AMOUNT END) AS cf_ops,
           SUM(CASE WHEN CONCEPT='cf_capex' THEN AMOUNT END) AS capex
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL = 'FY2025'
)
SELECT 'Op. Margin' AS metric, ROUND((i.rev-i.opex)/NULLIF(i.rev,0)*100,1) AS actual, 3.5 AS benchmark FROM is_d i
UNION ALL SELECT 'EBIDA Margin', ROUND((i.rev-i.opex+i.da)/NULLIF(i.rev,0)*100,1), 9.0 FROM is_d i
UNION ALL SELECT 'Days Cash', ROUND((COALESCE(b.cash,0)+COALESCE(b.lt_inv,0))/NULLIF((i.opex-COALESCE(i.da,0))/365.0,0),0), 225 FROM is_d i, bs_d b
UNION ALL SELECT 'Days AR', ROUND(b.ar/NULLIF(i.rev/365.0,0),0), 48 FROM is_d i, bs_d b
UNION ALL SELECT 'Debt/Cap', ROUND(b.lt_debt/NULLIF(COALESCE(b.lt_debt,0)+COALESCE(b.na,0),0)*100,1), 33 FROM bs_d b
UNION ALL SELECT 'CF Margin', ROUND(c.cf_ops/NULLIF(i.rev,0)*100,1), 7.0 FROM is_d i, cf_d c
UNION ALL SELECT 'CapEx/Depr', ROUND(c.capex/NULLIF(i.da,0)*100,0), 110 FROM is_d i, cf_d c;

-- ─────────────────────────────────────────────────────────────────
-- SLIDE 8: Payer Mix (from note callouts)
-- ─────────────────────────────────────────────────────────────────
SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
       c.value:concept::STRING AS metric,
       c.value:amount::NUMBER AS pct
  FROM AUDITED_FINANCIALS.MEDSTAR_HEALTH.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND c.value:concept::STRING LIKE '%_revenue_pct'
 ORDER BY pct DESC;
