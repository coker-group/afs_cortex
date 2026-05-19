-- =============================================================================
-- 07: Key Financial Ratios & Trend Analysis
-- =============================================================================
-- Substitution: {ORG_ID}
-- Computes all standard hospital financial ratios from the normalized data.

WITH is_data AS (
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
           SUM(CASE WHEN CONCEPT = 'investment_return' THEN AMOUNT END)            AS inv_return
      FROM AUDITED_FINANCIALS.COMMON.INCOME_STATEMENT
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
),
bs_data AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT = 'cash_and_equivalents' THEN AMOUNT END)                 AS cash,
           SUM(CASE WHEN CONCEPT = 'long_term_investments' THEN AMOUNT END)                AS lt_inv,
           SUM(CASE WHEN CONCEPT = 'patient_ar_net' THEN AMOUNT END)                       AS ar,
           SUM(CASE WHEN CONCEPT = 'long_term_debt' THEN AMOUNT END)                       AS lt_debt,
           SUM(CASE WHEN CONCEPT = 'current_portion_long_term_debt' THEN AMOUNT END)       AS cur_debt,
           SUM(CASE WHEN CONCEPT = 'net_assets_without_donor_restrictions' THEN AMOUNT END) AS net_assets,
           SUM(CASE WHEN CONCEPT = 'ppe_net' THEN AMOUNT END)                              AS ppe_net
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
),
cf_data AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT = 'cf_operating' THEN AMOUNT END)  AS cf_ops,
           SUM(CASE WHEN CONCEPT = 'cf_capex' THEN AMOUNT END)      AS capex
      FROM AUDITED_FINANCIALS.COMMON.CASH_FLOW
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
),
computed AS (
    SELECT i.FY_LABEL,

           -- Revenue & expense totals
           COALESCE(i.npsr,0) + COALESCE(i.other_rev,0) + COALESCE(i.premium_rev,0) AS total_revenue,
           COALESCE(i.labor,0) + COALESCE(i.supplies,0) + COALESCE(i.purchased,0)
             + COALESCE(i.dep_amort,0) + COALESCE(i.interest,0) + COALESCE(i.other_opex,0) AS total_opex,

           -- Operating income & EBIDA
           (COALESCE(i.npsr,0) + COALESCE(i.other_rev,0) + COALESCE(i.premium_rev,0))
             - (COALESCE(i.labor,0) + COALESCE(i.supplies,0) + COALESCE(i.purchased,0)
                + COALESCE(i.dep_amort,0) + COALESCE(i.interest,0) + COALESCE(i.other_opex,0)) AS operating_income,
           (COALESCE(i.npsr,0) + COALESCE(i.other_rev,0) + COALESCE(i.premium_rev,0))
             - (COALESCE(i.labor,0) + COALESCE(i.supplies,0) + COALESCE(i.purchased,0)
                + COALESCE(i.dep_amort,0) + COALESCE(i.interest,0) + COALESCE(i.other_opex,0))
             + COALESCE(i.dep_amort, 0) AS ebida,

           -- Component amounts
           i.labor,
           i.supplies,
           i.purchased,
           i.dep_amort,
           i.interest,
           i.inv_return,

           -- Balance sheet
           b.cash,
           b.lt_inv,
           b.ar,
           b.lt_debt,
           COALESCE(b.lt_debt, 0) + COALESCE(b.cur_debt, 0) AS total_debt,
           b.net_assets,
           b.ppe_net,

           -- Cash flow
           c.cf_ops,
           c.capex

      FROM is_data i
      LEFT JOIN bs_data b ON b.FY_LABEL = i.FY_LABEL
      LEFT JOIN cf_data c ON c.FY_LABEL = i.FY_LABEL
)
SELECT FY_LABEL,
       total_revenue,
       total_opex,
       operating_income,
       ebida,

       -- Margin ratios
       ROUND(operating_income / NULLIF(total_revenue, 0) * 100, 2)     AS operating_margin_pct,
       ROUND(ebida / NULLIF(total_revenue, 0) * 100, 2)               AS ebida_margin_pct,

       -- Cost ratios
       ROUND(labor / NULLIF(total_revenue, 0) * 100, 2)               AS labor_pct_of_revenue,
       ROUND(supplies / NULLIF(total_revenue, 0) * 100, 2)            AS supplies_pct_of_revenue,
       ROUND(purchased / NULLIF(total_opex, 0) * 100, 2)              AS purchased_pct_of_opex,
       ROUND(interest / NULLIF(total_revenue, 0) * 100, 2)            AS interest_pct_of_revenue,

       -- Liquidity
       ROUND((COALESCE(cash, 0) + COALESCE(lt_inv, 0))
             / NULLIF((total_opex - COALESCE(dep_amort, 0)) / 365.0, 0), 1) AS days_cash_on_hand,
       ROUND(ar / NULLIF(total_revenue / 365.0, 0), 1)                AS days_in_ar,

       -- Leverage
       ROUND(lt_debt / NULLIF(COALESCE(lt_debt, 0) + COALESCE(net_assets, 0), 0) * 100, 2)
                                                                        AS debt_to_cap_pct,
       ROUND(total_debt / NULLIF(ebida, 0), 2)                        AS debt_to_ebida_x,

       -- Capital intensity
       ROUND(capex / NULLIF(dep_amort, 0) * 100, 1)                   AS capex_to_dep_pct,

       -- Cash flow
       cf_ops,
       ROUND(cf_ops / NULLIF(total_revenue, 0) * 100, 2)              AS cf_margin_pct,
       COALESCE(cf_ops, 0) - COALESCE(capex, 0)                       AS free_cash_flow,

       -- YoY revenue growth
       ROUND((total_revenue / NULLIF(LAG(total_revenue) OVER (ORDER BY FY_LABEL), 0) - 1) * 100, 2)
                                                                        AS rev_growth_pct

  FROM computed
 ORDER BY FY_LABEL;
