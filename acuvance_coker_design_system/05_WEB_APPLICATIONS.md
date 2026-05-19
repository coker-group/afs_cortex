# Acuvance Coker — Web Application Design Guide

> **Load this file for:** Building HTML websites, web applications, dashboards, and portals. Always load `00_DESIGN_LANGUAGE.md` and `01_TOKENS.md` first. Load `04_DATA_VISUALIZATION.md` if the application includes charts.

---

## Architecture Principles

1. **Semantic HTML first.** Use proper elements (`<nav>`, `<main>`, `<aside>`, `<header>`, `<footer>`, `<article>`, `<section>`) before reaching for divs.
2. **CSS custom properties for theming.** All colors, fonts, and spacing reference tokens from `01_TOKENS.md`.
3. **Progressive enhancement.** Core content works without JavaScript. Interactivity enhances the experience.
4. **Mobile-first responsive.** Start with the mobile layout and add complexity at wider breakpoints.

---

## Responsive Breakpoints

```css
/* Mobile first — base styles apply to all sizes */

/* Small tablets and up */
@media (min-width: 640px)  { /* --bp-sm */ }

/* Tablets and up */
@media (min-width: 768px)  { /* --bp-md */ }

/* Laptops and up */
@media (min-width: 1024px) { /* --bp-lg */ }

/* Desktops and up */
@media (min-width: 1280px) { /* --bp-xl */ }

/* Wide screens */
@media (min-width: 1536px) { /* --bp-2xl */ }
```

### Content Width

```css
.container {
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 var(--sp-4);
}

@media (min-width: 768px) {
  .container { padding: 0 var(--sp-6); }
}

@media (min-width: 1280px) {
  .container { padding: 0 var(--sp-8); }
}

.container-narrow { max-width: 960px; }
.container-wide   { max-width: 1536px; }
```

---

## Layout System

### CSS Grid — Page Layout

```css
.app-layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  grid-template-rows: 64px 1fr;
  grid-template-areas:
    "sidebar header"
    "sidebar main";
  min-height: 100vh;
}

.app-header  { grid-area: header; }
.app-sidebar { grid-area: sidebar; }
.app-main    { grid-area: main; }

/* Collapsed sidebar on mobile */
@media (max-width: 1023px) {
  .app-layout {
    grid-template-columns: 1fr;
    grid-template-areas:
      "header"
      "main";
  }
  .app-sidebar { display: none; }
  .app-sidebar.is-open { display: block; position: fixed; inset: 0; z-index: var(--z-overlay); }
}
```

### Grid Content Layouts

```css
/* Two-column content */
.grid-2 {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--sp-6);
}

/* Three-column content */
.grid-3 {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--sp-6);
}

/* Four-column KPI row */
.grid-4 {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--sp-4);
}

/* Responsive: stack on mobile */
@media (max-width: 767px) {
  .grid-2, .grid-3, .grid-4 {
    grid-template-columns: 1fr;
  }
}

@media (min-width: 768px) and (max-width: 1023px) {
  .grid-3 { grid-template-columns: repeat(2, 1fr); }
  .grid-4 { grid-template-columns: repeat(2, 1fr); }
}
```

---

## Navigation Components

### Top Navigation Bar

```html
<header class="app-header">
  <div class="header-inner">
    <div class="header-left">
      <button class="menu-toggle" aria-label="Toggle menu">
        <!-- Hamburger icon SVG -->
      </button>
      <img src="assets/acuvance-coker-logo-color.png"
           alt="Acuvance Coker" class="header-logo">
    </div>
    <nav class="header-nav" aria-label="Main navigation">
      <a href="#" class="nav-link is-active">Dashboard</a>
      <a href="#" class="nav-link">Reports</a>
      <a href="#" class="nav-link">Analytics</a>
      <a href="#" class="nav-link">Settings</a>
    </nav>
    <div class="header-right">
      <div class="user-avatar" aria-label="User menu">NC</div>
    </div>
  </div>
</header>
```

