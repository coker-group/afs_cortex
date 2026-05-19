-- =============================================================================
-- 06: Payer Mix & Revenue/AR Concentration
-- =============================================================================
-- Substitution: {ORG_ID}, {ORG_CODE}
-- Extracts payer mix data from note callouts (typically from "Business and
-- Credit Concentrations" footnote) and cross-references with AR balances.
--
-- IMPORTANT: Callouts carry their own fy_label (callout_fy) which is the year
-- the data describes. This often differs from the filing's FY_LABEL because
-- notes in an FY2025 filing may disclose FY2024 data. All queries below use
-- the callout's fy_label (COALESCE to filing FY as fallback) for attribution.

-- Payer mix percentages from callouts (attributed to the year the data describes)
SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
       f.FY_LABEL                                      AS filing_fy,
       c.value:concept::STRING                          AS payer_metric,
       c.value:amount::NUMBER                           AS pct,
       c.value:uom::STRING                              AS uom,
       n.TITLE                                          AS source_note
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '{ORG_ID}'
   AND c.value:concept::STRING LIKE '%_revenue_pct'
 ORDER BY data_fy, payer_metric;

-- AR concentration percentages from callouts
SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
       f.FY_LABEL                                      AS filing_fy,
       c.value:concept::STRING                          AS ar_metric,
       c.value:amount::NUMBER                           AS pct,
       c.value:uom::STRING                              AS uom,
       n.TITLE                                          AS source_note
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '{ORG_ID}'
   AND c.value:concept::STRING LIKE '%_ar_pct'
 ORDER BY data_fy, ar_metric;

-- Government payer dependency (Medicare + Medicaid combined)
SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
       SUM(CASE WHEN c.value:concept::STRING IN ('medicare_revenue_pct', 'medicaid_revenue_pct')
                THEN c.value:amount::NUMBER END) AS govt_revenue_pct,
       SUM(CASE WHEN c.value:concept::STRING IN ('medicare_ar_pct', 'medicaid_ar_pct')
                THEN c.value:amount::NUMBER END) AS govt_ar_pct
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '{ORG_ID}'
   AND c.value:concept::STRING IN ('medicare_revenue_pct','medicaid_revenue_pct',
                                    'medicare_ar_pct','medicaid_ar_pct')
 GROUP BY data_fy
 ORDER BY data_fy;

-- Cross-reference: actual AR balance × payer concentration
-- Uses callout fy_label to match AR balances to the correct fiscal year
WITH ar_balance AS (
    SELECT FY_LABEL,
           AMOUNT AS patient_ar
      FROM AUDITED_FINANCIALS.COMMON.BALANCE_SHEET
     WHERE ORG_ID = '{ORG_ID}'
       AND CONCEPT = 'patient_ar_net'
),
payer_pcts AS (
    SELECT COALESCE(c.value:fy_label::STRING, f.FY_LABEL) AS data_fy,
           MAX(CASE WHEN c.value:concept::STRING = 'medicare_ar_pct'
                    THEN c.value:amount::NUMBER END) AS medicare_ar_pct,
           MAX(CASE WHEN c.value:concept::STRING = 'medicaid_ar_pct'
                    THEN c.value:amount::NUMBER END) AS medicaid_ar_pct,
           MAX(CASE WHEN c.value:concept::STRING = 'blue_cross_ar_pct'
                    THEN c.value:amount::NUMBER END) AS bc_ar_pct,
           MAX(CASE WHEN c.value:concept::STRING = 'other_commercial_ar_pct'
                    THEN c.value:amount::NUMBER END) AS other_comm_ar_pct,
           MAX(CASE WHEN c.value:concept::STRING = 'self_pay_ar_pct'
                    THEN c.value:amount::NUMBER END) AS self_pay_ar_pct
      FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
      JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
        ON f.FILING_ID = n.FILING_ID,
           LATERAL FLATTEN(input => n.CALLOUTS) c
     WHERE f.ORG_ID = '{ORG_ID}'
       AND c.value:concept::STRING LIKE '%_ar_pct'
     GROUP BY data_fy
)
SELECT a.FY_LABEL,
       a.patient_ar,
       p.medicare_ar_pct,
       ROUND(a.patient_ar * p.medicare_ar_pct / 100, 2)       AS medicare_ar_dollars,
       p.medicaid_ar_pct,
       ROUND(a.patient_ar * p.medicaid_ar_pct / 100, 2)       AS medicaid_ar_dollars,
       p.bc_ar_pct,
       ROUND(a.patient_ar * p.bc_ar_pct / 100, 2)             AS bc_ar_dollars,
       p.other_comm_ar_pct,
       ROUND(a.patient_ar * p.other_comm_ar_pct / 100, 2)     AS other_comm_ar_dollars,
       p.self_pay_ar_pct,
       ROUND(a.patient_ar * p.self_pay_ar_pct / 100, 2)       AS self_pay_ar_dollars
  FROM ar_balance a
  LEFT JOIN payer_pcts p ON p.data_fy = a.FY_LABEL
 ORDER BY a.FY_LABEL;
