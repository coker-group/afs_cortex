-- =============================================================================
-- MedStar Health, Inc. — Opportunity Analysis SQL
-- Generated: 2026-05-15
-- ORG_ID:   8ae0219f-5a4d-47e1-a379-74c5b44e08c1
-- ORG_CODE: MEDSTAR_HEALTH
-- =============================================================================

-- =============================================================================
-- 00: DATA QUALITY PRE-CHECKS
-- =============================================================================

-- Check for negative NPSR (bad-debt mis-mapping)
SELECT FY_LABEL, CONCEPT, AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND CONCEPT = 'net_patient_service_revenue'
   AND AMOUNT < 0;
-- RESULT: FY2016 (-$225.3M), FY2017 (-$202.1M) — "Provision for bad debts"
-- mapped to NPSR. Exclude these years from ratio analysis.

-- Check for duplicate standardized concepts
SELECT FY_LABEL, CONCEPT, COUNT(*) AS n
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
 GROUP BY FY_LABEL, CONCEPT
HAVING COUNT(*) > 1;
-- RESULT: 0 rows — no duplicates in standardized tables.

-- =============================================================================
-- 01: ORGANIZATION PROFILE & FILING INVENTORY
-- =============================================================================

SELECT ORG_ID, ORG_CODE, LEGAL_NAME, SECTOR, HQ_STATE
  FROM AUDITED_FINANCIALS.COMMON.ORG_REGISTRY
 WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1';

SELECT f.FILING_ID, f.FY_LABEL, f.FISCAL_YEAR_END, f.AUDIT_OPINION,
       f.SOURCE_FILENAME, f.PAGE_COUNT
  FROM AUDITED_FINANCIALS.COMMON.FILINGS f
 WHERE f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
 ORDER BY f.FY_LABEL;

-- =============================================================================
-- 02: INCOME STATEMENT — REVENUE & EXPENSE DECOMPOSITION
-- =============================================================================

WITH raw AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END) AS npsr,
           SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END) AS other_rev,
           SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END) AS premium_rev,
           SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END) AS labor,
           SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END) AS supplies,
           SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END) AS purchased,
           SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END) AS dep_amort,
           SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END) AS interest,
           SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END) AS other_opex,
           SUM(CASE WHEN CONCEPT='investment_return' THEN AMOUNT END) AS inv_return
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL, npsr, other_rev, premium_rev,
       COALESCE(npsr,0)+COALESCE(other_rev,0)+COALESCE(premium_rev,0) AS total_revenue,
       labor, supplies, purchased, dep_amort, interest, other_opex,
       COALESCE(labor,0)+COALESCE(supplies,0)+COALESCE(purchased,0)
         +COALESCE(dep_amort,0)+COALESCE(interest,0)+COALESCE(other_opex,0) AS total_opex,
       (COALESCE(npsr,0)+COALESCE(other_rev,0)+COALESCE(premium_rev,0))
         -(COALESCE(labor,0)+COALESCE(supplies,0)+COALESCE(purchased,0)
           +COALESCE(dep_amort,0)+COALESCE(interest,0)+COALESCE(other_opex,0)) AS operating_income,
       inv_return
  FROM raw ORDER BY FY_LABEL;

-- =============================================================================
-- 03: BALANCE SHEET — CAPITAL STRUCTURE & LIQUIDITY
-- =============================================================================

