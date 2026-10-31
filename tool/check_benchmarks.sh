#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Run after build_workers.sh. These tiny workloads check the benchmark protocol
# and baseline comparison; timings are deliberately not used as CI gates.
node tool/benchmark_workers.mjs --pattern glider,random --random-size 16 \
  --exponent 2 --jumps 3 --output build/benchmarks/ci-smoke.json
node tool/benchmark_workers.mjs --pattern glider,random --random-size 16 \
  --exponent 2 --jumps 3 --baseline build/benchmarks/ci-smoke.json \
  --output build/benchmarks/ci-repeat.json
