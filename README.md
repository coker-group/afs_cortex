# afs_cortex

Snowflake Cortex edition of the AFS parser. Runs entirely inside Snowflake — no external API keys required for Phase 1.

## Architecture

PDFs are uploaded to a Snowflake internal stage (`@AFS_STAGE`). Text is extracted via `SNOWFLAKE.CORTEX.PARSE_DOCUMENT()` and stored in `COMMON.PDF_STAGING`. The pipeline then runs LLM extraction using `SNOWFLAKE.CORTEX.COMPLETE()` with `mistral-large2`.

### Phase 1 (current) — pure Cortex
```
PUT pdf → @AFS_STAGE
    → PARSE_DOCUMENT() → COMMON.PDF_STAGING
    → CORTEX.COMPLETE (mistral-large2) → identify / classify / extract
    → AUDITED_FINANCIALS.*
```

### Phase 2 (once Claude API key is provisioned)
Swap `MODEL_ID = "mistral-large2"` to `"claude-opus-4-6"` in `src/afs/config.py` and configure an External Access Integration pointing to `api.anthropic.com`. No other changes needed.

## Deployment

```bash
# Install Snowflake CLI
pip install snowflake-cli

# Deploy all notebooks and stage
snow project deploy

# Or deploy individually
snow notebook deploy --notebook-name AFS_03_PARSE
```

## Usage (inside Snowflake Notebooks)

1. **`AFS_01_BOOTSTRAP`** — Run once to create all database objects.
2. **`AFS_02_INGEST`** — Upload PDFs via the UI or `PUT` command; extracts and stages text.
3. **`AFS_03_PARSE`** — Runs the full pipeline on pending filings.
4. **`AFS_04_ANALYZE`** — Generates ratio tables and consulting findings for a loaded org.

## Snowflake objects

Same schema as `audited_financials`:
- `AUDITED_FINANCIALS.COMMON` — `ORG_REGISTRY`, `FILINGS`, `STANDARD_TAXONOMY`, `LINE_ITEM_MAP`, `INCOME_STATEMENT`, `BALANCE_SHEET`, `CASH_FLOW`, `OPERATING_STATS`, `FINDINGS`, `REVIEW_QUEUE`.
- `AUDITED_FINANCIALS.COMMON.PDF_STAGING` — extracted text cache; avoids re-calling `PARSE_DOCUMENT` on re-parse.
- `AUDITED_FINANCIALS.<ORG_CODE>` — per-org schemas created lazily.
