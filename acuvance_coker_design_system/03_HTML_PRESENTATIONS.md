# Acuvance Coker — HTML Presentation Design Guide

> **Load this file for:** Building HTML slide decks (single-file `.html` presentations). Always load `00_DESIGN_LANGUAGE.md` and `01_TOKENS.md` first. Load `04_DATA_VISUALIZATION.md` if slides contain charts.

---

## Architecture

HTML presentations are self-contained single-file documents using CSS `aspect-ratio: 16/9` for each slide frame. No external frameworks — vanilla HTML + CSS + inline JavaScript only.

---

## Slide Frame CSS

```css
.slide-frame {
  aspect-ratio: 16 / 9;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto var(--sp-8);
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
  background: var(--ac-white);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-card);
}

.slide-header {
  flex-shrink: 0;
  padding: var(--sp-5) var(--sp-6) 0;
  border-top: 3px solid var(--ac-blue);
}

.slide-header h2 {
  font-family: var(--font-family);
  font-size: var(--font-size-2xl);
  font-weight: 700;
  color: var(--ac-blue);
  line-height: var(--line-height-tight);
  margin: 0;
}

.slide-body {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: var(--sp-4);
  padding: var(--sp-5) var(--sp-6);
}

.slide-footer {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--sp-2) var(--sp-6);
  border-top: 1px solid var(--ac-gray-40);
  font-size: var(--font-size-xs);
  color: var(--ac-dark-60);
}
```

---

## Content Budget — Hard Limits Per Slide

Overflow is the most common defect in HTML slides. These limits are non-negotiable:

| Element | Maximum | Notes |
|---|---|---|
| Table rows (including header) | 12 | Use pagination or summary for larger datasets |
| Callout boxes | 4 | Arrange in 2x2 grid max |
| KPI blocks in a strip | 5 | Single horizontal row, `flex-wrap: nowrap` |
| Charts per slide | 1 | One primary chart; pair with max 3 stat callouts |
| Body text paragraphs | 2 | Keep prose minimal — slides are visual, not narrative |
| Bullet points | 6 | If you need more, split across slides |
| Combined elements | One primary element rule — do not combine a full table AND a chart on one slide |

---

## Slide Types

### Cover Slide

```html
<div class="slide-frame" style="background: var(--gradient-tl); color: var(--ac-white);">
  <!-- Grid Shapes: bottom-right corner -->
  <div class="grid-shape grid-shape--bottom-right"
       style="width:180px;height:180px;transform:rotate(180deg);
              transform-origin:bottom right;">
    <div class="grid-shape-layer"
         style="width:120px;height:40px;bottom:0;right:0;
                background:rgba(255,255,255,0.15);"></div>
    <div class="grid-shape-layer"
         style="width:80px;height:40px;bottom:48px;right:0;
                background:rgba(255,255,255,0.20);"></div>
    <div class="grid-shape-layer"
         style="width:48px;height:40px;bottom:96px;right:0;
                background:rgba(255,255,255,0.28);"></div>
  </div>

  <div style="position:relative;z-index:1;padding:var(--sp-10);
              display:flex;flex-direction:column;justify-content:center;height:100%;">
    <!-- Logo -->
    <div style="margin-bottom:var(--sp-8);">
      <img src="assets/acuvance-coker-logo-white.png" alt="Acuvance Coker"
           style="height:36px;width:auto;">
      <!-- LOGO PLACEHOLDER: replace with actual image asset -->
    </div>

    <div style="font-size:var(--font-size-xs);font-weight:600;letter-spacing:2px;
                text-transform:uppercase;color:rgba(255,255,255,0.65);
                margin-bottom:var(--sp-4);">REPORT TYPE</div>
    <h1 style="font-size:var(--font-size-4xl);font-weight:700;
               line-height:var(--line-height-tight);margin-bottom:var(--sp-3);">
      Presentation Title
    </h1>
    <p style="font-size:var(--font-size-base);color:rgba(255,255,255,0.80);">
      Client Name | Month Year
    </p>
  </div>
</div>
```

### Section Divider

