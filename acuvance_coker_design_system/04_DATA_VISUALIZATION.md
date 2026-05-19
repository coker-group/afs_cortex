# Acuvance Coker — Data Visualization Design Guide

> **Load this file for:** Any chart, graph, or data visualization. Always load `00_DESIGN_LANGUAGE.md` and `01_TOKENS.md` first. This guide covers Chart.js, D3.js, and advanced visualization patterns.

---

## Library Decision Matrix

| Need | Library | Rationale |
|---|---|---|
| Bar, line, donut, pie, sparkline | **Chart.js** | Simple, small, canvas-based, good defaults |
| Scatter, gauge, heat map, treemap | **D3.js** | SVG-based, fine control over layout |
| Sankey, chord, force-directed, arc | **D3.js** | Only D3 supports these natively |
| Geographic / choropleth | **D3.js** + TopoJSON | SVG map projections |
| Animated transitions, brushing, zoom | **D3.js** | Full interaction model |
| Simple KPI with sparkline | **Chart.js** | Lightweight inline canvas |

---

## Color System for Data

### Primary Series Sequence (Fixed Order)

Always assign series colors in this order. Never randomize or reorder.

```javascript
const AC = {
  blue:      '#004BFF',  // 1st series — primary / current / subject
  deepBlue:  '#0C36B4',  // 2nd series — secondary / comparison
  blueMid:   '#4A78FF',  // 3rd series
  bluePale:  '#7BA3FF',  // 4th series
  blueGhost: '#B3C8FF',  // 5th series
  teal:      '#4CC6C6',  // 6th series — breaks from blue family
  amber:     '#F4B73F',  // benchmark / highlight — always dashed when a line
  green:     '#169873',  // favorable only
  red:       '#B83232',  // unfavorable only
  dark:      '#22272D',
  gray:      '#C5C9CB',
  lightGray: '#F3F4F5',
  white:     '#FFFFFF',
};

// Categorical palette (up to 6 series)
const AC_CATEGORICAL = [AC.blue, AC.deepBlue, AC.blueMid, AC.bluePale, AC.blueGhost, AC.teal];

// Diverging palette (favorable → neutral → unfavorable)
const AC_DIVERGING = ['#169873', '#45AD8F', '#73C1AB', '#D3D4D5', '#FF7A7A', '#B83232'];

// Sequential blue palette (light → dark)
const AC_SEQUENTIAL = ['#CCDBFF', '#99B7FF', '#6693FF', '#336FFF', '#004BFF', '#0C36B4'];
```

### Semantic Color Rules

| Meaning | Color | Token | Notes |
|---|---|---|---|
| Favorable / positive | `#169873` | `--ac-green` | Green = good. Never reversed. |
| Unfavorable / negative | `#B83232` | `--ac-red` | Red = bad. Never reversed. |
| Benchmark / target | `#F4B73F` | `--ac-amber` | Always dashed line, never solid fill |
| Neutral / no judgment | `#C5C9CB` | `--ac-gray` | Use when variance is not applicable |
| KPI delta positive | `#5FD38D` | `--viz-green-light` | Lighter for background fills |
| KPI delta negative | `#FF7A7A` | `--viz-red-light` | Lighter for background fills |

### Helper: Hex to RGBA

```javascript
function hexToRgba(hex, alpha = 1) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}
```

---

## Chart.js — Global Defaults

Apply once before creating any chart:

```javascript
Chart.defaults.font.family = 'Arial, Helvetica, sans-serif';
Chart.defaults.font.size = 13;
Chart.defaults.color = '#22272D';
Chart.defaults.plugins.legend.labels.usePointStyle = true;
Chart.defaults.plugins.legend.labels.padding = 16;
Chart.defaults.plugins.tooltip.backgroundColor = '#22272D';
Chart.defaults.plugins.tooltip.titleFont = { weight: '700', size: 13 };
Chart.defaults.plugins.tooltip.bodyFont = { size: 12 };
Chart.defaults.plugins.tooltip.padding = 10;
Chart.defaults.plugins.tooltip.cornerRadius = 4;
Chart.defaults.plugins.tooltip.displayColors = true;
Chart.defaults.plugins.tooltip.boxPadding = 4;
Chart.defaults.scale.grid.color = '#E8E9EA';
Chart.defaults.scale.grid.drawBorder = false;
Chart.defaults.scale.ticks.padding = 8;
```

