# Acuvance Coker — Design Tokens

> **Load this file for:** Every HTML/CSS task. This is the single source of truth for all design values. Always load first alongside `00_DESIGN_LANGUAGE.md`.

---

## CSS Custom Properties

Paste this `:root` block into every HTML file before any other styles. Never hard-code a color, font, or spacing value — always reference a token.

```css
:root {
  /* ── Core Brand Colors ───────────────────────────── */
  --ac-blue:           #004BFF;   /* Vibrant Blue — primary */
  --ac-deep-blue:      #0C36B4;   /* Deep Blue — headings, borders, logo script */
  --ac-dark:           #22272D;   /* Brand Charcoal — body text, ACUVANCE in logo */
  --ac-white:          #FFFFFF;
  --ac-light-gray:     #F3F4F5;   /* page backgrounds, subtle fills */
  --ac-gray:           #C5C9CB;   /* dividers, muted icons, logo pipe */

  /* ── Blue Tint Progression ──────────────────────── */
  --ac-blue-80:        #336FFF;
  --ac-blue-60:        #6693FF;
  --ac-blue-40:        #99B7FF;
  --ac-blue-20:        #CCDBFF;   /* table row alternation, light tint backgrounds */

  /* ── Deep Blue Tint Progression ─────────────────── */
  --ac-deep-blue-80:   #3D5EC3;
  --ac-deep-blue-60:   #6D86D2;
  --ac-deep-blue-40:   #9EAFE1;
  --ac-deep-blue-20:   #CED7F0;

  /* ── Charcoal Tint Progression ──────────────────── */
  --ac-dark-80:        #4E5257;
  --ac-dark-60:        #7A7D81;
  --ac-dark-40:        #A7A9AB;
  --ac-dark-20:        #D3D4D5;

  /* ── Neutral Gray Tint Progression ──────────────── */
  --ac-gray-80:        #D1D4D5;
  --ac-gray-60:        #DCDFE0;
  --ac-gray-40:        #E8E9EA;
  --ac-gray-20:        #F3F4F5;   /* alias for --ac-light-gray */

  /* ── Accent Colors ──────────────────────────────── */
  --ac-amber:          #F4B73F;   /* warm accent — benchmarks, attention */
  --ac-teal:           #4CC6C6;   /* cool accent — differentiation from blue */
  --ac-green:          #169873;   /* favorable variance, positive */
  --ac-red:            #B83232;   /* unfavorable variance, negative */

  /* ── Amber Tint Progression ─────────────────────── */
  --ac-amber-80:       #F6C565;
  --ac-amber-60:       #F8D48C;
  --ac-amber-40:       #FBE2B2;
  --ac-amber-20:       #FDF1D9;

  /* ── Teal Tint Progression ──────────────────────── */
  --ac-teal-80:        #70D1D1;
  --ac-teal-60:        #94DDDD;
  --ac-teal-40:        #B7E8E8;
  --ac-teal-20:        #DBF4F4;

  /* ── Green Tint Progression ─────────────────────── */
  --ac-green-80:       #45AD8F;
  --ac-green-60:       #73C1AB;
  --ac-green-40:       #A2D6C7;
  --ac-green-20:       #D0EAE3;

  /* ── Visualization Extended Palette ─────────────── */
  --viz-blue-mid:      #4A78FF;   /* 3rd data series */
  --viz-blue-pale:     #7BA3FF;   /* 4th data series */
  --viz-blue-ghost:    #B3C8FF;   /* 5th data series / very light fill */
  --viz-green-light:   #5FD38D;   /* KPI delta positive */
  --viz-red-light:     #FF7A7A;   /* KPI delta negative */

  /* ── Typography ─────────────────────────────────── */
  --font-family:       Arial, Helvetica, sans-serif;
  --font-size-base:    1rem;       /* 16px */
  --font-size-sm:      0.875rem;   /* 14px */
  --font-size-xs:      0.75rem;    /* 12px */
  --font-size-lg:      1.125rem;   /* 18px */
  --font-size-xl:      1.25rem;    /* 20px */
  --font-size-2xl:     1.5rem;     /* 24px */
  --font-size-3xl:     1.875rem;   /* 30px */
  --font-size-4xl:     2.25rem;    /* 36px — hero/cover titles only */
  --line-height-tight: 1.2;
  --line-height-base:  1.5;
  --line-height-loose: 1.7;

  /* ── Spacing Scale (4px base) ───────────────────── */
  --sp-1:   4px;
  --sp-2:   8px;
  --sp-3:   12px;
  --sp-4:   16px;
  --sp-5:   20px;
  --sp-6:   24px;
  --sp-8:   32px;
  --sp-10:  40px;
  --sp-12:  48px;
  --sp-16:  64px;
  --sp-20:  80px;
  --sp-24:  96px;

  /* ── Borders ────────────────────────────────────── */
  --radius-sm:    4px;
  --radius-md:    8px;
  --radius-lg:    12px;
  --radius-xl:    16px;
  --radius-pill:  999px;
  --border-light: 1px solid var(--ac-blue-20);
  --border-mid:   1px solid var(--ac-gray);
  --border-deep:  1px solid var(--ac-deep-blue);

  /* ── Shadows ────────────────────────────────────── */
  --shadow-sm:       0 1px 4px rgba(0,0,0,0.06);
  --shadow-card:     0 2px 8px rgba(0,0,0,0.08);
  --shadow-elevated: 0 4px 16px rgba(0,0,0,0.12);
  --shadow-modal:    0 8px 32px rgba(0,0,0,0.18);

  /* ── Transitions ────────────────────────────────── */
  --transition-fast:   150ms ease-out;
  --transition-base:   250ms ease-out;
  --transition-slow:   400ms ease-out;
  --transition-spring: 500ms cubic-bezier(0.34, 1.56, 0.64, 1);

  /* ── Z-Index Scale ──────────────────────────────── */
  --z-base:      0;
  --z-card:      10;
  --z-dropdown:  100;
  --z-sticky:    200;
  --z-overlay:   300;
  --z-modal:     400;
  --z-toast:     500;

  /* ── Gradient Presets ───────────────────────────── */
  --gradient-tl: radial-gradient(circle at top left,    #004BFF 0%, #0C36B4 100%);
  --gradient-tr: radial-gradient(circle at top right,   #004BFF 0%, #0C36B4 100%);
  --gradient-bl: radial-gradient(circle at bottom left, #004BFF 0%, #0C36B4 100%);
  --gradient-br: radial-gradient(circle at bottom right,#004BFF 0%, #0C36B4 100%);

  /* ── Breakpoints (reference — use in @media) ────── */
  /* --bp-sm:   640px;  */
  /* --bp-md:   768px;  */
  /* --bp-lg:   1024px; */
  /* --bp-xl:   1280px; */
  /* --bp-2xl:  1536px; */
}
```