WITH raw AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='cash_and_equivalents' THEN AMOUNT END) AS cash,
           SUM(CASE WHEN CONCEPT='patient_ar_net' THEN AMOUNT END) AS ar,
           SUM(CASE WHEN CONCEPT='long_term_investments' THEN AMOUNT END) AS lt_inv,
           SUM(CASE WHEN CONCEPT='assets_limited_use_noncurrent' THEN AMOUNT END) AS board_desig,
           SUM(CASE WHEN CONCEPT='ppe_net' THEN AMOUNT END) AS ppe_net,
           SUM(CASE WHEN CONCEPT='goodwill_and_intangibles' THEN AMOUNT END) AS goodwill,
           SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END) AS lt_debt,
           SUM(CASE WHEN CONCEPT='current_portion_long_term_debt' THEN AMOUNT END) AS cur_debt,
           SUM(CASE WHEN CONCEPT='pension_and_postretirement_liability' THEN AMOUNT END) AS pension,
           SUM(CASE WHEN CONCEPT='self_insurance_reserves' THEN AMOUNT END) AS self_ins,
           SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END) AS na_unrestricted,
           SUM(CASE WHEN CONCEPT='net_assets_with_donor_restrictions' THEN AMOUNT END) AS na_restricted,
           SUM(CASE WHEN CONCEPT='accounts_payable' THEN AMOUNT END) AS ap,
           SUM(CASE WHEN CONCEPT='accrued_salaries_and_benefits' THEN AMOUNT END) AS accrued_sal,
           SUM(CASE WHEN CONCEPT='operating_lease_liability_lt' THEN AMOUNT END) AS lease_liab
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL, cash, ar, lt_inv, board_desig, ppe_net, goodwill,
       lt_debt, cur_debt, COALESCE(lt_debt,0)+COALESCE(cur_debt,0) AS total_debt,
       pension, self_ins, na_unrestricted, na_restricted,
       COALESCE(na_unrestricted,0)+COALESCE(na_restricted,0) AS total_net_assets,
       ap, accrued_sal, lease_liab
  FROM raw ORDER BY FY_LABEL;

-- =============================================================================
-- 04: CASH FLOW — OPERATING, INVESTING, FINANCING
-- =============================================================================

WITH raw AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='cf_operating' THEN AMOUNT END) AS cf_ops,
           SUM(CASE WHEN CONCEPT='cf_investing' THEN AMOUNT END) AS cf_inv,
           SUM(CASE WHEN CONCEPT='cf_financing' THEN AMOUNT END) AS cf_fin,
           SUM(CASE WHEN CONCEPT='cf_capex' THEN AMOUNT END) AS capex,
           SUM(CASE WHEN CONCEPT='cf_debt_issued' THEN AMOUNT END) AS debt_issued,
           SUM(CASE WHEN CONCEPT='cf_debt_repaid' THEN AMOUNT END) AS debt_repaid,
           SUM(CASE WHEN CONCEPT='cf_working_capital_changes' THEN AMOUNT END) AS wc_changes,
           SUM(CASE WHEN CONCEPT='cf_third_party_settlements' THEN AMOUNT END) AS tps,
           SUM(CASE WHEN CONCEPT='cf_supplemental_interest' THEN AMOUNT END) AS interest_paid
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL, cf_ops, cf_inv, cf_fin, capex,
       COALESCE(cf_ops,0)-COALESCE(capex,0) AS free_cash_flow,
       debt_issued, debt_repaid, wc_changes, tps, interest_paid
  FROM raw ORDER BY FY_LABEL;

-- =============================================================================
-- 05: NOTES — QUALITATIVE INTELLIGENCE
-- =============================================================================

-- Note coverage summary
SELECT f.FY_LABEL, COUNT(*) AS note_count,
       SUM(LENGTH(n.BODY_TEXT)) AS total_body_chars,
       SUM(ARRAY_SIZE(n.CALLOUTS)) AS total_callouts
  FROM AUDITED_FINANCIALS.MEDSTAR_HEALTH.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID
 WHERE f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
 GROUP BY f.FY_LABEL ORDER BY f.FY_LABEL;

-- FY2025 notes inventory
SELECT n.NOTE_NUM, n.TITLE, LENGTH(n.BODY_TEXT) AS body_len, ARRAY_SIZE(n.CALLOUTS) AS callouts
  FROM AUDITED_FINANCIALS.MEDSTAR_HEALTH.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID
 WHERE f.FY_LABEL = 'FY2025'
   AND f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
 ORDER BY n.NOTE_NUM;

-- Key note body texts
SELECT n.NOTE_NUM, n.TITLE, n.BODY_TEXT
  FROM AUDITED_FINANCIALS.MEDSTAR_HEALTH.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID
 WHERE f.FY_LABEL = 'FY2025'
   AND f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND n.NOTE_NUM IN ('1','2','6','7','9','11','12','13','14','15','16')
 ORDER BY n.NOTE_NUM;

-- =============================================================================
-- 06: PAYER MIX & REVENUE/AR CONCENTRATION
-- =============================================================================