### Chart.js — Vertical Bar

```javascript
new Chart(ctx, {
  type: 'bar',
  data: {
    labels: categories,
    datasets: [{
      data: values,
      backgroundColor: AC.blue,
      borderRadius: 4,
      maxBarThickness: 48,
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: { callback: v => '$' + v.toLocaleString() },
      },
      x: {
        grid: { display: false },
      }
    }
  }
});
```

### Chart.js — Donut

```javascript
new Chart(ctx, {
  type: 'doughnut',
  data: {
    labels: categories,
    datasets: [{
      data: values,
      backgroundColor: AC_CATEGORICAL.slice(0, categories.length),
      borderWidth: 2,
      borderColor: '#FFFFFF',
    }]
  },
  options: {
    cutout: '62%',    // Acuvance Coker standard donut cutout
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'right',
        labels: { usePointStyle: true, padding: 12 },
      },
    }
  }
});
```

### Chart.js — Line with Benchmark

```javascript
new Chart(ctx, {
  type: 'line',
  data: {
    labels: months,
    datasets: [
      {
        label: 'Actual',
        data: actualValues,
        borderColor: AC.blue,
        backgroundColor: hexToRgba(AC.blue, 0.08),
        fill: true,
        tension: 0.3,
        pointRadius: 4,
        pointBackgroundColor: AC.blue,
      },
      {
        label: 'Benchmark',
        data: benchmarkValues,
        borderColor: AC.amber,
        borderDash: [6, 4],       // REQUIRED: benchmarks are always dashed
        pointRadius: 0,
        fill: false,
        tension: 0,
      }
    ]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'top' },
    },
    scales: {
      y: { beginAtZero: false },
      x: { grid: { display: false } },
    }
  }
});
```

### Chart.js — Sparkline

```javascript
function sparkline(canvasId, data, color = AC.blue) {
  const ctx = document.getElementById(canvasId).getContext('2d');
  new Chart(ctx, {
    type: 'line',
    data: {
      labels: data.map((_, i) => i),
      datasets: [{
        data: data,
        borderColor: color,
        backgroundColor: hexToRgba(color, 0.1),
        fill: true,
        tension: 0.4,
        pointRadius: 0,
        borderWidth: 2,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: { enabled: false } },
      scales: { x: { display: false }, y: { display: false } },
    }
  });
}
```

---

## D3.js — Foundation Patterns

### Standard Chart Boilerplate

```javascript
function createChart(containerId, { width = 720, height = 400, margin = { top: 40, right: 30, bottom: 50, left: 60 } } = {}) {
  const innerW = width - margin.left - margin.right;
  const innerH = height - margin.top - margin.bottom;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .style('width', '100%')
    .style('height', 'auto');

  const g = svg.append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  return { svg, g, innerW, innerH, margin };
}
```

### Axis Helpers

```javascript
function acAxis(g, scale, orient, { format, label, innerW, innerH }) {
  const axis = orient === 'bottom'
    ? d3.axisBottom(scale).tickFormat(format).tickSizeOuter(0)
    : d3.axisLeft(scale).tickFormat(format).tickSizeOuter(0).tickSize(-innerW);

  const axisG = g.append('g')
    .attr('transform', orient === 'bottom' ? `translate(0,${innerH})` : '')
    .call(axis);

  axisG.selectAll('.domain').remove();
  axisG.selectAll('.tick line')
    .attr('stroke', '#E8E9EA')
    .attr('stroke-dasharray', orient === 'left' ? '2,2' : '');
  axisG.selectAll('.tick text')
    .attr('fill', '#7A7D81')
    .attr('font-size', '12px')
    .attr('font-family', 'Arial, Helvetica, sans-serif');

  if (label) {
    const isX = orient === 'bottom';
    axisG.append('text')
      .attr('fill', '#22272D')
      .attr('font-size', '13px')
      .attr('font-weight', '600')
      .attr('font-family', 'Arial, Helvetica, sans-serif')
      .attr('text-anchor', isX ? 'middle' : 'middle')
      .attr('x', isX ? innerW / 2 : -innerH / 2)
      .attr('y', isX ? 40 : -45)
      .attr('transform', isX ? '' : 'rotate(-90)')
      .text(label);
  }

  return axisG;
}
```

