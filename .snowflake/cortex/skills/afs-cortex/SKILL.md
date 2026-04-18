---
name: afs-cortex
description: Use when working on the AFS (Audited Financial Statements) Cortex pipeline — parsing PDFs, extracting financial data, mapping line items, generating consulting findings. Covers pipeline stages, schema design, prompt engineering, and Snowflake Cortex LLM usage.
---

# AFS Cortex — Workspace Skill

## Purpose
Parse US health system audited financial statement PDFs into structured Snowflake tables and generate consulting-grade financial insights. Runs entirely inside Snowflake using Cortex AI functions.

## Architecture
```
PUT pdf → @AUDITED_FINANCIALS.COMMON.AFS_STAGE
    → PARSE_DOCUMENT() → COMMON.PDF_STAGING
    → CORTEX.COMPLETE (mistral-large2) → identify / classify / extract
    → AUDITED_FINANCIALS.*
```

## Pipeline Stages (in order)
1. **identify** — Scan first ~6 pages to extract legal name, EIN, FYE, audit opinion, years shown
2. **classify** — Label every page (is, bs, cf, note, exhibit, stats, etc.) in batches of 4
3. **extract statements** — Pull IS, BS, CF, equity line items with amounts per FY
4. **extract IS exhibits** — Revenue mix, expense detail, entity P&L
5. **extract BS exhibits** — Debt, investments, PP&E schedules
6. **extract notes** — Footnote prose + numeric callouts
7. **extract stats** — MD&A / operating statistics
8. **normalize** — Map native labels → STANDARD_TAXONOMY via LLM + cache
9. **load** — Write to COMMON statement tables + per-org exhibit tables
10. **insights** — Compute ratios, trends, synthesize consulting findings

## Key Files
- `src/afs/pipeline.py` — Main orchestrator (process_filing)
- `src/afs/config.py` — Model IDs, thresholds, path config
- `src/afs/cortex_llm.py` — Wrapper around SNOWFLAKE.CORTEX.COMPLETE with JSON repair
- `src/afs/schemas.py` — Pydantic models for all LLM contracts
- `src/afs/snowflake_io.py` — Connection management, DDL, MERGE helpers, checkpoint functions
- `prompts/*.md` — LLM prompt templates (one per extraction task)
- `sql/bootstrap.sql` — Idempotent DDL for all COMMON schema objects
- `notebooks/01-04` — Bootstrap, Ingest, Parse, Analyze

## Database Layout
- `AUDITED_FINANCIALS.COMMON` — Cross-org tables: ORG_REGISTRY, FILINGS, STANDARD_TAXONOMY, LINE_ITEM_MAP, INCOME_STATEMENT, BALANCE_SHEET, CASH_FLOW, OPERATING_STATS, FINDINGS, REVIEW_QUEUE, PDF_STAGING
- `AUDITED_FINANCIALS.<ORG_CODE>` — Per-org schemas created lazily with exhibit tables

## Connection Pattern
- **Snowpark session**: Used for Cortex LLM calls and notebook DataFrame operations
- **Raw cursor** (via `cursor_from_session()`): Used by library modules for parameterised DML
- Both share the same underlying connection/transaction

## LLM Configuration
- Default model: `mistral-large2` (Phase 1)
- Override via env vars: `AFS_MODEL`, `AFS_MODEL_CLASSIFY`, `AFS_MODEL_MAP`
- Phase 2: swap to `claude-opus-4-6` with External Access Integration

## Checkpointing
- `PDF_STAGING.STAGES_COMPLETED` tracks which pipeline stages finished
- On retry, completed stages are skipped (no wasted LLM credits)
- Stage names: filing_row, statements, is_exhibits, bs_exhibits, notes, stats, insights

## Testing Guidance
- Prompt changes: test with a single filing via `03_parse.ipynb` (set STAGING_ID)
- Schema changes: re-run `01_bootstrap.ipynb` (all DDL is idempotent)
- Taxonomy changes: re-run bootstrap seed cell (truncate + reload)
