-- =============================================================================
-- 04: Cash Flow — Operating, Investing, Financing Dynamics
-- =============================================================================
-- Substitution: {ORG_ID}

SELECT FY_LABEL,
       CONCEPT,
       AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
 WHERE ORG_ID = '{ORG_ID}'
 ORDER BY FY_LABEL, CONCEPT;

-- Summary CF by category
-- NOTE: Some filings produce duplicate rows per concept (from comparative columns).
-- Use SUM to handle this; duplicates will be visible in the raw data above.
WITH raw AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT = 'cf_operating' THEN AMOUNT END)                  AS cf_ops,
           SUM(CASE WHEN CONCEPT = 'cf_investing' THEN AMOUNT END)                  AS cf_investing,
           SUM(CASE WHEN CONCEPT = 'cf_financing' THEN AMOUNT END)                  AS cf_financing,
           SUM(CASE WHEN CONCEPT = 'cf_capex' THEN AMOUNT END)                      AS capex,
           SUM(CASE WHEN CONCEPT = 'cf_depreciation_amortization' THEN AMOUNT END)  AS da_addback,
           SUM(CASE WHEN CONCEPT = 'cf_debt_issued' THEN AMOUNT END)                AS debt_issued,
           SUM(CASE WHEN CONCEPT = 'cf_debt_repaid' THEN AMOUNT END)                AS debt_repaid,
           SUM(CASE WHEN CONCEPT = 'cf_working_capital_changes' THEN AMOUNT END)    AS wc_changes,
           SUM(CASE WHEN CONCEPT = 'cf_third_party_settlements' THEN AMOUNT END)    AS tps,
           SUM(CASE WHEN CONCEPT = 'cf_supplemental_interest' THEN AMOUNT END)      AS interest_paid,
           SUM(CASE WHEN CONCEPT = 'cf_beginning_cash_balance' THEN AMOUNT END)     AS begin_cash
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       cf_ops,
       cf_investing,
       cf_financing,
       capex,
       COALESCE(cf_ops, 0) - COALESCE(capex, 0)    AS free_cash_flow,
       da_addback,
       debt_issued,
       debt_repaid,
       wc_changes,
       tps,
       interest_paid,
       begin_cash
  FROM raw
 ORDER BY FY_LABEL;
