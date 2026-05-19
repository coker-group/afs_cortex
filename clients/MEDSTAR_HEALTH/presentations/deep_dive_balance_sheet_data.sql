-- =============================================================================
-- MedStar Health — Balance Sheet Deep Dive: Presentation Data Queries
-- Generated: 2026-05-15
-- ORG_ID: 8ae0219f-5a4d-47e1-a379-74c5b44e08c1
-- =============================================================================

-- SLIDE 3: Asset Composition (Stacked Area)
SELECT FY_LABEL,
       SUM(CASE WHEN CONCEPT='cash_and_equivalents' THEN AMOUNT END)/1e6 AS cash_M,
       SUM(CASE WHEN CONCEPT='patient_ar_net' THEN AMOUNT END)/1e6 AS ar_M,
       SUM(CASE WHEN CONCEPT='long_term_investments' THEN AMOUNT END)/1e6 AS investments_M,
       SUM(CASE WHEN CONCEPT='ppe_net' THEN AMOUNT END)/1e6 AS ppe_M,
       (COALESCE(SUM(CASE WHEN CONCEPT='assets_limited_use_noncurrent' THEN AMOUNT END),0)
        +COALESCE(SUM(CASE WHEN CONCEPT='goodwill_and_intangibles' THEN AMOUNT END),0)
        +COALESCE(SUM(CASE WHEN CONCEPT='inventories' THEN AMOUNT END),0)
        +COALESCE(SUM(CASE WHEN CONCEPT='other_assets' THEN AMOUNT END),0)
        +COALESCE(SUM(CASE WHEN CONCEPT='right_of_use_assets' THEN AMOUNT END),0)
        +COALESCE(SUM(CASE WHEN CONCEPT='prepaid_and_other_current' THEN AMOUNT END),0))/1e6 AS other_M
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL>='FY2018'
 GROUP BY FY_LABEL ORDER BY FY_LABEL;

-- SLIDE 4: Net Asset Waterfall components
WITH yearly AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END)/1e6 AS na
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
     GROUP BY FY_LABEL
),
is_data AS (
    SELECT SUM(CASE WHEN FY_LABEL>='FY2018' THEN
           CASE WHEN CONCEPT IN ('net_patient_service_revenue','other_operating_revenue','premium_revenue') THEN AMOUNT
                WHEN CONCEPT IN ('total_salaries_and_benefits','supplies','purchased_services','depreciation_amortization','interest_expense','other_operating_expense') THEN -AMOUNT END END)/1e6 AS cum_op_inc,
           SUM(CASE WHEN FY_LABEL>='FY2018' AND CONCEPT='investment_return' THEN AMOUNT END)/1e6 AS cum_inv_ret
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
)
SELECT 'FY2018 Net Assets' AS item, (SELECT na FROM yearly WHERE FY_LABEL='FY2018') AS value
UNION ALL SELECT 'Cumulative Op Income', cum_op_inc FROM is_data
UNION ALL SELECT 'Cumulative Inv Returns', cum_inv_ret FROM is_data
UNION ALL SELECT 'FY2025 Net Assets', (SELECT na FROM yearly WHERE FY_LABEL='FY2025');

-- SLIDE 5: Gauge Dashboard — all key BS ratios for latest year
-- (See executive_summary_data.sql Chart 03 for this query)

-- SLIDE 6: Leverage trajectory
SELECT FY_LABEL,
       ROUND(SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END)
             /NULLIF(COALESCE(SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END),0)
                    +COALESCE(SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END),0),0)*100,1) AS debt_cap_pct,
       ROUND(SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END)/1e6,0) AS na_M,
       ROUND(SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END)/1e6,0) AS debt_M
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL>='FY2018'
 GROUP BY FY_LABEL ORDER BY FY_LABEL;

-- SLIDE 7: Pension trajectory
SELECT FY_LABEL, ROUND(AMOUNT/1e6,0) AS pension_M
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND CONCEPT='pension_and_postretirement_liability' AND FY_LABEL>='FY2018'
 ORDER BY FY_LABEL;

