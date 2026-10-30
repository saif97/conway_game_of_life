# Engine and web build decisions

## Choice: HashLife for expanding, structured patterns

This app already targets gliders, guns and puffers on a pannable board. Use
Gosper's HashLife: immutable canonical quadtrees, structural sharing, and cached
future central regions. Repeated patterns can reuse both space and computation;
large jumps do not require visiting every intermediate generation.

There is no universally fastest Life algorithm. Golly explicitly recommends
QuickLife instead of HashLife for highly chaotic patterns. A packed-bit,
double-buffered grid is a good candidate for dense bounded boards at one
step/frame; GPU compute is another option for very large dense grids, with
additional portability and rendering integration costs. Those are different
workloads. This change prioritizes the existing expanding-pattern simulator.

### Correctness invariants

- Conway B3/S23, eight neighbors, simultaneous updates, dead background.
- The plane expands; it does not wrap or clip cells at the initial seed area.
- A node at depth d represents a square of side 2^d. Branches are interned by
  their four canonical child identities, without recursive equality.
- A successor returns the central half after exactly 2^k generations, where
  k <= d-2. Its cache key contains both the node and k.
- Nine overlapping subregions are evolved and recombined. At the maximum jump,
  a second recursive evolution supplies the second half of the elapsed time;
  smaller jumps only extract the centers at that stage.
- Before a public advance, all activity lies in the central quarter and the
  jump is at most one eighth of the root's width. Life propagates no faster
  than one cell/generation, so the returned central half retains every birth.
- Generation accounting happens once at the public API boundary.
- Save/restore retains immutable roots, world origins and generation counts.
- Cache collection drops historical results and re-interns the current and saved
  DAGs. The 200,000-entry threshold is a soft collection trigger, not a hard
  memory budget: a single jump and reachable live state can exceed it.

Unlike the old implementation, rendering never allocates a full rectangular
world or stores one Rect for every possible cell. Traversal rejects empty and
out-of-view nodes, and aggregates occupied subtrees once they are smaller than a
screen pixel or the bounded frame detail (at most roughly 256 squares across). This aggregation affects display only, never simulation. A single
viewport-sized CustomPainter listens directly for changes and batches visible
squares into a path. Grid work scales with visible lines, not total board area.

### Verification

`flutter test` covers all 65,536 possible 4x4 seeds against a separate sparse
neighbor-counting oracle, including births outside each seed; randomized sparse
and dense worlds; alternating jump sizes; still lifes; oscillators; gliders;
bundled guns/puffers; negative coordinates and edges; editing; cache collection;
save/restore; viewport culling; RLE parsing; and application controls.

The glider test checks its exact position after 1,048,576 generations, not merely
its population. The independent reference algorithm deliberately shares no
HashLife machinery. CI also runs the engine suite on Chrome's JavaScript target. The Flutter-free
`tool/verify_web_engine.dart` repeats all 65,536 seeds and mixed/large-jump checks
on optimized JavaScript and Wasm, executed with Node 24. These target parity
checks validate engine compilation, not browser rendering or frame performance.

`dart run tool/benchmark.dart` emits JSON lines for reproducible engine-only
measurements. It uses seven samples, fixed random seeds, separate first-jump and
cached-repeat medians, and excludes loading/rendering. Cached-repeat numbers are
not representative of every animation tick. The same file can be compiled to
JavaScript and Wasm. Measure a release build on target devices before claiming
end-to-end speedups or a universal winner; JIT/VM measurements are not browser
benchmarks.

## Choice: Flutter WebAssembly with JavaScript fallback

Pinned toolchain: Flutter 3.47.9 stable / Dart 3.13.7, verified against the official
Linux release manifest on 2026-10-30. The Dart/Flutter minimums, FVM pin and CI
version agree. Direct dependencies are provider 6.1.5+1, cupertino_icons 2.0.0
(for the adaptive icon font), web 1.1.2 (browser worker interop), and flutter_lints 6.0.0. Unused tuple, fixnum and
split_view dependencies were removed. Transitive packages were upgraded to the
latest versions compatible with Flutter; SDK-pinned test_api and
material_color_utilities were not overridden.

Build with `bash tool/build_web.sh`. This first compiles the simulation worker
to optimized JavaScript and Wasm, then runs Flutter’s release Wasm build. This compiles Dart application
code to WebAssembly and emits a JavaScript fallback. Flutter's generated loader
selects a supported build/renderer; do not force Wasm on incompatible browsers.
Use the stable release's feature detection defaults. The current online docs
also describe newer 3.50 behavior, which should not be assumed for this pin.

Firebase Hosting is configured with COOP `same-origin` and COEP `credentialless`
for the renderer's threading support, and an explicit Wasm MIME type. These
headers must also be configured on any alternative host.

### Worker ownership and scheduling

