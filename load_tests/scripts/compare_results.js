#!/usr/bin/env node

/**
 * compare_results.js - Parse k6 JSON output and display comparison table
 *
 * Usage: node scripts/compare_results.js results/
 */

const fs = require('fs');
const path = require('path');

const resultsDir = process.argv[2] || 'results';

// Metrics we want to extract
const METRICS = {
  'http_reqs': { label: 'Total Requests', format: 'count' },
  'http_req_duration': { label: 'Avg Latency (ms)', format: 'duration', stat: 'avg' },
  'http_req_duration_p95': { label: 'p95 Latency (ms)', format: 'duration' },
  'http_req_duration_p99': { label: 'p99 Latency (ms)', format: 'duration' },
  'http_req_failed': { label: 'Error Rate', format: 'rate' },
  'iterations': { label: 'Iterations', format: 'count' }
};

function parseK6Json(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.trim().split('\n');

  const metrics = {};
  let testDuration = 0;

  for (const line of lines) {
    try {
      const data = JSON.parse(line);

      if (data.type === 'Metric' && data.data) {
        const name = data.data.name;
        const metricData = data.data;

        if (name === 'http_reqs') {
          metrics['http_reqs'] = metricData.value || 0;
        } else if (name === 'http_req_duration') {
          metrics['http_req_duration'] = metricData.value || 0;
        } else if (name === 'http_req_failed') {
          metrics['http_req_failed'] = metricData.value || 0;
        } else if (name === 'iterations') {
          metrics['iterations'] = metricData.value || 0;
        }
      }

      // Extract point data for aggregation
      if (data.type === 'Point' && data.data) {
        const name = data.metric;
        const value = data.data.value;

        if (!metrics[`${name}_values`]) {
          metrics[`${name}_values`] = [];
        }
        metrics[`${name}_values`].push(value);
      }

    } catch (e) {
      // Skip malformed lines
    }
  }

  // Calculate aggregates from point data
  if (metrics['http_req_duration_values']) {
    const values = metrics['http_req_duration_values'].sort((a, b) => a - b);
    const len = values.length;

    if (len > 0) {
      metrics['http_req_duration'] = values.reduce((a, b) => a + b, 0) / len;
      metrics['http_req_duration_p95'] = values[Math.floor(len * 0.95)] || 0;
      metrics['http_req_duration_p99'] = values[Math.floor(len * 0.99)] || 0;
      metrics['http_reqs'] = len;
    }
  }

  if (metrics['http_req_failed_values']) {
    const failed = metrics['http_req_failed_values'].filter(v => v > 0).length;
    const total = metrics['http_req_failed_values'].length;
    metrics['http_req_failed'] = total > 0 ? (failed / total) * 100 : 0;
  }

  if (metrics['iteration_duration_values']) {
    metrics['iterations'] = metrics['iteration_duration_values'].length;
  }

  return metrics;
}

function formatValue(value, format) {
  if (value === undefined || value === null) {
    return '-';
  }

  switch (format) {
    case 'count':
      return value.toLocaleString();
    case 'duration':
      return value.toFixed(2);
    case 'rate':
      return `${value.toFixed(2)}%`;
    default:
      return String(value);
  }
}

function printComparison(results) {
  const apis = Object.keys(results);

  if (apis.length === 0) {
    console.log('No results found.');
    return;
  }

  // Calculate column widths
  const labelWidth = 18;
  const colWidth = 12;

  // Header
  console.log('\n=== API Performance Comparison ===\n');

  // Column headers
  let header = 'Metric'.padEnd(labelWidth);
  for (const api of apis) {
    header += api.charAt(0).toUpperCase() + api.slice(1);
    header = header.padEnd(header.length + (colWidth - api.length - 1));
  }
  console.log(header);
  console.log('─'.repeat(labelWidth + apis.length * colWidth));

  // Metric rows
  const metricsToShow = [
    { key: 'http_reqs', label: 'Total Requests', format: 'count' },
    { key: 'http_req_duration', label: 'Avg Latency (ms)', format: 'duration' },
    { key: 'http_req_duration_p95', label: 'p95 Latency (ms)', format: 'duration' },
    { key: 'http_req_duration_p99', label: 'p99 Latency (ms)', format: 'duration' },
    { key: 'http_req_failed', label: 'Error Rate', format: 'rate' }
  ];

  for (const metric of metricsToShow) {
    let row = metric.label.padEnd(labelWidth);

    // Find best value for highlighting
    const values = apis.map(api => results[api][metric.key] || 0);
    const isBetterLower = metric.key !== 'http_reqs';
    const bestValue = isBetterLower ? Math.min(...values) : Math.max(...values);

    for (const api of apis) {
      const value = results[api][metric.key];
      const formatted = formatValue(value, metric.format);
      row += formatted.padStart(colWidth);
    }

    console.log(row);
  }

  console.log('─'.repeat(labelWidth + apis.length * colWidth));

  // Calculate requests per second
  let rpsRow = 'Req/sec (approx)'.padEnd(labelWidth);
  for (const api of apis) {
    // Estimate based on typical test duration
    const reqs = results[api]['http_reqs'] || 0;
    // Rough estimate: assume 3 minute test
    const rps = Math.round(reqs / 180);
    rpsRow += String(rps.toLocaleString()).padStart(colWidth);
  }
  console.log(rpsRow);

  console.log('\n');
}

// Main execution
try {
  const files = fs.readdirSync(resultsDir).filter(f => f.endsWith('.json'));

  if (files.length === 0) {
    console.log('No JSON result files found in', resultsDir);
    process.exit(1);
  }

  const results = {};

  for (const file of files) {
    const apiName = path.basename(file, '.json');
    const filePath = path.join(resultsDir, file);

    try {
      results[apiName] = parseK6Json(filePath);
    } catch (e) {
      console.error(`Error parsing ${file}:`, e.message);
    }
  }

  printComparison(results);

} catch (e) {
  console.error('Error:', e.message);
  process.exit(1);
}
