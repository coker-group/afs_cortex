---
name: presentation-development
description: Use when building a consulting presentation or slide deck from an opportunity analysis. Creates executive summary or deep-dive presentations with data visualizations, insights, and recommendations. Requires a completed opportunity analysis briefing as input. Supports domain-specific deep dives (e.g., revenue cycle, supply chain, margin) or comprehensive overviews.
---

# Presentation Development — Workspace Skill

## Purpose
Transform opportunity analysis findings into a client-ready consulting presentation.
Outputs slide content as a structured markdown file and supporting SQL-driven data
visualizations into the client's presentations folder.

## Output Directory Convention
```
clients/{ORG_CODE}/
├── analysis/                          ← input (from opportunity-analysis skill)
│   ├── opportunity_analysis.sql
│   └── opportunity_briefing.md
└── presentations/                     ← this skill writes here
    ├── {presentation_name}.html       ← self-contained HTML slide deck
    └── {presentation_name}_data.sql   ← SQL for all charts/tables (reproducibility)
```

## When to Use
- User asks to build a presentation, deck, or slides from analysis results
- User wants an executive summary or deep-dive slide deck
- User says "present", "pitch", "deck", "slides", or "board presentation"
- User asks for a domain-specific deep dive (revenue cycle, supply chain, labor, etc.)

## Prerequisites
- A completed opportunity analysis MUST exist at `clients/{ORG_CODE}/analysis/opportunity_briefing.md`
- If no analysis exists, invoke the `opportunity-analysis` skill FIRST, then return here
- The Acuvance Coker design template, if loaded into the workspace, should be referenced
  for visual styling guidance. Check for it at `templates/acuvance_coker_template.*` or
  ask the user for its location.

---

## Execution Workflow

### Step 0 — Confirm Prerequisites and Gather Context

**0a. Verify analysis exists:**
Read `clients/{ORG_CODE}/analysis/opportunity_briefing.md`. If it does not exist,
tell the user and invoke the `opportunity-analysis` skill first.

**0b. Ask for target audience (MANDATORY — do not skip):**
Before building any presentation, ask the user:
> Who is the target audience for this presentation?

Common audiences and how they change the deck:
| Audience | Emphasis | Tone | Depth |
|----------|----------|------|-------|
| C-suite (CEO/CFO) | Strategic trajectory, total opportunity size, engagement ROI | Decisive, bottom-line | High-level with 2-3 supporting detail slides |
| Board of Directors | Governance, risk, rating agency positioning, capital allocation | Authoritative, balanced risk/opportunity | Summary with appendix detail |
| VP/Director Operations | Specific cost levers, implementation feasibility, quick wins | Practical, actionable | Detailed with benchmarks |
| Service Line Leaders | Domain-specific metrics, peer comparison, clinical relevance | Collaborative, evidence-based | Deep domain detail |
| External (rating agency, lender) | Creditworthiness, coverage ratios, liquidity, management action | Conservative, data-forward | Metrics-heavy, minimal narrative |
| Internal strategy team | Full analytical depth, methodology, data quality caveats | Technical, comprehensive | Maximum detail |

**0c. Determine presentation type:**

Ask the user or infer from context:

**Executive Summary** (8–15 slides):
- Organization snapshot
- Financial trajectory (1 slide)
- Key findings (2–3 slides)
- Opportunity sizing (1 slide)
- Recommended approach (1–2 slides)
- Appendix (2–4 slides)

**Deep Dive — Comprehensive** (20–35 slides):
- Organization snapshot
- Revenue analysis (2–3 slides)
- Cost structure deep dive (3–4 slides)
- Margin analysis (2–3 slides)
- Balance sheet health (2–3 slides)
- Cash flow dynamics (2 slides)
- Qualitative intelligence (2–3 slides)
- Opportunity sizing & prioritization (2–3 slides)
- Engagement roadmap (2–3 slides)
- Appendix (3–5 slides)

**Deep Dive — Domain-Specific** (12–20 slides):
Focused on one area. Common domains:
- Revenue Cycle (AR trends, payer mix, denial rates, days AR, cash acceleration)
- Supply Chain (supply % of revenue, CAGR analysis, physician preference, GPO opportunity)
- Labor & Workforce (labor % trends, productivity ratios, contract labor, span of control)
- Purchased Services (vendor concentration, insourcing analysis, contract rationalization)
- Capital & Facilities (capex-to-depreciation, deferred maintenance, facilities age, capital plan)
- Margin & Operating Performance (margin trends, revenue-expense scissors, EBIDA benchmarking)
- Balance Sheet & Credit (leverage, liquidity, debt profile, rating agency positioning)

