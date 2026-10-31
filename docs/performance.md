# Reproducible worker benchmarks

See [the first measured optimization and recorded results](performance-results.md)
and [upstream Golly/lifelib benchmarking research](performance-research.md).

Use Node 24+ and the project's Dart SDK to build and benchmark the exact JavaScript and Wasm simulation workers used by the app:

```sh
bash tool/build_workers.sh
node tool/benchmark_workers.mjs --output build/benchmarks/before.json
```

The default workload is the published three-digit hexadecimal counter, with four consecutive jumps of 32,768 generations in one fresh worker for each target. Use `--jumps 32 --samples 3` for a longer comparison reaching generation 1,048,576, matching the reported slow counter run. That full run can take several minutes. Each sample loads once and advances forward; it never restores an earlier state to replay a cached answer. There is no discarded warm-up. First-jump and final-quarter timings are reported separately so cache growth and later slowdowns remain visible.

The Node harness executes `web/workers/life_worker_bootstrap.js` with a small browser messaging/fetch shim. It exercises the production worker binaries, viewport extraction, serialization, and transferred frame data. It does not measure Flutter rendering, requestAnimationFrame, browser scheduling, or mobile performance. Keep browser profiling separate when those are the bottleneck. Rebuild after every engine change; the artifact records generated worker SHA-256 hashes, Git revision/dirty status, and runtime/machine information. Use `--worker-dir /path/to/preserved/workers` to measure a previous build without swapping source files; preserve the bootstrap and all generated worker files together. Worker-directory paths and binary hashes may differ between baseline and candidate.

## Workloads and repeatability

```sh
# A short run while investigating; keep these options identical for comparisons.
node tool/benchmark_workers.mjs --target wasm --jumps 8 --samples 1 --output build/benchmarks/quick.json

# Repeated circuitry, a computing construction, and an OTCA metapixel world.
node tool/benchmark_workers.mjs --pattern hexadecimal-counter,pi-calculator,metapixel-galaxy --output build/benchmarks/suite.json

# Less repetitive activity, generated with a fixed xorshift32 seed in the driver.
node tool/benchmark_workers.mjs --pattern random --random-size 128 --seed 42 --density 0.25 --exponent 8 --jumps 16 --samples 3

# Small protocol/profile smoke check.
node tool/benchmark_workers.mjs --pattern glider --exponent 2 --jumps 2 --samples 1
```

Other bundled fixtures are `demonoid` and `metapixel-p216-gun`; a path to a `.mc` file is also accepted. Fixture hashes identify the exact input. The seeded random workload is generated once as explicit coordinates and sent to both targets, avoiding differences between random generators in different runtimes. Random soup is useful as a different cache workload, but does not predict the performance of repetitive circuitry.

The default viewport covers the initial macrocell root at about 512 tiles per side and remains fixed during evolution. To reproduce a particular view, pass `--view left,top,right,bottom,minimumSize`, for example `--view 0,0,32768,32768,64`. The worker may impose its usual minimum detail for large views. Viewport work affects round-trip timing, so keep it fixed across comparisons.

Every artifact contains raw per-jump rows, per-sample and combined median/p95/min/max timings, initial load/startup costs, generations, population, node counts, and any available result-cache/collection statistics. `simulationUs` is the worker's command stopwatch, excluding viewport extraction. `roundTripUs` includes simulation, viewport extraction, message serialization/transfer, and scheduling. Their difference is `otherUs`; it is not a pure rendering measurement. Different timer precision can make this difference slightly negative for very short commands. SHA-256 signatures cover sorted viewport `(x, y, size, density)` tuples plus generation and population. They must agree across fresh samples, JS/Wasm targets, and a supplied baseline. Aggregated viewport signatures are a regression signal, not a proof of every cell's correctness; retain the engine's exact-state tests.

Pass `--memory` to sample `process.memoryUsage()` inside the worker after loading and each jump, outside the timed command. Rows then include worker V8 heap used/total, external, and ArrayBuffer bytes. These are partial Node/V8 memory measurements, not total Wasm memory, browser tab memory, or peak allocation during a jump. The harness deliberately omits process-wide RSS, which cannot be attributed to one worker. Use the same flag for both baseline and candidate.

## Comparing a change

```sh
# Capture before changing the engine.
node tool/benchmark_workers.mjs --target wasm --jumps 32 --samples 3 --output build/benchmarks/before.json

# After changing the engine, rebuild and repeat the identical workload.
bash tool/build_workers.sh
node tool/benchmark_workers.mjs --target wasm --jumps 32 --samples 3 --baseline build/benchmarks/before.json --output build/benchmarks/after.json
```

Comparison rejects incompatible configurations, changed fixture bytes, and state/viewport mismatches. Worker binary hashes are allowed to change. Run on the same idle machine and Node version, avoid simultaneous benchmark/profiling runs, and compare several independent samples. Inspect the raw late-jump timings and cache counts as well as the median: a periodic cache flush can disappear in an overall average. p95 uses the nearest-rank definition; small sample counts provide little tail precision.

There is no default timing pass/fail gate. An explicit `--max-regression 20` with `--baseline` returns a nonzero exit status if any workload/target's combined median simulation time exceeds its baseline by more than 20%. Timing gates belong on controlled hardware, not noisy shared CI. Protocol errors, timeouts, mismatched generations, and incompatible signatures always fail. `--timeout-ms` controls startup and each command; workers are terminated on failure and partial results are saved with `complete: false`.

For a small harness/baseline smoke check, run `bash tool/check_benchmarks.sh`
after building the workers. It runs glider and seeded-random workloads twice on
both targets and saves artifacts in `build/benchmarks/`. A CI workflow can invoke
that command after its worker build and optionally upload those JSON files.
The workflow hook is not included here because the publishing GitHub App lacks
the `workflows` permission; the existing CI still runs the engine regression tests.

## CPU profiles

```sh
node tool/benchmark_workers.mjs --target js --jumps 8 --samples 1 --profile-dir build/benchmarks/profiles --output build/benchmarks/profiled.json
```

The harness starts Node's inspector CPU profiler **inside the simulation worker**, after loading, and writes one `.cpuprofile` per fixture/target/sample. It profiles sequential advances and viewport replies, excluding parsing/loading. Import a profile in Chrome DevTools' Performance panel or another CPU-profile viewer to identify time in successor recursion, interning, collection, and viewport traversal. JavaScript profiles contain compiler-generated names; the generated source map helps relate them to Dart. Wasm profiles may expose less useful symbol names, depending on the runtime.

Profiling introduces overhead, so collect ordinary timings separately; the baseline checker rejects comparisons between profiled and unprofiled configurations. Running `node --cpu-prof` on only the driver is not a substitute for profiling the engine's worker thread. Profiles also include worker idle samples while the driver hashes and records replies; filter idle frames when investigating simulation CPU cost.
