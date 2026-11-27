# Package check — ~/trim-repro-package (2026-11-26)

Read-only check: nothing in the package was changed, moved or committed, and no git push or GitHub command was run.
Proof: a fingerprint of every package file (mtime, size, path) was the same before and after the check (`2e620a9463031eb54a677a61a05ee798`).
`py_compile` wrote its cache to /tmp (`PYTHONPYCACHEPREFIX`), and the `.gitignore` test used a copy in a throwaway /tmp repo.

**Result: 0 FAIL. 9 PASS (items 1, 2, 4, 5, 6, 7, 9, 10, plus the privacy check). 2 NOTE (items 3 and 8).**

| # | Check | Result | Reason |
|---|---|---|---|
| 1 | Files exist | PASS | All 14 requested files are present and there are no extra files. The three `.sh` entry scripts are 755; `common.sh` (sourced) and `make_synthetic.py` (run with python3) are 644. |
| 2 | Size | PASS | 38,131 bytes in total (88K on disk). The largest file is LICENSE at 11,357 bytes; 0 files are over 1 MB. |
| 3a | Exclusions: contents | PASS | No .hdf5, .bin, .empty, .so, .venv, build, TRIM clone, .git, tmp/ or smoke/ in the package. |
| 3b | Exclusions: .gitignore | NOTE | It covers the default layout (TRIM/, .venv/, data/, tmp/, smoke/, *.hdf5, __pycache__/; tested: all ignored). It has no standalone rules for `*.bin`, `*.empty`, `*.so` or `build/`, so a stray `foo.bin` or `build/` at the package root would **not** be ignored. |
| 4 | Syntax | PASS | `bash -n` passes on common.sh, smoke_test.sh, run_gist_thnsw.sh and run_gist_tivfpq.sh; `python3 -m py_compile scripts/make_synthetic.py` passes. |
| 5 | LICENSE | PASS | Byte-identical (`cmp`) to `git show 481811b7:LICENSE` and to ~/trim/LICENSE. sha256 c71d239d…0ab4; ~/trim HEAD = 481811b7d0315b45d24fcfdeb05543f454f3b6da. |
| 6 | fixes.patch | PASS | Byte-identical to ~/trim-logs/fixes.patch, sha256 d7d69dfd…3da on both. |
| 7 | README steps | PASS | Steps 1–8 are in order and each has commands except Step 8, which by design is a pointer to COMPARISON.md. See the details below. |
| 8 | Placeholders | NOTE | 28 matches: 19 lines with PLACEHOLDER (README 6 lines, COMPARISON 13) and 9 with UNKNOWN (ENVIRONMENT 7, README 1, common.sh 1). No TODOs. The full list is below. |
| 9 | Smoke test | PASS | ~/trim-logs/package-smoke-test.txt (18:49:59, the only package-smoke run) ends with `SMOKE TEST PASS: ... has 11 rows`. package-smoke-results.csv has 11 data rows, and package-smoke-bench-output.txt has 11 query configs. |
| 10 | No GIST runs | PASS | No bench.py process is running; results/ and logs/ hold only .gitkeep; no tmp/ in the package; no `gist_*` files anywhere under ~ or /tmp. run.log shows only the GIST size check and the DRY_RUN and guard tests (lines 54, 56, 81). |
| + | Privacy | PASS | No names, hostnames, /home paths or emails in the package. |

## Item 7 details — README steps

| Heading | Code blocks / command lines |
|---|---|
| Requirements (layout diagram) | 1 / 8 |
| Step 1 — Clone upstream at the exact commit | 1 / 6 |
| Step 2 — Apply fixes.patch | 1 / 3 |
| Step 3 — Install packages (exact versions) | 2 / 13 |
| Step 4 — Build the C++ library and the Python bindings | 2 / 11 |
| Step 5 — Smoke test | 1 / 1 |
| Step 6 — Get the GIST dataset | 1 / 3 |
| Step 7 — Run the GIST benchmarks | 1 / 5 |
| Step 8 — Compare with the paper | 0 (points to COMPARISON.md) |

