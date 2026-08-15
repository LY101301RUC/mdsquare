#!/usr/bin/env bash
set -euo pipefail

TESTING_FRAMEWORKS_DIR="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
TESTING_INTEROP_DIR="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"

if [[ -d "$TESTING_FRAMEWORKS_DIR/Testing.framework" ]]; then
  node script/create_perf_fixtures.mjs >/dev/null

  swift test \
    -Xswiftc -F \
    -Xswiftc "$TESTING_FRAMEWORKS_DIR" \
    -Xlinker -rpath \
    -Xlinker "$TESTING_FRAMEWORKS_DIR" \
    -Xlinker -rpath \
    -Xlinker "$TESTING_INTEROP_DIR"
else
  node script/create_perf_fixtures.mjs >/dev/null

  swift test
fi

if [[ -f "script/verify_preview_fixtures.mjs" ]]; then
  node script/verify_preview_fixtures.mjs
fi

test -s tmp/perf-fixtures/100kb.md
test -s tmp/perf-fixtures/1mb.md

echo "Run node script/measure_core_perf.mjs --budget for local performance budget checks."