### Tooltip System

```javascript
const acTip = d3.select('body').append('div')
  .attr('class', 'ac-tooltip')
  .style('position', 'absolute')
  .style('pointer-events', 'none')
  .style('opacity', 0)
  .style('background', '#22272D')
  .style('color', '#FFFFFF')
  .style('padding', '8px 12px')
  .style('border-radius', '4px')
  .style('font-family', 'Arial, Helvetica, sans-serif')
  .style('font-size', '12px')
  .style('line-height', '1.4')
  .style('box-shadow', '0 4px 16px rgba(0,0,0,0.18)')
  .style('z-index', '500')
  .style('max-width', '240px');

function showTip(event, html) {
  acTip.html(html)
    .style('opacity', 1)
    .style('left', (event.pageX + 12) + 'px')
    .style('top', (event.pageY - 28) + 'px');
}

function hideTip() {
  acTip.style('opacity', 0);
}
```

### Transition Constants

```javascript
const T = {
  fast:   d3.transition().duration(200).ease(d3.easeQuadOut),
  base:   d3.transition().duration(400).ease(d3.easeCubicOut),
  slow:   d3.transition().duration(700).ease(d3.easeCubicOut),
  spring: d3.transition().duration(600).ease(d3.easeBackOut.overshoot(1.2)),
};
```

---

## D3.js — Advanced Chart Implementations

### Scatter Plot (Productivity Analysis)

```javascript
function scatterProductivity(containerId, data, { xKey, yKey, sizeKey, labelKey, xLabel, yLabel }) {
  const { g, innerW, innerH } = createChart(containerId, { width: 800, height: 480 });

  const x = d3.scaleLinear()
    .domain(d3.extent(data, d => d[xKey])).nice()
    .range([0, innerW]);

  const y = d3.scaleLinear()
    .domain(d3.extent(data, d => d[yKey])).nice()
    .range([innerH, 0]);

  const size = d3.scaleSqrt()
    .domain(d3.extent(data, d => d[sizeKey]))
    .range([4, 24]);

  acAxis(g, x, 'bottom', { format: d3.format(',.0f'), label: xLabel, innerW, innerH });
  acAxis(g, y, 'left', { format: d3.format('$,.0f'), label: yLabel, innerW, innerH });

  // Quadrant lines (median)
  const medX = d3.median(data, d => d[xKey]);
  const medY = d3.median(data, d => d[yKey]);

  [{ val: medX, axis: 'x' }, { val: medY, axis: 'y' }].forEach(({ val, axis }) => {
    g.append('line')
      .attr('x1', axis === 'x' ? x(val) : 0)
      .attr('x2', axis === 'x' ? x(val) : innerW)
      .attr('y1', axis === 'y' ? y(val) : 0)
      .attr('y2', axis === 'y' ? y(val) : innerH)
      .attr('stroke', AC.gray)
      .attr('stroke-dasharray', '4,3')
      .attr('stroke-width', 1);
  });

  // Dots
  g.selectAll('.dot')
    .data(data)
    .join('circle')
    .attr('class', 'dot')
    .attr('cx', d => x(d[xKey]))
    .attr('cy', d => y(d[yKey]))
    .attr('r', d => size(d[sizeKey]))
    .attr('fill', AC.blue)
    .attr('fill-opacity', 0.65)
    .attr('stroke', AC.deepBlue)
    .attr('stroke-width', 1.5)
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('fill-opacity', 1).attr('r', size(d[sizeKey]) + 2);
      showTip(event, `<strong>${d[labelKey]}</strong><br>${xLabel}: ${d3.format(',.0f')(d[xKey])}<br>${yLabel}: ${d3.format('$,.0f')(d[yKey])}`);
    })
    .on('mouseleave', function(event, d) {
      d3.select(this).attr('fill-opacity', 0.65).attr('r', size(d[sizeKey]));
      hideTip();
    });
}
```

### Gauge / Percentile Indicator

