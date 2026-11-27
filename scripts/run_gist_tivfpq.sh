#!/usr/bin/env bash
# GIST-960 tIVFPQ benchmark: the upstream README command, unchanged except -d (dataset path).
# Starts in the background with nohup and is timed with /usr/bin/time -v.
# Run it after run_gist_thnsw.sh has finished (it refuses to start while another bench.py runs).
#   DRY_RUN=1 scripts/run_gist_tivfpq.sh  print the command, run nothing
#   scripts/run_gist_tivfpq.sh            start the run
# Outputs: results/QPSDCRecall_GIST_tIVFPQ_KNN_k10.csv, logs/gist_tivfpq_<time>.{out,time,env}.txt and .pid
# Threads: OMP_NUM_THREADS=16 (scripts/common.sh) for FAISS IVFPQ training; queries are single-threaded.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

CSV=./results/QPSDCRecall_GIST_tIVFPQ_KNN_k10.csv
CMD=(python3 "$TRIM_DIR/bench/bench.py" -qt ann -k 10 -nq 1000 -d "$GIST_PATH" -m tIVFPQ
  -b 'ivfpq_index_path:"./tmp/index/gist_ivfpq4096x30.bin";C:4096;m:30;nbits:8'
  -s 'trim_opened:[true];gamma:[0.62];k_factor:[0.0];nprobe:[40,60,80,100,150,200,250,300,400,500,600]'
  -si "./tmp/index/gist_ivfpq4096x30.bin"
  -sr "$CSV")

if [ "${DRY_RUN:-0}" = 1 ]; then
  echo "DRY RUN — would run (from $(pwd)):"; printf '%q ' "${CMD[@]}"; echo; exit 0
fi

require_gist
refuse_if_running
refuse_if_exists "$CSV"
mkdir -p tmp/index results logs
RUN=logs/gist_tivfpq_$(date +%Y%m%d-%H%M%S)
write_env "$RUN.env.txt"
printf '%q ' "${CMD[@]}" > "$RUN.cmd.txt"; echo >> "$RUN.cmd.txt"
nohup /usr/bin/time -v -o "$RUN.time.txt" "${CMD[@]}" > "$RUN.out.txt" 2>&1 &
echo $! > "$RUN.pid"
echo "Started tIVFPQ GIST run, PID $(cat "$RUN.pid")"
echo "  progress: tail -f $RUN.out.txt"
echo "  timing:   $RUN.time.txt (written when the run ends)"
echo "  results:  $CSV"
