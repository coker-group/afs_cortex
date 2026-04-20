"""Thin wrapper around SNOWFLAKE.CORTEX.COMPLETE with JSON mode + repair.

Replaces llm.py from the original afs package. No vision support — text only.
The Snowpark session must be registered once via init(session) before use.

Phase 2: once an External Access Integration + Claude API key are configured,
swap MODEL_ID in config.py to "claude-opus-4-6". The interface here is unchanged.
"""
from __future__ import annotations

import json
import re
from typing import Any

from snowflake.cortex import Complete, CompleteOptions

from . import config as C

_SESSION = None


def init(session) -> None:
    """Register the Snowpark session. Call once at notebook startup."""
    global _SESSION
    _SESSION = session


def _session():
    if _SESSION is None:
        raise RuntimeError("Call cortex_llm.init(session) before using this module.")
    return _SESSION


def load_prompt(name: str) -> str:
    return (C.PROMPTS / f"{name}.md").read_text(encoding="utf-8")


def _complete(model: str, prompt: str, max_tokens: int = 8192) -> str:
    opts = CompleteOptions({"max_tokens": min(max_tokens, 8192)})
    return Complete(model, prompt, session=_session(), options=opts)


def call_text_json(
    prompt: str,
    context_text: str,
    max_tokens: int = 8192,
    model: str | None = None,
    retries: int = 3,
) -> Any:
    """Call CORTEX.COMPLETE with a prompt + extracted text block, return parsed JSON.

    `context_text` is the raw text extracted from PDF pages via PARSE_DOCUMENT.
    The combined message is: system instructions (prompt) + document text.
    """
    model = model or C.MODEL_ID
    sys_block = (
        "You are a meticulous financial statement extractor. "
        "Return ONLY a valid JSON object matching the requested schema. "
        "Do not include any prose before or after the JSON. "
        "If a value is missing or illegible, use null rather than guessing."
    )
    full_prompt = (
        f"{sys_block}\n\n"
        f"{prompt}\n\n"
        "--- DOCUMENT TEXT ---\n"
        f"{context_text}\n"
        "--- END DOCUMENT TEXT ---"
    )

    last_err: Exception | None = None
    for attempt in range(retries + 1):
        try:
            response = _complete(model, full_prompt, max_tokens=max_tokens)
            try:
                return _parse_json(response)
            except (json.JSONDecodeError, ValueError) as e:
                print(f"[cortex_llm] JSON parse failed ({e}); attempting repair", flush=True)
                repaired = _repair_json(response, error=str(e), model=model)
                return _parse_json(repaired)
        except Exception as e:
            last_err = e
            print(f"[cortex_llm] attempt {attempt + 1}/{retries + 1} failed: {e}", flush=True)
    raise RuntimeError(f"CORTEX.COMPLETE failed after {retries + 1} attempts: {last_err}")


def call_text_json_no_context(
    prompt: str,
    model: str | None = None,
    retries: int = 3,
    **kwargs,
) -> Any:
    """Variant for prompts that are self-contained (no document text block).

    Used for label mapping, insights synthesis, and JSON repair — tasks where
    all necessary input is already embedded in the prompt string.
    """
    model = model or C.MODEL_ID
    max_tokens = kwargs.get("max_tokens", 8192)
    last_err: Exception | None = None
    for attempt in range(retries + 1):
        try:
            response = _complete(model, prompt, max_tokens=max_tokens)
            try:
                return _parse_json(response)
            except (json.JSONDecodeError, ValueError) as e:
                repaired = _repair_json(response, error=str(e), model=model)
                return _parse_json(repaired)
        except Exception as e:
            last_err = e
    raise RuntimeError(f"CORTEX.COMPLETE failed after {retries + 1} attempts: {last_err}")


def _repair_json(text: str, error: str, model: str) -> str:
    repair_prompt = (
        "The following text should be a single JSON object, but parsing failed with: "
        f"{error}\n\n"
        "Return ONLY a corrected, strictly valid JSON object with no prose, no markdown fences. "
        "Preserve every field and value. If the input was truncated mid-row, drop the partial "
        "trailing row/record so the overall structure becomes valid. Do not invent new values.\n\n"
        "----- INPUT -----\n"
        f"{text}\n"
        "----- END INPUT -----"
    )
    return _complete(model, repair_prompt, max_tokens=8192)


def _parse_json(text: str) -> Any:
    text = text.strip()
    fence = re.match(r"^```(?:json)?\s*(.*?)\s*```$", text, re.DOTALL)
    if fence:
        text = fence.group(1)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        i, j = text.find("{"), text.rfind("}")
        if i != -1 and j != -1 and j > i:
            return json.loads(text[i : j + 1])
        raise
