# TRIM reproduction — status

Last updated: 2026-11-26 23:42 (stopped for the night)
Current day: **Day 1 complete. Day 2 not started — waiting for user go-ahead.**
No benchmark process running (checked 23:41 with `pgrep -af 'bench\.py|run_gist|smoke_test|make_synthetic|time -v'`: none).

## Done

| Item | Status | Evidence |
|---|---|---|
| WSL2 + Ubuntu 24.04, user USER, 16 CPUs, 23 GiB | done | C:\trim-reproducibility\logs\wsl-setup-log.md |
| ~/trim-logs/, status.md, run.log | done | run.log |
| Shallow clone ~/trim @ 481811b7d0315b45d24fcfdeb05543f454f3b6da | done, unmodified (`git status` clean) | run.log |
| apt + pip packages (venv ~/trim/.venv), versions logged | done | run.log, pip-install.txt |
| C++ build (cmake, make -j16) | done | cmake.txt, make.txt |
| Python bindings | done with fix — fixes.patch (no AVX-512), built in ~/trim-logs/patched-src | bindings-build.txt, bindings-build-patched.txt, fixes.patch |
| Synthetic smoke test (tHNSW) | PASS, 11 rows (recall 1.0: data too easy, pipeline check only) | smoke/, DAY1.md |
| GIST file size | 3933056096 bytes, matches | run.log |
| DAY1.md (plain-language notes) | done | DAY1.md |
| ~/CLAUDE.md (project rules) | created verbatim from user text | run.log |
| Reproducibility package skeleton ~/trim-repro-package | done, with placeholders; smoke test via package passes | PACKAGE_STATUS.md, package-smoke-*.txt/csv |
| Read-only package check | 0 FAIL, 9 PASS, 2 NOTE | PACKAGE_CHECK.md |

## Not started

- **Day 2:** GIST benchmarks (tHNSW, tIVFPQ). No GIST index, result or log exists yet.
- **Day 3:** paper numbers, COMPARISON.md, explaining differences.
- **Days 4-5:** report draft; fill package placeholders; .gitignore additions; git init + first commit (no attribution). The push is the user's to run.

## Decisions needed from the user before Day 2
1. **Baselines:** also run plain HNSW (`dco:"exact"`) and plain IVFPQ? Without them the paper's speedup claims can't be checked (COMPARISON.md rows 11 and 21).
2. **Run location:** proposed: run from ~/trim-repro-package with overrides (below), so results land in its results/ and logs/.

## Exact next step for Day 2 (only after the user says go)

```bash
cd ~/trim-repro-package
export TRIM_DIR=~/trim VENV_DIR=~/trim/.venv TRIMLIB_DIR=~/trim-logs/patched-src/python \
       GIST_PATH=/mnt/c/trim-reproducibility/data/gist-960.hdf5
DRY_RUN=1 scripts/run_gist_thnsw.sh     # 1. print the command, run nothing; check it
scripts/run_gist_thnsw.sh               # 2. start tHNSW in the background (nohup, /usr/bin/time -v)
tail -f logs/gist_thnsw_*.out.txt       # 3. watch; next morning check logs/*.time.txt and results/
# 4. only after tHNSW has finished:
scripts/run_gist_tivfpq.sh
```
Record anything that breaks in run.log; if unrecoverable, write STOPPED.txt and stop.

## Known limits
- tIVFPQfs cannot run on this CPU (needs AVX-512).
- bench/trim.py uses os.cpu_count()-2 = 14 threads (unchanged); it only affects index loading, and queries are single-threaded.