### Step 1 — Design the Slide Framework

Using the appropriate framework template from `templates/`, design the slide sequence.
Each slide must have:
- **Slide number and title**
- **Slide type**: one of `title`, `insight`, `data`, `comparison`, `waterfall`, `roadmap`, `appendix`
- **Key message**: The single takeaway the audience should remember (1 sentence)
- **Content specification**: What goes on the slide — narrative, chart type, table, or callout
- **Data source**: Which section of the briefing or which SQL query feeds this slide
- **Speaker notes**: 2–4 sentences the presenter would say aloud

### Step 2 — Generate Supporting Data Queries

For each slide that requires a chart or table, write the SQL query that produces
exactly the data needed for that visualization. Collect all queries into a single
`{presentation_name}_data.sql` file.

**Chart type guidelines:**

| Data Pattern | Recommended Chart | When to Use |
|---|---|---|
| Single metric over time | Line chart | Margin trends, revenue trajectory, days AR |
| Multiple metrics over time | Multi-line or grouped bar | Revenue vs. expense growth, cost component trends |
| Part-to-whole | Stacked bar or donut | Cost breakdown, payer mix, revenue composition |
| Comparison to benchmark | Bullet chart or bar with reference line | Ratio vs. A-rated median |
| Before/after or gap | Waterfall | Opportunity sizing, bridge from current to target |
| Ranking | Horizontal bar | Opportunity prioritization, risk ranking |
| Correlation or scatter | Scatter plot | Revenue growth vs. margin (across years or peers) |

**Visualization principles for consulting decks:**
- Every chart must have a clear title that states the insight, not just the metric
  - Bad: "Operating Margin FY2018–FY2025"
  - Good: "Operating Margin Has Never Reached A-Rated Median Despite Revenue Growth"
- Use no more than 4–5 colors per chart; use brand colors from the design template
- Annotate the most important data point (latest year, inflection point, anomaly)
- Include the benchmark/peer reference directly on the chart, not in a footnote
- Right-align dollar amounts, use consistent $M or $B notation within a slide
- Source line at bottom of every data slide: "Source: Audited Financial Statements, FY{YEAR}"

### Step 3 — Write Slide Content

For each slide in the framework, produce the full content. The output format is
a structured markdown document where each slide is a section.

**Slide content format:**
```markdown
---
## Slide {N}: {Title}
**Type:** {slide_type}
**Key Message:** {one-sentence takeaway}

### Content
{Narrative text, bullet points, or table content for the slide body}

### Visualization
{Chart specification — type, data reference, axis labels, annotations, colors}
{Or: "No visualization — text/callout slide"}

### Speaker Notes
{2–4 sentences the presenter says aloud. Include the "so what" and transition to next slide.}

### Data Query Reference
{Reference to the query in the _data.sql file, e.g., "Query 03: Margin Trends"}
---
```

### Step 4 — Consulting Presentation Style Guide

Regardless of audience, all presentations must follow these principles:

**Narrative arc:**
Every presentation tells a story in three acts:
1. **Context** (Act 1): Who is this organization? What is their trajectory? (2–3 slides)
2. **Tension** (Act 2): What are the problems? How big are they? What evidence supports this? (40–60% of slides)
3. **Resolution** (Act 3): What do we recommend? What's the payoff? What's the sequence? (2–4 slides)

**Slide design principles:**
- One key message per slide — if you need two messages, make two slides
- Lead with the insight, not the data. The slide title IS the finding.
- Data supports the narrative; the narrative does not describe the data
- Use callout boxes for the single most important number on a data slide
- "Why it matters" must appear on every insight slide — connect the metric to a dollar impact or strategic consequence
- Benchmark comparisons make metrics meaningful — never show a ratio without context

