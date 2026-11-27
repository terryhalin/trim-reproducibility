# Reproducibility package — status

Package: ~/trim-repro-package/ (88K, 17 entries). Last updated: 2026-11-26 18:50
Not a git repository yet; nothing committed or pushed.

## Complete

| Item | State | Evidence |
|---|---|---|
| README.md: all requested sections (scope, requirements, Steps 1-8, known issues) | done, with placeholders below | — |
| Step 1 clone-by-commit instructions | tested: fetch by SHA gives HEAD=481811b7..., fixes.patch applies | run.log (package section) |
| ENVIRONMENT.md | done, copied from run.log only | run.log |
| fixes.patch | identical copy of ~/trim-logs/fixes.patch | cmp check |
| LICENSE | identical to upstream LICENSE at 481811b7 | cmp check |
| NOTICE.md | credits Song et al., DOI 10.1145/3769838, describes the patch | — |
| scripts/smoke_test.sh (+ make_synthetic.py, common.sh) | tested: exit 0, 11-row CSV, SMOKE TEST PASS (Day 1 env through overrides) | package-smoke-test.txt, package-smoke-results.csv, package-smoke-bench-output.txt |
| scripts/run_gist_thnsw.sh, run_gist_tivfpq.sh | syntax OK, DRY_RUN prints the README commands (only -d changed), missing-GIST guard refuses. **Not run.** | run.log |
| results/, logs/ with .gitkeep notes | done | — |
| .gitignore (TRIM/, .venv/, data/, tmp/, smoke/, *.hdf5) | done | — |
| Exclusions: no GIST data, .venv, build, clone, .so or index files in package | verified | find check |
| Permissions: smoke_test.sh, run_gist_*.sh 755; common.sh, make_synthetic.py 644 | verified | — |

## Still placeholder

| Where | What | Filled from |
|---|---|---|
| README Requirements | disk need (~15 GB is an estimate) | Day 2 df / index sizes |
| README Step 6 | exact Hugging Face file link | user / Day 2 download |
| README Step 7 | expected runtime tHNSW, tIVFPQ; peak memory | Day 2 logs/*.time.txt |
| README Known issue 6 | whether to run baselines (plain HNSW / IVFPQ) | user decision |
| COMPARISON.md | every paper value, our value, difference, claim holds; the settings list itself; sources; why results differ | Day 2 results + Day 3 paper |
| ENVIRONMENT.md UNKNOWNs | CPU model, AVX-512 flag, Ubuntu release, exact gcc/g++ version, git/python3-venv/python3-dev/time versions | not in run.log; need a logged check |

## Open questions for the user
1. Baselines: the README commands run only TRIM variants, so the paper's speedup claims cannot be checked without plain HNSW and plain IVFPQ runs.
2. Day 2 location: run from ~/trim-repro-package with overrides (TRIM_DIR=~/trim VENV_DIR=~/trim/.venv TRIMLIB_DIR=~/trim-logs/patched-src/python GIST_PATH=/mnt/c/trim-reproducibility/data/gist-960.hdf5) so results land in the package's results/ and logs/.