```javascript
function gaugePercentile(containerId, value, { label, min = 0, max = 100, thresholds = [25, 50, 75] }) {
  const width = 240, height = 160;
  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .style('width', '100%');

  const cx = width / 2, cy = height - 20, radius = 90;
  const scale = d3.scaleLinear().domain([min, max]).range([-Math.PI * 0.75, Math.PI * 0.75]);

  const zones = [
    { from: min, to: thresholds[0], color: AC.red },
    { from: thresholds[0], to: thresholds[1], color: AC.amber },
    { from: thresholds[1], to: thresholds[2], color: hexToRgba(AC.teal, 0.6) },
    { from: thresholds[2], to: max, color: AC.green },
  ];

  const arc = d3.arc().innerRadius(radius - 16).outerRadius(radius).cornerRadius(2);

  zones.forEach(z => {
    svg.append('path')
      .attr('d', arc({ startAngle: scale(z.from) + Math.PI / 2, endAngle: scale(z.to) + Math.PI / 2 }))
      .attr('transform', `translate(${cx},${cy})`)
      .attr('fill', z.color);
  });

  // Needle
  const angle = scale(value);
  svg.append('line')
    .attr('x1', cx).attr('y1', cy)
    .attr('x2', cx + Math.cos(angle) * (radius - 24))
    .attr('y2', cy + Math.sin(angle) * (radius - 24))
    .attr('stroke', AC.dark)
    .attr('stroke-width', 3)
    .attr('stroke-linecap', 'round');

  svg.append('circle').attr('cx', cx).attr('cy', cy).attr('r', 5).attr('fill', AC.dark);

  // Value label
  svg.append('text')
    .attr('x', cx).attr('y', cy - 24)
    .attr('text-anchor', 'middle')
    .attr('font-family', 'Arial').attr('font-size', '28px').attr('font-weight', '700')
    .attr('fill', AC.dark)
    .text(value + (max === 100 ? '%' : ''));

  svg.append('text')
    .attr('x', cx).attr('y', cy - 6)
    .attr('text-anchor', 'middle')
    .attr('font-family', 'Arial').attr('font-size', '11px')
    .attr('fill', '#7A7D81')
    .text(label);
}
```

### Heat Map

```javascript
function heatMap(containerId, data, { xLabels, yLabels, valueKey, xKey, yKey, format = ',.0f' }) {
  const cellSize = 56;
  const margin = { top: 60, right: 20, bottom: 20, left: 120 };
  const width = margin.left + xLabels.length * cellSize + margin.right;
  const height = margin.top + yLabels.length * cellSize + margin.bottom;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .style('width', '100%');

  const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

  const colorScale = d3.scaleSequential()
    .domain(d3.extent(data, d => d[valueKey]))
    .interpolator(t => d3.interpolateRgb('#CCDBFF', '#004BFF')(t));

  const x = d3.scaleBand().domain(xLabels).range([0, xLabels.length * cellSize]).padding(0.08);
  const y = d3.scaleBand().domain(yLabels).range([0, yLabels.length * cellSize]).padding(0.08);

  // Column headers
  g.selectAll('.x-label')
    .data(xLabels)
    .join('text')
    .attr('x', d => x(d) + x.bandwidth() / 2)
    .attr('y', -8)
    .attr('text-anchor', 'middle')
    .attr('font-family', 'Arial').attr('font-size', '11px').attr('font-weight', '600')
    .attr('fill', '#22272D')
    .text(d => d);

  // Row headers
  g.selectAll('.y-label')
    .data(yLabels)
    .join('text')
    .attr('x', -8)
    .attr('y', d => y(d) + y.bandwidth() / 2 + 4)
    .attr('text-anchor', 'end')
    .attr('font-family', 'Arial').attr('font-size', '11px')
    .attr('fill', '#22272D')
    .text(d => d);

  // Cells
  g.selectAll('.cell')
    .data(data)
    .join('rect')
    .attr('x', d => x(d[xKey]))
    .attr('y', d => y(d[yKey]))
    .attr('width', x.bandwidth())
    .attr('height', y.bandwidth())
    .attr('rx', 3)
    .attr('fill', d => colorScale(d[valueKey]))
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('stroke', AC.dark).attr('stroke-width', 2);
      showTip(event, `<strong>${d[yKey]} × ${d[xKey]}</strong><br>Value: ${d3.format(format)(d[valueKey])}`);
    })
    .on('mouseleave', function() {
      d3.select(this).attr('stroke', 'none');
      hideTip();
    });

  // Cell value labels
  g.selectAll('.cell-label')
    .data(data)
    .join('text')
    .attr('x', d => x(d[xKey]) + x.bandwidth() / 2)
    .attr('y', d => y(d[yKey]) + y.bandwidth() / 2 + 4)
    .attr('text-anchor', 'middle')
    .attr('font-family', 'Arial').attr('font-size', '11px').attr('font-weight', '600')
    .attr('fill', d => d[valueKey] > (d3.max(data, d => d[valueKey]) * 0.6) ? '#FFFFFF' : '#22272D')
    .text(d => d3.format(format)(d[valueKey]));
}
```