Paths that are in neither the package nor ~/trim-logs. All are NOTE (expected), none are errors:
- **Created by an earlier step:** `TRIM/`, `TRIM/build`, `../python` (= `TRIM/python`), `$PWD/TRIM/python`, `include/trim/trim-forwards.h` (inside the clone); `.venv/`, `.venv/bin/activate` (Step 3); `data/`, `data/gist-960.hdf5` (Step 6); `tmp/index/`, `logs/gist_thnsw_*.out.txt` (Step 7).
- **Not package paths:** `build/python` appears only in a comment saying *not* to use it. `/path/to/gist-960.hdf5` is for the user to replace. `/usr/bin/time` is a system file from the `time` package.
- Relative paths checked by hand: `git -C TRIM apply ../fixes.patch` resolves to the package's `fixes.patch`. `cd TRIM/build` → `cd ../python` → `cd ../..` returns to the package root.
- Caveat: my automated path check wrongly marked a few folders (TRIM/, .venv/, data/, tmp/index/) as "present". The exclusion check in item 3a confirms they are not in the package.

## Item 8 — every marker (all NOTE: expected for Day 2 / Day 3)

| File:line | Marker |
|---|---|
| README.md:3 | PLACEHOLDER (status banner explaining the markers) |
| README.md:20 | PLACEHOLDER — disk need (15 GB estimate) |
| README.md:79 | UNKNOWN — versions of git, python3-venv, python3-dev, time |
| README.md:129 | PLACEHOLDER — exact Hugging Face file link |
| README.md:161 | PLACEHOLDER ×2 — expected runtime, tHNSW and tIVFPQ |
| README.md:162 | PLACEHOLDER — peak memory |
| README.md:175 | PLACEHOLDER — baseline runs decision |
| ENVIRONMENT.md:3 | UNKNOWN (legend line) |
| ENVIRONMENT.md:9 | UNKNOWN — CPU model |
| ENVIRONMENT.md:10 | UNKNOWN — AVX-512 |
| ENVIRONMENT.md:13 | UNKNOWN — OS release |
| ENVIRONMENT.md:22 | UNKNOWN — exact gcc version |
| ENVIRONMENT.md:23 | UNKNOWN — exact g++ version |
| ENVIRONMENT.md:29 | UNKNOWN — git, python3-venv, python3-dev, time versions |
| COMPARISON.md:10–14 | PLACEHOLDER — 5 tHNSW rows |
| COMPARISON.md:20–23 | PLACEHOLDER — 4 tIVFPQ rows |
| COMPARISON.md:29 | PLACEHOLDER — tIVFPQfs paper value |
| COMPARISON.md:33–34 | PLACEHOLDER — sources |
| COMPARISON.md:38 | PLACEHOLDER — why results differ |
| scripts/common.sh:49 | `UNKNOWN` is a runtime fallback string, not a placeholder — no action needed |

## Claims in the package not backed by a log (found during the check)
- README.md:116 says the smoke test takes "about 1 minute". run.log lines 78→79 (18:49:54 → 18:49:59) and the package-smoke file times show **about 5 seconds**, and the duration itself was not logged. **Unverified as written.**
- README.md:170 says bench/trim.py "crashes on machines with fewer than 3 CPUs". This comes from the user's project notes, not from a test or a log. **Unverified.**

## Must change before the package is pushed to GitHub
1. **Fill every PLACEHOLDER** (README 6 lines, COMPARISON 13 lines) from the Day 2 / Day 3 logs, or mark it "not measured".
2. **Resolve the ENVIRONMENT.md UNKNOWNs** with one logged check (CPU model, AVX-512 flag, Ubuntu release, `gcc --version`, versions of git, python3-venv, python3-dev and time), or keep them marked UNKNOWN on purpose.
3. **Fix the smoke-test duration** in the README.md:116 heading ("about 1 minute"): replace it with a logged, measured time.
4. **Back up or mark the "<3 CPUs crashes" claim** (README.md:170) as unverified.
5. **Add `*.bin`, `*.empty`, `*.so` and `build/` to .gitignore** to be safe.
6. **Decide on baselines** (README.md:175, COMPARISON.md:11 and :21). Without plain HNSW / IVFPQ runs, the speedup rows can't be filled.
7. **Privacy check of Day 2 logs before committing them:** `logs/*.env.txt` records the hostname (`uname -a`), and `.env.txt` / `.cmd.txt` will contain home-directory paths when the overrides point at ~/trim and ~/trim-logs.
8. **The package is not a git repository yet.** `git init` and the first commit are still to do, with no AI attribution lines (CLAUDE.md). The push itself is yours to run.