-- Payer revenue mix from callouts (attributed to callout fy_label)
SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
       c.value:concept::STRING AS payer_metric,
       c.value:amount::NUMBER AS pct,
       n.TITLE AS source_note
  FROM AUDITED_FINANCIALS.MEDSTAR_HEALTH.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND (c.value:concept::STRING LIKE '%_revenue_pct' OR c.value:concept::STRING LIKE '%_ar_pct')
 ORDER BY data_fy, payer_metric;

-- AR balance × payer concentration cross-reference
WITH ar_balance AS (
    SELECT FY_LABEL, AMOUNT AS patient_ar
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND CONCEPT = 'patient_ar_net'
),
payer_pcts AS (
    SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
           MAX(CASE WHEN c.value:concept::STRING='medicare_ar_pct' THEN c.value:amount::NUMBER END) AS medicare_pct,
           MAX(CASE WHEN c.value:concept::STRING='medicaid_ar_pct' THEN c.value:amount::NUMBER END) AS medicaid_pct,
           MAX(CASE WHEN c.value:concept::STRING='blue_cross_ar_pct' THEN c.value:amount::NUMBER END) AS bc_pct,
           MAX(CASE WHEN c.value:concept::STRING='other_commercial_ar_pct' THEN c.value:amount::NUMBER END) AS other_pct,
           MAX(CASE WHEN c.value:concept::STRING='self_pay_ar_pct' THEN c.value:amount::NUMBER END) AS selfpay_pct
      FROM AUDITED_FINANCIALS.MEDSTAR_HEALTH.NOTES n
      JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID,
           LATERAL FLATTEN(input => n.CALLOUTS) c
     WHERE f.ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' AND c.value:concept::STRING LIKE '%_ar_pct'
     GROUP BY data_fy
)
SELECT a.FY_LABEL, a.patient_ar,
       p.medicare_pct, ROUND(a.patient_ar*p.medicare_pct/100,0) AS medicare_ar$,
       p.medicaid_pct, ROUND(a.patient_ar*p.medicaid_pct/100,0) AS medicaid_ar$,
       p.bc_pct, ROUND(a.patient_ar*p.bc_pct/100,0) AS bc_ar$,
       p.other_pct, ROUND(a.patient_ar*p.other_pct/100,0) AS other_ar$,
       p.selfpay_pct, ROUND(a.patient_ar*p.selfpay_pct/100,0) AS selfpay_ar$
  FROM ar_balance a LEFT JOIN payer_pcts p ON p.data_fy = a.FY_LABEL
 ORDER BY a.FY_LABEL;

-- =============================================================================
-- 07: KEY FINANCIAL RATIOS
-- =============================================================================