**Consulting-specific conventions:**
- Use traffic-light indicators (green/amber/red) for benchmark comparisons
- Size opportunities as ranges, not point estimates
- Always attribute data: "Source: Audited Financial Statements, FY2025"
- Use "we" language when presenting recommendations (collaborative, not adversarial)
- Frame problems as opportunities — "MedStar has a $225M supply chain optimization opportunity" not "MedStar is wasting $225M on supplies"
- Include a "quick wins" slide — clients need to see near-term ROI, not just long-term transformation
- End with a clear "next steps" or "proposed engagement" slide

**Data presentation standards:**
- Dollar amounts: Use $M for millions, $B for billions. Be consistent within a deck.
- Percentages: One decimal place for margins and ratios. Zero decimals for payer mix.
- Trends: Always show at least 3 years to establish trajectory. Annotate inflection points.
- Tables: Maximum 6 rows × 5 columns on a single slide. More than that → use appendix or split.
- Charts: Maximum 2 charts per slide. Never 3+.

### Step 5 — Write Output Files

1. Check if `clients/{ORG_CODE}/presentations/` already contains files.
   - If yes, confirm with the user before overwriting.
2. Read the design system source files:
   - `/acuvance_coker_design_system/01_TOKENS.md` — extract `:root` CSS block
   - `/acuvance_coker_design_system/03_HTML_PRESENTATIONS.md` — extract slide frame CSS + HTML shell
   - `/acuvance_coker_design_system/04_DATA_VISUALIZATION.md` — extract chart config patterns
3. Build the HTML file using the shell from Step 2, injecting slide content and Chart.js code.
4. Write the HTML to `clients/{ORG_CODE}/presentations/{presentation_name}.html`
5. Write supporting SQL to `clients/{ORG_CODE}/presentations/{presentation_name}_data.sql`
6. Copy logo assets into `clients/{ORG_CODE}/presentations/assets/` if not already present.
7. Report file paths to the user.

**Naming convention for presentation files:**
- Executive summary: `executive_summary.html`
- Comprehensive deep dive: `deep_dive_comprehensive.html`
- Domain deep dive: `deep_dive_{domain}.html` (e.g., `deep_dive_revenue_cycle.html`)
- Append date if re-running: `executive_summary_2026-05-15.html`

---

## Slide Framework Templates

### Executive Summary (8–15 slides)

| # | Title Pattern | Type | Content |
|---|---|---|---|
| 1 | Title slide | title | Org name, "Financial Performance & Strategic Opportunity Assessment", date, confidential |
| 2 | Organization Snapshot | insight | Key facts: revenue, hospitals, geography, FYE, audit status |
| 3 | Financial Trajectory at a Glance | data | Revenue bar + margin line combo chart, 5+ years |
| 4 | Where {Org} is Winning | insight | 3–4 bullet strengths with supporting metrics |
| 5 | The Core Challenge | insight | 1–2 sentence thesis + key tension metric (e.g., margin vs. peer) |
| 6 | Cost Structure Pressure | data | Stacked cost breakdown or cost-ratio trend lines |
| 7 | Balance Sheet & Liquidity | data | Key BS ratios vs. A-rated benchmarks (bullet chart) |
| 8 | Qualitative Intelligence | insight | Top 2–3 footnote findings (payer mix, covenants, related-party) |
| 9 | Opportunity Sizing | data | Waterfall or horizontal bar: opportunity categories with dollar ranges |
| 10 | Recommended Engagement | roadmap | Phased timeline: quick wins → transformation → strategic |
| 11 | Proposed Next Steps | insight | Specific actions, timeline, expected deliverables |
| 12–15 | Appendix | appendix | Ratio detail table, benchmark comparison, methodology notes |

### Deep Dive — Comprehensive (20–35 slides)

| # | Title Pattern | Type | Content |
|---|---|---|---|
| 1 | Title slide | title | Org name, subtitle, date |
| 2 | Table of Contents | insight | Section overview with page numbers |
| 3 | Organization Snapshot | insight | Key facts + geography + system structure |
| 4 | Filing Coverage & Data Quality | appendix | Filing table + DQ caveats |
| 5–6 | Revenue Analysis | data | Revenue trajectory + composition + growth rates |
| 7–10 | Cost Structure Deep Dive | data | Labor trends, supply chain, purchased services, D&A |
| 11–13 | Margin Analysis | data | Op margin + EBIDA trends, peer benchmarking, FY anomaly analysis |
| 14–16 | Balance Sheet Health | data | Capital structure, liquidity ratios, pension trajectory |
| 17–18 | Cash Flow Dynamics | data | CF from ops, FCF, capex-to-dep, volatility analysis |
| 19–21 | Qualitative Intelligence | insight | Payer mix, covenants, self-insurance, related-party |
| 22–24 | Opportunity Sizing & Prioritization | data | Each opportunity with evidence + dollar sizing |
| 25–27 | Engagement Roadmap | roadmap | Phase 1/2/3 detail with deliverables and timeline |
| 28 | Investment & Expected ROI | data | Engagement cost vs. expected margin improvement |
| 29–35 | Appendix | appendix | Full ratio tables, benchmark details, methodology, data sources |