-- SLIDE 8: Liquidity — cash + investments + DCOH
WITH bs AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='cash_and_equivalents' THEN AMOUNT END)/1e6 AS cash_M,
           SUM(CASE WHEN CONCEPT='long_term_investments' THEN AMOUNT END)/1e6 AS inv_M
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL>='FY2018'
     GROUP BY FY_LABEL
),
is_opex AS (
    SELECT FY_LABEL,
           (COALESCE(SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END),0)
           +COALESCE(SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END),0)
           +COALESCE(SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END),0)
           +COALESCE(SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END),0)
           +COALESCE(SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END),0))/365.0/1e6 AS daily_cash_opex_M
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL>='FY2018'
     GROUP BY FY_LABEL
)
SELECT b.FY_LABEL, b.cash_M, b.inv_M,
       ROUND((b.cash_M+b.inv_M)/o.daily_cash_opex_M,1) AS dcoh
  FROM bs b JOIN is_opex o ON o.FY_LABEL=b.FY_LABEL ORDER BY b.FY_LABEL;

-- SLIDE 9: Days AR
WITH rev AS (
    SELECT FY_LABEL,
           (COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
           +COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
           +COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0))/365.0 AS daily_rev
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' GROUP BY FY_LABEL
),
ar AS (
    SELECT FY_LABEL, AMOUNT AS patient_ar
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND CONCEPT='patient_ar_net'
)
SELECT a.FY_LABEL, ROUND(a.patient_ar/r.daily_rev,1) AS days_ar
  FROM ar a JOIN rev r ON r.FY_LABEL=a.FY_LABEL WHERE a.FY_LABEL>='FY2018' ORDER BY a.FY_LABEL;

-- SLIDE 10: CapEx vs Depreciation
SELECT i.FY_LABEL,
       ROUND(SUM(CASE WHEN c.CONCEPT='cf_capex' THEN c.AMOUNT END)/1e6,0) AS capex_M,
       ROUND(SUM(CASE WHEN i.CONCEPT='depreciation_amortization' THEN i.AMOUNT END)/1e6,0) AS depr_M,
       ROUND(SUM(CASE WHEN c.CONCEPT='cf_capex' THEN c.AMOUNT END)
             /NULLIF(SUM(CASE WHEN i.CONCEPT='depreciation_amortization' THEN i.AMOUNT END),0)*100,1) AS ratio_pct
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT i
  LEFT JOIN AUDITED_FINANCIALS.COMMON.CASH_FLOW c ON c.ORG_ID=i.ORG_ID AND c.FY_LABEL=i.FY_LABEL
 WHERE i.ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND i.FY_LABEL>='FY2018'
 GROUP BY i.FY_LABEL ORDER BY i.FY_LABEL;

-- SLIDE 11: Self-insurance reserves
SELECT FY_LABEL, ROUND(AMOUNT/1e6,0) AS self_ins_M
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND CONCEPT='self_insurance_reserves' AND FY_LABEL>='FY2018'
 ORDER BY FY_LABEL;

-- SLIDE 12: Investment returns vs operating income
SELECT FY_LABEL,
       ROUND((COALESCE(SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END),0)
             +COALESCE(SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END),0)
             +COALESCE(SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END),0)
             -COALESCE(SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END),0)
             -COALESCE(SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END),0)
             -COALESCE(SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END),0)
             -COALESCE(SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END),0)
             -COALESCE(SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END),0)
             -COALESCE(SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END),0))/1e6,0) AS op_income_M,
       ROUND(SUM(CASE WHEN CONCEPT='investment_return' THEN AMOUNT END)/1e6,0) AS inv_return_M
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID='8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND FY_LABEL>='FY2018'
 GROUP BY FY_LABEL ORDER BY FY_LABEL;