### Treemap

```javascript
function treemapChart(containerId, data, { valueKey, labelKey, parentKey, format = '$,.0f' }) {
  const width = 720, height = 420;
  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .style('width', '100%');

  const root = d3.hierarchy({ children: data }).sum(d => d[valueKey]);
  d3.treemap().size([width, height]).padding(2).round(true)(root);

  const color = d3.scaleOrdinal(AC_CATEGORICAL);

  const leaf = svg.selectAll('.leaf')
    .data(root.leaves())
    .join('g')
    .attr('transform', d => `translate(${d.x0},${d.y0})`);

  leaf.append('rect')
    .attr('width', d => d.x1 - d.x0)
    .attr('height', d => d.y1 - d.y0)
    .attr('rx', 3)
    .attr('fill', d => color(d.data[parentKey] || d.data[labelKey]))
    .attr('fill-opacity', 0.85)
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('fill-opacity', 1);
      showTip(event, `<strong>${d.data[labelKey]}</strong><br>${d3.format(format)(d.data[valueKey])}`);
    })
    .on('mouseleave', function() {
      d3.select(this).attr('fill-opacity', 0.85);
      hideTip();
    });

  leaf.append('text')
    .attr('x', 6).attr('y', 16)
    .attr('font-family', 'Arial').attr('font-size', '11px').attr('font-weight', '600')
    .attr('fill', '#FFFFFF')
    .text(d => {
      const w = d.x1 - d.x0;
      return w > 60 ? d.data[labelKey] : '';
    });
}
```

### Sankey Diagram (Referral / Flow Analysis)

```javascript
function sankeyChart(containerId, { nodes, links }, { width = 800, height = 500, format = ',.0f' } = {}) {
  const margin = { top: 20, right: 20, bottom: 20, left: 20 };
  const innerW = width - margin.left - margin.right;
  const innerH = height - margin.top - margin.bottom;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .style('width', '100%');

  const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

  const sankey = d3.sankey()
    .nodeWidth(18)
    .nodePadding(12)
    .nodeAlign(d3.sankeyJustify)
    .extent([[0, 0], [innerW, innerH]]);

  const graph = sankey({ nodes: nodes.map(d => ({ ...d })), links: links.map(d => ({ ...d })) });
  const color = d3.scaleOrdinal(AC_CATEGORICAL);

  // Links
  g.selectAll('.link')
    .data(graph.links)
    .join('path')
    .attr('class', 'link')
    .attr('d', d3.sankeyLinkHorizontal())
    .attr('fill', 'none')
    .attr('stroke', d => hexToRgba(color(d.source.name), 0.35))
    .attr('stroke-width', d => Math.max(1, d.width))
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('stroke', hexToRgba(color(d.source.name), 0.7));
      showTip(event, `${d.source.name} → ${d.target.name}<br><strong>${d3.format(format)(d.value)}</strong>`);
    })
    .on('mouseleave', function(event, d) {
      d3.select(this).attr('stroke', hexToRgba(color(d.source.name), 0.35));
      hideTip();
    });

  // Nodes
  const node = g.selectAll('.node')
    .data(graph.nodes)
    .join('g')
    .attr('transform', d => `translate(${d.x0},${d.y0})`);

  node.append('rect')
    .attr('width', sankey.nodeWidth())
    .attr('height', d => d.y1 - d.y0)
    .attr('rx', 2)
    .attr('fill', d => color(d.name));

  node.append('text')
    .attr('x', d => d.x0 < innerW / 2 ? sankey.nodeWidth() + 6 : -6)
    .attr('y', d => (d.y1 - d.y0) / 2)
    .attr('dy', '0.35em')
    .attr('text-anchor', d => d.x0 < innerW / 2 ? 'start' : 'end')
    .attr('font-family', 'Arial').attr('font-size', '11px').attr('font-weight', '600')
    .attr('fill', '#22272D')
    .text(d => d.name);
}
// Requires: <script src="https://unpkg.com/d3-sankey@0.12/dist/d3-sankey.min.js"></script>
```

