-- =============================================================================
-- 02: Income Statement — Revenue & Expense Decomposition
-- =============================================================================
-- Substitution: {ORG_ID}

SELECT FY_LABEL,
       CONCEPT,
       AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
 WHERE ORG_ID = '{ORG_ID}'
 ORDER BY FY_LABEL, CONCEPT;

-- Pivoted summary with computed totals
WITH raw AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT = 'net_patient_service_revenue' THEN AMOUNT END)  AS npsr,
           SUM(CASE WHEN CONCEPT = 'other_operating_revenue' THEN AMOUNT END)      AS other_rev,
           SUM(CASE WHEN CONCEPT = 'premium_revenue' THEN AMOUNT END)              AS premium_rev,
           SUM(CASE WHEN CONCEPT = 'total_salaries_and_benefits' THEN AMOUNT END)  AS labor,
           SUM(CASE WHEN CONCEPT = 'supplies' THEN AMOUNT END)                     AS supplies,
           SUM(CASE WHEN CONCEPT = 'purchased_services' THEN AMOUNT END)           AS purchased,
           SUM(CASE WHEN CONCEPT = 'depreciation_amortization' THEN AMOUNT END)    AS dep_amort,
           SUM(CASE WHEN CONCEPT = 'interest_expense' THEN AMOUNT END)             AS interest,
           SUM(CASE WHEN CONCEPT = 'other_operating_expense' THEN AMOUNT END)      AS other_opex,
           SUM(CASE WHEN CONCEPT = 'investment_return' THEN AMOUNT END)            AS inv_return,
           SUM(CASE WHEN CONCEPT = 'change_in_net_assets' THEN AMOUNT END)         AS change_na
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       npsr,
       other_rev,
       premium_rev,
       COALESCE(npsr,0) + COALESCE(other_rev,0) + COALESCE(premium_rev,0)         AS total_revenue,
       labor,
       supplies,
       purchased,
       dep_amort,
       interest,
       other_opex,
       COALESCE(labor,0) + COALESCE(supplies,0) + COALESCE(purchased,0)
         + COALESCE(dep_amort,0) + COALESCE(interest,0) + COALESCE(other_opex,0)  AS total_opex,
       (COALESCE(npsr,0) + COALESCE(other_rev,0) + COALESCE(premium_rev,0))
         - (COALESCE(labor,0) + COALESCE(supplies,0) + COALESCE(purchased,0)
            + COALESCE(dep_amort,0) + COALESCE(interest,0) + COALESCE(other_opex,0)) AS operating_income,
       inv_return,
       change_na
  FROM raw
 ORDER BY FY_LABEL;

-- YoY growth rates
WITH summary AS (
    SELECT FY_LABEL,
           COALESCE(SUM(CASE WHEN CONCEPT = 'net_patient_service_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT = 'other_operating_revenue' THEN AMOUNT END),0)
             + COALESCE(SUM(CASE WHEN CONCEPT = 'premium_revenue' THEN AMOUNT END),0)  AS total_revenue,
           COALESCE(SUM(CASE WHEN CONCEPT = 'total_salaries_and_benefits' THEN AMOUNT END),0) AS labor,
           COALESCE(SUM(CASE WHEN CONCEPT = 'supplies' THEN AMOUNT END),0) AS supplies,
           COALESCE(SUM(CASE WHEN CONCEPT = 'purchased_services' THEN AMOUNT END),0) AS purchased
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
)
SELECT s.FY_LABEL,
       s.total_revenue,
       ROUND((s.total_revenue / LAG(s.total_revenue) OVER (ORDER BY s.FY_LABEL) - 1) * 100, 2) AS rev_growth_pct,
       ROUND((s.labor / LAG(s.labor) OVER (ORDER BY s.FY_LABEL) - 1) * 100, 2)                 AS labor_growth_pct,
       ROUND((s.supplies / LAG(s.supplies) OVER (ORDER BY s.FY_LABEL) - 1) * 100, 2)           AS supply_growth_pct,
       ROUND((s.purchased / LAG(s.purchased) OVER (ORDER BY s.FY_LABEL) - 1) * 100, 2)         AS purchased_growth_pct
  FROM summary s
 ORDER BY s.FY_LABEL;
