# MedStar Health — Balance Sheet Deep Dive: HTML → PPTX Conversion Spec

**Source:** `clients/MEDSTAR_HEALTH/presentations/deep_dive_balance_sheet.html`
**Target:** `clients/MEDSTAR_HEALTH/presentations/deep_dive_balance_sheet.pptx`
**Template:** `2026_PPT_Acuvance Coker_Template.potx`
**Design System:** `acuvance_coker_design_system/02_POWERPOINT.md` + `04_DATA_VISUALIZATION.md`

---

## Global PPTX Settings

| Property | Value |
|---|---|
| Slide dimensions | 13.333" × 7.5" (widescreen 16:9) |
| Font (all elements) | Arial |
| Title color | `#004BFF` |
| Body text color | `#22272D` |
| Footer text color | `#7A7D81` |
| Slide numbering format | `pg. X` (bottom-right) |
| Footer left | Acuvance Coker logo (color PNG) |
| Footer center | `www.cokergroup.com` |
| Copyright | `© 2026 Acuvance Coker. All rights reserved.` |

---

## Slide-by-Slide Specification

### Slide 1 — Cover

**Layout:** `Title Slide w/ Image` (Master 1)

| Element | Specification |
|---|---|
| Left panel | `#004BFF` full bleed |
| Logo | White Acuvance Coker logo (`acuvance-coker-logo-white.png`), bottom-left of blue panel |
| Tag (top-left) | Dark label: "Balance Sheet & Credit" — Arial 9pt, `#22272D` on white pill |
| Title | "MedStar Health, Inc." — Arial 36pt Bold, White |
| Subtitle | "Balance Sheet Health & Trajectory — Deep Dive Analysis" — Arial 16pt, White, 85% opacity |
| Right panel | Healthcare/hospital photography (stock, if available) or solid `#0C36B4` |
| Stepping rectangles | Preserved from template — three offset rectangles bridging left/right panels |
| Bottom-left text | "CONFIDENTIAL | May 2026 | Domain Deep Dive" — Arial 9pt, White, 60% opacity |

---

### Slide 2 — Balance Sheet Snapshot

**Layout:** `Title Only` (Master 1 — light)

| Element | Position | Specification |
|---|---|---|
| Blue rule | Top, full width | 4pt `#004BFF` horizontal line |
| Title | Below rule | "Balance Sheet Snapshot: Structural Strength Masking Operational Fragility" — Arial 24pt Bold, `#004BFF` |
| KPI strip | 0.5" below title | 5 dark stat callout boxes (`#22272D`) in a row, evenly spaced |

**KPI Boxes (5 across):**

| # | Value | Label | Value Color |
|---|---|---|---|
| 1 | $4.3B | Net Assets (Unrest.) | White |
| 2 | 28.5% | Debt / Cap | `#169873` (green) |
| 3 | 122d | Days Cash | `#B83232` (red) |
| 4 | 51d | Days A/R | `#F4B73F` (amber) |
| 5 | $14M | Pension Liab. | `#169873` (green) |

Each box: `#22272D` fill, 4–8px corner radius, value in Arial 28pt Bold, label in Arial 10pt Regular White.

**Callout grid:** 2×2 grid of callout boxes below KPI strip.

| Position | Border-left color | Title | Body text |
|---|---|---|---|
| Top-left | `#169873` (green) | "The Good: Capital Structure Is the Strongest in a Decade" | "Unrestricted net assets grew 140% since FY2018 ($1.8B→$4.3B). Debt-to-cap at 28.5% is well below the 33% A-rated ceiling. Pension virtually eliminated ($629M→$14M)." |
| Top-right | `#B83232` (red) | "The Concern: Liquidity and Cash Generation Lag" | "Days cash stuck at ~122 vs. 225-day A-rated median. Operating CF margin at 2.0% vs. 7% benchmark. CapEx/depreciation at 8% = severe deferred maintenance." |
| Bottom-left | `#F4B73F` (amber) | "The Risk: Growth Driven by Investment Returns, Not Operations" | "Cumulative operating income FY2018–FY2025: $1.3B. But net assets grew $2.5B. The difference = investment market gains." |
| Bottom-right | `#004BFF` | "The Opportunity: Debt Capacity Headroom" | "At 28.5% debt-to-cap vs. 33% ceiling, MedStar has $300–400M in unused strategic debt capacity." |

