-- =============================================================================
-- 08: Existing Pipeline Findings
-- =============================================================================
-- Substitution: {ORG_ID}

SELECT FY_LABEL,
       SEVERITY,
       CATEGORY,
       TITLE,
       NARRATIVE,
       EST_IMPACT_LOW,
       EST_IMPACT_HIGH,
       IMPACT_UNIT,
       SUPPORTING_CONCEPTS,
       PLAYBOOK_HINT
  FROM AUDITED_FINANCIALS.COMMON.FINDINGS
 WHERE ORG_ID = '{ORG_ID}'
 ORDER BY FY_LABEL, SEVERITY;

-- Summary: finding frequency by category and severity
SELECT CATEGORY,
       SEVERITY,
       COUNT(*) AS finding_count,
       ROUND(AVG(EST_IMPACT_LOW), 0) AS avg_impact_low,
       ROUND(AVG(EST_IMPACT_HIGH), 0) AS avg_impact_high
  FROM AUDITED_FINANCIALS.COMMON.FINDINGS
 WHERE ORG_ID = '{ORG_ID}'
 GROUP BY CATEGORY, SEVERITY
 ORDER BY SEVERITY, CATEGORY;

-- Data quality: review queue items (low-confidence extractions)
SELECT STATEMENT,
       COUNT(*) AS flagged_items,
       ROUND(AVG(CONFIDENCE), 3) AS avg_confidence,
       SUM(CASE WHEN RESOLVED THEN 1 ELSE 0 END) AS resolved_count
  FROM AUDITED_FINANCIALS.COMMON.REVIEW_QUEUE
 WHERE ORG_ID = '{ORG_ID}'
 GROUP BY STATEMENT
 ORDER BY STATEMENT;
