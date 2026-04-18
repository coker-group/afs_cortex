"""Compute ratios, trend deltas, and Cortex-generated consulting findings."""
from __future__ import annotations

import json as _json
import uuid
from typing import Any

from .cortex_llm import call_text_json_no_context, load_prompt


def _fetch_common_is(cur, org_id):
    cur.execute("SELECT FY_LABEL, CONCEPT, AMOUNT FROM COMMON.INCOME_STATEMENT WHERE ORG_ID = %s", (org_id,))
    out: dict[str, dict] = {}
    for fy, concept, amt in cur.fetchall():
        out.setdefault(fy, {})[concept] = float(amt) if amt is not None else None
    return out


def _fetch_common_bs(cur, org_id):
    cur.execute("SELECT FY_LABEL, CONCEPT, AMOUNT FROM COMMON.BALANCE_SHEET WHERE ORG_ID = %s", (org_id,))
    out: dict[str, dict] = {}
    for fy, concept, amt in cur.fetchall():
        out.setdefault(fy, {})[concept] = float(amt) if amt is not None else None
    return out


def _fetch_common_cf(cur, org_id):
    cur.execute("SELECT FY_LABEL, CONCEPT, AMOUNT FROM COMMON.CASH_FLOW WHERE ORG_ID = %s", (org_id,))
    out: dict[str, dict] = {}
    for fy, concept, amt in cur.fetchall():
        out.setdefault(fy, {})[concept] = float(amt) if amt is not None else None
    return out


def _safe_ratio(num, den):
    if num is None or den is None or den == 0:
        return None
    return num / den


def compute_ratios(cur, org_id: str) -> dict[str, Any]:
    is_data = _fetch_common_is(cur, org_id)
    bs_data = _fetch_common_bs(cur, org_id)
    cf_data = _fetch_common_cf(cur, org_id)
    years = sorted(set(is_data) | set(bs_data) | set(cf_data), reverse=True)
    ratios_by_fy: dict[str, dict] = {}
    for fy in years:
        i = is_data.get(fy, {})
        b = bs_data.get(fy, {})
        rev = i.get("total_operating_revenue")
        opex = i.get("total_operating_expense")
        op_income = i.get("operating_income")
        if op_income is None and rev is not None and opex is not None:
            op_income = rev - opex
        da = i.get("depreciation_amortization")
        salaries = i.get("total_salaries_and_benefits") or (
            (i.get("salaries_and_wages") or 0) + (i.get("employee_benefits") or 0)
            if i.get("salaries_and_wages") is not None or i.get("employee_benefits") is not None
            else None
        )
        supplies = i.get("supplies")
        purchased = i.get("purchased_services")
        cash = b.get("cash_and_equivalents")
        sti = b.get("short_term_investments")
        lti = b.get("long_term_investments")
        ar = b.get("patient_ar_net")
        lt_debt = b.get("long_term_debt")
        accum_depr = b.get("accumulated_depreciation")
        net_assets = b.get("net_assets_without_donor_restrictions")
        daily_opex = ((opex or 0) - (da or 0)) / 365 if opex else None
        ratios_by_fy[fy] = {
            "operating_margin_pct": (op_income / rev * 100) if op_income is not None and rev else None,
            "ebida_margin_pct": ((op_income or 0) + (da or 0)) / rev * 100 if rev else None,
            "salaries_pct_of_revenue": salaries / rev * 100 if salaries and rev else None,
            "supplies_pct_of_revenue": supplies / rev * 100 if supplies and rev else None,
            "purchased_services_pct_of_opex": purchased / opex * 100 if purchased and opex else None,
            "days_cash_on_hand": _safe_ratio((cash or 0) + (sti or 0) + (lti or 0), daily_opex),
            "days_in_ar": _safe_ratio(ar, (rev / 365) if rev else None),
            "debt_to_capitalization_pct": lt_debt / ((lt_debt or 0) + (net_assets or 0)) * 100
                if lt_debt and ((lt_debt or 0) + (net_assets or 0)) else None,
            "age_of_plant_years": _safe_ratio(
                -accum_depr if accum_depr is not None and accum_depr < 0 else accum_depr, da
            ),
        }
    return {"years": years, "ratios_by_fy": ratios_by_fy,
            "income_statement": is_data, "balance_sheet": bs_data, "cash_flow": cf_data}


def compute_trends(ratios: dict[str, Any]) -> dict[str, Any]:
    years = ratios["years"]
    trends: dict[str, dict] = {}
    for metric in next(iter(ratios["ratios_by_fy"].values()), {}):
        trends[metric] = {}
        for idx, fy in enumerate(years[:-1]):
            cur_val = ratios["ratios_by_fy"][fy].get(metric)
            prev_val = ratios["ratios_by_fy"][years[idx + 1]].get(metric)
            trends[metric][f"{fy}_vs_{years[idx + 1]}"] = (
                None if cur_val is None or prev_val is None else cur_val - prev_val
            )
    return trends


def synthesize_findings(ratios: dict[str, Any], trends: dict[str, Any], org_code: str) -> list[dict]:
    input_obj = {"org_code": org_code, "ratios": ratios, "trends": trends}
    prompt = load_prompt("insights").replace("{INPUT}", _json.dumps(input_obj, default=str))
    data = call_text_json_no_context(prompt, max_tokens=6000)
    return data.get("findings", [])


def write_findings(cur, org_id, filing_id, fy_label, findings: list[dict]) -> int:
    sql = """
        INSERT INTO COMMON.FINDINGS
          (FINDING_ID, ORG_ID, FILING_ID, FY_LABEL, CATEGORY, SEVERITY, TITLE, NARRATIVE,
           EST_IMPACT_LOW, EST_IMPACT_HIGH, IMPACT_UNIT, SUPPORTING_CONCEPTS, PLAYBOOK_HINT)
        SELECT %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,PARSE_JSON(%s),%s
    """
    n = 0
    for f in findings:
        cur.execute(sql, (
            str(uuid.uuid4()), org_id, filing_id, fy_label,
            f.get("category"), f.get("severity"), f.get("title"), f.get("narrative"),
            f.get("est_impact_low"), f.get("est_impact_high"),
            f.get("impact_unit") or "usd_annualized",
            _json.dumps(f.get("supporting_concepts") or []),
            f.get("playbook_hint"),
        ))
        n += 1
    return n