Each callout box: `#F3F4F5` fill, 8px corner radius, 4px left border in specified color. Title: Arial 11pt Bold `#22272D`. Body: Arial 9pt Regular `#6B6F73`.

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025 | Benchmarks: Moody's A-rated health system medians" — Arial 8pt `#7A7D81`, bottom of content area.

---

### Slide 3 — Asset Composition (Stacked Area)

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Asset Composition Has Shifted Toward Investments and Away from Liquidity" |
| Chart type | **Native PPTX Stacked Area chart** |
| Chart position | Centered, 10.5" × 4.8", 0.5" below title |

**Chart Data (8 years × 5 series, values in $M):**

| Year | Cash | Patient AR | LT Investments | PP&E Net | Other Assets |
|---|---:|---:|---:|---:|---:|
| FY2018 | 693 | 652 | 1,077 | 1,321 | 1,569 |
| FY2019 | 560 | 692 | 1,210 | 1,433 | 1,542 |
| FY2020 | 2,065 | 685 | 1,215 | 1,635 | 1,589 |
| FY2021 | 1,524 | 897 | 1,467 | 1,821 | 1,932 |
| FY2022 | 846 | 964 | 1,422 | 2,037 | 1,724 |
| FY2023 | 811 | 930 | 1,608 | 2,230 | 1,724 |
| FY2024 | 835 | 1,049 | 1,744 | 2,317 | 1,887 |
| FY2025 | 739 | 1,246 | 2,102 | 2,318 | 2,031 |

**Chart Formatting:**

| Series | Color | Order (bottom→top) |
|---|---|---|
| Cash | `#004BFF` | 1 (bottom) |
| Patient AR | `#F4B73F` | 2 |
| LT Investments | `#4CC6C6` | 3 |
| PP&E Net | `#0C36B4` | 4 |
| Other Assets | `#B3C8FF` | 5 (top) |

- Y-axis: "$0M" to "$10,000M", formatted as `$#,##0"M"`, gridlines `#E8E9EA`
- X-axis: FY labels, no gridlines
- Legend: Top-right, horizontal, Arial 9pt
- No chart border, white plot area

**Annotation:** Add a text callout pointing to FY2020 cash spike: "CARES Act / Medicare accelerated payments" — Arial 8pt Italic, `#7A7D81`

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025" — Arial 8pt `#7A7D81`

---

### Slide 4 — Net Asset Waterfall

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Net Asset Growth: $2.5B Built Primarily on Investment Returns" |
| Chart type | **Native PPTX Waterfall chart** (or stacked bar simulation if waterfall unavailable) |
| Chart position | Centered, 10.5" × 5.0" |

**Waterfall Data:**

| Label | Value ($M) | Bar Type | Color |
|---|---:|---|---|
| FY2018 Net Assets | 1,788 | Total | `#0C36B4` |
| Cumulative Op. Income | +1,310 | Increase | `#169873` |
| Cumulative Inv. Returns | +1,296 | Increase | `#169873` |
| Other Changes | −105 | Decrease | `#B83232` |
| FY2025 Net Assets | 4,289 | Total | `#0C36B4` |

- Connector lines: `#E8E9EA` dashed between bars
- Value labels: Arial 11pt Bold `#22272D`, positioned above each bar
- Bar corner radius: 4px (if supported), max width 80px
- Y-axis: "$0M" to "$5,000M"

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025"

---

### Slide 5 — Rating Agency Gauge Dashboard

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Rating Agency Dashboard: Two Green, Two Amber, Three Red" |
| Chart type | **7 individual gauge shapes** (built with PowerPoint arcs/shapes) |
| Layout | 4 gauges top row, 3 gauges bottom row, centered |

**Gauge Specifications (each gauge is ~2.0" × 1.8"):**

