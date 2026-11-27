# TRIM reproduction — Day 1 logs (sanitized)

This folder holds my Day 1 working logs, in sanitized form: personal details
such as my username and machine name are replaced (see "Sanitizing" below).
The logs come from my reproduction of "TRIM: Accelerating High-Dimensional
Vector Similarity Search with Enhanced Triangle-Inequality-Based Pruning"
(Song et al.), https://github.com/petrizhang/TRIM, for course CMKL 41-634.

## Read this first

- **Day 2 results are not yet run.** I have not run any GIST benchmark (tHNSW,
  tIVFPQ, or the baselines). No GIST index, result or run log exists. In this
  package, the Day 2 logs will go in `logs/`, where `.gitkeep` (an empty
  placeholder file) holds the folder until then.
- **The smoke test used synthetic data, not GIST.** The script
  `trim-logs/scripts/make_synthetic.py` generates the data: 10,000 × 960 random
  vectors and 100 queries, with seed 42. The test only checks that the build and
  the benchmark pipeline run from start to finish. Its recall of 1.0 is only
  because the data is too easy. It is not a result, and it says nothing about
  how TRIM performs on GIST.
- On Day 1 I set up the environment, built the code, built the Python bindings
  (with a fix for CPUs without AVX-512, `trim-logs/fixes.patch`) and ran the
  synthetic smoke test. See `trim-logs/DAY1.md` and `trim-logs/status.md`.

## Files not included in this copy

The logs mention these files, but they are not in this copy. The table says what each one is and, where possible, how to recreate it.

| File named in the logs | What it is | How to recreate it |
|---|---|---|
| `~/trim-logs/patched-src/` (incl. `python/trimlib.cpython-312-x86_64-linux-gnu.so`) | A copy of upstream `include/` and `python/` with the no-AVX-512 fix applied, plus the compiled Python module (202 MB) | From upstream commit `481811b7d0315b45d24fcfdeb05543f454f3b6da` (481811b7) plus `trim-logs/fixes.patch`. See step 1 below (`run.log` 18:21:50–18:23:59) |
| `~/trim-logs/smoke/synthetic-960.hdf5` | The synthetic smoke-test dataset: 10,000 × 960 base vectors and 100 queries (39 MB) | `trim-logs/scripts/make_synthetic.py`, which uses seed 42. See step 2 below (`run.log` Step 4a) |
| `~/trim-logs/smoke/tmp/index/syn_hnswlib16x500.bin` | HNSW index built on the synthetic data (40 MB) | `trim-logs/scripts/smoke_thnsw.sh` builds it when it is missing (`smoke-thnsw-output.txt` lines 3–6). See step 3 below |
| `~/trim-logs/smoke/tmp/index/syn_pq8x120.bin` | PQ index built on the synthetic data (2.2 MB) | Built by the same `smoke_thnsw.sh` run (step 3) |
| `C:\trim-reproducibility\logs\wsl-setup-log.md` | Windows-side notes on the WSL2 and Ubuntu setup, cited in `status.md` | Cannot be recreated from this copy. It is a manual setup record kept outside both log folders. `run.log` line 2 records the resulting environment (kernel, `nproc=16`, `mem=23Gi`) |

To recreate them, run the steps below. They assume you cloned upstream to `$HOME/trim` and created the venv as in `run.log` Steps 2–3b. First set `PUB` to the folder that holds this README:

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

To sanitize the logs, I replaced personal details with neutral names:
- The home folder is `$HOME` in commands, compiler flags and tool output, so those
  lines still work if you paste them into a shell. In plain text it is `~`.
- The machine name is `HOST` and the username is `USER`.

I also left out large binary files: the synthetic dataset, the index files, and
the patched source tree with its build output. `SANITIZE_REPORT.md` has the details.