A persistent dedicated web worker owns the universe, caches, snapshots, evolution,
and viewport traversal. Flutter receives only statistics and a transferable
Float64Array of visible square coordinates and sizes. The worker uses Wasm when
the Flutter application uses Wasm, and JavaScript with the fallback application.
The bootstrap URL respects the application's base path. Native tests use a real
Dart isolate; synchronous service transports exist only in tests.

Only one request is in flight. Playback skips ticks while busy; viewport requests
coalesce to the latest camera position. Camera transforms remain local, so the
existing frame moves immediately during a long jump; newly exposed cells appear
when the worker can produce the next frame. Pause stops scheduling and lets the
current jump finish. New world terminates the worker immediately, invalidates
old replies with a session counter, and creates a fresh worker. Pattern changes
also replace the worker. Startup and runtime errors stop playback and appear in
the interface; New world retries with a new worker.

The searchable pattern library, responsive drawer, explicit Draw mode, fit/zoom
controls, generation/population counters, and playback dock replace the old UI.
Display aggregation caps frame transfer and painting costs without changing Life
rules. Browser frame-time profiling is still needed to quantify responsiveness.

`node tool/test_workers.mjs` runs both generated worker targets through the actual
bootstrap using Node worker threads with a browser messaging shim. It checks
startup, transferable frames, exact million-generation glider positions, restore,
errors, and a main-thread heartbeat during work. Model tests additionally cover
backpressure, coalescing, cancellation, stale replies, disposal, and error recovery.

The obsolete hand-written service worker bootstrap and unused Firebase 8.7.1
scripts were removed. Firebase Hosting needs no Firebase JavaScript SDK. Use
normal HTTP caching/revalidation and host-provided compression. Outputs retain
stable filenames, so the hosting configuration requests revalidation rather than
unsafe year-long immutable caching. Offline installation is not implemented by
this change. Deploy the entire build/web directory, including renderer assets
and fallback code; only the selected runtime resources are loaded as needed.

Browser validation should include Chromium and fallback browsers, startup time,
main-thread frame latency, a moving gun/puffer, dense random seeds, pan/zoom and
heap growth. Wasm is the recommended build target, not a promised speedup or a
claim of native-equivalent performance. The mobile/desktop platform directories
are legacy scaffolds and need their own SDK migration and platform build checks
before shipping those targets; this upgrade targets the web app.

## Performance panel

The sidebar samples rendered Flutter frames over actual elapsed time once per
second, using passive post-frame callbacks. It does not force animation frames;
idle FPS is intentionally low (the panel itself refreshes once per second).
This is UI throughput, not generations per second or GPU presentation timing.

Memory is sampled asynchronously about every ten seconds with at most one request
in flight. Where exposed, `measureUserAgentSpecificMemory` estimates page and worker
memory. Otherwise `performance.memory` is explicitly labeled “JS heap only”,
excluding worker, Wasm and GPU allocations. Unsupported platforms show
“Unavailable”. Neither browser metric represents total process RAM. Timers stop
when the panel is disposed, and late asynchronous replies are ignored.

## Sources

- [Flutter stable release manifest](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)
- [Flutter SDK archive](https://docs.flutter.dev/install/archive)
- [Flutter WebAssembly support and hosting headers](https://docs.flutter.dev/platform-integration/web/wasm)
- [Flutter web renderers](https://docs.flutter.dev/platform-integration/web/renderers)
- [Golly HashLife strengths and limitations](https://golly.sourceforge.io/Help/Algorithms/HashLife.html)
- [Golly QuickLife](https://golly.sourceforge.io/Help/Algorithms/QuickLife.html)
- [Original project's HashLife tutorial](https://www.dev-mind.blog/hashlife/)

## Local validation (2026-10-30)

- Static analysis with fatal infos: clean; formatting check: clean.
- `flutter test --no-pub`: 36 tests pass, including all 65,536 local seeds.
- Optimized JavaScript and Wasm parity executables, run with Node 24.21.0:
  all 65,536 seeds, mixed jumps, random worlds, large coordinates, and the
  million-generation glider pass on both targets.
- `bash tool/build_web.sh --no-pub`: succeeds. The generated loader
  contains dart2wasm/skwasm and dart2js/CanvasKit variants. Both application
  artifacts exist, the base URL placeholder is replaced, and both icon fonts
  are tree-shaken.
- Reproducible benchmark harness executed on the Dart VM and Node/Wasm. These
  measurements exclude rendering and are not evidence of browser frame rates.

Chrome CI checks are defined in the staged workflow at `tool/flutter.yml`, but
were not executed locally. GitHub Actions remains inactive until the file is
moved to `.github/workflows/flutter.yml` using workflow-authorized credentials. No native
platform builds, browser frame-rate profiling, or production deployment were
performed. Existing installations of the old service worker should be included
in deployment testing; clients may need to close old tabs for a worker update
before seeing the new app.