| Gauge | Actual | Benchmark | Arc Color | Status |
|---|---|---|---|---|
| Op. Margin | 2.4% | 3.5% | `#B83232` (red) | Below |
| EBIDA Margin | 5.5% | 9.0% | `#B83232` (red) | Below |
| Days Cash | 122d | 225d | `#B83232` (red) | Below |
| Days AR | 51d | 48d | `#F4B73F` (amber) | Warning |
| Debt/Cap | 28.5% | 33% | `#169873` (green) | Strong |
| CF Margin | 2.0% | 7.0% | `#B83232` (red) | Below |
| CapEx/Depr | 8% | 110% | `#B83232` (red) | Critical |

**Each gauge construction (PowerPoint shapes):**
1. Background arc: `#F3F4F5`, 270° sweep, 16pt stroke
2. Value arc: Status color, sweep = (actual/max) × 270°
3. Benchmark tick: `#F4B73F` dashed line (2pt) at benchmark angle
4. Center value: Arial 20pt Bold, status color
5. Label: Arial 9pt Regular `#6B6F73`, below center
6. Benchmark annotation: "▸ {benchmark} median" — Arial 8pt `#F4B73F`

**Alternative if gauges are too complex:** Use a horizontal bar chart with 7 rows. Each row = metric name | colored bar (actual) | dashed amber line (benchmark) | values.

**Source line:** "Source: Audited Financial Statements, FY2025 | Benchmarks: Moody's A-rated medians"

---

### Slide 6 — Leverage Trajectory

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Leverage Is Declining Rapidly — Driven by Net Asset Growth, Not Debt Paydown" |
| Chart type | **Combo chart**: Clustered bar (Net Assets) + Line (Debt/Cap %) |
| Chart position | Centered, 10.5" × 4.8" |

**Data:**

| Year | Net Assets ($M) | Debt/Cap % |
|---|---:|---:|
| FY2018 | 1,788 | 45.9% |
| FY2019 | 1,796 | 46.7% |
| FY2020 | 1,700 | 53.6% |
| FY2021 | 2,748 | 38.0% |
| FY2022 | 2,692 | 39.8% |
| FY2023 | 3,127 | 36.3% |
| FY2024 | 3,737 | 30.2% |
| FY2025 | 4,289 | 28.5% |

**Formatting:**
- Bars (Net Assets): `#B3C8FF`, 60% opacity, primary Y-axis (left, $0–$5,000M)
- Line (Debt/Cap): `#B83232`, 3pt, circle markers, secondary Y-axis (right, 0–60%)
- Data labels on line: Arial 10pt Bold `#B83232`, each point labeled "XX.X%"
- Benchmark line: `#F4B73F` horizontal dashed at 33%, labeled "33% A-rated ceiling" at right end
- Legend: Top-left, 3 items (Net Assets, Debt/Cap %, A-rated Ceiling)

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025"

---

### Slide 7 — Pension Elimination

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Pension Liability Virtually Eliminated: A $615M Turnaround Story" |
| Chart type | **Area chart with line** |
| Chart position | Top half of slide, 10.5" × 3.5" |

**Data:**

| Year | Pension Liability ($M) |
|---|---:|
| FY2018 | 290 |
| FY2019 | 437 |
| FY2020 | 629 |
| FY2021 | 305 |
| FY2022 | 188 |
| FY2023 | 94 |
| FY2024 | 17 |
| FY2025 | 14 |

**Formatting:**
- Area fill: `#B83232` at 15% opacity
- Line: `#B83232`, 3pt
- Data points: Circle markers, 5px
- Data labels: Arial 10pt Bold, color transitions from `#B83232` (>$50M) to `#169873` (<$50M)
- Y-axis: "$0M" to "$700M"

**Callout box** below chart:
- Green left border (`#169873`), `#F3F4F5` fill
- Title: "From $629M liability (FY2020) to $14M (FY2025) — now overfunded with $58.7M in plan assets" — Arial 11pt Bold
- Body: "Plan appears frozen with improving funded status. Frees ~$30–50M in annual required contributions for strategic redeployment." — Arial 9pt `#6B6F73`

