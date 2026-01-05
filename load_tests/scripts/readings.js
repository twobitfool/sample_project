/**
 * Write Performance Test - POST /readings
 *
 * Tests the API's ability to handle device reading submissions under load.
 * Each virtual user continuously posts new device readings.
 *
 * Usage:
 *   k6 run -e BASE_URL=http://localhost:3000 scripts/readings.js
 *   k6 run -e BASE_URL=http://localhost:3000 -e PROFILE=heavy scripts/readings.js
 */

import http from 'k6/http';
import { sleep } from 'k6';
import {
  generateReadingsPayload,
  checkReadingsResponse,
  getLoadProfile,
  getBaseUrl,
  jsonHeaders
} from '../lib/helpers.js';

const profile = getLoadProfile();

export const options = {
  stages: profile.stages,
  thresholds: profile.thresholds
};

export default function() {
  const baseUrl = getBaseUrl();
  const payload = generateReadingsPayload();

  const response = http.post(
    `${baseUrl}/readings`,
    JSON.stringify(payload),
    { headers: jsonHeaders }
  );

  checkReadingsResponse(response);

  // Small pause between requests to simulate realistic traffic
  sleep(0.1);
}