```css
.app-header {
  background: var(--ac-white);
  border-bottom: 1px solid var(--ac-gray-40);
  position: sticky;
  top: 0;
  z-index: var(--z-sticky);
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 64px;
  padding: 0 var(--sp-6);
  max-width: 1536px;
  margin: 0 auto;
}

.header-logo {
  height: 28px;
  width: auto;
}

.header-nav {
  display: flex;
  gap: var(--sp-1);
}

.nav-link {
  display: flex;
  align-items: center;
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--radius-sm);
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--ac-dark-60);
  text-decoration: none;
  transition: all var(--transition-fast);
}

.nav-link:hover {
  color: var(--ac-dark);
  background: var(--ac-gray-20);
  text-decoration: none;
}

.nav-link.is-active {
  color: var(--ac-blue);
  background: var(--ac-blue-20);
}

.user-avatar {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-pill);
  background: var(--ac-deep-blue);
  color: var(--ac-white);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--font-size-xs);
  font-weight: 700;
  cursor: pointer;
}
```

### Sidebar Navigation

```html
<aside class="app-sidebar">
  <div class="sidebar-header">
    <img src="assets/acuvance-coker-logo-color.png"
         alt="Acuvance Coker" style="height:28px;width:auto;">
  </div>
  <nav class="sidebar-nav" aria-label="Sidebar navigation">
    <div class="nav-section-label">Analytics</div>
    <a href="#" class="sidebar-link is-active">
      <svg class="sidebar-icon"><!-- icon --></svg>
      Dashboard
    </a>
    <a href="#" class="sidebar-link">
      <svg class="sidebar-icon"><!-- icon --></svg>
      Reports
    </a>
    <div class="nav-section-label">Administration</div>
    <a href="#" class="sidebar-link">
      <svg class="sidebar-icon"><!-- icon --></svg>
      Settings
    </a>
  </nav>
</aside>
```

```css
.app-sidebar {
  background: var(--ac-white);
  border-right: 1px solid var(--ac-gray-40);
  padding: var(--sp-4) 0;
  overflow-y: auto;
}

.sidebar-header {
  padding: var(--sp-4) var(--sp-5);
  margin-bottom: var(--sp-4);
}

.nav-section-label {
  font-size: var(--font-size-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--ac-dark-40);
  padding: var(--sp-4) var(--sp-5) var(--sp-2);
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: var(--sp-3);
  padding: var(--sp-2) var(--sp-5);
  font-size: var(--font-size-sm);
  font-weight: 500;
  color: var(--ac-dark-60);
  text-decoration: none;
  border-left: 3px solid transparent;
  transition: all var(--transition-fast);
}

.sidebar-link:hover {
  color: var(--ac-dark);
  background: var(--ac-gray-20);
  text-decoration: none;
}

.sidebar-link.is-active {
  color: var(--ac-blue);
  background: var(--ac-blue-20);
  border-left-color: var(--ac-blue);
  font-weight: 600;
}

.sidebar-icon {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}
```

---

## Card Components

### Standard Card

```html
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Card Title</h3>
    <span class="badge badge-blue">Active</span>
  </div>
  <div class="card-body">
    <!-- Content -->
  </div>
  <div class="card-footer">
    <button class="btn btn-ghost">View Details</button>
  </div>
</div>
```

```css
.card {
  background: var(--ac-white);
  border: 1px solid var(--ac-gray-40);
  border-radius: var(--radius-md);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--transition-fast);
}

.card:hover {
  box-shadow: var(--shadow-card);
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--sp-4) var(--sp-5);
  border-bottom: 1px solid var(--ac-gray-40);
}

.card-title {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--ac-dark);
  margin: 0;
}

.card-body {
  padding: var(--sp-5);
}

.card-footer {
  padding: var(--sp-3) var(--sp-5);
  border-top: 1px solid var(--ac-gray-40);
  background: var(--ac-gray-20);
}
```

### KPI Card

```html
<div class="kpi-card">
  <div class="kpi-label">Total Revenue</div>
  <div class="kpi-value">$12.4M</div>
  <div class="kpi-delta positive">+8.2%</div>
  <div class="kpi-spark">
    <canvas id="spark-1" width="100%" height="40"></canvas>
  </div>
</div>
```

```css
.kpi-card {
  background: var(--ac-white);
  border: 1px solid var(--ac-gray-40);
  border-radius: var(--radius-md);
  padding: var(--sp-5);
  box-shadow: var(--shadow-sm);
}

.kpi-label {
  font-size: var(--font-size-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--ac-dark-60);
  margin-bottom: var(--sp-2);
}

.kpi-value {
  font-size: var(--font-size-3xl);
  font-weight: 700;
  color: var(--ac-dark);
  line-height: var(--line-height-tight);
}

.kpi-delta {
  font-size: var(--font-size-sm);
  font-weight: 600;
  margin-top: var(--sp-1);
}

.kpi-delta.positive { color: var(--ac-green); }
.kpi-delta.negative { color: var(--ac-red); }

.kpi-spark {
  margin-top: var(--sp-3);
  height: 40px;
  position: relative;
}
```

