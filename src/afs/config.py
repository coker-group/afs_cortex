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
# Resolve prompts/ directory using multiple fallback strategies:
#   1. Relative to this file (works in workspace layout: src/afs/config.py -> ../../prompts)
#   2. Walk up from this file until prompts/ is found
#   3. Current working directory (Snowflake Notebooks set CWD to artifact root)
def _find_prompts_dir() -> Path:
    candidates = [
        Path(__file__).resolve().parents[2] / "prompts",
        Path(__file__).resolve().parents[3] / "prompts",
        Path.cwd() / "prompts",
        Path.cwd().parent / "prompts",
    ]
    for p in candidates:
        if p.is_dir():
            return p
    return candidates[0]

PROMPTS = _find_prompts_dir()

# ---- extraction thresholds ----
MIN_NUMERIC_CONFIDENCE = 0.85
MIN_MAPPING_CONFIDENCE = 0.90