**Source line:** "Source: Audited Financial Statements + Note 6, FY2025"

---

### Slide 8 — Liquidity Deep Dive

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Liquidity: $2.8B in Investments, But Only 122 Days of Operating Cash" |
| Chart type | **Combo chart**: Stacked bar (Cash + Investments) + Line (Days Cash on Hand) |
| Chart position | Centered, 10.5" × 4.8" |

**Data:**

| Year | Cash ($M) | LT Investments ($M) | Days Cash |
|---|---:|---:|---:|
| FY2018 | 693 | 1,077 | 123 |
| FY2019 | 560 | 1,210 | 121 |
| FY2020 | 2,065 | 1,215 | 220 |
| FY2021 | 1,524 | 1,467 | 175 |
| FY2022 | 846 | 1,422 | 119 |
| FY2023 | 811 | 1,608 | 120 |
| FY2024 | 835 | 1,744 | 120 |
| FY2025 | 739 | 2,102 | 122 |

**Formatting:**
- Stacked bars: Cash = `#004BFF`, LT Investments = `#4CC6C6`, primary Y-axis (left, $0–$4,000M)
- Line (Days Cash): `#B83232`, 2.5pt, secondary Y-axis (right, 0–300 days)
- Data labels on line: Arial 9pt Bold `#B83232`, "XXXd"
- Benchmark: `#F4B73F` horizontal dashed at 225 days
- Legend: Top-left, 4 items

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025. FY2020 spike = CARES Act."

---

### Slide 9 — Days in A/R

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Days in A/R Rising Steadily: 42 → 51 Days, $204M in Consumed Working Capital" |
| Chart type | **Bar chart** with conditional coloring |
| Chart position | Top portion, 10.5" × 3.2" |

**Data:**

| Year | Days AR | Bar Color |
|---|---:|---|
| FY2018 | 42.4 | `#169873` (green, <45) |
| FY2019 | 44.4 | `#169873` |
| FY2020 | 43.2 | `#169873` |
| FY2021 | 48.7 | `#F4B73F` (amber, 45–48) |
| FY2022 | 48.3 | `#F4B73F` |
| FY2023 | 43.9 | `#169873` |
| FY2024 | 46.4 | `#F4B73F` |
| FY2025 | 50.7 | `#B83232` (red, >48) |

- Y-axis: 35–55 days
- Benchmark: `#F4B73F` horizontal dashed at 48 days, labeled "48d A-rated median"
- Data labels: Arial 10pt Bold `#22272D`, "XX.Xd" above each bar
- Bar corner radius: 4px, max width 48px

**Note:** Native PPTX charts cannot do per-bar conditional coloring natively. Implementation options:
1. Use a single series with manual data point coloring (right-click each point → Format Data Point → Fill)
2. Use 3 separate series (green/amber/red) with zero values for non-matching bars

**Two callout boxes** below chart (2-column):

| Position | Border | Title | Body |
|---|---|---|---|
| Left | `#B83232` (red) | "$204M in Working Capital Consumed" | "8.3-day deterioration × $24.6M/day. AR grew 91% ($652M→$1,246M) while revenue grew only 60%." |
| Right | `#F4B73F` (amber) | "Commercial Payers Are the Friction Point" | "'Other commercial' = 26% of revenue but 37% of AR ($388M). Denial management and contract enforcement are the highest-yield targets." |

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025"

---

### Slide 10 — CapEx vs. Depreciation

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Capital Reinvestment Crisis: CapEx Has Never Exceeded 31% of Depreciation" |
| Chart type | **Grouped bar chart** (paired bars per year) |
| Chart position | Top portion, 10.5" × 3.2" |

**Data:**

| Year | Depreciation ($M) | CapEx ($M) | Ratio |
|---|---:|---:|---:|
| FY2018 | 206 | 21 | 10.1% |
| FY2019 | 202 | 30 | 14.7% |
| FY2020 | 205 | 33 | 16.2% |
| FY2021 | 216 | 41 | 19.0% |
| FY2022 | 219 | 51 | 23.4% |
| FY2023 | 223 | 70 | 31.3% |
| FY2024 | 248 | 22 | 9.1% |
| FY2025 | 272 | 20 | 7.5% |