### Chord Diagram (Payer–Service Relationships)

```javascript
function chordChart(containerId, matrix, labels, { width = 600, height = 600, format = ',.0f' } = {}) {
  const outerRadius = Math.min(width, height) / 2 - 40;
  const innerRadius = outerRadius - 24;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `${-width/2} ${-height/2} ${width} ${height}`)
    .style('width', '100%');

  const chord = d3.chord().padAngle(0.04).sortSubgroups(d3.descending);
  const chords = chord(matrix);
  const color = d3.scaleOrdinal(AC_CATEGORICAL);
  const arc = d3.arc().innerRadius(innerRadius).outerRadius(outerRadius);
  const ribbon = d3.ribbon().radius(innerRadius - 1);

  // Groups (arcs)
  const group = svg.selectAll('.group')
    .data(chords.groups)
    .join('g');

  group.append('path')
    .attr('d', arc)
    .attr('fill', d => color(labels[d.index]))
    .attr('stroke', '#FFFFFF')
    .attr('stroke-width', 1.5);

  group.append('text')
    .each(d => { d.angle = (d.startAngle + d.endAngle) / 2; })
    .attr('transform', d => `rotate(${d.angle * 180 / Math.PI - 90}) translate(${outerRadius + 8})${d.angle > Math.PI ? ' rotate(180)' : ''}`)
    .attr('text-anchor', d => d.angle > Math.PI ? 'end' : 'start')
    .attr('font-family', 'Arial').attr('font-size', '11px').attr('font-weight', '600')
    .attr('fill', '#22272D')
    .text(d => labels[d.index]);

  // Ribbons
  svg.selectAll('.ribbon')
    .data(chords)
    .join('path')
    .attr('d', ribbon)
    .attr('fill', d => hexToRgba(color(labels[d.source.index]), 0.55))
    .attr('stroke', d => hexToRgba(color(labels[d.source.index]), 0.15))
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('fill', hexToRgba(color(labels[d.source.index]), 0.85));
      showTip(event, `${labels[d.source.index]} ↔ ${labels[d.target.index]}<br><strong>${d3.format(format)(d.source.value)}</strong>`);
    })
    .on('mouseleave', function(event, d) {
      d3.select(this).attr('fill', hexToRgba(color(labels[d.source.index]), 0.55));
      hideTip();
    });
}
```

### Force-Directed Network (Physician Referral Network)

```javascript
function forceNetwork(containerId, { nodes, links }, { width = 800, height = 600, radiusKey = 'volume' } = {}) {
  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .style('width', '100%');

  const color = d3.scaleOrdinal(AC_CATEGORICAL);
  const radius = d3.scaleSqrt()
    .domain(d3.extent(nodes, d => d[radiusKey]))
    .range([5, 28]);

  const simulation = d3.forceSimulation(nodes)
    .force('link', d3.forceLink(links).id(d => d.id).distance(80))
    .force('charge', d3.forceManyBody().strength(-200))
    .force('center', d3.forceCenter(width / 2, height / 2))
    .force('collision', d3.forceCollide().radius(d => radius(d[radiusKey]) + 4));

  const link = svg.selectAll('.link')
    .data(links)
    .join('line')
    .attr('stroke', '#D3D4D5')
    .attr('stroke-width', d => Math.sqrt(d.value || 1))
    .attr('stroke-opacity', 0.6);

  const node = svg.selectAll('.node')
    .data(nodes)
    .join('circle')
    .attr('r', d => radius(d[radiusKey]))
    .attr('fill', d => color(d.group || d.type))
    .attr('fill-opacity', 0.8)
    .attr('stroke', '#FFFFFF')
    .attr('stroke-width', 2)
    .style('cursor', 'pointer')
    .call(d3.drag()
      .on('start', (event, d) => { if (!event.active) simulation.alphaTarget(0.3).restart(); d.fx = d.x; d.fy = d.y; })
      .on('drag', (event, d) => { d.fx = event.x; d.fy = event.y; })
      .on('end', (event, d) => { if (!event.active) simulation.alphaTarget(0); d.fx = null; d.fy = null; })
    )
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('fill-opacity', 1).attr('stroke-width', 3);
      showTip(event, `<strong>${d.name}</strong><br>${d.type || ''}<br>Volume: ${d[radiusKey]}`);
    })
    .on('mouseleave', function() {
      d3.select(this).attr('fill-opacity', 0.8).attr('stroke-width', 2);
      hideTip();
    });

  const label = svg.selectAll('.label')
    .data(nodes.filter(d => radius(d[radiusKey]) > 14))
    .join('text')
    .attr('text-anchor', 'middle')
    .attr('font-family', 'Arial').attr('font-size', '10px').attr('font-weight', '600')
    .attr('fill', '#FFFFFF')
    .attr('pointer-events', 'none')
    .text(d => d.name.split(' ').pop());

  simulation.on('tick', () => {
    link.attr('x1', d => d.source.x).attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x).attr('y2', d => d.target.y);
    node.attr('cx', d => d.x).attr('cy', d => d.y);
    label.attr('x', d => d.x).attr('y', d => d.y + 4);
  });
}
```

