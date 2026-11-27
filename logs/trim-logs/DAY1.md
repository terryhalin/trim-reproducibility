# Day 1 — setup and smoke test (2026-11-26)

Every result below comes from a file in ~/trim-logs/ (named in brackets). Full timestamped trail: [run.log].

## What each command does, in plain language

### 1. Log folder
| Command | What it does |
|---|---|
| `mkdir -p ~/trim-logs/scripts` | Makes the folder for all logs, notes and helper scripts. |

### 2. Get the code
| Command | What it does |
|---|---|
| `git clone --depth 1 https://github.com/petrizhang/TRIM.git ~/trim` | Downloads the authors' code. `--depth 1` fetches only the latest version, not the whole history. We got commit `481811b7` (2026-04-02) [run.log]. We never edit files in ~/trim. |

### 3. Install tools and build
| Command | What it does |
|---|---|
| `apt-get install build-essential cmake libopenblas-dev liblapack-dev libhdf5-dev` | Installs the C++ compiler (g++ 13.2), the CMake build tool (3.28.3), fast maths libraries (OpenBLAS 0.3.26, LAPACK 3.12.0) and the HDF5 library that reads `.hdf5` data files [run.log]. Run as root through `wsl -u root` instead of `sudo`, so no password prompt. |
| `python3 -m venv ~/trim/.venv` | Makes a private Python environment for this project. Ubuntu 24.04 refuses `pip install` into the system Python (PEP 668). `.venv` is already in upstream's `.gitignore`. |
| `pip install numpy pandas scipy h5py faiss-cpu hnswlib pybind11 setuptools` | Installs the Python libraries. numpy/scipy/pandas = maths and tables; h5py = reads HDF5; faiss-cpu = Meta's vector search library (builds the PQ index); hnswlib = the HNSW graph index; pybind11 = glue to call C++ from Python. `setuptools` is not in the README, but Python 3.12 needs it for `setup.py`. Versions: Python 3.12.3, numpy 2.5.5, pandas 3.1.1, scipy 1.18.1, h5py 3.16.0, faiss-cpu 1.16.0, hnswlib 0.8.0, pybind11 3.1.0, setuptools 84.2.1 [run.log, pip-install.txt]. |
| `cd ~/trim/build && cmake .. && make -j16` | Builds the C++ part: two static libraries (`libfaiss.a`, `libfaiss_blas.a`) and five example programs. `cmake` writes the build recipe and `make` runs it with 16 parallel jobs. The README says `make -j` (no limit); we used 16 per our thread rule. Exit 0, 37 s, 0 warnings [cmake.txt, make.txt]. The benchmarks do not use these files. |
| `python setup.py build_ext --inplace` (in ~/trim/python) | Compiles the Python module `trimlib` that the benchmarks import. **Failed** [bindings-build.txt]; see Problems. |
| `git apply ~/trim-logs/fixes.patch` (in ~/trim-logs/patched-src) | Applies our 8-line fix to a *copy* of upstream's `include/` and `python/`, so ~/trim stays exactly as cloned. |
| `python setup.py build_ext --inplace` (in ~/trim-logs/patched-src/python) | Compiles `trimlib` from the patched copy. Exit 0, 129 s [bindings-build-patched.txt]. |

### 4. Smoke test
| Command | What it does |
|---|---|
| `python ~/trim-logs/scripts/make_synthetic.py ~/trim-logs/smoke/synthetic-960.hdf5` | Makes a small fake dataset in the same layout as the paper's files: 10,000 base vectors (`train`) and 100 queries (`test`), 960 dimensions like GIST, drawn around 50 random cluster centres (seed 42). `neighbors` is the exact top-100 per query (brute-force faiss search). `ranges` / `neighbors_001` / `neighbors_01` are placeholders for range search (radius holding 1% / 10% of the data) and are not checked. 39 MB [run.log]. |
| `~/trim-logs/scripts/smoke_thnsw.sh` | Runs the README's tHNSW command on the fake dataset. The only changes: `-d` points to the fake file, `-nq 100`, and it runs from ~/trim-logs/smoke so outputs land there. `PYTHONPATH` makes Python use the patched `trimlib`. |

