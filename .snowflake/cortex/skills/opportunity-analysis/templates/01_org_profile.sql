-- =============================================================================
-- 01: Organization Profile & Filing Inventory
-- =============================================================================
-- Substitution: {ORG_ID}

SELECT r.ORG_ID,
       r.ORG_CODE,
       r.LEGAL_NAME,
       r.SECTOR,
       r.HQ_STATE
  FROM AUDITED_FINANCIALS.COMMON.ORG_REGISTRY r
 WHERE r.ORG_ID = '{ORG_ID}';

SELECT f.FILING_ID,
       f.FY_LABEL,
       f.FISCAL_YEAR_END,
       f.AUDIT_OPINION,
       f.YEARS_PRESENT,
       f.SOURCE_FILENAME,
       f.PAGE_COUNT,
       ps.STAGES_COMPLETED
  FROM AUDITED_FINANCIALS.COMMON.FILINGS f
  LEFT JOIN AUDITED_FINANCIALS.COMMON.PDF_STAGING ps
    ON ps.FILING_ID = f.FILING_ID
 WHERE f.ORG_ID = '{ORG_ID}'
 ORDER BY f.FY_LABEL;

SELECT COUNT(*) AS total_filings,
       MIN(FY_LABEL) AS earliest_fy,
       MAX(FY_LABEL) AS latest_fy,
       COUNT(DISTINCT AUDIT_OPINION) AS distinct_opinions,
       LISTAGG(DISTINCT AUDIT_OPINION, ', ') AS opinions
  FROM AUDITED_FINANCIALS.COMMON.FILINGS
 WHERE ORG_ID = '{ORG_ID}';