### Deep Dive — Domain-Specific (12–20 slides)

Adapt based on domain. General structure:
| # | Title Pattern | Type |
|---|---|---|
| 1 | Title slide | title |
| 2 | Domain Context | insight |
| 3–4 | Current State Assessment | data |
| 5–7 | Trend Analysis & Root Causes | data |
| 8–9 | Peer/Benchmark Comparison | comparison |
| 10–11 | Opportunity Sizing | data |
| 12–13 | Recommended Actions | roadmap |
| 14 | Expected Impact & Timeline | data |
| 15 | Next Steps | insight |
| 16–20 | Appendix | appendix |

---

## Acuvance Coker Design System

The design system lives at `/acuvance_coker_design_system/`. Before building any
presentation, load the relevant files in this order:

1. `00_DESIGN_LANGUAGE.md` — Brand philosophy, voice, grid shapes
2. `01_TOKENS.md` — CSS custom properties (`:root` variables), typography scale, spacing
3. `03_HTML_PRESENTATIONS.md` — Slide frame CSS, slide types, body modules, overflow rules
4. `04_DATA_VISUALIZATION.md` — Chart.js/D3 patterns, color sequences, axis rules

### Output Format: Self-Contained HTML

Presentations are **single-file `.html` documents** using the Acuvance Coker slide frame
system. Each slide is a `<div class="slide-frame">` with 16:9 aspect ratio. The HTML file
includes all CSS (from tokens + slide CSS), all chart JavaScript (Chart.js inline), and
all data (embedded in `<script>` blocks).

### Color Palette (from design system tokens)

| Role | Token | Hex | Usage |
|---|---|---|---|
| Primary / 1st series | `--ac-blue` | `#004BFF` | Bars, primary lines, KPI blocks |
| Secondary / 2nd series | `--ac-deep-blue` | `#0C36B4` | Comparison series, waterfall totals |
| 3rd series | `--ac-blue-mid` | `#4A78FF` | Additional series |
| 4th series | `--ac-blue-pale` | `#7BA3FF` | Additional series |
| 5th series | `--ac-blue-ghost` | `#B3C8FF` | Additional series |
| 6th series | `--ac-teal` | `#4CC6C6` | Breaks from blue family |
| Benchmark / target | `--ac-amber` | `#F4B73F` | Always dashed lines, never solid fill |
| Favorable | `--ac-green` | `#169873` | Green = good. Never reversed. |
| Unfavorable | `--ac-red` | `#B83232` | Red = bad. Never reversed. |
| Dark / text | `--ac-dark` | `#22272D` | Body text, axis labels |
| Grid lines | `--ac-gray-40` | `#E8E9EA` | Chart gridlines, table borders |
| Light background | `--ac-light-gray` | `#F3F4F5` | Callout box fills, alt table rows |
| Cover gradient | `--gradient-tl` | `linear-gradient(135deg, #004BFF 0%, #0C36B4 100%)` | Title/divider slides |

### Typography

- Font family: `Arial, Helvetica, sans-serif` (via `--font-family`)
- Slide titles: `var(--font-size-2xl)` (1.5rem), weight 700, color `--ac-blue`
- Body text: `var(--font-size-sm)` (0.875rem), color `--ac-dark`
- Captions/labels: `var(--font-size-xs)` (0.75rem), uppercase, letter-spacing 1–2px
- KPI values: `var(--font-size-3xl)` (1.875rem), weight 700

### Logo Assets

- Color logo (for content slide footers): `acuvance_coker_design_system/assets/acuvance-coker-logo-color.png`
- White logo (for cover/divider slides): `acuvance_coker_design_system/assets/acuvance-coker-logo-white.png`

