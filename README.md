# TRIM reproduction package (CMKL 41-634)

> **Status: in progress. Day 1 setup and smoke test are complete. The GIST benchmarks, baselines, and comparison are not yet run.**
> Anything marked **[PLACEHOLDER]** is filled in after the Day 2 (GIST runs) and Day 3 (comparison) logs exist.

## What this reproduces

This package tries to repeat the key results of **TRIM: Accelerating High-Dimensional Vector Similarity Search with Enhanced Triangle-Inequality-Based Pruning** (Song et al., SIGMOD 2026 / PACMMOD 3(6), [doi:10.1145/3769838](https://doi.org/10.1145/3769838)). It uses the authors' own code from https://github.com/petrizhang/TRIM.

TRIM speeds up nearest-neighbour search: finding the stored vectors closest to a query vector. It uses a cheap lower bound on the distance (from the triangle inequality) to skip, or "prune", candidates that are too far away, so it computes fewer exact distances. The paper adds TRIM to existing search indexes. These are the variants:

| Variant | In scope? | Notes |
|---|---|---|
| **tHNSW** (TRIM on an HNSW graph, hnswlib) | yes | README command, GIST-960, k=10 |
| **tIVFPQ** (TRIM on FAISS IVFPQ) | yes | README command, GIST-960, k=10 |
| tIVFPQfs (TRIM on fast-scan IVFPQ) | **no** on CPUs without AVX-512 | Its code is AVX-512 only. `fixes.patch` compiles it out on such CPUs. My machine (see ENVIRONMENT.md) has no AVX-512. |

Terms used above:
- HNSW is a graph index: each vector links to nearby vectors, and search walks the graph.
- IVFPQ is a FAISS index that groups vectors into clusters and stores them compressed.
- AVX-512 is a set of fast CPU instructions. My CPU does not have it.
- GIST-960 is the benchmark dataset of 960-dimensional vectors, and k=10 means each query asks for its 10 nearest neighbours.

## Requirements

- Ubuntu 24.04 (WSL2 or native Linux), x86-64 with AVX2
- 16 cores recommended
- 24 GB RAM recommended
- About 15 GB free disk [estimate — confirm from Day 2 logs: PLACEHOLDER]
- Internet access for the clone, pip and the dataset download

The exact versions I used are in [ENVIRONMENT.md](ENVIRONMENT.md).

Every script expects this folder layout. All paths are relative to this folder:

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

Every script reads its settings from `scripts/common.sh`, and the defaults match the layout above. If your files are somewhere else, set these environment variables to point at them: `TRIM_DIR`, `VENV_DIR`, `TRIMLIB_DIR` (the folder holding the built `trimlib*.so`), `GIST_PATH`.

## Step 1 — Clone upstream at the exact commit

This step downloads the authors' code at the exact version I tested. Use the commit ID, not a branch name, so later changes upstream cannot change the code you run:

```bash
cd trim-repro-package
git init TRIM
git -C TRIM remote add origin https://github.com/petrizhang/TRIM.git
git -C TRIM fetch --depth 1 origin 481811b7d0315b45d24fcfdeb05543f454f3b6da
git -C TRIM checkout --detach FETCH_HEAD
git -C TRIM rev-parse HEAD     # must print 481811b7d0315b45d24fcfdeb05543f454f3b6da
```

## Step 2 — Apply fixes.patch

This step applies my small fix to the code, so that it compiles on CPUs without AVX-512:

```bash
git -C TRIM apply --check ../fixes.patch   # dry run: must print nothing
git -C TRIM apply ../fixes.patch
git -C TRIM diff --stat                    # include/trim/trim-forwards.h | 8 ++++++++
```

Why it is needed: without the patch, the Python bindings (the C++ code that Python calls) fail to compile on CPUs without AVX-512, with this error:
`tIVFPQfs.h:120: 'L2SqrSIMD16ExtAVX512' is not a member of 'hnswlib'`.
The patch compiles tIVFPQfs only when the compiler targets AVX-512. It does not change the tHNSW or tIVFPQ code. The patch header has the details.

## Step 3 — Install packages (exact versions)

This step installs the compiler, the libraries and the Python packages, at the versions I used, so your build matches mine.

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

- `git`, `python3-venv`, `python3-dev` and `time` (for `/usr/bin/time`) were already installed on my machine, so my logs do not record their versions (UNKNOWN). The upstream README does not list them, but the steps below need them.
- Ubuntu replaces packages when it ships security updates, so a pinned version may disappear. If apt says a pinned version is not available, install the package without `=version` and write down the version you got.

Install the Python packages in a virtual environment, a private Python setup for this project only. Ubuntu 24.04 blocks system-wide `pip install` (PEP 668):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install pip==26.3
pip install numpy==2.5.5 pandas==3.1.1 scipy==1.18.1 h5py==3.16.0 \
            faiss-cpu==1.16.0 hnswlib==0.8.0 pybind11==3.1.0 setuptools==84.2.1
```

The upstream README does not list `setuptools`, but Python 3.12 needs it to run `setup.py`.

## Step 4 — Build the C++ library and the Python bindings

This step compiles the C++ code and then the Python module `trimlib`, which the benchmark scripts import:

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

**Do not run `python setup.py install`.** It is deprecated and not needed. Python finds `trimlib` through `PYTHONPATH`, the list of folders Python searches for modules. `scripts/common.sh` sets it to `TRIM/python` (or `$TRIMLIB_DIR`) for you. To set it yourself:

```bash
export PYTHONPATH="$PWD/TRIM/python"
python -c "import trimlib; print(trimlib.__file__)"
```

## Step 5 — Smoke test (synthetic data, about 5 seconds)

This step runs a quick test on small made-up data. It checks that the build and the benchmark pipeline work before you run the real dataset.

Measured time: 5 s for my Day 1 run of the same tHNSW command (`logs/trim-logs/run.log`, 2026-11-26 18:24:30). `scripts/smoke_test.sh` also generates the dataset first, and I did not log its own run time.

```bash
scripts/smoke_test.sh
```

The script makes a small synthetic dataset in `smoke/`: 10,000 vectors, 100 queries, 960 dimensions like GIST, and a fixed seed so the data is the same every time. It then runs the upstream README's tHNSW command on it.

**Expected:** `smoke/results/QPSDCRecall_SYN_tHNSW_KNN_k10.csv` with a header and **11 rows** (one per `ef`), and the script prints `SMOKE TEST PASS`. `ef` is the search effort setting: higher means a slower but more thorough search.

Recall (the share of true nearest neighbours found) is about 1.0 at every `ef`, because the synthetic data is easy. This step only shows that the pipeline works. Its numbers are not results.

## Step 6 — Get the GIST dataset

This step downloads the real benchmark dataset and checks that the file is complete.

Download `gist-960.hdf5` from https://huggingface.co/datasets/songyitong/TRIM_Datasets
[PLACEHOLDER: exact file link on Hugging Face — not yet verified]. Then:

```bash
mkdir -p data
mv /path/to/gist-960.hdf5 data/gist-960.hdf5
stat -c %s data/gist-960.hdf5      # must print 3933056096
```

The run scripts check this file size and refuse to start if it is different. If you keep the file somewhere else, set `GIST_PATH=/path/to/gist-960.hdf5` instead of moving it. Do not commit the dataset.

## Step 7 — Run the GIST benchmarks

This step runs the two TRIM benchmarks on GIST and saves the results and logs.

Run them **one after the other, not at the same time**. Two runs at once would compete for the CPU and make the QPS (queries per second) numbers wrong. Each script refuses to start while another `bench.py` is running.

```bash
DRY_RUN=1 scripts/run_gist_thnsw.sh    # optional: print the exact command, run nothing
scripts/run_gist_thnsw.sh              # starts in the background with nohup; prints PID and log paths
tail -f logs/gist_thnsw_*.out.txt      # follow progress; Ctrl-C stops following, not the run
# when it has finished:
scripts/run_gist_tivfpq.sh
```

Each run writes these files:
- `results/QPSDCRecall_GIST_tHNSW_KNN_k10.csv` or `results/QPSDCRecall_GIST_tIVFPQ_KNN_k10.csv`: QPS, recall, pruning ratio and distance computations for each setting. The pruning ratio is the share of candidates TRIM skipped without computing an exact distance.
- `logs/<run>.out.txt`: everything bench.py prints
- `logs/<run>.time.txt`: `/usr/bin/time -v` output (wall time, peak memory)
- `logs/<run>.env.txt`: commit, versions, CPU and memory at start
- `logs/<run>.pid`: the background process ID

The commands are the upstream README commands. The only change is `-d`, the dataset path.
The first run builds the indexes in `tmp/index/`. Later runs reuse them, so the build time is recorded only once (`*.build.seconds.txt`).

**Expected runtime:** tHNSW [PLACEHOLDER from Day 2 logs]; tIVFPQ [PLACEHOLDER from Day 2 logs].
**Peak memory:** [PLACEHOLDER from Day 2 logs].

## Step 8 — Compare with the paper

This step puts your numbers next to the paper's numbers so you can see whether its claims hold.

Fill in [COMPARISON.md](COMPARISON.md) using `results/*.csv` and the numbers reported in the paper. Every "my value" must point to a file in `results/` or `logs/`. Mark anything without a supporting file as unverified.

## Known issues

1. **Thread count in `bench/trim.py`.** It sets `num_threads = os.cpu_count() - 2` (14 on a 16-CPU machine) and crashes on machines with fewer than 3 CPUs: unverified (reported in my notes, not tested). I leave it unchanged. This setting only sizes the thread pool that precomputes PQ reconstruction errors when the index loads. PQ (product quantization) is the compressed copy of each vector. Queries run one at a time, so QPS measures single-thread performance. The scripts set `OMP_NUM_THREADS=16`, which affects FAISS index training. hnswlib's index build uses all CPUs by default.
2. **Path error in the upstream README.** After building in `build/`, it says `cd python`, but `python/` is at the repo root. Use `cd ../python` instead (Step 4).
3. **`python setup.py install` is deprecated.** On CPUs without AVX-512 it fails with the same error as the build. Use `build_ext --inplace` + `PYTHONPATH` instead (Step 4).
4. **No AVX-512:** the bindings need `fixes.patch` (Step 2). `CMakeLists.txt` also forces AVX-512 compiler flags, so the five example programs in `TRIM/build` may crash on such CPUs. The benchmarks do not use them.
5. **`bench.py` adds rows to an existing results CSV instead of replacing it.** To keep two runs from mixing, the run scripts refuse to start if their CSV already exists. To run again, move the old CSV somewhere else first.
6. **Baselines:** the README commands run only the TRIM variants. To check the paper's speedup claims, you also need runs of plain HNSW / IVFPQ without TRIM. [PLACEHOLDER: decide on Day 2/3]

## License and credit

Upstream TRIM is licensed under Apache 2.0 ([LICENSE](LICENSE)). Credit to the original authors is in [NOTICE.md](NOTICE.md).
