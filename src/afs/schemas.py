"""Pydantic models that mirror the JSON contracts emitted by the extractors."""
from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field


# ---------- identify ----------
class IdentifyResult(BaseModel):
    legal_name: str
    dba: Optional[str] = None
    ein: Optional[str] = None
    hq_state: Optional[str] = None
    fye_month: Optional[int] = Field(default=None, ge=1, le=12)
    sector: Optional[str] = None
    audit_firm: Optional[str] = None
    audit_opinion: Optional[str] = None
    years_shown: list[str]
    fye_by_year: dict[str, str] = Field(default_factory=dict)
    table_of_contents: list[dict] = Field(default_factory=list)
    confidence: float = 1.0


# ---------- page classify ----------
PageLabel = Literal[
    "cover", "toc", "auditor_letter", "is", "bs", "cf", "equity",
    "is_exhibit", "bs_exhibit", "note", "mdna", "stats", "other",
]


class PageClassification(BaseModel):
    page: int
    label: PageLabel
    topic: Optional[str] = None
    note_num: Optional[str] = None
    confidence: float = 1.0


# ---------- statement rows ----------
class StatementAmount(BaseModel):
    fy_label: str
    amount: Optional[float] = None
    confidence: float = 1.0


class StatementLine(BaseModel):
    line_order: int
    native_label: str
    is_subtotal: bool = False
    parent_label: Optional[str] = None
    section: Optional[str] = None
    amounts: list[StatementAmount]
    source_page: int


class StatementExtract(BaseModel):
    statement: Literal["is", "bs", "cf", "equity"]
    lines: list[StatementLine]


# ---------- exhibits ----------
class ExhibitRow(BaseModel):
    dimension: str
    category: str
    fy_label: str
    amount: Optional[float] = None
    entity: Optional[str] = None
    source_page: int
    confidence: float = 1.0


class DebtInstrumentRow(BaseModel):
    instrument: str
    outstanding_by_fy: dict[str, float]
    rate: Optional[float] = None
    maturity_year: Optional[int] = None
    secured: Optional[bool] = None
    covenants_text: Optional[str] = None
    source_page: int
    confidence: float = 1.0


class InvestmentsRow(BaseModel):
    fv_level: Optional[str] = None
    category: str
    fair_value_by_fy: dict[str, float]
    source_page: int
    confidence: float = 1.0


class PPERow(BaseModel):
    category: str
    by_fy: dict[str, dict[str, Optional[float]]]
    source_page: int
    confidence: float = 1.0


# ---------- notes ----------
class NoteExtract(BaseModel):
    note_num: Optional[str] = None
    title: Optional[str] = None
    body_text: str = ""
    callouts: list[dict] = Field(default_factory=list)
    source_page_start: int
    source_page_end: int


# ---------- stats ----------
class StatRow(BaseModel):
    native_label: str
    fy_label: str
    amount: Optional[float] = None
    uom: Optional[str] = None
    source_page: int
    confidence: float = 1.0


# ---------- common mapping ----------
class MappingProposal(BaseModel):
    native_label: str
    statement: Literal["income_statement", "balance_sheet", "cash_flow", "stat"]
    concept: Optional[str] = None
    confidence: float
    rationale: str


# ---------- finding ----------
class Finding(BaseModel):
    category: str
    severity: Literal["high", "medium", "low"]
    title: str
    narrative: str
    est_impact_low: Optional[float] = None
    est_impact_high: Optional[float] = None
    impact_unit: str = "usd_annualized"
    supporting_concepts: list[dict] = Field(default_factory=list)
    playbook_hint: Optional[str] = None
