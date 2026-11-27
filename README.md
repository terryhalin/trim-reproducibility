# TRIM reproduction package (CMKL 41-634)

> **Status: in progress. Day 1 setup and smoke test are complete. The GIST benchmarks, baselines, and comparison are not yet run.**
> Anything marked **[PLACEHOLDER]** is filled in after the Day 2 (GIST runs) and Day 3 (comparison) logs exist.

## What this reproduces

The key results of **TRIM: Accelerating High-Dimensional Vector Similarity Search with Enhanced Triangle-Inequality-Based Pruning** (Song et al., SIGMOD 2026 / PACMMOD 3(6), [doi:10.1145/3769838](https://doi.org/10.1145/3769838)), using the authors' code at https://github.com/petrizhang/TRIM.

| Variant | In scope? | Notes |
|---|---|---|
| **tHNSW** (TRIM on an HNSW graph, hnswlib) | yes | README command, GIST-960, k=10 |
| **tIVFPQ** (TRIM on FAISS IVFPQ) | yes | README command, GIST-960, k=10 |
| tIVFPQfs (TRIM on fast-scan IVFPQ) | **no** on CPUs without AVX-512 | Its code is AVX-512 only. `fixes.patch` compiles it out on such CPUs. Our machine (see ENVIRONMENT.md) has no AVX-512. |

## Requirements

- Ubuntu 24.04 (WSL2 or native Linux), x86-64 with AVX2
- 16 cores recommended
- 24 GB RAM recommended
- About 15 GB free disk [estimate — confirm from Day 2 logs: PLACEHOLDER]
- Internet access for the clone, pip and the dataset download

Exact versions we used: [ENVIRONMENT.md](ENVIRONMENT.md).

Folder layout used by every script (all paths relative to this folder):

```
trim-repro-package/
  TRIM/            upstream clone (Step 1)      - not committed
  .venv/           Python virtual env (Step 3)  - not committed
  data/            gist-960.hdf5 (Step 6)       - not committed
  tmp/index/       indexes built by bench.py    - not committed
  results/         benchmark CSVs (Step 7)
  logs/            run logs, /usr/bin/time output (Step 7)
  scripts/         smoke_test.sh, run_gist_*.sh, common.sh, make_synthetic.py
```

Every script reads `scripts/common.sh`. Its defaults are the layout above. Override with environment variables if your files live elsewhere: `TRIM_DIR`, `VENV_DIR`, `TRIMLIB_DIR` (the folder holding the built `trimlib*.so`), `GIST_PATH`.

## Step 1 — Clone upstream at the exact commit

Pin the commit, not a branch, so later upstream changes cannot change the code you run:

```bash
cd trim-repro-package
git init TRIM
git -C TRIM remote add origin https://github.com/petrizhang/TRIM.git
git -C TRIM fetch --depth 1 origin 481811b7d0315b45d24fcfdeb05543f454f3b6da
git -C TRIM checkout --detach FETCH_HEAD
git -C TRIM rev-parse HEAD     # must print 481811b7d0315b45d24fcfdeb05543f454f3b6da
```

## Step 2 — Apply fixes.patch

```bash
git -C TRIM apply --check ../fixes.patch   # dry run: must print nothing
git -C TRIM apply ../fixes.patch
git -C TRIM diff --stat                    # include/trim/trim-forwards.h | 8 ++++++++
```

Why: without it, the Python bindings fail to compile on CPUs without AVX-512
(`tIVFPQfs.h:120: 'L2SqrSIMD16ExtAVX512' is not a member of 'hnswlib'`). The patch compiles tIVFPQfs only when the compiler targets AVX-512. tHNSW and tIVFPQ code is not changed. Details are in the patch header.

## Step 3 — Install packages (exact versions)

System packages (versions from ENVIRONMENT.md):

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential=12.10ubuntu1 \
  cmake=3.28.3-1build7 \
  libopenblas-dev=0.3.26+ds-1ubuntu0.1 \
  liblapack-dev=3.12.0-3build1.1 \
  libhdf5-dev=1.10.10+repack-3.1ubuntu4 \
  git python3-venv python3-dev time
```

- `git`, `python3-venv`, `python3-dev` and `time` (for `/usr/bin/time`) were already installed on our machine, so their versions are not in our logs (UNKNOWN). They are not in the upstream README, but the steps below need them.
- If apt says a pinned version is no longer available (Ubuntu replaces security-updated packages), install without `=version` and record the versions you got.

Python packages, in a virtual environment (Ubuntu 24.04 blocks system-wide `pip install`, PEP 668):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pip==26.3
pip install numpy==2.5.5 pandas==3.1.1 scipy==1.18.1 h5py==3.16.0 \
            faiss-cpu==1.16.0 hnswlib==0.8.0 pybind11==3.1.0 setuptools==84.2.1
```

`setuptools` is not in the upstream README. Python 3.12 needs it to run `setup.py`.

## Step 4 — Build the C++ library and the Python bindings

```bash
# C++ static libraries + example programs (the benchmarks do not use the examples)
mkdir -p TRIM/build && cd TRIM/build
cmake ..
make -j16
cd ../python                     # NOT build/python: python/ is at the repo root (README error)

# Python module 'trimlib' (needs the venv from Step 3 active)
python setup.py build_ext --inplace
ls trimlib*.so                   # trimlib.cpython-312-x86_64-linux-gnu.so
cd ../..
```

**Do not run `python setup.py install`.** It is deprecated and not needed. Python finds `trimlib` through `PYTHONPATH`, which `scripts/common.sh` sets to `TRIM/python` (or `$TRIMLIB_DIR`) for you. To use it by hand:

```bash
export PYTHONPATH="$PWD/TRIM/python"
python -c "import trimlib; print(trimlib.__file__)"
```

## Step 5 — Smoke test (synthetic data, about 5 seconds)

Measured time: 5 s for the Day 1 run of the same tHNSW command (`logs/trim-logs/run.log`, 2026-11-26 18:24:30). `scripts/smoke_test.sh` also generates the dataset first, and its own run time was not logged.

```bash
scripts/smoke_test.sh
```

This makes a small synthetic dataset in `smoke/` (10,000 vectors, 100 queries, 960 dimensions like GIST, fixed seed). It then runs the upstream README's tHNSW command on it.
**Expected:** `smoke/results/QPSDCRecall_SYN_tHNSW_KNN_k10.csv` with a header and **11 rows** (one per `ef`), and the script prints `SMOKE TEST PASS`.
Recall is about 1.0 at every `ef` because the synthetic data is easy. This step only shows the pipeline works. Its numbers are not results.

## Step 6 — Get the GIST dataset

Download `gist-960.hdf5` from https://huggingface.co/datasets/songyitong/TRIM_Datasets
[PLACEHOLDER: exact file link on Hugging Face — not yet verified]. Then:

```bash
mkdir -p data
mv /path/to/gist-960.hdf5 data/gist-960.hdf5
stat -c %s data/gist-960.hdf5      # must print 3933056096
```

The run scripts check this size and refuse to start if it differs. If the file is elsewhere, set `GIST_PATH=/path/to/gist-960.hdf5` instead of moving it. Do not commit the dataset.

## Step 7 — Run the GIST benchmarks

Run them **one after the other, not at the same time** (two runs would compete for CPU and make QPS wrong — each script refuses to start while another `bench.py` is running):

```bash
DRY_RUN=1 scripts/run_gist_thnsw.sh    # optional: print the exact command, run nothing
scripts/run_gist_thnsw.sh              # starts in the background with nohup; prints PID and log paths
tail -f logs/gist_thnsw_*.out.txt      # follow progress; Ctrl-C stops following, not the run
# when it has finished:
scripts/run_gist_tivfpq.sh
```

Each run writes:
- `results/QPSDCRecall_GIST_tHNSW_KNN_k10.csv` or `results/QPSDCRecall_GIST_tIVFPQ_KNN_k10.csv`: QPS, recall, pruning ratio and distance computations per setting
- `logs/<run>.out.txt`: everything bench.py prints
- `logs/<run>.time.txt`: `/usr/bin/time -v` output (wall time, peak memory)
- `logs/<run>.env.txt`: commit, versions, CPU and memory at start
- `logs/<run>.pid`: the background process ID

The commands are the upstream README commands, unchanged except `-d` (dataset path).
The first run builds the indexes in `tmp/index/`. Later runs reuse them, so build time is recorded only once (`*.build.seconds.txt`).

**Expected runtime:** tHNSW [PLACEHOLDER from Day 2 logs]; tIVFPQ [PLACEHOLDER from Day 2 logs].
**Peak memory:** [PLACEHOLDER from Day 2 logs].

## Step 8 — Compare with the paper

Fill in [COMPARISON.md](COMPARISON.md) from `results/*.csv` and the paper's reported numbers. Every "our value" must point to a file in `results/` or `logs/`. Mark anything without a supporting file as unverified.

## Known issues

1. **Thread count in `bench/trim.py`.** It sets `num_threads = os.cpu_count() - 2` (14 on a 16-CPU machine) and crashes on machines with fewer than 3 CPUs: unverified (reported in our notes, not tested). We leave it unchanged. It only sizes the thread pool that precomputes PQ reconstruction errors when the index loads. Queries run one at a time, so QPS is single-thread performance. The scripts set `OMP_NUM_THREADS=16`, which affects FAISS index training; hnswlib's index build uses all CPUs by default.
2. **Upstream README path error.** After building in `build/` it says `cd python`, but `python/` is at the repo root. Use `cd ../python` (Step 4).
3. **`python setup.py install` is deprecated** and fails the same way as the build on non-AVX-512 CPUs. Use `build_ext --inplace` + `PYTHONPATH` (Step 4).
4. **No AVX-512:** the bindings need `fixes.patch` (Step 2). `CMakeLists.txt` also forces AVX-512 compiler flags, so the five example programs in `TRIM/build` may crash on such CPUs. The benchmarks do not use them.
5. **`bench.py` appends to an existing results CSV.** The run scripts refuse to start if their CSV already exists, so two runs never mix. Move the old CSV away to rerun.
6. **Baselines:** the README commands run only the TRIM variants. Checking the paper's speedup claims also needs plain HNSW / IVFPQ runs. [PLACEHOLDER: decide on Day 2/3]

## License and credit

Upstream TRIM is Apache 2.0 ([LICENSE](LICENSE)). Credit to the original authors: [NOTICE.md](NOTICE.md).
