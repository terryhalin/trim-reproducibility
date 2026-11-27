#!/usr/bin/env bash
# GIST-960 tHNSW benchmark: the upstream README command, unchanged except -d (dataset path).
# Starts in the background with nohup and is timed with /usr/bin/time -v.
#   DRY_RUN=1 scripts/run_gist_thnsw.sh   print the command, run nothing
#   scripts/run_gist_thnsw.sh             start the run
# Outputs: results/QPSDCRecall_GIST_tHNSW_KNN_k10.csv, logs/gist_thnsw_<time>.{out,time,env}.txt and .pid
# Threads: OMP_NUM_THREADS=16 (scripts/common.sh); bench/trim.py uses os.cpu_count()-2 (unchanged).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

CSV=./results/QPSDCRecall_GIST_tHNSW_KNN_k10.csv
CMD=(python3 "$TRIM_DIR/bench/bench.py" -qt ann -k 10 -nq 1000 -d "$GIST_PATH" -m trim
  -b "hnswlib_index_path:\"./tmp/index/gist_hnswlib16x500.bin\";M:16;efConstruction:500;pq_index_path:\"./tmp/index/gist_pq8x120.bin\";pq_m:120;pq_nbits:8;dco:\"trim\""
  -s "enable_batch_dco:[true];gamma:[0.67];ef:[10,30,50,70,90,150,300,400,600,800,1000]"
  -si "./tmp/index/gist_thnsw16x500_pq8x120.empty"
  -sr "$CSV")

if [ "${DRY_RUN:-0}" = 1 ]; then
  echo "DRY RUN — would run (from $(pwd)):"; printf '%q ' "${CMD[@]}"; echo; exit 0
fi

require_gist
refuse_if_running
refuse_if_exists "$CSV"
mkdir -p tmp/index results logs
RUN=logs/gist_thnsw_$(date +%Y%m%d-%H%M%S)
write_env "$RUN.env.txt"
printf '%q ' "${CMD[@]}" > "$RUN.cmd.txt"; echo >> "$RUN.cmd.txt"
nohup /usr/bin/time -v -o "$RUN.time.txt" "${CMD[@]}" > "$RUN.out.txt" 2>&1 &
echo $! > "$RUN.pid"
echo "Started tHNSW GIST run, PID $(cat "$RUN.pid")"
echo "  progress: tail -f $RUN.out.txt"
echo "  timing:   $RUN.time.txt (written when the run ends)"
echo "  results:  $CSV"
