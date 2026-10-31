#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Project Pages uses /repository/; user sites and custom domains can override it.
pages_base_path="${PAGES_BASE_PATH:-/conway_game_of_life/}"
if [[ "$pages_base_path" != /*/ && "$pages_base_path" != / ]]; then
  echo "PAGES_BASE_PATH must start and end with /" >&2
  exit 1
fi
bash tool/build_web.sh --base-href "$pages_base_path" "$@"
touch build/web/.nojekyll
