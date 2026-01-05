/**
 * Mixed Workload Test - Combined Read/Write Operations
 *
 * Simulates realistic production traffic with 70% reads and 30% writes.
 * Maintains a pool of known device IDs to query while continuously adding new data.
 *
 * Usage:
 *   k6 run -e BASE_URL=http://localhost:3000 scripts/mixed_workload.js
 *   k6 run -e BASE_URL=http://localhost:3000 -e PROFILE=heavy scripts/mixed_workload.js
 */

import http from 'k6/http';
import { sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { Counter } from 'k6/metrics';
import {
  generateUUID,
  generateReadingsPayload,
  checkReadingsResponse,
  checkLatestTimestampResponse,
  checkTotalCountResponse,
  getLoadProfile,
  getBaseUrl,
  jsonHeaders
} from '../lib/helpers.js';

const profile = getLoadProfile();

// Custom metrics to track operation types
const writeOps = new Counter('write_operations');
const readOps = new Counter('read_operations');

// Pre-generate device IDs for consistent querying
const seedDeviceIds = new SharedArray('seedDeviceIds', function() {
  const ids = [];
  for (let i = 0; i < 50; i++) {
    ids.push(generateUUID());
  }
  return ids;
});

export const options = {
  stages: profile.stages,
  thresholds: {
    ...profile.thresholds,
    'write_operations': ['count>0'],
    'read_operations': ['count>0']
  }
};

// Setup: seed some initial devices
export function setup() {
  const baseUrl = getBaseUrl();

  console.log('Seeding initial devices...');

  for (const deviceId of seedDeviceIds) {
    const payload = generateReadingsPayload(deviceId, 3);
    http.post(
      `${baseUrl}/readings`,
      JSON.stringify(payload),
      { headers: jsonHeaders }
    );
  }

  console.log(`Seeded ${seedDeviceIds.length} devices.`);
  return {};
}

export default function() {
  const baseUrl = getBaseUrl();
  const rand = Math.random();

  if (rand < 0.30) {
    // 30% writes - POST /readings
    // Mix of new devices and updates to existing devices
    const useExisting = Math.random() < 0.5;
    const deviceId = useExisting
      ? seedDeviceIds[Math.floor(Math.random() * seedDeviceIds.length)]
      : generateUUID();

    const payload = generateReadingsPayload(deviceId);
    const response = http.post(
      `${baseUrl}/readings`,
      JSON.stringify(payload),
      { headers: jsonHeaders }
    );

    checkReadingsResponse(response);
    writeOps.add(1);

  } else if (rand < 0.65) {
    // 35% reads - GET latest_timestamp
    const deviceId = seedDeviceIds[Math.floor(Math.random() * seedDeviceIds.length)];
    const response = http.get(
      `${baseUrl}/devices/${deviceId}/latest_timestamp`,
      { headers: jsonHeaders }
    );

    checkLatestTimestampResponse(response, true);
    readOps.add(1);

  } else {
    // 35% reads - GET total_count
    const deviceId = seedDeviceIds[Math.floor(Math.random() * seedDeviceIds.length)];
    const response = http.get(
      `${baseUrl}/devices/${deviceId}/total_count`,
      { headers: jsonHeaders }
    );

    checkTotalCountResponse(response, true);
    readOps.add(1);
  }

  sleep(0.1);
}
