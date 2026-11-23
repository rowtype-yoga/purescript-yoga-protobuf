#!/usr/bin/env bash
# Builds everything, runs each implementation RUNS times (default 3) and prints the median of
# each measurement as two tables, Go and Bun.
#
#   bench/run.sh
#   RUNS=5 bench/run.sh
set -euo pipefail
cd "$(dirname "$0")/.."

runs=${RUNS:-3}
results=bench/results
mkdir -p "$results"
raw="$results/raw.txt"
: >"$raw"

echo "building..." >&2
spago build -p yoga-protobuf-bench >/dev/null 2>&1
iris_go=$(iris go -p yoga-protobuf-bench --entry Bench.Main.main 2>/dev/null | tail -1)
(cd bench/go && GOTOOLCHAIN=auto go build -o bin/comparators .)
(cd bench/js && bun install --frozen-lockfile >/dev/null)

for run in $(seq "$runs"); do
  echo "run ${run} of ${runs}..." >&2
  "$iris_go" | grep '^RESULT' >>"$raw"
  bench/go/bin/comparators >>"$raw"
  bun -e "import('$PWD/output-es/Bench.Main/index.js').then(module => module.main())" | grep '^RESULT' >>"$raw"
  (cd bench/js && bun bench.mjs) >>"$raw"
done

bun bench/tools/table.ts <"$raw" | tee "$results/table.md"
