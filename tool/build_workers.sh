#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p web/workers
dart compile js -O4 tool/worker/main.dart -o web/workers/life_worker.js
dart compile wasm tool/worker/main.dart -o web/workers/life_worker.wasm
