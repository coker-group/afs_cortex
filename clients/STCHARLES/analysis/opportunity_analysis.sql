-- =============================================================================
-- ST. CHARLES HEALTH SYSTEM — OPPORTUNITY ANALYSIS
-- Generated: 2026-05-15
-- ORG_ID:   c8491e50-d9ef-49e3-93e4-5e73b2804a8b
-- ORG_CODE: STCHARLES
-- =============================================================================

-- ===================== SECTION 1: ORG PROFILE & FILING INVENTORY =============

SELECT ORG_ID, ORG_CODE, LEGAL_NAME, SECTOR, HQ_STATE
  FROM AUDITED_FINANCIALS.COMMON.ORG_REGISTRY
 WHERE ORG_CODE = 'STCHARLES';

SELECT FILING_ID, FY_LABEL, FISCAL_YEAR_END, AUDIT_OPINION, YEARS_PRESENT
  FROM AUDITED_FINANCIALS.COMMON.FILINGS
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 ORDER BY FY_LABEL;

-- ===================== SECTION 2: INCOME STATEMENT ===========================

SELECT FY_LABEL, CONCEPT, SUM(AMOUNT) AS AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 GROUP BY FY_LABEL, CONCEPT
 ORDER BY FY_LABEL, CONCEPT;

SELECT FY_LABEL, NATIVE_LABEL, AMOUNT, IS_SUBTOTAL, LINE_ORDER
  FROM AUDITED_FINANCIALS.STCHARLES.IS_NATIVE
 ORDER BY FY_LABEL, LINE_ORDER;

-- ===================== SECTION 3: BALANCE SHEET ==============================

SELECT FY_LABEL, CONCEPT, SUM(AMOUNT) AS AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 GROUP BY FY_LABEL, CONCEPT
 ORDER BY FY_LABEL, CONCEPT;

-- ===================== SECTION 4: CASH FLOW ==================================

SELECT FY_LABEL, CONCEPT, SUM(AMOUNT) AS AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 GROUP BY FY_LABEL, CONCEPT
 ORDER BY FY_LABEL, CONCEPT;

-- ===================== SECTION 5: NOTES QUALITATIVE ==========================

SELECT f.FY_LABEL, COUNT(*) AS note_count,
       SUM(ARRAY_SIZE(n.CALLOUTS)) AS total_callouts
  FROM AUDITED_FINANCIALS.STCHARLES.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID
 WHERE f.ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 GROUP BY f.FY_LABEL ORDER BY f.FY_LABEL;

-- ===================== SECTION 6: CALLOUTS FLATTENED =========================

SELECT f.FY_LABEL AS FILING_FY,
       c.value:concept::STRING AS CONCEPT,
       COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS DATA_FY,
       c.value:value::STRING AS VAL,
       c.value:unit::STRING AS UNIT,
       n.TITLE
  FROM AUDITED_FINANCIALS.STCHARLES.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 ORDER BY FILING_FY, CONCEPT;

-- ===================== SECTION 7: KEY RATIOS =================================

WITH is_data AS (
    SELECT FY_LABEL, CONCEPT, SUM(AMOUNT) AS AMT
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
     GROUP BY FY_LABEL, CONCEPT
), bs_data AS (
    SELECT FY_LABEL, CONCEPT, SUM(AMOUNT) AS AMT
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
     GROUP BY FY_LABEL, CONCEPT
), cf_data AS (
    SELECT FY_LABEL, CONCEPT, SUM(AMOUNT) AS AMT
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
     GROUP BY FY_LABEL, CONCEPT
), subtotals AS (
    SELECT DISTINCT FY_LABEL, NATIVE_LABEL, AMOUNT
      FROM AUDITED_FINANCIALS.STCHARLES.IS_NATIVE
     WHERE IS_SUBTOTAL = 1
       AND NATIVE_LABEL IN ('Total operating revenue', 'Total expenses',
                            'Excess of revenue over expenses from operations')
)
SELECT
    s_rev.FY_LABEL,
    s_rev.AMOUNT AS total_op_rev,
    s_exp.AMOUNT AS total_expenses,
    s_oi.AMOUNT  AS operating_income,
    ROUND(s_oi.AMOUNT / NULLIF(s_rev.AMOUNT, 0) * 100, 2) AS operating_margin_pct,
    ROUND((COALESCE(sal.AMT,0) + COALESCE(ben.AMT,0)) / NULLIF(s_rev.AMOUNT, 0) * 100, 1)
        AS labor_pct_rev,
    ROUND(sup.AMT / NULLIF(s_rev.AMOUNT, 0) * 100, 1) AS supplies_pct_rev,
    ROUND(prof.AMT / NULLIF(s_exp.AMOUNT, 0) * 100, 1) AS purchased_svcs_pct_opex,
    ROUND(dep.AMT / NULLIF(s_rev.AMOUNT, 0) * 100, 1) AS depreciation_pct_rev,
    ROUND(bs_cash.AMT / (s_exp.AMOUNT / 365.0), 1) AS days_cash_on_hand,
    ROUND(bs_ar.AMT / (s_rev.AMOUNT / 365.0), 1) AS days_in_ar,
    ROUND((COALESCE(bs_ltd.AMT,0) + COALESCE(bs_cpltd.AMT,0)) /
        NULLIF(COALESCE(bs_ltd.AMT,0) + COALESCE(bs_cpltd.AMT,0) +
               COALESCE(bs_nawr.AMT,0) + COALESCE(bs_nawd.AMT,0), 0) * 100, 1)
        AS debt_to_cap_pct,
    cf_ops.AMT AS cf_operating,
    cf_capex.AMT AS cf_capex,
    ROUND(cf_ops.AMT / NULLIF(s_rev.AMOUNT, 0) * 100, 1) AS cf_ops_margin_pct,
    ROUND(ABS(cf_capex.AMT) / NULLIF(dep.AMT, 0) * 100, 1) AS capex_to_depreciation_pct
