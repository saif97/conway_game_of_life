# HashLife benchmark and profiling research

Researched 2026-10-31 using primary documentation and source. The reported
4.3-second jumps on `hexadecimal-counter.mc` at 32,768 generations are the
motivation, not a measurement reproduced here. No engine benchmarks were run
for this note, and no speedup or bottleneck in this repository is established.
Commands below are source-checked recipes, not recorded benchmark results.

**Recommendation:** make consecutive 32,768-generation advances on the exact
bundled counter the main workload. Report the first advance, the subsequent
sequence, cache collections, and process memory separately. Keep replaying the
same cached advance as a clearly labeled microbenchmark.

## Scope and source versions

- Golly source: revision `2cf06330cab58dccec085724067e17ddd7a56905`, retrieved
  from its official SourceForge repository. Relevant entry points are
  [`cmdline/bgolly.cpp`][bgolly] and [`gollybase/hlifealgo.cpp`][hlife].
- Lifelib source: revision `05632e382096925c0b1724fd59d2f0784f0213d6` in
  [Adam P. Goucher's repository][lifelib-commit]. Documentation links below
  use that revision. This is the cellular-automata library, distributed as
  `python-lifelib`, rather than another package named `lifelib`.[ll-install]
- Node references are the Node 24 documentation; record the actual patch
  version and V8 version used. V8's compilation article describes its
  documented pipeline, not a promise about every Node release.[node-cli], [v8-wasm]
- Local context: [architecture](architecture.md),
  [existing benchmark](../tool/benchmark.dart),
  [Wasm runner](../tool/run_wasm.mjs), and
  [counter catalog entry](../assets/patterns/catalog.json). These describe a
  persistent worker owning the universe and caches, and distinguish simulation
  from viewport traversal, transfer, and painting. Recheck the implementation
  when applying this note; it is being developed concurrently.

The counter's [original file][counter] explicitly recommends HashLife at
`8^5`, which is 32,768 generations. Its decompressed SHA-256, verified during
this research, is
`938e3b324e1e29c852b37165b2bedbfd9e8a60f4c1367bfd704a82e4b8dad6c5`,
matching the bundled catalog's recorded hash. This recommendation does not
specify an expected latency on another engine or machine.

## Verified Golly approach

Golly provides **bgolly**, a GUI-free batch executable. Its build documentation
explicitly supports building that target without wxWidgets or Python. The
Linux makefile supplies `-O3`; preserve the actual build command and compiler
version with results.[golly-build], [golly-make]

The command-line source provides these controls:[bgolly]

- `-a HashLife` selects HashLife; the default is QuickLife.
- `-i 32768` fixes the step size. `-m` is the **absolute stopping generation**,
  not the number of jumps. Without an explicit increment, the runner can choose
  increments from the remaining distance. `-2` changes increments exponentially.
- `-M` controls the engine memory setting, whose implementation converts the
  value to MiB. The CLI default is 256.[hlife]
- `-b` prints timestamps. One `-q` suppresses population calculation while
  retaining generation output. Avoid `-q -q` when parsing timestamp/generation
  pairs: the timestamp output occurs outside the quiet-output condition.
- `--popcount`, `--render`, and `--autofit` deliberately add work. Rendering
  uses a null renderer, so it exercises traversal/render preparation rather
  than GUI painting. `-t` retains timeline frames. These are different workloads.
- `-v` enables diagnostic messages including HashLife collections and increment
  changes. Use it in a separate diagnostic run because logging adds work.

### Runnable Golly baseline

Example for Linux with Git, a C++ toolchain, Make, and zlib development headers.
Use a separate upstream checkout, outside this application:

```sh
git clone https://git.code.sf.net/p/golly/code /tmp/golly-performance-reference
git -C /tmp/golly-performance-reference checkout 2cf06330cab58dccec085724067e17ddd7a56905
make -C /tmp/golly-performance-reference/gui-wx -f makefile-gtk bgolly

# This bundled input has no saved-generation directive: start generation is 0.
# 1,048,576 / 32,768 = 32 consecutive jumps in one universe.
/tmp/golly-performance-reference/bgolly \
  -a HashLife -b -q -M 1024 -i 32768 -m 1048576 \
  /home/agent/conway_game_of_life/assets/patterns/hexadecimal-counter.mc \
  > /tmp/bgolly-counter.txt
```

**Timing interpretation, verified from the main loop:** the clock starts before
reading the pattern; the first generation timestamp therefore includes loading.
Subtract adjacent generation timestamps to obtain successive advance intervals.
Those intervals still include the small generation-output/loop overhead; they
are not a stopwatch placed solely around `imp->step()`. Do not call the final
timestamp an import-free engine time. Population/render flags add work between
those timestamps.[bgolly]

**Recommended repetitions:** run a new process for each of seven sequences,
retain every row, and repeat with `-M 256`, `512`, `1024`, and `2048` where
practical. For a single first jump use `-m 32768`. Use `-v` separately to
correlate latency spikes with collection. A subprocess wall timer measures a
different quantity, including startup, loading, and exit.

## Verified lifelib approach

The inspected documentation and source expose a useful benchmarking API; the
recipe below is our harness, **not an upstream standardized benchmark suite**.

- `load_rules("b3s23")` may generate and compile a native shared library before
  loading it. Keep that work outside the simulation timer.[ll-example]
- `sess.lifetree(memory=..., n_layers=1)` explicitly selects one layer; the C++
  factory constructs ordinary HashLife for positive layer counts. Its special
  `n_layers=-1` path selects StreamLife, which should be reported as a different
  algorithm.[ll-session], [ll-native]
- `lt.load()` accepts macrocell and RLE files. `p[32768]` returns a new pattern;
  it does not advance `p` in place. Patterns in one lifetree share compressed
  structure and computation.[ll-analysis], [ll-example], [ll-pattern]
- Population is computed through the tree. Keep population queries and file
  export outside the evolution interval.[ll-example]
- Its documented low-level iterators operate on 32×32 cells and return a
  central 16×16 region; its B3/S23 generator can use x86 SIMD. Native lifelib
  results therefore mix algorithm, representation, iterator, compiler, and ISA
  differences. They do not predict a Dart/JS/Wasm speedup.[ll-structure]

### Runnable lifelib baseline

The pinned upstream documentation targets x86-64 with a C++ compiler and Python.
Use its installation instructions for other supported environment details.
Cloning the source is explicitly supported; its directory must be named
`lifelib` for the documented import arrangement.[ll-install], [ll-quickstart]

```sh
mkdir -p /tmp/life-reference
git clone https://gitlab.com/apgoucher/lifelib.git /tmp/life-reference/lifelib
git -C /tmp/life-reference/lifelib checkout 05632e382096925c0b1724fd59d2f0784f0213d6
git -C /tmp/life-reference/lifelib submodule update --init --recursive
python3 -m venv /tmp/life-reference/venv
/tmp/life-reference/venv/bin/python -m pip install numpy
```

Save this proposed harness as `/tmp/life-reference/bench_lifelib.py`:

```python
import json
import sys
from time import perf_counter_ns
import lifelib

filename = sys.argv[1]
memory_mib = int(sys.argv[2]) if len(sys.argv) > 2 else 1024
jumps = int(sys.argv[3]) if len(sys.argv) > 3 else 32
step = 32768
session = lifelib.load_rules("b3s23")  # Compilation/loading excluded.
tree = session.lifetree(memory=memory_mib, n_layers=1)
t0 = perf_counter_ns()
p = tree.load(filename)
load_ns = perf_counter_ns() - t0
rows = []
for i in range(jumps):
    t0 = perf_counter_ns()
    p = p[step]  # Advance CURRENT state, releasing the prior Python pattern.
    elapsed_ns = perf_counter_ns() - t0
    rows.append({"jump": i + 1, "generations_advanced": (i + 1) * step,
                 "elapsed_ns": elapsed_ns})

# Output and expensive observations occur after the entire timed sequence.
print(json.dumps({"kind": "metadata", "memory_mib": memory_mib,
                  "step": step, "load_ns": load_ns,
                  "final_population": p.population,
                  "final_bounds": p.bounding_box}))
for row in rows:
    print(json.dumps(row))
```

```sh
PYTHONPATH=/tmp/life-reference /tmp/life-reference/venv/bin/python \
  /tmp/life-reference/bench_lifelib.py \
  /home/agent/conway_game_of_life/assets/patterns/hexadecimal-counter.mc \
  1024 32 > /tmp/lifelib-counter.jsonl
```

This measures the Python API call/assignment including binding overhead and
cleanup it triggers. In particular, the C++ pattern destructor calls
`threshold_gc()`; timing `q = p[step]` and deleting `p` only after stopping the
timer can omit relevant collection work.[ll-pattern], [ll-pattern-native]
The generation field above is an offset from the loaded seed, not an assertion
that every macrocell file starts at generation zero.

For independent first-jump samples, run new processes with `jumps=1`. For
consecutive playback, retain only the current pattern, as above. Keeping all
past `Pattern` objects in a list retains their handles and changes collection
roots.[ll-hypertree] A replay microbenchmark instead holds a fixed `seed` and
repeatedly computes `seed[step]`; give that a separate name and process.

## Cache and memory policy lessons

**Verified upstream facts:**

1. Golly interns nodes, attaches cached results to nodes, allocates nodes in
   chunks with a free list, and accounts for hash-table storage. Its comments
   discuss allocator rounding and repurposing old hash-table storage. Ordinary
   `do_gc(0)` marks the current root, active recursion stack, timeline frames,
   structural children, and cached result pointers reachable from them; it
   recycles unmarked nodes. It is not an unconditional deletion of every
   successor result.[hlife]
2. Golly's `new_ngens()` can collect and invalidate cached results at affected
   depths when the increment changes. Changing step sizes is therefore a
   separate benchmark dimension, not a harmless way to obtain more samples.
   Its `clearcache()` documentation calls complete invalidation expensive.[hlife]
3. Lifelib converts `memory` to a byte threshold with `maxmem << 20` and checks
   `htree.total_bytes()`. It also has per-level occupancy-triggered collection.
   Full collection marks registered pattern handles and their structural
   children, then removes unmarked entries. This differs from Golly's explicit
   cached-result marking.[ll-tree], [ll-hypertree]
4. Lifelib's collector is invoked at object-lifetime boundaries as well as
   through its API. A threshold test followed by collection is not a process
   RSS ceiling or a guarantee that every allocation stays below that number.
   Golly's tracked allocation setting likewise should not be equated with
   complete process memory.[ll-pattern-native], [ll-tree], [hlife]

**Recommendations for this repository:**

- Instrument each jump with nodes/results before and after, peak counts during
  the jump, collection count and duration, and entries retained/reclaimed.
  Boundary counts alone can hide a large transient allocation or a cache clear.
- In a diagnostic build, count successor lookups/hits/misses, intern
  lookups/hits/new nodes, leaf evaluations, and root-depth changes. Keep these
  counters optional and compare their overhead with the ordinary build.
- Vary the cache budget while holding pattern, jump, sequence length, and
  snapshot policy constant. An entry threshold in Dart is not equivalent to
  a native MiB setting; measure bytes independently before comparing policies.
- Include collection time in the user-visible advance measurement; optionally
  break it out as a component. Excluding it merely transfers the apparent cost.
- Treat preserving reusable results, packed leaves, and denser node storage as
  hypotheses to test after profiling. Upstream implementation choices alone
  do not establish which change benefits this engine.

## Cold, cached replay, and consecutive playback

These are recommended benchmark definitions, motivated by the shared-cache
semantics above and V8's compilation behavior.[hlife], [ll-example], [v8-wasm]

| Measurement | Required state | What it answers |
| --- | --- | --- |
| Process startup and import | New process, load exact bytes | Startup/import experience; report separately |
| First advance | Fresh universe/tree, no previous evolution | Cost before this pattern's successor cache exists |
| Runtime-conditioned first advance | Runtime exercised separately, then fresh universe | Separates runtime warmup from pattern-cache reuse |
| Cached replay | Restore the identical root and repeat identical jump, retaining cache | Cost when exactly the requested result may already exist |
| Consecutive playback | Repeatedly advance the returned/current state, no restore | Latencies the persistent simulation sees over time |
| Budget stress | Same sequence with explicit cache thresholds | Collection behavior and latency/memory tradeoffs |

Recommended protocol:

1. Preserve the full sequence, including the first jump and any slow later
   jumps. Use at least 32 jumps for an initial study and seven fresh-process
   repetitions when feasible. Report first-jump values separately and a
   predeclared later window, such as jumps 9–32. Call that a **later window**,
   not proven steady state; extend runs if latency or memory still trends.
2. Use per-process totals and medians across independent repetitions. Report
   the per-jump median, maximum, and raw samples for playback. A p95 from a short
   sequence is descriptive and noisy; do not imply a reliable p99 from 32 jumps.
   Aggregate generation throughput as total generations divided by total
   elapsed time, not an average of individual rates.
3. Record revision/dirty state, pattern hash, rule, initial generation/origin,
   target, compiler options, Dart/Flutter/Node/V8 versions, CPU/OS, jump size,
   cache setting, retained snapshots, and timed boundaries. Alternate baseline
   and candidate run order and use identical generation windows.
4. Hold the counter at exponent 15. If testing exponents 10 or 12, start fresh
   sequences and compare both latency per advance and time to an equal final
   generation. Add a glider/oscillator, a gun/puffer, and fixed-seed chaotic
   patterns for coverage. Golly explicitly recommends QuickLife for highly
   chaotic patterns; do not rank engines from one structured construction.[golly-hashlife]
5. Separate engine evolution, worker request-to-reply including viewport
   traversal/serialization, and real browser frame latency. Node execution
   measures compiled engine behavior, not Flutter painting or browser FPS.
   The repository's worker architecture defines those distinct boundaries.

## JS and Wasm profiling with Node

**Verified facilities:** Node `--cpu-prof` samples from process startup and
emits a `.cpuprofile` at exit; its default interval is 1,000 microseconds.
`--heap-prof` samples allocations. `--prof` and `--prof-process` provide the
alternative V8 log workflow. Node's diagnostics guide documents `--trace-gc`.
Use these in separate diagnostic runs, not as the authoritative timing
samples.[node-cli], [node-gc]

From the application root, these commands profile the repository benchmark
entry point with the existing Wasm launcher. They introduce no hypothetical
benchmark CLI flags. Select the counter and consecutive mode through the
implemented harness interface when available; compiling an unrelated workload
does not produce a counter profile.

```sh
mkdir -p /tmp/life-profiles
dart --version
node -p 'JSON.stringify(process.versions)'
dart compile js -O4 tool/benchmark.dart -o /tmp/life-profiles/benchmark.js
dart compile wasm tool/benchmark.dart -o /tmp/life-profiles/benchmark.wasm

# Ordinary timing runs, without profiler instrumentation.
node /tmp/life-profiles/benchmark.js > /tmp/life-profiles/js.jsonl
node tool/run_wasm.mjs /tmp/life-profiles/benchmark.wasm \
  > /tmp/life-profiles/wasm.jsonl

# CPU profiles; allow normal exit so Node writes each artifact.
node --cpu-prof --cpu-prof-dir=/tmp/life-profiles --cpu-prof-name=js.cpuprofile \
  /tmp/life-profiles/benchmark.js
node --cpu-prof --cpu-prof-dir=/tmp/life-profiles --cpu-prof-name=wasm.cpuprofile \
  tool/run_wasm.mjs /tmp/life-profiles/benchmark.wasm

# Allocation and runtime GC diagnostics in separate runs.
node --heap-prof --heap-prof-dir=/tmp/life-profiles \
  /tmp/life-profiles/benchmark.js
node --trace-gc /tmp/life-profiles/benchmark.js \
  > /tmp/life-profiles/js-gc.log 2>&1
node --trace-gc tool/run_wasm.mjs /tmp/life-profiles/benchmark.wasm \
  > /tmp/life-profiles/wasm-gc.log 2>&1
```

Recommendations for interpreting profiles:

- Retain generated JS source maps and Wasm companion files. Optimized code may
  show minified functions or Wasm indices; do not infer a Dart function name
  without mapping it. An additional build with better symbols is diagnostic;
  compare release timings using the original optimization settings.
- Record the timed generation range so profiles of parsing/initialization are
  not mistaken for profiles of later evolution. For precise phase isolation,
  Node's [Inspector API example][node-inspector] supports `Profiler.start` and
  `Profiler.stop` around the target work. With worker threads, profile the
  executing worker's isolate, not only the waiting parent.
- V8 documents lazy baseline Wasm compilation followed by background tier-up
  for hot functions, and explains that debugging/profiling can affect tiering.
  Keep ordinary runtime settings for headline timings; record any experimental
  V8 flags and check availability with `node --v8-options`. A cached HashLife
  replay is not sufficient warmup for recursion that replay bypasses.[v8-wasm]
- Keep runtime GC and HashLife cache collection as separate event types.
  `--trace-gc` observes V8 collection, not the application's decision to clear
  or rebuild its memoization tables.[node-gc]
- Node's `process.memoryUsage()` reports RSS, V8 heap, external memory, and
  ArrayBuffers. ArrayBuffers are included in `external`; do not add them twice.
  In worker threads, RSS covers the process while the other fields describe
  the current thread. `memoryUsage.rss()` is the cheaper RSS-only call.
  None of these alone identifies engine-owned bytes.[node-memory]
- Sample memory outside timed calls and use an external process monitor if
  peaks during a synchronous jump matter. Timers on that same blocked event
  loop cannot sample the middle of the jump. Do not assume JS heap or sampled
  allocations describe all Wasm storage or browser page/worker/GPU memory.

## Correctness gates before accepting an optimization

**Verified precedents:** lifelib's integration tests check both known outcomes
(Lidka population 1,623 after 30,000 generations) and equality of evolution
with different decompositions, such as
`lidka[1093][3511] == lidka[3511][1093]`. They also check exact translated
patterns. Golly's `-o` option exports the resulting state.[ll-tests], [bgolly]

**Recommended checks:**

1. Keep this repository's independent sparse oracle and exact glider-position
   checks, and run the existing JS/Wasm parity verification. Population alone
   cannot distinguish different patterns with the same number of live cells.
2. Obtain reference counter states after 32,768, 65,536, and 1,048,576
   generations from Golly and/or lifelib in a separate validation run. For
   example, append `-o /tmp/counter-g32768.mc` to the bgolly first-jump command.
   Export/parsing/digest work stays outside performance runs.[bgolly], [ll-analysis]
3. Compare generation, rule, population, bounding box **and full cell state**.
   Compare absolute coordinates after documenting any importer-origin
   conversion; merely centering both patterns can hide translation bugs.
   Macrocell file bytes and internal node IDs need not match for equal worlds.
   Prefer exact coordinate-set equality at these sizes, or a shared specified
   spatial digest plus spot checks when enumeration is too expensive.
4. Recheck under forced cache pressure, mixed jumps, save/restore, negative
   coordinates, and large translations. Compare repeated 32,768-generation
   advances with a direct equal-total advance outside timing runs. Agreement
   within one implementation is useful but does not replace the independent
   oracle/reference engine.
5. Avoid computing state digests or populations between timed jumps in the
   primary sequence: even observations can traverse/memoize data and alter
   later work. Use a separate deterministic replay for per-jump validation,
   and report final observations after the measured sequence.

[bgolly]: https://sourceforge.net/p/golly/code/ci/2cf06330cab58dccec085724067e17ddd7a56905/tree/cmdline/bgolly.cpp?format=raw
[hlife]: https://sourceforge.net/p/golly/code/ci/2cf06330cab58dccec085724067e17ddd7a56905/tree/gollybase/hlifealgo.cpp?format=raw
[golly-build]: https://sourceforge.net/p/golly/code/ci/2cf06330cab58dccec085724067e17ddd7a56905/tree/docs/Build.html?format=raw
[golly-make]: https://sourceforge.net/p/golly/code/ci/2cf06330cab58dccec085724067e17ddd7a56905/tree/gui-wx/makefile-gtk?format=raw
[golly-hashlife]: https://golly.sourceforge.io/Help/Algorithms/HashLife.html
[counter]: https://golly.sourceforge.net/patterns/hex-3digit-7seg.mc.gz
[lifelib-commit]: https://gitlab.com/apgoucher/lifelib/-/commit/05632e382096925c0b1724fd59d2f0784f0213d6
[ll-install]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/doc/install.md
[ll-quickstart]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/doc/quickstart.md
[ll-example]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/doc/exampleusage.md
[ll-analysis]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/doc/analysis.md
[ll-structure]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/doc/structure.md
[ll-session]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/pythlib/session.py
[ll-pattern]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/pythlib/pattern.py
[ll-native]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/lifelib.cpp
[ll-pattern-native]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/pattern2.h
[ll-tree]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/lifetree.h
[ll-hypertree]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/hashtrees/hypertree.h
[ll-tests]: https://gitlab.com/apgoucher/lifelib/-/blob/05632e382096925c0b1724fd59d2f0784f0213d6/tests/integration/test_gol.py
[node-cli]: https://nodejs.org/docs/latest-v24.x/api/cli.html#--cpu-prof
[node-gc]: https://nodejs.org/en/learn/diagnostics/memory/using-gc-traces
[node-memory]: https://nodejs.org/docs/latest-v24.x/api/process.html#processmemoryusage
[node-inspector]: https://nodejs.org/docs/latest-v24.x/api/inspector.html#cpu-profiler
[v8-wasm]: https://v8.dev/docs/wasm-compilation-pipeline