### Waterfall / Bridge Chart (Financial Variance)

```javascript
function waterfallChart(containerId, data, { format = '$,.0f', height = 380 } = {}) {
  const { g, innerW, innerH } = createChart(containerId, { width: 780, height, margin: { top: 30, right: 20, bottom: 60, left: 70 } });

  let cumulative = 0;
  const processed = data.map((d, i) => {
    const start = d.isTotal ? 0 : cumulative;
    const end = d.isTotal ? d.value : cumulative + d.value;
    cumulative = end;
    return { ...d, start: Math.min(start, end), end: Math.max(start, end), isNeg: d.value < 0 };
  });

  const x = d3.scaleBand().domain(data.map(d => d.label)).range([0, innerW]).padding(0.3);
  const y = d3.scaleLinear()
    .domain([0, d3.max(processed, d => d.end) * 1.1])
    .range([innerH, 0]);

  acAxis(g, x, 'bottom', { innerW, innerH });
  acAxis(g, y, 'left', { format: d3.format(format), innerW, innerH });

  // Connector lines
  processed.forEach((d, i) => {
    if (i < processed.length - 1 && !d.isTotal) {
      g.append('line')
        .attr('x1', x(d.label) + x.bandwidth())
        .attr('x2', x(processed[i+1].label))
        .attr('y1', y(cumulative - (processed[i+1].isTotal ? 0 : processed[i+1].value) + (processed[i+1].value >= 0 ? 0 : processed[i+1].value)))
        .attr('y2', y(cumulative - (processed[i+1].isTotal ? 0 : processed[i+1].value) + (processed[i+1].value >= 0 ? 0 : processed[i+1].value)))
        .attr('stroke', AC.gray)
        .attr('stroke-dasharray', '3,2')
        .attr('stroke-width', 1);
    }
  });

  // Bars
  g.selectAll('.bar')
    .data(processed)
    .join('rect')
    .attr('x', d => x(d.label))
    .attr('y', d => y(d.end))
    .attr('width', x.bandwidth())
    .attr('height', d => Math.abs(y(d.start) - y(d.end)))
    .attr('rx', 2)
    .attr('fill', d => d.isTotal ? AC.deepBlue : d.isNeg ? AC.red : AC.green)
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      showTip(event, `<strong>${d.label}</strong><br>${d3.format(format)(d.value)}`);
    })
    .on('mouseleave', hideTip);

  // Value labels
  g.selectAll('.val-label')
    .data(processed)
    .join('text')
    .attr('x', d => x(d.label) + x.bandwidth() / 2)
    .attr('y', d => y(d.end) - 6)
    .attr('text-anchor', 'middle')
    .attr('font-family', 'Arial').attr('font-size', '11px').attr('font-weight', '700')
    .attr('fill', AC.dark)
    .text(d => d3.format(format)(d.value));
}
```

### Geographic Choropleth (US State Map)