```html
<div class="slide-frame" style="background:var(--ac-deep-blue);color:var(--ac-white);
            display:flex;align-items:center;justify-content:center;text-align:center;">
  <div style="position:relative;z-index:1;">
    <div style="font-size:var(--font-size-xs);font-weight:600;letter-spacing:2px;
                text-transform:uppercase;color:rgba(255,255,255,0.55);
                margin-bottom:var(--sp-3);">SECTION 01</div>
    <h2 style="font-size:var(--font-size-3xl);font-weight:700;color:var(--ac-white);">
      Section Title
    </h2>
  </div>
</div>
```

### Standard Content Slide

```html
<div class="slide-frame">
  <div class="slide-header">
    <h2>Slide Title — Use Insight Titles</h2>
  </div>
  <div class="slide-body">
    <!-- One primary element here: table, chart, KPI strip, or callout grid -->
  </div>
  <div class="slide-footer">
    <div>
      <img src="assets/acuvance-coker-logo-color.png" alt="Acuvance Coker"
           style="height:20px;width:auto;">
    </div>
    <div>www.cokergroup.com</div>
    <div>pg. 3</div>
  </div>
</div>
```

---

## Body Modules

### KPI Strip

```html
<div class="kpi-strip">
  <div class="kpi-block" style="background:var(--ac-blue);color:var(--ac-white);
              padding:var(--sp-4);border-radius:var(--radius-md);">
    <div style="font-size:var(--font-size-xs);font-weight:600;letter-spacing:1px;
                text-transform:uppercase;color:rgba(255,255,255,0.7);
                margin-bottom:var(--sp-1);">METRIC LABEL</div>
    <div style="font-size:var(--font-size-3xl);font-weight:700;">$1.2M</div>
    <div style="font-size:var(--font-size-xs);color:rgba(255,255,255,0.7);
                margin-top:var(--sp-1);">vs. $1.0M prior year</div>
  </div>
  <!-- Repeat for additional KPI blocks (max 5) -->
</div>
```

```css
.kpi-strip {
  display: flex;
  flex-direction: row;
  flex-wrap: nowrap;
  gap: var(--sp-4);
  align-items: stretch;
}

.kpi-strip .kpi-block {
  flex: 1;
  min-width: 0;
}
```

### KPI Block Variants

| Variant | Background | Text | Use |
|---|---|---|---|
| Primary | `--ac-blue` | White | Primary KPI |
| Dark | `--ac-dark` | White | Financial totals |
| Light | `--ac-blue-20` | `--ac-dark` | Secondary metrics |
| Positive | `--ac-green-20` | `--ac-green` | Favorable delta |
| Negative | Light red (`#FFEBEB`) | `--ac-red` | Unfavorable delta |

### Data Table

```html
<table class="data-table">
  <thead>
    <tr>
      <th>Column A</th>
      <th>Column B</th>
      <th style="text-align:right;">Column C</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Row 1</td><td>Value</td><td style="text-align:right;">$100</td></tr>
    <tr><td>Row 2</td><td>Value</td><td style="text-align:right;">$200</td></tr>
  </tbody>
  <tfoot>
    <tr class="total-row">
      <td colspan="2"><strong>Total</strong></td>
      <td style="text-align:right;"><strong>$300</strong></td>
    </tr>
  </tfoot>
</table>
```

```css
.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--font-size-sm);
  line-height: 1.4;
}

.data-table th {
  background: var(--ac-blue);
  color: var(--ac-white);
  font-weight: 700;
  padding: 10px 12px;
  text-align: left;
  white-space: nowrap;
}

.data-table td {
  padding: 10px 12px;
  border-bottom: 1px solid var(--ac-gray-40);
}

.data-table tbody tr:nth-child(even) {
  background: var(--ac-blue-20);
}

.data-table .total-row {
  background: var(--ac-blue);
  color: var(--ac-white);
  font-weight: 700;
}

.data-table .subtotal-row {
  background: var(--ac-gray);
  font-weight: 700;
}

/* Tighter sizing inside slides */
.slide-body .data-table {
  font-size: 0.8125rem;  /* 13px */
}

.slide-body .data-table td,
.slide-body .data-table th {
  padding: 6px 10px;
}
```

### Callout Grid

