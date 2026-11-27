#!/usr/bin/env bash
# Day 1 smoke test: README tHNSW command on the synthetic dataset.
# Changes vs README: -d points to the synthetic file; -nq 100 (dataset has 100 queries); run from ~/trim-logs/smoke.
set -u
source ~/trim/.venv/bin/activate
export PYTHONPATH=~/trim-logs/patched-src/python   # patched trimlib (see fixes.patch)
export PYTHONDONTWRITEBYTECODE=1                   # keep ~/trim/bench free of __pycache__
cd ~/trim-logs/smoke
mkdir -p ./tmp/index ./results
python3 ~/trim/bench/bench.py -qt ann -k 10 -nq 100 -d "$HOME/trim-logs/smoke/synthetic-960.hdf5" -m trim \
  -b "hnswlib_index_path:\"./tmp/index/syn_hnswlib16x500.bin\";M:16;efConstruction:500;pq_index_path:\"./tmp/index/syn_pq8x120.bin\";pq_m:120;pq_nbits:8;dco:\"trim\"" \
  -s "enable_batch_dco:[true];gamma:[0.67];ef:[10,30,50,70,90,150,300,400,600,800,1000]" \
  -si "./tmp/index/syn_thnsw16x500_pq8x120.empty" \
  -sr "./results/QPSDCRecall_SYN_tHNSW_KNN_k10.csv"