**Formatting:**
- Depreciation bars: `#B3C8FF`, left position in each group
- CapEx bars: `#B83232`, right position in each group
- Data labels on CapEx bars: ratio percentage — Arial 9pt Bold `#B83232`, "XX.X%"
- Y-axis: $0–$300M
- Legend: Top-left, 2 items

**Callout box** below chart:
- Red left border (`#B83232`), `#F3F4F5` fill
- Title: "Estimated $1.4B in Accumulated Deferred Maintenance (FY2018–FY2025)" — Arial 11pt Bold
- Body: "With $2.3B in net PP&E and $272M in annual depreciation, the physical plant is aging without reinvestment. CapEx actually declined from $70M (FY2023) to $20M (FY2025) while revenue grew 16%." — Arial 9pt `#6B6F73`

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025. Benchmark: 100–120%."

---

### Slide 11 — Self-Insurance Reserves

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Self-Insurance Reserves Are Growing: A Hidden Cash Drain" |
| Chart type | **Area chart with line** |
| Chart position | Top portion, 10.5" × 3.0" |

**Data:**

| Year | Self-Insurance ($M) |
|---|---:|
| FY2018 | 283 |
| FY2019 | 273 |
| FY2020 | 282 |
| FY2021 | 328 |
| FY2022 | 359 |
| FY2023 | 336 |
| FY2024 | 363 |
| FY2025 | 394 |

**Formatting:**
- Area fill: `#F4B73F` at 20% opacity
- Line: `#F4B73F`, 3pt
- Data labels: Arial 10pt Bold `#22272D`, "$XXXM"
- Y-axis: $200–$420M

**Two callout boxes** below chart (2-column):

| Position | Border | Title | Body |
|---|---|---|---|
| Left | `#F4B73F` (amber) | "$394M in Reserves, Up 39% Since FY2018" | "Professional & general liability accruals: $448M (FY2025). Per-claim retention rose from $20M to $25M." |
| Right | `#004BFF` | "Why It Matters" | "Self-insurance is a long-tail liability. Today's reserves fund yesterday's claims. If actuarial estimates prove inadequate, future cash calls accelerate." |

**Source line:** "Source: Audited Financial Statements + Note 11, FY2018–FY2025"

---

### Slide 12 — Investment Returns vs. Operating Income

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Investment Returns Are Masking Weak Operating Performance" |
| Chart type | **Grouped bar chart** with positive/negative values |
| Chart position | Centered, 10.5" × 4.8" |

**Data:**

| Year | Operating Income ($M) | Investment Returns ($M) |
|---|---:|---:|
| FY2018 | 161 | 119 |
| FY2019 | 152 | 53 |
| FY2020 | 131 | 20 |
| FY2021 | 260 | 511 |
| FY2022 | 81 | −271 |
| FY2023 | 147 | 214 |
| FY2024 | 159 | 359 |
| FY2025 | 219 | 346 |

**Formatting:**
- Operating Income bars: `#004BFF`
- Investment Returns bars: `#4CC6C6` (positive) / `#B83232` (negative — FY2022 only)
- Y-axis: −$350M to +$550M, zero line emphasized (`#22272D`, 1pt)
- Legend: Top-left, 2 items
- Annotation (top-right): "Cumulative: Op Inc $1,310M vs Inv Returns $1,351M" — Arial 10pt `#22272D`

**Implementation note for negative values:** FY2022 investment return bar extends below zero. Use a single "Investment Returns" series; the negative value will render below the axis automatically. To color FY2022 differently, manually recolor that single data point to `#B83232`.

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025"

---

### Slide 13 — Opportunity Sizing Table

**Layout:** `Text Content` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Balance Sheet Opportunities: Protect Strengths, Close the Gaps" |
| Content | **Data table** (6 rows + header) |

**Table Data:**