### Dark KPI Card Variant

```css
.kpi-card--dark {
  background: var(--ac-dark);
  border-color: transparent;
  color: var(--ac-white);
}

.kpi-card--dark .kpi-label { color: rgba(255,255,255,0.6); }
.kpi-card--dark .kpi-value { color: var(--ac-white); }

.kpi-card--blue {
  background: var(--ac-blue);
  border-color: transparent;
  color: var(--ac-white);
}

.kpi-card--blue .kpi-label { color: rgba(255,255,255,0.7); }
.kpi-card--blue .kpi-value { color: var(--ac-white); }
```

---

## Button Components

```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--sp-2);
  padding: var(--sp-2) var(--sp-5);
  border-radius: var(--radius-sm);
  font-family: var(--font-family);
  font-size: var(--font-size-sm);
  font-weight: 600;
  line-height: 1;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all var(--transition-fast);
  text-decoration: none;
  white-space: nowrap;
}

/* Primary — Vibrant Blue */
.btn-primary {
  background: var(--ac-blue);
  color: var(--ac-white);
}
.btn-primary:hover { background: var(--ac-deep-blue); }
.btn-primary:active { background: #0A2E96; }

/* Secondary — Outlined */
.btn-secondary {
  background: transparent;
  color: var(--ac-blue);
  border-color: var(--ac-blue);
}
.btn-secondary:hover { background: var(--ac-blue-20); }

/* Ghost — Minimal */
.btn-ghost {
  background: transparent;
  color: var(--ac-blue);
}
.btn-ghost:hover { background: var(--ac-gray-20); }

/* Danger */
.btn-danger {
  background: var(--ac-red);
  color: var(--ac-white);
}
.btn-danger:hover { background: #9A2828; }

/* Size variants */
.btn-sm { padding: var(--sp-1) var(--sp-3); font-size: var(--font-size-xs); }
.btn-lg { padding: var(--sp-3) var(--sp-8); font-size: var(--font-size-base); }

/* Full width */
.btn-block { width: 100%; }

/* Disabled state */
.btn:disabled, .btn[aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}

/* Focus ring — accessibility */
.btn:focus-visible {
  outline: 2px solid var(--ac-blue);
  outline-offset: 2px;
}
```

---

## Form Components

```css
.form-group {
  margin-bottom: var(--sp-5);
}

.form-label {
  display: block;
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--ac-dark);
  margin-bottom: var(--sp-2);
}

.form-input {
  width: 100%;
  padding: var(--sp-2) var(--sp-3);
  border: 1px solid var(--ac-gray);
  border-radius: var(--radius-sm);
  font-family: var(--font-family);
  font-size: var(--font-size-base);
  color: var(--ac-dark);
  background: var(--ac-white);
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
}

.form-input:focus {
  outline: none;
  border-color: var(--ac-blue);
  box-shadow: 0 0 0 3px rgba(0, 75, 255, 0.15);
}

.form-input::placeholder {
  color: var(--ac-dark-40);
}

.form-input--error {
  border-color: var(--ac-red);
}

.form-input--error:focus {
  box-shadow: 0 0 0 3px rgba(184, 50, 50, 0.15);
}

.form-help {
  font-size: var(--font-size-xs);
  color: var(--ac-dark-60);
  margin-top: var(--sp-1);
}

.form-error {
  font-size: var(--font-size-xs);
  color: var(--ac-red);
  margin-top: var(--sp-1);
}

/* Select */
.form-select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%237A7D81' d='M6 8.5L1 3.5h10z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
  padding-right: 36px;
}

/* Checkbox / Radio custom */
.form-checkbox {
  appearance: none;
  width: 18px;
  height: 18px;
  border: 2px solid var(--ac-gray);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.form-checkbox:checked {
  background: var(--ac-blue);
  border-color: var(--ac-blue);
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='white' d='M10 3L5 9 2 6.5'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: center;
}
```

---

## Data Table (Application Context)

