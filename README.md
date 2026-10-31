# Conway’s Game of Life

Flutter web simulator with an expanding HashLife universe, exact single steps,
power-of-two generation jumps, pattern placement, and pan/zoom.

## Run

Use **Flutter 3.47.9 stable / Dart 3.13.7** (`.fvmrc` pins the SDK for FVM).

```sh
flutter pub get
bash tool/build_workers.sh
flutter run -d chrome --wasm
```

Turn on Draw to toggle cells, drag to pan, and scroll/pinch to zoom. Search the
37-pattern library (drawer on narrow screens): expand a family, search across
all families, or sort names A–Z. Click a card or Load world to start a new world,
or choose Place to insert it into the current world. The info button offers
experiment tips and source credits. Escape cancels placement. Step always advances one generation; the generations/tick
control changes playback jumps (up to 1,048,576 generations). Jump applies one
selected jump while paused. Random seed area controls the initial random
square, not a fixed boundary. Save/Restore keeps a snapshot in memory.

Simulation and viewport extraction run in a dedicated web worker. Pause lets the
current jump finish; New world terminates it immediately. Pan/zoom and controls
remain available during computation. Rebuild worker assets after engine changes;
Flutter hot reload does not rebuild them.

The side panel shows rendered Flutter FPS and memory in MiB (also available in
the mobile drawer). FPS drops when idle. Memory uses the browser’s page-and-worker
estimate when available, otherwise a clearly labeled partial JS heap estimate or
“Unavailable”; it is not total process RAM. Hover the metrics for details.

Patterns come from Golly and its Life Lexicon, ranging from simple still lifes
through breeders, memory circuits, and a Turing machine. They are bundled as
RLE files and load on demand using sparse coordinates. See
[the library and adding patterns](docs/pattern-library.md) and
[third-party pattern credits](assets/patterns/NOTICE.md).

## Verify and build

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter test --platform chrome test/core/hashlife_test.dart
bash tool/build_web.sh
node tool/test_workers.mjs
```

Build for GitHub Pages with `bash tool/build_pages.sh`. This includes the
`/conway_game_of_life/` base path, simulation workers, Wasm, and JavaScript fallback.
Building locally does not publish the app.

Read [the algorithm, tests, web-build tradeoffs and research sources](docs/architecture.md).
Run `dart run tool/benchmark.dart` for reproducible engine-only timings. HashLife
excels at repeating patterns and large jumps; it is not universally fastest for
chaotic dense boards. Web is the supported target of this modernization; native
platform scaffolds still need separate migration and validation.

## Publish to GitHub Pages

Site URL after deployment: https://saif97.github.io/conway_game_of_life/

The deployment workflow is staged at `tool/pages.yml` because the publishing
credential cannot write workflow files. Flutter verification CI already lives in
`.github/workflows/flutter.yml`. To activate deployment, run these commands on
the PR branch using credentials with workflow write access:

```sh
mkdir -p .github/workflows
git mv tool/pages.yml .github/workflows/pages.yml
git commit -m "Enable GitHub Pages deployment"
git push
```

In repository **Settings → Pages → Build and deployment**, select **GitHub
Actions** as the source. Merge the PR into `main`; the **Deploy GitHub Pages**
workflow tests, builds, and publishes the app. Subsequent pushes to `main`
redeploy it. You can also run the workflow manually from the Actions tab.

For a local production build:

```sh
flutter pub get
bash tool/build_pages.sh
```

The output is `build/web/`. For a custom domain hosted at its root, set
`PAGES_BASE_PATH=/` when invoking the build script and configure that domain in
GitHub Pages settings.

GitHub Pages does not allow custom COOP/COEP headers. Flutter therefore uses
single-threaded Wasm rendering; HashLife still runs in its own dedicated worker.
Full page-and-worker memory estimates may be unavailable, so the performance
panel uses its labeled partial-memory fallback. No service-worker workaround is
required. Firebase configuration has been removed; this does not delete or
unpublish any existing Firebase site.

## Credits

The original implementation was inspired by
[ngmsoftware’s HashLife](https://github.com/ngmsoftware/hashlife/blob/master/hashLife.py)
and [this tutorial](https://www.dev-mind.blog/hashlife/).

## MIT License

Copyright (c) [year] [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
