# Counter optimization: 2026-10-31

The hexadecimal counter's sustained slowdown came from two costs: repeated
record/map lookups during evolution, and clearing every successor after each
large jump. Instrumentation showed 4,061,051 entries created by the first
32,768-generation jump and 4,183,669 by the second, both exceeding the old
200,000-entry soft limit. Each cleanup left zero cached futures. A separate JS
CPU profile identified map lookup/insertion, interning, and allocation/GC costs.

The engine now interns branches in an open-addressed table without temporary
record keys or factory closures, stores one exponent-tagged successor memo on
each branch, and allows 8,000,000 entries before collection. Changing the
exponent recomputes the memo; structural tree contents remain immutable.
Collection still reconstructs the current and saved trees and drops old memos.
The finite limit counts nodes plus populated memos, not bytes, and remains soft:
a single computation can exceed it. Smaller explicit limits still work.

## Matched counter run

Both builds advanced the bundled counter from generation zero to 1,048,576 in
32 consecutive jumps of 32,768, using one fresh worker each. There was no
restore/replay and no discarded warm-up. Baseline: `d850236`; candidate: this
working change. Optimized production Wasm workers ran on Node 24.21.0, Linux
x64, AMD EPYC, using the pinned Dart 3.13.7 compiler. No other benchmark or test
was running concurrently.

| Measurement | Before | After |
| --- | ---: | ---: |
| Total simulation time, all 32 jumps | 340.259 s | 9.302 s |
| First jump | 11,389 ms | 4,399 ms |
| Median jump | 10,385 ms | 93.777 ms |
| p95 jump, nearest rank | 13,126 ms | 599.680 ms |
| Final jump | 10,319 ms | 2.883 ms |
| Peak RSS, whole Node benchmark process | 1.720 GiB | 0.807 GiB |

The whole sequence was **36.6× faster**, including the first jump. This is one
matched local sequence per build, not a statistical confidence interval or a
browser/device performance guarantee. Earlier exploratory candidate runs also
showed the transition from expensive first computation to cached later jumps.
The first jump still takes seconds; longer runs or different patterns may
trigger collections and pauses.

Every jump matched the baseline's generation, population, and sorted aggregated
viewport signature. The final population was 281,726, matching the reported
screenshot. The new JS and Wasm workers also matched each other through all 32
jumps. These signatures complement exact-state oracle tests; aggregation is not
a full cell-by-cell proof.

Peak RSS was obtained from Linux `resource.getrusage(RUSAGE_CHILDREN).ru_maxrss`
around a fresh Node subprocess, so it includes driver, worker, runtime, and
startup allocations. It is neither engine-owned memory nor browser tab memory.
The after-run worker V8 heap sample was about 604 MiB: retaining useful results
still uses substantial memory even though this run's process peak fell.

[Recorded timings, states, build hashes, and environment](benchmarks/counter-wasm-2026-10-31.json)
are checked in. Full local harness artifacts are in
`build/benchmarks/2026-10-31/` (ignored build output).

## Reproduce and extend

Preserve each build's complete worker directory, then run the same options on
both. See [the performance guide](performance.md) for preparation and profiling.

```sh
node tool/benchmark_workers.mjs --target wasm --jumps 32 --samples 1 --memory \
  --output build/benchmarks/before.json

# Apply the change and rebuild with bash tool/build_workers.sh, then:
node tool/benchmark_workers.mjs --target wasm --jumps 32 --samples 1 --memory \
  --baseline build/benchmarks/before.json --output build/benchmarks/after.json
```

Use `--samples 3` or more on **both** runs for repeated independent sequences.
The artifact's raw rows make cold costs, later cache reuse, and collection
spikes visible; a replay-only microbenchmark would miss the original problem.

Additional short comparisons used seeded 64×64 random soup, the OTCA galaxy,
and the Pi calculator: three consecutive 256-generation jumps per target.
All JS/Wasm and before/after signatures matched, and all six workload/target
median simulation timings improved. These short checks cover other behavior;
they are not claims about their larger default playback jumps.

Correctness coverage includes all 65,536 local 4×4 seeds against an independent
oracle, mixed jumps, exact long-distance glider positions, cache pressure on a
random world, table growth and reversed edits, save/restore, and real worker
messages. The counter regression checks retained futures rather than a flaky
wall-clock threshold; reverting the cache limit reproduced its failure.
`tool/check_benchmarks.sh` smoke-tests the benchmark and its baseline comparison
on JS and Wasm without enforcing timing thresholds on shared runners. The CI
hook is deferred because the publishing GitHub App lacks `workflows` permission;
existing CI continues to run the engine regression tests.

Local validation completed: formatting, `flutter analyze`, all 61 Flutter tests,
the separate optimized JS and Wasm exhaustive parity executables, real worker
integration tests, benchmark baseline/profile smoke checks, and
`bash tool/build_web.sh --no-pub`. Rebuilt Wasm worker hashes match the measured
candidate. No browser FPS measurement or production deployment was performed.