```javascript
async function choroplethUS(containerId, stateData, { valueKey, labelKey = 'state', format = ',.0f', title = '' }) {
  const width = 960, height = 600;
  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .style('width', '100%');

  const us = await d3.json('https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json');
  const states = topojson.feature(us, us.objects.states).features;

  const projection = d3.geoAlbersUsa().fitSize([width - 40, height - 80], { type: 'FeatureCollection', features: states });
  const path = d3.geoPath().projection(projection);

  const dataMap = new Map(stateData.map(d => [d[labelKey], d[valueKey]]));
  const extent = d3.extent(stateData, d => d[valueKey]);

  const colorScale = d3.scaleSequential()
    .domain(extent)
    .interpolator(t => d3.interpolateRgb('#CCDBFF', '#004BFF')(t));

  svg.selectAll('.state')
    .data(states)
    .join('path')
    .attr('d', path)
    .attr('fill', d => {
      const val = dataMap.get(d.properties.name);
      return val != null ? colorScale(val) : '#E8E9EA';
    })
    .attr('stroke', '#FFFFFF')
    .attr('stroke-width', 1)
    .style('cursor', 'pointer')
    .on('mouseenter', function(event, d) {
      d3.select(this).attr('stroke', AC.dark).attr('stroke-width', 2);
      const val = dataMap.get(d.properties.name);
      showTip(event, `<strong>${d.properties.name}</strong><br>${val != null ? d3.format(format)(val) : 'No data'}`);
    })
    .on('mouseleave', function() {
      d3.select(this).attr('stroke', '#FFFFFF').attr('stroke-width', 1);
      hideTip();
    });

  if (title) {
    svg.append('text')
      .attr('x', width / 2).attr('y', 24)
      .attr('text-anchor', 'middle')
      .attr('font-family', 'Arial').attr('font-size', '16px').attr('font-weight', '700')
      .attr('fill', AC.dark)
      .text(title);
  }
}
// Requires: <script src="https://unpkg.com/topojson-client@3"></script>
```

---

## Number Formatting Standards

| Data Type | Chart Format | Prose Format | Example |
|---|---|---|---|
| Currency (large) | `$1.2M` | "$1.2 million" | Revenue |
| Currency (exact) | `$12,345` | "$12,345" | Line item |
| Percentages | `45.2%` | "45.2 percent" | Rate metrics |
| wRVUs | `4,521.00` (2 decimals) | "4,521 wRVUs" | Physician productivity |
| $/wRVU | `$52.30` | "$52.30 per wRVU" | Compensation rate |
| Counts | `1,234` | "1,234 encounters" | Volumes |
| Delta (positive) | `+12.3%` with green | "an increase of 12.3 percent" | YoY change |
| Delta (negative) | `-8.1%` with red | "a decrease of 8.1 percent" | YoY change |

---

## Axis & Label Rules

1. Y-axis labels always left-aligned, rotated -90 degrees
2. X-axis labels below, centered under tick marks
3. Remove axis domain lines (`.domain { display: none }`)
4. Grid lines are `#E8E9EA`, dashed on Y-axis, hidden on X-axis
5. Benchmark/target lines always dashed (`stroke-dasharray: 6,4`), amber (`#F4B73F`), labeled at right end
6. Never rotate X-axis labels more than 45 degrees — if labels are too long, use a horizontal bar chart instead
7. Maximum 8 tick marks on any axis

---

## Interaction Patterns

| Interaction | Implementation |
|---|---|
| Hover highlight | Increase opacity to 1, add 2px stroke, show tooltip |
| Hover dim | Reduce all non-hovered elements to 0.3 opacity |
| Click filter | Filter dataset and re-render with transition |
| Brush select | `d3.brushX()` for time-range selection |
| Zoom | `d3.zoom()` for scatter and geographic charts only |
| Drag | `d3.drag()` for force-directed layouts only |

### Hover Dim CSS

```css
.chart-group:hover .chart-element { opacity: 0.3; transition: opacity 200ms; }
.chart-group:hover .chart-element:hover { opacity: 1; }
```

---

## Accessibility for Data Visualizations

| Requirement | Implementation |
|---|---|
| SVG role | `<svg role="img" aria-label="Chart description">` |
| Alt text | Every chart SVG needs a descriptive `aria-label` |
| Color + pattern | Do not rely on color alone — add patterns, labels, or texture |
| Focus management | Interactive charts should support keyboard tab navigation |
| Screen reader text | Add hidden `<desc>` element inside SVG with data summary |
| Reduced motion | Respect `prefers-reduced-motion: reduce` — disable transitions |

```css
@media (prefers-reduced-motion: reduce) {
  * { transition: none !important; animation: none !important; }
}
```

---

*Acuvance Coker Design System v2.0 — 04_DATA_VISUALIZATION.md*