```css
.app-table {
  width: 100%;
  border-collapse: collapse;
  font-size: var(--font-size-sm);
}

.app-table thead {
  position: sticky;
  top: 0;
  z-index: var(--z-card);
}

.app-table th {
  background: var(--ac-blue);
  color: var(--ac-white);
  font-weight: 700;
  padding: var(--sp-3) var(--sp-4);
  text-align: left;
  white-space: nowrap;
  border-bottom: 2px solid var(--ac-deep-blue);
}

.app-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.app-table th.sortable:hover {
  background: var(--ac-deep-blue);
}

.app-table td {
  padding: var(--sp-3) var(--sp-4);
  border-bottom: 1px solid var(--ac-gray-40);
  vertical-align: middle;
}

.app-table tbody tr:hover {
  background: var(--ac-blue-20);
}

.app-table tbody tr:nth-child(even) {
  background: var(--ac-gray-20);
}

.app-table tbody tr:nth-child(even):hover {
  background: var(--ac-blue-20);
}

/* Numeric columns right-aligned */
.app-table td.num,
.app-table th.num {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
```

---

## Badge & Tag Components

```css
.badge {
  display: inline-flex;
  align-items: center;
  padding: 2px var(--sp-2);
  border-radius: var(--radius-pill);
  font-size: var(--font-size-xs);
  font-weight: 600;
  letter-spacing: 0.5px;
  line-height: 1.4;
  white-space: nowrap;
}

.badge-blue   { background: var(--ac-blue-20);    color: var(--ac-deep-blue); }
.badge-green  { background: var(--ac-green-20);   color: var(--ac-green); }
.badge-amber  { background: var(--ac-amber-20);   color: #8A6B00; }
.badge-red    { background: rgba(184,50,50,0.12); color: var(--ac-red); }
.badge-gray   { background: var(--ac-gray-40);    color: var(--ac-dark-60); }

/* Filter chip (dismissible) */
.chip {
  display: inline-flex;
  align-items: center;
  gap: var(--sp-1);
  padding: var(--sp-1) var(--sp-3);
  border-radius: var(--radius-pill);
  border: 1px solid var(--ac-gray);
  font-size: var(--font-size-xs);
  font-weight: 600;
  color: var(--ac-dark-60);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.chip:hover { border-color: var(--ac-blue); color: var(--ac-blue); }
.chip.is-active { background: var(--ac-blue); color: var(--ac-white); border-color: var(--ac-blue); }
```

---

## Modal / Dialog

```html
<div class="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <div class="modal">
    <div class="modal-header">
      <h2 id="modal-title" class="modal-title">Dialog Title</h2>
      <button class="modal-close" aria-label="Close">&times;</button>
    </div>
    <div class="modal-body">
      <!-- Content -->
    </div>
    <div class="modal-footer">
      <button class="btn btn-ghost">Cancel</button>
      <button class="btn btn-primary">Confirm</button>
    </div>
  </div>
</div>
```

```css
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
  padding: var(--sp-6);
}

.modal {
  background: var(--ac-white);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-modal);
  width: 100%;
  max-width: 560px;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--sp-5) var(--sp-6);
  border-bottom: 1px solid var(--ac-gray-40);
}

.modal-title {
  font-size: var(--font-size-xl);
  font-weight: 700;
  color: var(--ac-dark);
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  color: var(--ac-dark-40);
  cursor: pointer;
  padding: var(--sp-1);
  border-radius: var(--radius-sm);
}

.modal-close:hover { color: var(--ac-dark); background: var(--ac-gray-20); }

.modal-body {
  padding: var(--sp-6);
  overflow-y: auto;
  flex: 1;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--sp-3);
  padding: var(--sp-4) var(--sp-6);
  border-top: 1px solid var(--ac-gray-40);
}
```

---

## Toast / Notification

```css
.toast-container {
  position: fixed;
  top: var(--sp-5);
  right: var(--sp-5);
  z-index: var(--z-toast);
  display: flex;
  flex-direction: column;
  gap: var(--sp-3);
}

.toast {
  background: var(--ac-dark);
  color: var(--ac-white);
  padding: var(--sp-3) var(--sp-5);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-elevated);
  font-size: var(--font-size-sm);
  max-width: 400px;
  display: flex;
  align-items: center;
  gap: var(--sp-3);
  animation: slideIn var(--transition-base) forwards;
}

.toast--success { border-left: 4px solid var(--ac-green); }
.toast--error   { border-left: 4px solid var(--ac-red); }
.toast--warning { border-left: 4px solid var(--ac-amber); }
.toast--info    { border-left: 4px solid var(--ac-blue); }

@keyframes slideIn {
  from { transform: translateX(100%); opacity: 0; }
  to   { transform: translateX(0);    opacity: 1; }
}
```