WITH is_data AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='net_patient_service_revenue' THEN AMOUNT END) AS npsr,
           SUM(CASE WHEN CONCEPT='other_operating_revenue' THEN AMOUNT END) AS other_rev,
           SUM(CASE WHEN CONCEPT='premium_revenue' THEN AMOUNT END) AS premium_rev,
           SUM(CASE WHEN CONCEPT='total_salaries_and_benefits' THEN AMOUNT END) AS labor,
           SUM(CASE WHEN CONCEPT='supplies' THEN AMOUNT END) AS supplies,
           SUM(CASE WHEN CONCEPT='purchased_services' THEN AMOUNT END) AS purchased,
           SUM(CASE WHEN CONCEPT='depreciation_amortization' THEN AMOUNT END) AS da,
           SUM(CASE WHEN CONCEPT='interest_expense' THEN AMOUNT END) AS interest,
           SUM(CASE WHEN CONCEPT='other_operating_expense' THEN AMOUNT END) AS other_opex
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' GROUP BY FY_LABEL
),
bs_data AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='cash_and_equivalents' THEN AMOUNT END) AS cash,
           SUM(CASE WHEN CONCEPT='long_term_investments' THEN AMOUNT END) AS lt_inv,
           SUM(CASE WHEN CONCEPT='patient_ar_net' THEN AMOUNT END) AS ar,
           SUM(CASE WHEN CONCEPT='long_term_debt' THEN AMOUNT END) AS lt_debt,
           SUM(CASE WHEN CONCEPT='current_portion_long_term_debt' THEN AMOUNT END) AS cur_debt,
           SUM(CASE WHEN CONCEPT='net_assets_without_donor_restrictions' THEN AMOUNT END) AS net_assets
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' GROUP BY FY_LABEL
),
cf_data AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT='cf_operating' THEN AMOUNT END) AS cf_ops,
           SUM(CASE WHEN CONCEPT='cf_capex' THEN AMOUNT END) AS capex
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1' GROUP BY FY_LABEL
),
c AS (
    SELECT i.FY_LABEL,
           COALESCE(i.npsr,0)+COALESCE(i.other_rev,0)+COALESCE(i.premium_rev,0) AS rev,
           COALESCE(i.labor,0)+COALESCE(i.supplies,0)+COALESCE(i.purchased,0)
             +COALESCE(i.da,0)+COALESCE(i.interest,0)+COALESCE(i.other_opex,0) AS opex,
           i.labor, i.supplies, i.purchased, i.da, i.interest,
           b.cash, b.lt_inv, b.ar, b.lt_debt,
           COALESCE(b.lt_debt,0)+COALESCE(b.cur_debt,0) AS total_debt, b.net_assets,
           cf.cf_ops, cf.capex
      FROM is_data i LEFT JOIN bs_data b ON b.FY_LABEL=i.FY_LABEL
      LEFT JOIN cf_data cf ON cf.FY_LABEL=i.FY_LABEL
)
SELECT FY_LABEL, rev, opex, rev-opex AS op_inc, rev-opex+da AS ebida,
       ROUND((rev-opex)/NULLIF(rev,0)*100,2) AS op_margin_pct,
       ROUND((rev-opex+da)/NULLIF(rev,0)*100,2) AS ebida_margin_pct,
       ROUND(labor/NULLIF(rev,0)*100,2) AS labor_pct,
       ROUND(supplies/NULLIF(rev,0)*100,2) AS supply_pct,
       ROUND(purchased/NULLIF(opex,0)*100,2) AS purch_pct_opex,
       ROUND(interest/NULLIF(rev,0)*100,2) AS int_pct,
       ROUND((COALESCE(cash,0)+COALESCE(lt_inv,0))/NULLIF((opex-COALESCE(da,0))/365.0,0),1) AS dcoh,
       ROUND(ar/NULLIF(rev/365.0,0),1) AS days_ar,
       ROUND(lt_debt/NULLIF(COALESCE(lt_debt,0)+COALESCE(net_assets,0),0)*100,2) AS debt_cap_pct,
       ROUND(total_debt/NULLIF(rev-opex+da,0),2) AS debt_ebida_x,
       ROUND(capex/NULLIF(da,0)*100,1) AS capex_dep_pct,
       cf_ops,
       ROUND(cf_ops/NULLIF(rev,0)*100,2) AS cf_margin_pct,
       COALESCE(cf_ops,0)-COALESCE(capex,0) AS fcf
  FROM c ORDER BY FY_LABEL;

-- =============================================================================
-- 08: EXISTING PIPELINE FINDINGS
-- =============================================================================

SELECT CATEGORY, SEVERITY, COUNT(*) AS n,
       ROUND(AVG(EST_IMPACT_LOW),0) AS avg_lo, ROUND(AVG(EST_IMPACT_HIGH),0) AS avg_hi
  FROM AUDITED_FINANCIALS.COMMON.FINDINGS
 WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
 GROUP BY CATEGORY, SEVERITY ORDER BY SEVERITY, CATEGORY;

SELECT FY_LABEL, SEVERITY, CATEGORY, TITLE, NARRATIVE, EST_IMPACT_LOW, EST_IMPACT_HIGH, PLAYBOOK_HINT
  FROM AUDITED_FINANCIALS.COMMON.FINDINGS
 WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
   AND FY_LABEL IN ('FY2024','FY2025')
 ORDER BY FY_LABEL, SEVERITY;

-- Review queue data quality
SELECT STATEMENT, COUNT(*) AS flagged, ROUND(AVG(CONFIDENCE),3) AS avg_conf,
       SUM(CASE WHEN RESOLVED THEN 1 ELSE 0 END) AS resolved
  FROM AUDITED_FINANCIALS.COMMON.REVIEW_QUEUE
 WHERE ORG_ID = '8ae0219f-5a4d-47e1-a379-74c5b44e08c1'
 GROUP BY STATEMENT ORDER BY STATEMENT;
