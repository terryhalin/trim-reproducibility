# TRIM reproduction — Day 1 logs (sanitized)

These are sanitized copies of the Day 1 working logs from a reproduction of
"TRIM: Accelerating High-Dimensional Vector Similarity Search with Enhanced
Triangle-Inequality-Based Pruning" (Song et al.), https://github.com/petrizhang/TRIM,
for course CMKL 41-634.

## Read this first

- **Day 2 results are not yet run.** No GIST benchmark (tHNSW, tIVFPQ, or the
  baselines) has been run. No GIST index, result or run log exists. The folder
  `trim-repro-package-logs/` holds only a `.gitkeep`, which marks where the Day 2
  logs will go.
- **The smoke test used synthetic data, not GIST.** `trim-logs/scripts/make_synthetic.py`
  generates the data: 10,000 × 960 random vectors and 100 queries, seed 42. The test
  only checks that the build and the benchmark pipeline run end to end. Its recall
  of 1.0 comes from the data being too easy. It is not a result and says nothing
  about TRIM's performance on GIST.
- Day 1 covered environment setup, the build, the Python bindings (with a
  no-AVX-512 fix, `trim-logs/fixes.patch`) and the synthetic smoke test.
  See `trim-logs/DAY1.md` and `trim-logs/status.md`.

## Files not included in this copy

The logs mention these files, but they are not in this copy.

| File named in the logs | What it is | How to recreate it |
|---|---|---|
| `~/trim-logs/patched-src/` (incl. `python/trimlib.cpython-312-x86_64-linux-gnu.so`) | A copy of upstream `include/` and `python/` with the no-AVX-512 fix applied, plus the compiled Python module (202 MB) | From upstream commit `481811b7d0315b45d24fcfdeb05543f454f3b6da` (481811b7) plus `trim-logs/fixes.patch`. See step 1 below (`run.log` 18:21:50–18:23:59) |
| `~/trim-logs/smoke/synthetic-960.hdf5` | The synthetic smoke-test dataset: 10,000 × 960 base vectors and 100 queries (39 MB) | `trim-logs/scripts/make_synthetic.py`, which uses seed 42. See step 2 below (`run.log` Step 4a) |
| `~/trim-logs/smoke/tmp/index/syn_hnswlib16x500.bin` | HNSW index built on the synthetic data (40 MB) | `trim-logs/scripts/smoke_thnsw.sh` builds it when it is missing (`smoke-thnsw-output.txt` lines 3–6). See step 3 below |
| `~/trim-logs/smoke/tmp/index/syn_pq8x120.bin` | PQ index built on the synthetic data (2.2 MB) | Built by the same `smoke_thnsw.sh` run (step 3) |
| `C:\trim-reproducibility\logs\wsl-setup-log.md` | Windows-side notes on the WSL2 and Ubuntu setup, cited in `status.md` | Cannot be recreated from this copy. It is a manual setup record kept outside both log folders. `run.log` line 2 records the resulting environment (kernel, `nproc=16`, `mem=23Gi`) |

Recreate steps. They assume upstream is cloned at `$HOME/trim` with the venv from `run.log` Steps 2–3b. Set `PUB` to the folder holding this README:

```bash
PUB=/path/to/this/folder
# 1. patched-src: upstream 481811b7 include/ + python/, plus fixes.patch, then build trimlib
mkdir -p "$HOME/trim-logs/patched-src"
git -C "$HOME/trim" archive 481811b7 include python | tar -x -C "$HOME/trim-logs/patched-src"
cd "$HOME/trim-logs/patched-src" && git apply "$PUB/trim-logs/fixes.patch"
source "$HOME/trim/.venv/bin/activate"
cd "$HOME/trim-logs/patched-src/python" && python setup.py build_ext --inplace
# 2. synthetic dataset (10000 x 960, 100 queries, seed 42 is fixed in the script)
mkdir -p "$HOME/trim-logs/smoke"
python "$PUB/trim-logs/scripts/make_synthetic.py" "$HOME/trim-logs/smoke/synthetic-960.hdf5"
# 3. the two .bin index files are built by the smoke test on first run
bash "$PUB/trim-logs/scripts/smoke_thnsw.sh"
```

## Sanitizing

The home directory is shown as `$HOME` in commands, compiler flags and tool output,
so those lines still work when pasted into a shell. In plain prose it is shown as `~`.
The machine name is shown as `HOST` and the username as `USER`. Large binary files
(the synthetic dataset, index files, the patched source tree and its build output)
are left out. Details are in `SANITIZE_REPORT.md`.