---

## Loading States

```css
/* Skeleton loader */
.skeleton {
  background: linear-gradient(90deg, var(--ac-gray-40) 25%, var(--ac-gray-60) 50%, var(--ac-gray-40) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: var(--radius-sm);
}

@keyframes shimmer {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

.skeleton-text   { height: 14px; width: 80%; margin-bottom: var(--sp-2); }
.skeleton-title  { height: 24px; width: 50%; margin-bottom: var(--sp-3); }
.skeleton-card   { height: 120px; width: 100%; }
.skeleton-avatar { height: 40px; width: 40px; border-radius: var(--radius-pill); }

/* Spinner */
.spinner {
  width: 24px;
  height: 24px;
  border: 3px solid var(--ac-gray-40);
  border-top-color: var(--ac-blue);
  border-radius: var(--radius-pill);
  animation: spin 0.7s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Empty state */
.empty-state {
  text-align: center;
  padding: var(--sp-16) var(--sp-6);
  color: var(--ac-dark-40);
}

.empty-state-icon {
  font-size: 3rem;
  margin-bottom: var(--sp-4);
  opacity: 0.4;
}

.empty-state-title {
  font-size: var(--font-size-xl);
  font-weight: 600;
  color: var(--ac-dark-60);
  margin-bottom: var(--sp-2);
}

.empty-state-text {
  font-size: var(--font-size-sm);
  max-width: 400px;
  margin: 0 auto var(--sp-5);
}
```

---

## Dashboard Layout Pattern

```html
<main class="app-main" style="padding:var(--sp-6);background:var(--ac-light-gray);">
  <!-- Page header -->
  <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:var(--sp-6);">
    <h1 style="font-size:var(--font-size-2xl);font-weight:700;color:var(--ac-dark);">Dashboard</h1>
    <div style="display:flex;gap:var(--sp-2);">
      <!-- Filter chips -->
      <button class="chip is-active">All Facilities</button>
      <button class="chip">YTD</button>
      <button class="chip">Monthly</button>
    </div>
  </div>

  <!-- KPI strip -->
  <div class="grid-4" style="margin-bottom:var(--sp-6);">
    <div class="kpi-card"><!-- KPI 1 --></div>
    <div class="kpi-card"><!-- KPI 2 --></div>
    <div class="kpi-card"><!-- KPI 3 --></div>
    <div class="kpi-card"><!-- KPI 4 --></div>
  </div>

  <!-- Chart row -->
  <div class="grid-2" style="margin-bottom:var(--sp-6);">
    <div class="card">
      <div class="card-header"><h3 class="card-title">Revenue Trend</h3></div>
      <div class="card-body">
        <div class="chart-wrap" style="height:280px;">
          <canvas id="chart-revenue"></canvas>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><h3 class="card-title">Payer Mix</h3></div>
      <div class="card-body">
        <div class="chart-wrap" style="height:280px;">
          <canvas id="chart-payer"></canvas>
        </div>
      </div>
    </div>
  </div>

  <!-- Full-width table -->
  <div class="card">
    <div class="card-header">
      <h3 class="card-title">Provider Performance</h3>
      <button class="btn btn-sm btn-ghost">Export</button>
    </div>
    <div class="card-body" style="padding:0;overflow-x:auto;">
      <table class="app-table"><!-- Table content --></table>
    </div>
  </div>
</main>
```

---

## Login / Authentication Page