---

## Base Reset

Include immediately after the `:root` block.

```css
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: var(--font-family);
  font-size: var(--font-size-base);
  color: var(--ac-dark);
  line-height: var(--line-height-base);
  background: var(--ac-light-gray);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

img { max-width: 100%; height: auto; display: block; }
a { color: var(--ac-blue); text-decoration: none; }
a:hover { color: var(--ac-deep-blue); text-decoration: underline; }
```

---

## Typography Application Quick Reference

| Element | Token | Weight | Color | Notes |
|---|---|---|---|---|
| H1 — cover title | `--font-size-3xl` or `--font-size-4xl` | 700 | `--ac-white` on blue, `--ac-dark` on white | Cover slides only |
| H2 — slide/section title | `--font-size-2xl` | 700 | `--ac-blue` on white, `--ac-white` on blue | Primary title element |
| H3 — section label | `--font-size-xl` | 600 | `--ac-deep-blue` | Card groups, subsections |
| H4 — card title | `--font-size-lg` | 600 | `--ac-dark` | Inside cards |
| Body text | `--font-size-base` | 400 | `--ac-dark` | |
| Table body | `--font-size-sm` | 400 | `--ac-dark` | |
| Table header | `--font-size-sm` | 700 | `--ac-white` | On `--ac-blue` background |
| Caption / footnote | `--font-size-xs` | 400 | `--ac-dark-60` | |
| Badge / label | `--font-size-xs` | 600 | varies | Uppercase, letter-spacing: 1px |

---

## Color Application Quick Reference

| Context | Token |
|---|---|
| Primary action, key data, first series | `--ac-blue` |
| Dark backgrounds, cover slides | `--ac-deep-blue` or `var(--gradient-tl)` |
| Subtle backgrounds, table row alternation | `--ac-blue-20` |
| Body text, headings on light backgrounds | `--ac-dark` |
| Muted / supporting text | `--ac-dark-60` |
| Page / section background | `--ac-light-gray` |
| Borders, dividers | `--ac-blue-20` or `--ac-gray` |
| Favorable delta / positive | `--ac-green` or `--viz-green-light` |
| Unfavorable delta / negative | `--ac-red` or `--viz-red-light` |
| Benchmark lines | `--ac-gray` (always dashed, never solid) |
| Attention / warning | `--ac-amber` |

---

## Data Series Color Sequence

When charting multiple series, use this fixed order:

| Series | Token | Hex | Semantic Role |
|---|---|---|---|
| 1st | `--ac-blue` | `#004BFF` | Primary / current / subject |
| 2nd | `--ac-deep-blue` | `#0C36B4` | Secondary / comparison |
| 3rd | `--viz-blue-mid` | `#4A78FF` | Tertiary |
| 4th | `--viz-blue-pale` | `#7BA3FF` | Fourth |
| 5th | `--viz-blue-ghost` | `#B3C8FF` | Fifth / light fill |
| 6th | `--ac-teal` | `#4CC6C6` | Differentiation from blue |
| Benchmark | `--ac-amber` | `#F4B73F` | Always dashed line |
| Favorable | `--ac-green` | `#169873` | Positive variance only |
| Unfavorable | `--ac-red` | `#B83232` | Negative variance only |

---

## Utility Class Conventions

When building reusable CSS, follow these naming patterns:

```css
/* Colors */
.bg-ac-blue      { background: var(--ac-blue); }
.bg-ac-deep-blue { background: var(--ac-deep-blue); }
.bg-ac-dark      { background: var(--ac-dark); }
.bg-ac-light     { background: var(--ac-light-gray); }
.bg-ac-blue-20   { background: var(--ac-blue-20); }
.text-ac-blue    { color: var(--ac-blue); }
.text-ac-dark    { color: var(--ac-dark); }
.text-white      { color: var(--ac-white); }

/* Spacing */
.p-4  { padding: var(--sp-4); }
.p-6  { padding: var(--sp-6); }
.px-6 { padding-left: var(--sp-6); padding-right: var(--sp-6); }
.py-4 { padding-top: var(--sp-4); padding-bottom: var(--sp-4); }
.gap-4 { gap: var(--sp-4); }

/* Layout */
.flex      { display: flex; }
.flex-col  { flex-direction: column; }
.items-center { align-items: center; }
.justify-between { justify-content: space-between; }
.grid      { display: grid; }
```

---

*Acuvance Coker Design System v2.0 — 01_TOKENS.md*
