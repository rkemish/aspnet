import http from 'k6/http';
import { check, sleep } from 'k6';

// ──────────────────────────────────────────────
// k6 Load Test for ASP.NET Core App
// ──────────────────────────────────────────────
// Target URL is passed via K6_TARGET_URL environment variable.
// Ramps from 50 → 100 → 200 VUs with a cool-down period.

const BASE_URL = __ENV.K6_TARGET_URL || 'https://localhost:5001';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // ramp up to 50 VUs
    { duration: '3m', target: 50 },   // hold at 50 VUs
    { duration: '1m', target: 100 },  // ramp up to 100 VUs
    { duration: '3m', target: 100 },  // hold at 100 VUs
    { duration: '1m', target: 200 },  // ramp up to 200 VUs
    { duration: '3m', target: 200 },  // hold at 200 VUs
    { duration: '2m', target: 0 },    // cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95th percentile response time < 500ms
    http_req_failed: ['rate<0.01'],    // error rate < 1%
  },
};

export default function () {
  // Test homepage
  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, {
    'homepage status is 200': (r) => r.status === 200,
    'homepage response time < 1s': (r) => r.timings.duration < 1000,
  });

  sleep(1);

  // Test privacy page
  const privacyRes = http.get(`${BASE_URL}/Home/Privacy`);
  check(privacyRes, {
    'privacy status is 200': (r) => r.status === 200,
    'privacy response time < 1s': (r) => r.timings.duration < 1000,
  });

  sleep(1);
}
