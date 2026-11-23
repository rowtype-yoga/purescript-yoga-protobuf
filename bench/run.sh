#!/usr/bin/env bash
# Builds everything, runs each implementation RUNS times (default 5), one after the other in
# each run, and prints the median of each measurement as two tables, Go and Bun, with the
# machine's load before and after.
#
#   bench/run.sh
#   RUNS=9 bench/run.sh
set -euo pipefail
cd "$(dirname "$0")/.."

runs=${RUNS:-5}
results=bench/results
mkdir -p "$results"
raw="$results/raw.txt"
: >"$raw"

echo "building..." >&2
spago build -p yoga-protobuf-bench >/dev/null 2>&1
iris_go=$(iris go -p yoga-protobuf-bench --entry Bench.Main.main 2>/dev/null | tail -1)
(cd bench/go && GOTOOLCHAIN=auto go build -o bin/comparators .)
(cd bench/js && bun install --frozen-lockfile >/dev/null)

load_before=$(uptime | sed 's/.*load average[s]*: //')
for run in $(seq "$runs"); do
  echo "run ${run} of ${runs}..." >&2
  "$iris_go" | grep '^RESULT' >>"$raw"
  bench/go/bin/comparators >>"$raw"
  bun -e "import('$PWD/output-es/Bench.Main/index.js').then(module => module.main())" | grep '^RESULT' >>"$raw"
  (cd bench/js && bun bench.mjs) >>"$raw"
done

load_after=$(uptime | sed 's/.*load average[s]*: //')

{
  bun bench/tools/table.ts <"$raw"
  echo
  echo "Median of ${runs} runs; load average ${load_before} before, ${load_after} after."
} | tee "$results/table.md"