Reference logos using relative paths from the presentation file location.

### Slide Type Reference

| Slide Type | Background | Header | Footer | Use For |
|---|---|---|---|---|
| Cover | `--gradient-tl` (blue gradient) | None | None | Title slide with logo, title, subtitle |
| Section Divider | `--ac-deep-blue` | None | None | Section breaks, centered text |
| Standard Content | `--ac-white` | Blue top border + title | Logo + URL + page | Data, insight, comparison slides |
| Appendix | `--ac-white` | Blue top border + title | Logo + URL + page | Detail tables, methodology |

### Content Budget (Hard Limits Per Slide — from design system)

| Element | Maximum |
|---|---|
| Table rows (including header) | 12 |
| Callout boxes | 4 (2×2 grid) |
| KPI blocks in a strip | 5 |
| Charts per slide | 1 (pair with max 3 stat callouts) |
| Body text paragraphs | 2 |
| Bullet points | 6 |

### Chart Implementation

Use **Chart.js** for bar, line, donut, and sparkline charts (most common in consulting decks).
Use **D3.js** only for waterfall, scatter, gauge, or geographic visualizations.

Key chart rules from the design system:
- Series colors follow fixed order: `#004BFF` → `#0C36B4` → `#4A78FF` → `#7BA3FF` → `#B3C8FF` → `#4CC6C6`
- Benchmarks are ALWAYS amber (`#F4B73F`) dashed lines (`borderDash: [6, 4]`)
- Green = favorable, Red = unfavorable. Never reversed.
- Bar border radius: 4px (`borderRadius: 4`)
- Max bar thickness: 48px
- Grid lines: `#E8E9EA`, dashed on Y-axis, hidden on X-axis
- Donut cutout: 62% (`cutout: '62%'`)
- Remove axis domain lines
- Max 8 tick marks per axis

### HTML Shell

Every presentation starts from the shell in `03_HTML_PRESENTATIONS.md`. The file must:
1. Include all `:root` CSS tokens from `01_TOKENS.md`
2. Include slide frame CSS from `03_HTML_PRESENTATIONS.md`
3. Include data-table and callout CSS if used
4. Include Chart.js via CDN: `<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>`
5. Include the overflow detection script at the end for QA
6. Embed chart data inline (no external data files)
7. Use `assets/` relative paths for logo images

---

## Cross-Referencing the Analysis

The opportunity briefing (`opportunity_briefing.md`) has a predictable structure.
Map briefing sections to presentation slides as follows:

| Briefing Section | Executive Summary Slide(s) | Deep Dive Slide(s) |
|---|---|---|
| Executive Summary | Slide 5 (Core Challenge) | Slide 2 (TOC context) |
| 1. Org & Data Profile | Slide 2 (Snapshot) | Slides 3–4 |
| 2. Revenue Analysis | Slide 3 (Trajectory) | Slides 5–6 |
| 3. Expense Structure | Slide 6 (Cost Pressure) | Slides 7–10 |
| 4. Margin Analysis | Slide 3 (Trajectory) | Slides 11–13 |
| 5. Balance Sheet | Slide 7 (BS & Liquidity) | Slides 14–16 |
| 6. Cash Flow | Slide 7 (BS & Liquidity) | Slides 17–18 |
| 7. Qualitative Intelligence | Slide 8 | Slides 19–21 |
| 8. Diagnostic Patterns | Slide 5 (Core Challenge) | Woven into domain slides |
| 9. Opportunities | Slide 9 (Sizing) | Slides 22–24 |
| 10. Engagement Approach | Slide 10 (Roadmap) | Slides 25–27 |
| Appendix A (Benchmarks) | Slide 12–15 | Slides 29–35 |
| Appendix B (Pipeline Findings) | — | Slides 29–35 |

---

## Database Reference

This skill does not query the database directly for new data. All data comes from:
1. The opportunity briefing markdown (narrative and tables)
2. The opportunity analysis SQL file (re-runnable queries for chart data)
3. Direct queries against `AUDITED_FINANCIALS` only if the briefing is missing
   a specific data point needed for a visualization

When writing the `_data.sql` file, use the same ORG_ID from the analysis SQL.
Reference the COMMON schema tables for standardized data and the per-org schema
for native-label detail and notes.
