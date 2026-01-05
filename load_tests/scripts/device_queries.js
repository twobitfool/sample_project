/**
 * Read Performance Test - GET /devices/:id/latest_timestamp and /devices/:id/total_count
 *
 * Tests the API's ability to handle device queries under load.
 * Pre-populates devices in setup phase, then queries them during the test.
 *
 * Usage:
 *   k6 run -e BASE_URL=http://localhost:3000 scripts/device_queries.js
 *   k6 run -e BASE_URL=http://localhost:3000 -e PROFILE=heavy scripts/device_queries.js
 */

import http from 'k6/http';
import { sleep } from 'k6';
import { SharedArray } from 'k6/data';
import {
  generateUUID,
  generateReadingsPayload,
  checkLatestTimestampResponse,
  checkTotalCountResponse,
  getLoadProfile,
  getBaseUrl,
  jsonHeaders
} from '../lib/helpers.js';

const profile = getLoadProfile();

// Pre-generate device IDs to use during the test
const deviceIds = new SharedArray('deviceIds', function() {
  const ids = [];
  for (let i = 0; i < 100; i++) {
    ids.push(generateUUID());
  }
  return ids;
});

export const options = {
  stages: profile.stages,
  thresholds: profile.thresholds
};

// Setup phase: populate devices with readings
export function setup() {
  const baseUrl = getBaseUrl();

  console.log(`Setting up ${deviceIds.length} devices with readings...`);

  for (const deviceId of deviceIds) {
    const payload = generateReadingsPayload(deviceId, 5);
    http.post(
      `${baseUrl}/readings`,
      JSON.stringify(payload),
      { headers: jsonHeaders }
    );
  }

  console.log('Setup complete.');
  return { deviceIds: deviceIds };
}

export default function(data) {
  const baseUrl = getBaseUrl();

  // Pick a random device from our pre-populated list
  const deviceId = deviceIds[Math.floor(Math.random() * deviceIds.length)];

  // Alternate between latest_timestamp and total_count queries
  if (Math.random() < 0.5) {
    const response = http.get(
      `${baseUrl}/devices/${deviceId}/latest_timestamp`,
      { headers: jsonHeaders }
    );
    checkLatestTimestampResponse(response, true);
  } else {
    const response = http.get(
      `${baseUrl}/devices/${deviceId}/total_count`,
      { headers: jsonHeaders }
    );
    checkTotalCountResponse(response, true);
  }

  sleep(0.1);
}
