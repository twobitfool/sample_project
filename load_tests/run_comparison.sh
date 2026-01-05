#!/bin/bash

# run_comparison.sh - Run k6 load tests against all API implementations
#
# Usage:
#   ./run_comparison.sh                           # Run mixed_workload with moderate profile
#   ./run_comparison.sh readings.js               # Run specific test
#   ./run_comparison.sh mixed_workload.js light   # Run with specific profile
#   ./run_comparison.sh mixed_workload.js heavy   # Run stress test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
TEST_SCRIPT="${1:-scripts/mixed_workload.js}"
PROFILE="${2:-moderate}"
RESULTS_DIR="results"

# API configurations: name:port
# Port order matches bin/dev alphabetical sort of *_api directories
APIS=(
  "express:3000"
  "rails:3001"
  "ruby:3002"
  "sinatra:3003"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  k6 API Performance Comparison${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "Test script: ${YELLOW}${TEST_SCRIPT}${NC}"
echo -e "Profile:     ${YELLOW}${PROFILE}${NC}"
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
  echo -e "${RED}Error: k6 is not installed.${NC}"
  echo "Install with: brew install k6"
  exit 1
fi

# Create results directory
mkdir -p "$RESULTS_DIR"

# Clean old results
rm -f "$RESULTS_DIR"/*.json

# Function to check if an API is running
check_api() {
  local port=$1
  curl -s -o /dev/null -w "%{http_code}" "http://localhost:${port}/ping" 2>/dev/null
}

# Verify APIs are running
echo -e "${YELLOW}Checking API availability...${NC}"
AVAILABLE_APIS=()
for api in "${APIS[@]}"; do
  name="${api%%:*}"
  port="${api##*:}"

  status=$(check_api "$port")
  if [ "$status" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} ${name} (port ${port}) - available"
    AVAILABLE_APIS+=("$api")
  else
    echo -e "  ${RED}✗${NC} ${name} (port ${port}) - not running"
  fi
done
echo ""

if [ ${#AVAILABLE_APIS[@]} -eq 0 ]; then
  echo -e "${RED}Error: No APIs are running.${NC}"
  echo "Start the APIs with: cd .. && bin/dev"
  exit 1
fi

# Run tests against each available API
for api in "${AVAILABLE_APIS[@]}"; do
  name="${api%%:*}"
  port="${api##*:}"

  echo -e "${BLUE}Testing ${name} API on port ${port}...${NC}"
  echo "----------------------------------------"

  k6 run \
    --out json="$RESULTS_DIR/${name}.json" \
    -e BASE_URL="http://localhost:$port" \
    -e PROFILE="$PROFILE" \
    "$TEST_SCRIPT" 2>&1 | tail -20

  echo ""
done

# Generate comparison summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Generating Comparison Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

if command -v node &> /dev/null; then
  node scripts/compare_results.js "$RESULTS_DIR"
else
  echo -e "${YELLOW}Node.js not found. Skipping comparison summary.${NC}"
  echo "Results are available in: $RESULTS_DIR/"
fi
