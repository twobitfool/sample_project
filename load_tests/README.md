# Load Testing with k6

Performance benchmarking suite for comparing the four API implementations.

## Prerequisites

- **k6** - Install with `brew install k6` (macOS) or see [k6.io/docs/get-started/installation](https://k6.io/docs/get-started/installation/)
- **Node.js** - Required for the comparison summary script
- **APIs running** - Start all APIs with `bin/dev` from the project root

## Quick Start

```bash
# Start all APIs (from project root)
cd .. && bin/dev

# In another terminal, run the comparison
cd load_tests
./run_comparison.sh
```

## Test Scripts

| Script | Description |
|--------|-------------|
| `scripts/readings.js` | Write performance - POST /readings |
| `scripts/device_queries.js` | Read performance - GET endpoints |
| `scripts/mixed_workload.js` | Combined 70% reads / 30% writes |

## Load Profiles

Set via the `PROFILE` environment variable or second argument:

| Profile | Virtual Users | Duration |
|---------|---------------|----------|
| `light` | 10 → 50 | ~2 min |
| `moderate` | 50 → 200 | ~3.5 min |
| `heavy` | 100 → 500 | ~5 min |

## Usage

### Run Full Comparison

```bash
# Default: mixed_workload with moderate profile
./run_comparison.sh

# Specific test script
./run_comparison.sh scripts/readings.js

# Specific profile
./run_comparison.sh scripts/mixed_workload.js light
./run_comparison.sh scripts/mixed_workload.js heavy
```

### Run Against Single API

```bash
# Test Rails API only
k6 run -e BASE_URL=http://localhost:3000 scripts/mixed_workload.js

# Test Express API with heavy load
k6 run -e BASE_URL=http://localhost:3002 -e PROFILE=heavy scripts/readings.js
```

### Export Results

```bash
# JSON output
k6 run --out json=results/rails.json -e BASE_URL=http://localhost:3000 scripts/mixed_workload.js

# CSV output
k6 run --out csv=results/rails.csv -e BASE_URL=http://localhost:3000 scripts/mixed_workload.js
```

## API Ports

| API | Port |
|-----|------|
| Rails | 3000 |
| Sinatra | 3001 |
| Express | 3002 |
| Ruby | 3003 |

## Interpreting Results

### Key Metrics

- **Total Requests** - Higher is better (throughput)
- **Avg/p95/p99 Latency** - Lower is better (response time)
- **Error Rate** - Lower is better (should be near 0%)
- **Req/sec** - Higher is better (throughput)

### Expected Characteristics

| API | Notes |
|-----|-------|
| **Rails** | Uses SQLite (disk I/O); full framework overhead |
| **Sinatra** | Lightweight Ruby; in-memory storage |
| **Express** | Node.js event loop; efficient async I/O |
| **Ruby** | WEBrick is single-threaded; educational only |

## Troubleshooting

### "k6 is not installed"

```bash
# macOS
brew install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

### "No APIs are running"

Start the APIs from the project root:

```bash
cd /path/to/sample_project
bin/dev
```

### High Error Rates

- Reduce load profile (`light` instead of `moderate`)
- Check API logs for errors
- Ensure database is set up for Rails (`cd rails_api && bin/setup`)

## File Structure

```
load_tests/
├── lib/
│   └── helpers.js           # Shared utilities
├── scripts/
│   ├── readings.js          # Write performance test
│   ├── device_queries.js    # Read performance test
│   ├── mixed_workload.js    # Combined workload
│   └── compare_results.js   # Results parser
├── results/                 # JSON output (gitignored)
├── run_comparison.sh        # Main runner script
└── README.md
```

## Latest Results

As of Jan 5, 2025 (commit 93f0be0)

| Metric         | Express | Ruby   | Sinatra | Rails (in-mem db)  | Rails (on-disk db)  |
|----------------|---------|--------|---------|--------------------|---------------------|
| Total Requests | 26,459  | 26,283 | 26,048  |      11,772        |        9,368        |
| Avg Latency    | 1.07ms  | 1.82ms | 2.64ms  |      128ms         |        187ms        |
| p95 Latency    | 1.93ms  | 5.59ms | 7.84ms  |      293ms         |        442ms        |
| p99 Latency    | 3.11ms  | 9.35ms | 19.35ms |      353ms         |        525ms        |
| Error Rate     | 0.00%   | 0.00%  | 0.00%   |      23.45%        |        0.00%        |
| Req/sec        | ~220    | ~219   | ~217    |      ~97           |        ~77          |

### Rails Performance
- Rails (with the in-memory database) has a 23% error rate!
- Switching to a standard on-disk SQLite database fixes the errors but degrades performance.
- Using the in-memory storage classes results in similar performance to Sinatra and Ruby.


### Performance Rankings

1. Express (Node.js) - Fastest, async I/O shines
2. Ruby/WEBrick - Surprisingly good for single-threaded
3. Sinatra - Solid performance with in-memory storage
4. Rails - SQLite is the bottleneck, not the framework itself

The in-memory storage implementations (Express, Ruby, Sinatra) all handled ~26k requests flawlessly. Rails with SQLite could only manage ~12k with significant errors.