What the tHNSW command does, step by step:
1. `bench.py` loads the dataset.
2. No index exists yet, so it builds an **HNSW graph** (`M:16` links per node, `efConstruction:500` = build effort) and a **PQ index** (`pq_m:120` pieces x `pq_nbits:8` = 256 codewords each). PQ is a compressed copy of every vector. TRIM uses it for cheap lower-bound distances. The build took 3.4 s.
3. It loads both indexes into TRIM (`dco:"trim"` = use TRIM's pruning when comparing distances).
4. For each `ef` (search effort: 10 to 1000) it runs every query with `k=10`, `gamma=0.67` (how tight TRIM's bound is) and batch pruning on. It measures **recall** (share of the true 10 nearest found), **QPS** (queries per second), **pruning_ratio** (share of candidates skipped without an exact distance), and how many distance computations were actually done vs the total.
5. It writes one CSV row per `ef`.

### 5. Dataset check
| Command | What it does |
|---|---|
| `stat -c %s /mnt/c/trim-reproducibility/data/gist-960.hdf5` | Prints the file size in bytes. Result: 3933056096, same as before [run.log]. The file was not copied or moved. |

## Smoke test result — PASS (the pipeline works)
CSV written: ~/trim-logs/smoke/results/QPSDCRecall_SYN_tHNSW_KNN_k10.csv (header + 11 rows, one per ef) [smoke-thnsw-output.txt].

| ef | recall | QPS | pruning ratio | exact distances / total |
|---|---|---|---|---|
| 10 | 1.0 | 6069 | 0.649 | 206 / 608 |
| 150 | 1.0 | 5596 | 0.618 | 225 / 608 |
| 300 | 1.0 | 3209 | 0.735 | 308 / 1186 |
| 1000 | 1.0 | 994 | 0.759 | 1000 / 4154 |

How to read it:
- TRIM's pruning is active: it skipped 62-77% of candidate distance computations.
- **Recall = 1.0 at every ef, even ef=10. The fake data is too easy.** This proves the code runs end to end, not that accuracy or speed match the paper. Do not use these numbers as results in the report.
- The PQ index was written by pip faiss 1.16 and read by TRIM's bundled faiss 1.11 code without error, which is a good sign for GIST.

## Problems and fixes
1. **The Python bindings do not compile on this CPU.** Error: `tIVFPQfs.h:120: 'L2SqrSIMD16ExtAVX512' is not a member of 'hnswlib'` [bindings-build.txt, bindings-install.txt].
   Cause: the Core Ultra 7 155H has AVX2 but no AVX-512 (checked in /proc/cpuinfo). The tIVFPQfs (fast-scan IVFPQ) code is written only in AVX-512, and `bindings.cc` always compiles it in. tHNSW and tIVFPQ have AVX2 code paths and need no change.
   Fix: [fixes.patch] adds 8 lines to `include/trim/trim-forwards.h` so that tIVFPQfs is compiled only on AVX-512 machines. Elsewhere, creating it raises a clear error. Applied only to the copy in ~/trim-logs/patched-src (user's choice); ~/trim is unmodified.
   **Effect on the report: tIVFPQfs cannot be run on this laptop.**
2. **README path mistake:** after building in `build/` it says `cd python`, but `python/` is at the repo root. We ran it from ~/trim/python.
3. **`python setup.py install` was skipped.** It is deprecated and failed with the same error as the build. We load `trimlib` through `PYTHONPATH` instead.
4. CMakeLists.txt forces AVX-512 compiler flags. The build succeeded, but the five example programs in ~/trim/build may crash on this CPU if run. The benchmarks do not use them, and we did not run them.
5. Cleanup: the failed build left `~/trim/python/tmp` and `~/trim/python/build` (compiler-probe and intermediate files). We removed them so ~/trim matches the clone.

## Threads
- `bench/trim.py` sets `num_threads = os.cpu_count()-2`, which is **14** here (16 visible CPUs). Left unchanged, as instructed. The code shows it only sizes the thread pool that precomputes PQ reconstruction errors when the index loads (`include/trim/trim-forwards.h`). **Queries run one at a time, so QPS is single-thread performance and does not depend on this value.**
- hnswlib's `add_items` (index build) uses all 16 CPUs by default, so build times depend on that.
- `make -j16` was the only thread setting we chose.

## Not done today
- No GIST benchmark run (Day 2, waiting for the go-ahead).