```html
<div style="display:grid;grid-template-columns:1fr 1fr;gap:var(--sp-4);">
  <div class="callout-box">
    <div class="callout-label">Label</div>
    <div class="callout-value">Key Finding</div>
    <div class="callout-detail">Supporting context in one sentence.</div>
  </div>
  <!-- Repeat (max 4 in 2x2 grid) -->
</div>
```

```css
.callout-box {
  background: var(--ac-light-gray);
  border-left: 4px solid var(--ac-blue);
  border-radius: var(--radius-sm);
  padding: var(--sp-4);
}

.callout-label {
  font-size: var(--font-size-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--ac-dark-60);
  margin-bottom: var(--sp-1);
}

.callout-value {
  font-size: var(--font-size-lg);
  font-weight: 700;
  color: var(--ac-dark);
  margin-bottom: var(--sp-2);
}

.callout-detail {
  font-size: var(--font-size-sm);
  color: var(--ac-dark-60);
  line-height: var(--line-height-base);
}
```

### Chart Module

```html
<div class="chart-wrap" style="height:300px;">
  <canvas id="chart-1"></canvas>
</div>
```

```css
.chart-wrap {
  position: relative;
  width: 100%;
}

.chart-wrap canvas {
  display: block;
}
```

---

## Overflow Prevention

### Critical CSS Rules

```css
.slide-frame {
  overflow: hidden;      /* hard clip — nothing escapes the frame */
}

.slide-body {
  flex: 1;
  min-height: 0;         /* REQUIRED — allows flex child to shrink */
  overflow: hidden;       /* never scroll inside a slide */
}

.slide-header,
.slide-footer,
.kpi-strip,
.callout-box {
  flex-shrink: 0;         /* these elements keep their size; body absorbs the squeeze */
}
```

### Overflow Detection Script

Include at end of HTML for QA:

```html
<script>
document.querySelectorAll('.slide-frame').forEach((frame, i) => {
  const body = frame.querySelector('.slide-body');
  if (body && body.scrollHeight > body.clientHeight) {
    console.warn(`Slide ${i + 1}: content overflows by ${body.scrollHeight - body.clientHeight}px`);
  }
});
</script>
```

---

## Grid Shape CSS (for cover/divider slides)

```css
.grid-shape {
  position: absolute;
  pointer-events: none;
  z-index: 0;
}

.grid-shape-layer {
  position: absolute;
  border-radius: 4px;
}

.grid-shape--top-right    { top: 0;    right: 0; }
.grid-shape--bottom-left  { bottom: 0; left: 0;  }
.grid-shape--top-left     { top: 0;    left: 0;  }
.grid-shape--bottom-right { bottom: 0; right: 0; }
```

---

## Print / Export Considerations

When the HTML presentation will be exported to PDF:

```css
@media print {
  .slide-frame {
    break-inside: avoid;
    page-break-inside: avoid;
    box-shadow: none;
    border: 1px solid var(--ac-gray-40);
    margin-bottom: 0;
  }

  body {
    background: white;
  }
}
```

---

## Complete Slide Shell Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Acuvance Coker — [Title]</title>
  <style>
    /* Paste :root tokens from 01_TOKENS.md */
    /* Paste base reset from 01_TOKENS.md */
    /* Paste slide CSS from this file */
    /* Paste data-table CSS if tables are used */
    /* Paste chart CSS if charts are used */
  </style>
</head>
<body style="padding:var(--sp-8);max-width:1400px;margin:0 auto;">

  <!-- Slide 1: Cover -->
  <div class="slide-frame" style="background:var(--gradient-tl);color:var(--ac-white);">
    <!-- Cover content -->
  </div>

  <!-- Slide 2: Content -->
  <div class="slide-frame">
    <div class="slide-header"><h2>Title</h2></div>
    <div class="slide-body"><!-- Content --></div>
    <div class="slide-footer">
      <div><!-- Logo --></div>
      <div>www.cokergroup.com</div>
      <div>pg. 2</div>
    </div>
  </div>

  <!-- Scripts (Chart.js, D3, etc.) -->
</body>
</html>
```

---

*Acuvance Coker Design System v2.0 — 03_HTML_PRESENTATIONS.md*
