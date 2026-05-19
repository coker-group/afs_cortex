-- =============================================================================
-- 05: Notes & Qualitative Intelligence
-- =============================================================================
-- Substitution: {ORG_ID}, {ORG_CODE}
-- Pulls footnote narratives and structured callouts for the most recent filing
-- and compares with the prior year where available.

-- All notes for the most recent filing (full text + callouts)
SELECT f.FY_LABEL,
       n.NOTE_NUM,
       n.TITLE,
       n.BODY_TEXT,
       n.CALLOUTS,
       n.SOURCE_PAGE_START,
       n.SOURCE_PAGE_END
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID
 WHERE f.ORG_ID = '{ORG_ID}'
   AND f.FY_LABEL = (SELECT MAX(FY_LABEL) FROM AUDITED_FINANCIALS.COMMON.FILINGS WHERE ORG_ID = '{ORG_ID}')
 ORDER BY n.NOTE_NUM;

-- All notes for the prior year filing (for comparison)
SELECT f.FY_LABEL,
       n.NOTE_NUM,
       n.TITLE,
       n.BODY_TEXT,
       n.CALLOUTS,
       n.SOURCE_PAGE_START,
       n.SOURCE_PAGE_END
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID
 WHERE f.ORG_ID = '{ORG_ID}'
   AND f.FY_LABEL = (
       SELECT MAX(FY_LABEL) FROM AUDITED_FINANCIALS.COMMON.FILINGS
        WHERE ORG_ID = '{ORG_ID}'
          AND FY_LABEL < (SELECT MAX(FY_LABEL) FROM AUDITED_FINANCIALS.COMMON.FILINGS WHERE ORG_ID = '{ORG_ID}')
   )
 ORDER BY n.NOTE_NUM;

-- Flattened callouts across ALL filings for trend analysis
SELECT f.FY_LABEL,
       n.NOTE_NUM,
       n.TITLE AS note_title,
       c.value:concept::STRING     AS callout_concept,
       c.value:fy_label::STRING    AS callout_fy,
       c.value:amount::NUMBER      AS callout_amount,
       c.value:uom::STRING         AS callout_uom,
       c.value:context::STRING     AS callout_context
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID,
       LATERAL FLATTEN(input => n.CALLOUTS) c
 WHERE f.ORG_ID = '{ORG_ID}'
 ORDER BY f.FY_LABEL, n.NOTE_NUM, callout_concept;

-- Note coverage summary (which notes exist across filings)
SELECT f.FY_LABEL,
       COUNT(*) AS note_count,
       SUM(LENGTH(n.BODY_TEXT)) AS total_body_chars,
       SUM(ARRAY_SIZE(n.CALLOUTS)) AS total_callouts
  FROM AUDITED_FINANCIALS.{ORG_CODE}.NOTES n
  JOIN AUDITED_FINANCIALS.COMMON.FILINGS f
    ON f.FILING_ID = n.FILING_ID
 WHERE f.ORG_ID = '{ORG_ID}'
 GROUP BY f.FY_LABEL
 ORDER BY f.FY_LABEL;