| Domain | Status | Action | Impact |
|---|---|---|---|
| Debt / Capitalization | ✓ STRONG | Protect. Use 450bp headroom as strategic debt capacity ($300–400M). | Enabling |
| Pension Elimination | ✓ STRONG | Redirect $30–50M in freed annual contributions to capital investment. | $30–50M/yr |
| Days in A/R | ⚠ WARNING | Reduce from 51d to 45d via commercial denial management. One-time $148M cash release. | $148M + ongoing |
| Days Cash on Hand | ✗ BELOW | Improve CF via margin gains, release AR working capital, rebalance investment liquidity. | +78 days target |
| CapEx / Depreciation | ✗ CRITICAL | Facilities master plan. Phase $1.4B deferred backlog over 5–7 years. | $1.0–1.4B plan |
| Self-Insurance | ⚠ RISING | Actuarial adequacy review. Explore risk transfer for tail exposure. | Risk mitigation |

**Table Formatting (per 02_POWERPOINT.md):**
- Header row: `#004BFF` fill, White text, Arial 10pt Bold, centered
- Odd rows: White fill
- Even rows: `#CCDBFF` fill
- Text: Arial 10pt, `#22272D`
- Outer border: `#0C36B4`, 1pt
- Internal rules: `#0C36B4`, 0.5pt horizontal only
- Status indicators: Use text tags — "✓ STRONG" in `#169873`, "⚠ WARNING/RISING" in `#F4B73F`, "✗ BELOW/CRITICAL" in `#B83232`

**Source line:** "Source: Analysis based on Audited Financial Statements, FY2018–FY2025"

---

### Slide 14 — Engagement Roadmap

**Layout:** `Title Only` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Recommended Engagement: Protect, Release, Rebuild" |
| Content | **3 phase blocks** (horizontal row) + 1 callout box below |

**Phase Blocks (3 across, equal width):**

| Block | Background | Header | Bullets |
|---|---|---|---|
| Phase 1: Protect (0–6 mo) | `#004BFF` | Arial 12pt Bold, White | • Revenue cycle diagnostic — commercial AR deep dive • Working capital optimization — AR to 45 days • Self-insurance actuarial adequacy review • Investment portfolio liquidity assessment |
| Phase 2: Release (6–18 mo) | `#0C36B4` | Arial 12pt Bold, White | • Freed pension contributions → capital reserve • AR cash release → liquidity cushion • Operating margin improvement → CF generation • Debt capacity sizing for strategic deployment |
| Phase 3: Rebuild (18–36 mo) | `#4A78FF` | Arial 12pt Bold, White | • Facilities master plan & capital allocation • Phased deferred maintenance program • Rating agency engagement strategy • Long-term investment policy rebalancing |

Each block: Rectangle shape, specified fill color, 8px corner radius, White text. Header: Arial 12pt Bold. Bullets: Arial 9pt Regular, 1.6 line spacing.

**Green callout box** below phase blocks:
- Green left border (`#169873`), `#F3F4F5` fill
- Title: "MedStar has the balance sheet to fund its own transformation" — Arial 11pt Bold
- Body: "$300–400M in debt capacity headroom + $30–50M/yr in freed pension contributions + $148M in AR cash release = the capital exists." — Arial 9pt `#6B6F73`

---

### Slide 15 — Appendix: Full Ratio Table

**Layout:** `Text Content` (Master 1 — light)

| Element | Specification |
|---|---|
| Title | "Appendix: Key Balance Sheet Ratios (FY2018–FY2025)" |
| Content | **Data table** (9 metrics × 9 columns + header) |

**Table Data:**