```html
<div style="min-height:100vh;display:flex;align-items:center;justify-content:center;
            background:var(--gradient-tl);padding:var(--sp-6);">
  <div style="background:var(--ac-white);border-radius:var(--radius-lg);
              box-shadow:var(--shadow-modal);padding:var(--sp-10);
              width:100%;max-width:440px;">
    <div style="text-align:center;margin-bottom:var(--sp-8);">
      <img src="assets/acuvance-coker-logo-color.png"
           alt="Acuvance Coker" style="height:40px;margin:0 auto var(--sp-4);">
      <h1 style="font-size:var(--font-size-2xl);font-weight:700;color:var(--ac-dark);">Sign In</h1>
      <p style="font-size:var(--font-size-sm);color:var(--ac-dark-60);margin-top:var(--sp-2);">
        Welcome back. Enter your credentials to continue.
      </p>
    </div>
    <form>
      <div class="form-group">
        <label class="form-label" for="email">Email</label>
        <input class="form-input" type="email" id="email" placeholder="name@cokergroup.com">
      </div>
      <div class="form-group">
        <label class="form-label" for="password">Password</label>
        <input class="form-input" type="password" id="password">
      </div>
      <button class="btn btn-primary btn-block btn-lg" type="submit">Sign In</button>
    </form>
  </div>
</div>
```

---

## Footer

```html
<footer style="background:var(--ac-dark);color:var(--ac-white);padding:var(--sp-10) var(--sp-6);">
  <div class="container" style="display:grid;grid-template-columns:repeat(4,1fr);gap:var(--sp-8);">
    <div>
      <img src="assets/acuvance-coker-logo-white.png"
           alt="Acuvance Coker" style="height:32px;margin-bottom:var(--sp-4);">
      <p style="font-size:var(--font-size-xs);color:rgba(255,255,255,0.6);line-height:var(--line-height-base);">
        Uniquely focused, exceptionally capable.
      </p>
    </div>
    <div>
      <h4 style="font-size:var(--font-size-xs);font-weight:600;text-transform:uppercase;
                  letter-spacing:1px;color:rgba(255,255,255,0.5);margin-bottom:var(--sp-4);">Solutions</h4>
      <nav style="display:flex;flex-direction:column;gap:var(--sp-2);">
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Performance Transformation</a>
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Strategy & Transactions</a>
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Compliance Services</a>
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Healthcare IT</a>
      </nav>
    </div>
    <div>
      <h4 style="font-size:var(--font-size-xs);font-weight:600;text-transform:uppercase;
                  letter-spacing:1px;color:rgba(255,255,255,0.5);margin-bottom:var(--sp-4);">Company</h4>
      <nav style="display:flex;flex-direction:column;gap:var(--sp-2);">
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">About</a>
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Team</a>
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Careers</a>
        <a href="#" style="color:rgba(255,255,255,0.8);font-size:var(--font-size-sm);">Contact</a>
      </nav>
    </div>
    <div>
      <h4 style="font-size:var(--font-size-xs);font-weight:600;text-transform:uppercase;
                  letter-spacing:1px;color:rgba(255,255,255,0.5);margin-bottom:var(--sp-4);">Contact</h4>
      <p style="font-size:var(--font-size-sm);color:rgba(255,255,255,0.8);line-height:var(--line-height-loose);">
        (800) 345-5829<br>
        2400 Lakeview Parkway, Suite 400<br>
        Alpharetta, Georgia 30009
      </p>
    </div>
  </div>
  <div class="container" style="margin-top:var(--sp-8);padding-top:var(--sp-5);
              border-top:1px solid rgba(255,255,255,0.12);
              display:flex;justify-content:space-between;align-items:center;">
    <span style="font-size:var(--font-size-xs);color:rgba(255,255,255,0.4);">
      &copy; 2016&ndash;2026 Coker Group Holdings, LLC, d.b.a. Coker
    </span>
    <a href="#" style="font-size:var(--font-size-xs);color:rgba(255,255,255,0.4);">Privacy Policy</a>
  </div>
</footer>
```

---

## Accessibility Checklist for Web Applications

| Requirement | Implementation |
|---|---|
| Landmark regions | `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>` |
| Skip navigation | Hidden "Skip to content" link at top of page |
| Focus management | Visible focus ring on all interactive elements |
| Keyboard navigation | All actions reachable via Tab, Enter, Escape, Arrow keys |
| ARIA labels | All icon-only buttons have `aria-label` |
| Color contrast | 4.5:1 minimum for text, 3:1 for large text and UI components |
| Form errors | `aria-describedby` linking error messages to inputs |
| Dynamic content | `aria-live="polite"` for toast notifications and status updates |
| Reduced motion | `@media (prefers-reduced-motion: reduce)` disables animations |

---

*Acuvance Coker Design System v2.0 — 05_WEB_APPLICATIONS.md*
