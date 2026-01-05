import { check } from 'k6';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Generate a random UUID v4
export function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Generate a random ISO timestamp within the last hour
export function generateTimestamp() {
  const now = Date.now();
  const randomOffset = randomIntBetween(0, 3600000); // 0 to 1 hour in ms
  return new Date(now - randomOffset).toISOString();
}

// Generate a readings payload for POST /readings
export function generateReadingsPayload(deviceId, readingCount = null) {
  const count = readingCount || randomIntBetween(1, 10);
  const readings = [];

  for (let i = 0; i < count; i++) {
    readings.push({
      timestamp: generateTimestamp(),
      count: randomIntBetween(1, 100)
    });
  }

  return {
    id: deviceId || generateUUID(),
    readings: readings
  };
}

// Validate POST /readings response
export function checkReadingsResponse(response) {
  return check(response, {
    'readings: status is 200': (r) => r.status === 200,
    'readings: response has success': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.success === true;
      } catch (e) {
        return false;
      }
    }
  });
}

// Validate GET /devices/:id/latest_timestamp response
export function checkLatestTimestampResponse(response, expectFound = true) {
  if (expectFound) {
    return check(response, {
      'latest_timestamp: status is 200': (r) => r.status === 200,
      'latest_timestamp: has timestamp': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.latest_timestamp !== undefined;
        } catch (e) {
          return false;
        }
      }
    });
  } else {
    return check(response, {
      'latest_timestamp: status is 404': (r) => r.status === 404
    });
  }
}

// Validate GET /devices/:id/total_count response
export function checkTotalCountResponse(response, expectFound = true) {
  if (expectFound) {
    return check(response, {
      'total_count: status is 200': (r) => r.status === 200,
      'total_count: has count': (r) => {
        try {
          const body = JSON.parse(r.body);
          return typeof body.total_count === 'number';
        } catch (e) {
          return false;
        }
      }
    });
  } else {
    return check(response, {
      'total_count: status is 404': (r) => r.status === 404
    });
  }
}

// Get load profile configuration based on PROFILE env var
export function getLoadProfile() {
  const profile = __ENV.PROFILE || 'moderate';

  const profiles = {
    light: {
      stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 50 },
        { duration: '30s', target: 0 }
      ],
      thresholds: {
        http_req_duration: ['p(95)<500'],
        http_req_failed: ['rate<0.05']
      }
    },
    moderate: {
      stages: [
        { duration: '1m', target: 50 },
        { duration: '2m', target: 200 },
        { duration: '30s', target: 0 }
      ],
      thresholds: {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.05']
      }
    },
    heavy: {
      stages: [
        { duration: '1m', target: 100 },
        { duration: '3m', target: 500 },
        { duration: '1m', target: 0 }
      ],
      thresholds: {
        http_req_duration: ['p(95)<2000'],
        http_req_failed: ['rate<0.10']
      }
    }
  };

  return profiles[profile] || profiles.moderate;
}

// Get base URL from env or default
export function getBaseUrl() {
  return __ENV.BASE_URL || 'http://localhost:3000';
}

// Common HTTP headers for JSON requests
export const jsonHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
};