| Metric | FY18 | FY19 | FY20 | FY21 | FY22 | FY23 | FY24 | FY25 | A-Rated |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Days Cash | 123 | 121 | 220 | 175 | 119 | 120 | 120 | 122 | 225 |
| Days AR | 42 | 44 | 43 | 49 | 48 | 44 | 46 | 51 | 48 |
| Debt/Cap % | 45.9 | 46.7 | 53.6 | 38.0 | 39.8 | 36.3 | 30.2 | 28.5 | 33 |
| Debt/EBIDA | 4.6x | 4.6x | 6.0x | 3.7x | 6.1x | 5.0x | 4.1x | 3.6x | 3.0x |
| CapEx/Depr % | 10 | 15 | 16 | 19 | 23 | 31 | 9 | 8 | 110 |
| CF Margin % | 4.0 | 4.8 | 18.4 | 5.7 | −6.0 | 3.6 | 3.7 | 2.0 | 7.0 |
| Pension ($M) | 290 | 437 | 629 | 305 | 188 | 94 | 17 | 14 | — |
| Self-Ins ($M) | 283 | 273 | 282 | 328 | 359 | 336 | 363 | 394 | — |
| Net Assets ($M) | 1,788 | 1,796 | 1,700 | 2,748 | 2,692 | 3,127 | 3,737 | 4,289 | — |

**Table Formatting:**
- Font size: Arial 9pt (smaller for data density)
- Header: `#004BFF` fill, White, Bold
- A-Rated column: `#F4B73F` fill (amber), White text, Bold
- Apply `#CCDBFF` alternating row shading
- Right-align all numeric columns
- Last column header: "A-Rated Median"

**Source line:** "Source: Audited Financial Statements, FY2018–FY2025 | Benchmarks: Moody's A-rated medians (2024)"

---

## Implementation Notes

### Chart Generation Strategy

PPTX charts should use **native PowerPoint chart objects** (not embedded images) wherever possible. This ensures editability, resolution independence, and animation support.

| HTML Chart (D3) | PPTX Implementation | Notes |
|---|---|---|
| Stacked area (Slide 3) | Native Stacked Area chart | Use `python-pptx` `add_chart()` with `XL_CHART_TYPE.AREA_STACKED` |
| Waterfall (Slide 4) | Native Waterfall chart (Office 365+) or Stacked Bar simulation | Waterfall chart type requires Office 2016+. Fallback: invisible base + colored stack |
| Radial gauges (Slide 5) | **PowerPoint shapes** (arcs + text boxes) | No native gauge chart type. Build from grouped shapes or use a horizontal bar alternative |
| Combo bar+line (Slides 6, 8) | Native Combo chart | `XL_CHART_TYPE.BAR_CLUSTERED` primary + `XL_CHART_TYPE.LINE` secondary axis |
| Area with line (Slides 7, 11) | Native Area chart | Single series area + line overlay |
| Conditional-color bars (Slide 9) | Bar chart with manual data point formatting | Right-click individual points to override series color |
| Grouped bars (Slides 10, 12) | Native Grouped Bar chart | `XL_CHART_TYPE.BAR_CLUSTERED` |

### python-pptx Code Pattern

```python
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.chart import XL_CHART_TYPE, XL_LABEL_POSITION

prs = Presentation('2026_PPT_Acuvance Coker_Template.potx')
slide = prs.slides.add_slide(prs.slide_layouts[9])  # Title Only

chart_data = CategoryChartData()
chart_data.categories = ['FY2018', 'FY2019', ...]
chart_data.add_series('Cash', (693, 560, ...))

chart = slide.shapes.add_chart(
    XL_CHART_TYPE.AREA_STACKED, Inches(1.2), Inches(1.5),
    Inches(10.5), Inches(4.8), chart_data
).chart
```

### Color Reference for python-pptx

```python
AC_BLUE = RGBColor(0x00, 0x4B, 0xFF)
AC_DEEP = RGBColor(0x0C, 0x36, 0xB4)
AC_MID  = RGBColor(0x4A, 0x78, 0xFF)
AC_PALE = RGBColor(0x7B, 0xA3, 0xFF)
AC_GHOST= RGBColor(0xB3, 0xC8, 0xFF)
AC_TEAL = RGBColor(0x4C, 0xC6, 0xC6)
AC_AMBER= RGBColor(0xF4, 0xB7, 0x3F)
AC_GREEN= RGBColor(0x16, 0x98, 0x73)
AC_RED  = RGBColor(0xB8, 0x32, 0x32)
AC_DARK = RGBColor(0x22, 0x27, 0x2D)
AC_GRAY = RGBColor(0x7A, 0x7D, 0x81)
```
