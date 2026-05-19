-- =============================================================================
-- 03: Balance Sheet — Asset/Liability Structure & Capital Position
-- =============================================================================
-- Substitution: {ORG_ID}

SELECT FY_LABEL,
       CONCEPT,
       AMOUNT
  FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
 WHERE ORG_ID = '{ORG_ID}'
 ORDER BY FY_LABEL, CONCEPT;

-- Pivoted balance sheet summary
WITH raw AS (
    SELECT FY_LABEL,
           SUM(CASE WHEN CONCEPT = 'cash_and_equivalents' THEN AMOUNT END)                AS cash,
           SUM(CASE WHEN CONCEPT = 'patient_ar_net' THEN AMOUNT END)                      AS ar,
           SUM(CASE WHEN CONCEPT = 'long_term_investments' THEN AMOUNT END)                AS lt_investments,
           SUM(CASE WHEN CONCEPT = 'assets_limited_use_noncurrent' THEN AMOUNT END)        AS board_designated,
           SUM(CASE WHEN CONCEPT = 'ppe_net' THEN AMOUNT END)                              AS ppe_net,
           SUM(CASE WHEN CONCEPT = 'goodwill_and_intangibles' THEN AMOUNT END)             AS goodwill,
           SUM(CASE WHEN CONCEPT = 'long_term_debt' THEN AMOUNT END)                       AS lt_debt,
           SUM(CASE WHEN CONCEPT = 'current_portion_long_term_debt' THEN AMOUNT END)       AS cur_debt,
           SUM(CASE WHEN CONCEPT = 'pension_and_postretirement_liability' THEN AMOUNT END) AS pension_liab,
           SUM(CASE WHEN CONCEPT = 'self_insurance_reserves' THEN AMOUNT END)              AS self_ins,
           SUM(CASE WHEN CONCEPT = 'net_assets_without_donor_restrictions' THEN AMOUNT END) AS net_assets_unrestricted,
           SUM(CASE WHEN CONCEPT = 'net_assets_with_donor_restrictions' THEN AMOUNT END)   AS net_assets_restricted,
           SUM(CASE WHEN CONCEPT = 'accounts_payable' THEN AMOUNT END)                     AS ap,
           SUM(CASE WHEN CONCEPT = 'accrued_salaries_and_benefits' THEN AMOUNT END)        AS accrued_salaries,
           SUM(CASE WHEN CONCEPT = 'operating_lease_liability_lt' THEN AMOUNT END)         AS lease_liab,
           SUM(CASE WHEN CONCEPT = 'right_of_use_assets' THEN AMOUNT END)                  AS rou_assets
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '{ORG_ID}'
     GROUP BY FY_LABEL
)
SELECT FY_LABEL,
       cash,
       ar,
       lt_investments,
       board_designated,
       ppe_net,
       goodwill,
       lt_debt,
       cur_debt,
       COALESCE(lt_debt, 0) + COALESCE(cur_debt, 0) AS total_debt,
       pension_liab,
       self_ins,
       net_assets_unrestricted,
       net_assets_restricted,
       COALESCE(net_assets_unrestricted, 0) + COALESCE(net_assets_restricted, 0) AS total_net_assets,
       ap,
       accrued_salaries,
       lease_liab,
       rou_assets
  FROM raw
 ORDER BY FY_LABEL;
