#!/usr/bin/env bash
# Smoke test: make a synthetic dataset and run the upstream README tHNSW command on it.
# Run from anywhere:  scripts/smoke_test.sh     (needs README Steps 1-4 done)
# Output: smoke/  (dataset, indexes, results CSV, output log). Expected: CSV with 11 rows.
# Changes vs the upstream README command: -d (synthetic file), -nq 100 (it has 100 queries),
# and index/result paths under ./smoke/.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh
refuse_if_running

rm -rf smoke                       # start clean: bench.py appends to existing CSVs
mkdir -p smoke/tmp/index smoke/results

echo "== 1/2 Making synthetic dataset (10000 x 960, 100 queries, seed 42)"
python3 scripts/make_synthetic.py smoke/synthetic-960.hdf5

echo "== 2/2 Running tHNSW on it (output: smoke/smoke-thnsw-output.txt)"
CSV=smoke/results/QPSDCRecall_SYN_tHNSW_KNN_k10.csv
python3 "$TRIM_DIR/bench/bench.py" -qt ann -k 10 -nq 100 -d "smoke/synthetic-960.hdf5" -m trim \
  -b "hnswlib_index_path:\"./smoke/tmp/index/syn_hnswlib16x500.bin\";M:16;efConstruction:500;pq_index_path:\"./smoke/tmp/index/syn_pq8x120.bin\";pq_m:120;pq_nbits:8;dco:\"trim\"" \
  -s "enable_batch_dco:[true];gamma:[0.67];ef:[10,30,50,70,90,150,300,400,600,800,1000]" \
  -si "./smoke/tmp/index/syn_thnsw16x500_pq8x120.empty" \
  -sr "./$CSV" > smoke/smoke-thnsw-output.txt 2>&1 \
  || { tail -20 smoke/smoke-thnsw-output.txt; die "bench.py failed (see smoke/smoke-thnsw-output.txt)"; }

[ -f "$CSV" ] || die "no results CSV written"
rows=$(( $(wc -l < "$CSV") - 1 ))
cat "$CSV"
[ "$rows" -eq 11 ] || die "expected 11 rows in $CSV, got $rows"
echo "SMOKE TEST PASS: $CSV has $rows rows"