FROM subtotals s_rev
JOIN subtotals s_exp ON s_exp.FY_LABEL = s_rev.FY_LABEL AND s_exp.NATIVE_LABEL = 'Total expenses'
LEFT JOIN subtotals s_oi ON s_oi.FY_LABEL = s_rev.FY_LABEL AND s_oi.NATIVE_LABEL = 'Excess of revenue over expenses from operations'
LEFT JOIN is_data sal ON sal.FY_LABEL = s_rev.FY_LABEL AND sal.CONCEPT = 'salaries_and_wages'
LEFT JOIN is_data ben ON ben.FY_LABEL = s_rev.FY_LABEL AND ben.CONCEPT = 'employee_benefits'
LEFT JOIN is_data sup ON sup.FY_LABEL = s_rev.FY_LABEL AND sup.CONCEPT = 'supplies'
LEFT JOIN is_data prof ON prof.FY_LABEL = s_rev.FY_LABEL AND prof.CONCEPT = 'professional_fees'
LEFT JOIN is_data dep ON dep.FY_LABEL = s_rev.FY_LABEL AND dep.CONCEPT = 'depreciation_amortization'
LEFT JOIN bs_data bs_cash ON bs_cash.FY_LABEL = s_rev.FY_LABEL AND bs_cash.CONCEPT = 'cash_and_equivalents'
LEFT JOIN bs_data bs_ar ON bs_ar.FY_LABEL = s_rev.FY_LABEL AND bs_ar.CONCEPT = 'patient_ar_net'
LEFT JOIN bs_data bs_ltd ON bs_ltd.FY_LABEL = s_rev.FY_LABEL AND bs_ltd.CONCEPT = 'long_term_debt'
LEFT JOIN bs_data bs_cpltd ON bs_cpltd.FY_LABEL = s_rev.FY_LABEL AND bs_cpltd.CONCEPT = 'current_portion_long_term_debt'
LEFT JOIN bs_data bs_nawr ON bs_nawr.FY_LABEL = s_rev.FY_LABEL AND bs_nawr.CONCEPT = 'net_assets_without_donor_restrictions'
LEFT JOIN bs_data bs_nawd ON bs_nawd.FY_LABEL = s_rev.FY_LABEL AND bs_nawd.CONCEPT = 'net_assets_with_donor_restrictions'
LEFT JOIN cf_data cf_ops ON cf_ops.FY_LABEL = s_rev.FY_LABEL AND cf_ops.CONCEPT = 'cf_operating'
LEFT JOIN cf_data cf_capex ON cf_capex.FY_LABEL = s_rev.FY_LABEL AND cf_capex.CONCEPT = 'cf_capex'
WHERE s_rev.NATIVE_LABEL = 'Total operating revenue'
ORDER BY s_rev.FY_LABEL;

-- ===================== SECTION 8: PIPELINE FINDINGS ==========================

SELECT FY_LABEL, SEVERITY, CATEGORY, TITLE, NARRATIVE,
       EST_IMPACT_LOW, EST_IMPACT_HIGH, PLAYBOOK_HINT
  FROM AUDITED_FINANCIALS.COMMON.FINDINGS
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 ORDER BY FY_LABEL, SEVERITY;

-- ===================== DATA QUALITY CHECKS ===================================

SELECT FY_LABEL, CONCEPT, AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
   AND CONCEPT = 'net_patient_service_revenue'
   AND AMOUNT < 0;

SELECT FY_LABEL, CONCEPT, COUNT(*) AS n
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 GROUP BY FY_LABEL, CONCEPT
HAVING COUNT(*) > 1;

SELECT STATEMENT, REASON, COUNT(*) AS CNT
  FROM AUDITED_FINANCIALS.COMMON.REVIEW_QUEUE
 WHERE ORG_ID = 'c8491e50-d9ef-49e3-93e4-5e73b2804a8b'
 GROUP BY STATEMENT, REASON
 ORDER BY STATEMENT, REASON;
