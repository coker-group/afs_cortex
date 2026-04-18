"""Central configuration — Cortex edition.

Local filesystem paths are removed. PDFs live in @AFS_STAGE; text in COMMON.PDF_STAGING.
Swap MODEL_ID to "claude-opus-4-6" once an External Access Integration is configured.
"""
from __future__ import annotations

import os
from pathlib import Path

EXTRACTOR_VERSION = "0.2.0"

# ---- LLM models (all served via SNOWFLAKE.CORTEX.COMPLETE) ----
# Phase 1: mistral-large2  |  Phase 2 (with EAI + Claude API): claude-opus-4-6
MODEL_ID       = os.environ.get("AFS_MODEL",          "mistral-large2")
MODEL_CLASSIFY = os.environ.get("AFS_MODEL_CLASSIFY", "mistral-large2")
MODEL_MAP      = os.environ.get("AFS_MODEL_MAP",      "mistral-large2")

# ---- Snowflake objects ----
SNOWFLAKE_DATABASE = "AUDITED_FINANCIALS"
SNOWFLAKE_WAREHOUSE = os.environ.get("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH")
AFS_STAGE = "AUDITED_FINANCIALS.COMMON.AFS_STAGE"

# ---- prompts ----
# In Snowflake Notebooks, artifacts are uploaded alongside the notebook.
# The prompts/ directory is in the notebook's working directory.
PROMPTS = Path(__file__).resolve().parents[3] / "prompts"

# ---- extraction thresholds ----
MIN_NUMERIC_CONFIDENCE = 0.85
MIN_MAPPING_CONFIDENCE = 0.90
