#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash tool/build_workers.sh
flutter build web --release --wasm "$@"
