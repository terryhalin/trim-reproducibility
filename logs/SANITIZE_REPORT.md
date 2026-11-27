# Sanitize report — Day 1 logs

Created: 2026-11-27. Revised 2026-11-27 (`$HOME` in commands, README section on missing files, run.log entry; `trim-logs/run.log` re-copied from the original and re-sanitized so it includes the 15:48:12 entry).
Sources: `~/trim-logs/` → `trim-logs/`, `~/trim-repro-package/logs/` → `trim-repro-package-logs/`.
The copied files were not edited in the originals. The one exception is a single entry appended to `~/trim-logs/run.log` at 2026-11-27 15:48:12 to log this step.
The copy was made with rsync. Replacements were made by Python regex scripts and applied in this order:

| Rule | Pattern | Replacement |
|---|---|---|
| home (code) | the home-directory path inside a command, a compiler flag or tool output (quoted or not) | `$HOME` |
| home (prose) | the home-directory path in plain prose | `~` |
| hostname | the machine's hostname (case-insensitive) | `HOST` |
| user | the username, case-insensitive (Linux and Windows usernames are the same) | `USER` |
| email | `name@domain.tld` | `PLACEHOLDER` (0 found) |
| ipv4 | `a.b.c.d`, except when followed by `-microsoft` (kernel version) | `PLACEHOLDER` (0 found) |

## Files and replacement counts

| File | Total | home → `$HOME` | home → `~` | hostname | user |
|---|---|---|---|---|---|
| trim-logs/DAY1.md | 0 | | | | |
| trim-logs/PACKAGE_CHECK.md | 0 | | | | |
| trim-logs/PACKAGE_STATUS.md | 0 | | | | |
| trim-logs/bindings-build-patched.txt | 5 | 5 | | | |
| trim-logs/bindings-build.txt | 8 | 8 | | | |
| trim-logs/bindings-install.txt | 9 | 9 | | | |
| trim-logs/cmake.txt | 1 | 1 | | | |
| trim-logs/fixes.patch | 0 | | | | |
| trim-logs/make.txt | 0 | | | | |
| trim-logs/package-smoke-bench-output.txt | 0 | | | | |
| trim-logs/package-smoke-results.csv | 0 | | | | |
| trim-logs/package-smoke-test.txt | 0 | | | | |
| trim-logs/pip-install.txt | 1 | 1 | | | |
| trim-logs/run.log (re-copied, 87 lines) | 10 | 3 (lines 5, 53, 64) | 3 (lines 58, 60, 61) | 1 | 3 |
| trim-logs/scripts/make_synthetic.py | 0 | | | | |
| trim-logs/scripts/smoke_thnsw.sh | 0 | | | | |
| trim-logs/smoke/results/QPSDCRecall_SYN_tHNSW_KNN_k10.csv | 0 | | | | |
| trim-logs/smoke/smoke-thnsw-output.txt | 0 | | | | |
| trim-logs/smoke/tmp/index/syn_hnswlib16x500.bin.build.seconds.txt | 0 | | | | |
| trim-logs/smoke/tmp/index/syn_pq8x120.bin.build.seconds.txt | 0 | | | | |
| trim-logs/status.md | 1 | | | | 1 |
| trim-repro-package-logs/.gitkeep | 0 | | | | |
| **Total** | **35** | **27** | **3** | **1** | **4** |

New files, not copies: `README.md` (with the sections "Read this first", "Files not included in this copy" and "Sanitizing") and `SANITIZE_REPORT.md`.

A script checked every copied file against its original, with every home path changed to `$HOME`, the hostname to `HOST` and the username to `USER`. The only differences are the three prose lines in run.log (58, 60, 61), which use `~` on purpose.

## `$HOME` check (commands still runnable)

- **9 compiler commands changed:** lines 2, 3, 5 of `bindings-build.txt`, `bindings-build-patched.txt` and lines 20, 21, 23 of `bindings-install.txt`. None contains `$(`, backticks, `;`, `&` or `|`.
- **How they were checked:** bash word-split each command (no globbing) with `HOME` set to a dummy home folder that does not exist. Every `$HOME` flag expanded to `-I<dummy home>/trim/.venv/...`, with no `~` or `$HOME` left over.
- **Paths checked against the real setup:** with the real HOME, every `-I` directory exists. The relative `-I../include` resolves from the `python/` folder where setup.py runs (`~/trim/python`, or `~/trim-logs/patched-src/python` for the patched build).
- **Not run as compilers:** lines 2 and 3 compile setup.py's temporary probe files `/tmp/tmpXXXXXXXX.cc`, which no longer exist. Line 5 would write `.o` files and rebuild trimlib, and on unpatched upstream it fails by design. So the check covers expansion and paths only.
- **`$HOME` in tool output** (cmake `Build files have been written to:`, pip `Stored in directory:`, the setuptools warning path, `Cloning into '$HOME/trim'...`, the `ls -l` line and `import OK from`) is output, not a command. It now reads correctly when the user's home is substituted.

## README recreate steps check

Steps 1 and 2 of the README's "Files not included in this copy" were run in a throwaway HOME in a scratch folder, which was deleted afterwards. Upstream `~/trim` was only read (`git status` still clean).

| Step | Result |
|---|---|
| 1 | `git archive 481811b7 include python` plus `git apply fixes.patch` gave sources identical to `~/trim-logs/patched-src` (`diff -rq` with build outputs excluded) |
| 2 | `make_synthetic.py` (seed 42) gave a file byte-identical to `~/trim-logs/smoke/synthetic-960.hdf5` (`cmp`) |

Not run: the `build_ext` part of step 1 (129 s on Day 1, `run.log` 18:23:59) and step 3 (the smoke test that builds the `.bin` files).

## Excluded from the copy

| Path in `~/trim-logs/` | Size | Reason |
|---|---|---|
| `patched-src/` | 202 MB | Patched copy of upstream source with build output and the compiled `trimlib…so`. Recreate from upstream 481811b7 plus `fixes.patch` (README). |
| `smoke/synthetic-960.hdf5` | 39 MB | Synthetic dataset. Recreate with `scripts/make_synthetic.py`, seed 42 (README). |
| `smoke/tmp/index/syn_hnswlib16x500.bin`, `syn_pq8x120.bin` | 40 MB, 2.2 MB | Index files. Rebuilt by `scripts/smoke_thnsw.sh` (README). |
| `smoke/tmp/index/syn_thnsw16x500_pq8x120.empty` | 0 B | Empty marker file, not needed by the package. It was excluded from the first copy onward and was never in `~/trim-logs-public/`. |

The GIST dataset, `~/trim/.venv` and `~/trim/build` are not inside either source folder, so they were never copied.
The copy contains no `.so`, `.o`, `.bin`, `.hdf5`, `.empty`, `.venv` or `build/` entries.
`C:\trim-reproducibility\logs\wsl-setup-log.md` (cited in status.md) is outside both source folders. It is listed in the README as not included and cannot be recreated from this copy.

## Leftover check (step 3)

Case-insensitive grep over the whole copy (README and this report included) for the username, the hostname, the home-directory prefix and the Windows users-folder prefix: **no matches**.
`grep -r "@"` in the copied logs gives 6 matches, all kept on purpose:

- `trim-logs/status.md:13` and `trim-logs/run.log:59`: `~/trim @ 481811b…`, a git commit reference
- `trim-logs/fixes.patch:1`: `petrizhang/TRIM @ 481811b…`, a commit reference
- `trim-logs/fixes.patch:10,21`: `@@ … @@`, diff hunk headers (changing them would break the patch)
- `trim-logs/run.log:2`: `USER@HOST`, already sanitized

## Spots I was unsure about

1. **`6.6.87.2` in run.log:2** looks like an IPv4 address, but it is the WSL2 kernel version (`6.6.87.2-microsoft-standard-WSL2`). It is a version, so I kept it.
2. **`error: Command '[...]'` lines** (`bindings-build.txt:90`, `bindings-install.txt:108`) are Python list reprs, so `'-I$HOME/...'` sits inside single quotes. They are error messages, not shell commands. Pasted into a shell they would not run and `$HOME` would not expand. They were treated as quoted output.
3. **Run.log lines 58, 60 and 61 kept `~`.** These are prose about where something happened (for example "in ~/trim-logs/patched-src: OK"), not the command itself. Line 60's command part, `git apply ~/trim-logs/fixes.patch`, was already `~` in the original.
4. **`~` written in the originals was left unchanged.** It appears in commands in DAY1.md, status.md, run.log and scripts/smoke_thnsw.sh, and in PACKAGE_*.md. It was not introduced by sanitizing. In every command it is unquoted at the start of a word or right after `=` in `export`, where bash expands it, so those commands already run.
5. **`user USER` in status.md:11.** The original names the Linux account. It was replaced under the username → USER rule.
6. **`-rw-r--r-- 1 USER USER … $HOME/trim-logs/smoke/synthetic-960.hdf5` in run.log:53.** The file owner and group were both the username. Both are replaced, and the path is treated as tool output.
7. **Kept as non-personal:**
   - the pip wheel-cache hash in pip-install.txt (a content hash)
   - random `/tmp/tmpXXXXXXXX.cc` names in the bindings logs
   - the Windows path `C:\trim-reproducibility\...` (contains no username)
   - `/mnt/c/trim-reproducibility/...` paths
8. **Smoke-test timing files** (`smoke/tmp/index/*.build.seconds.txt`) were kept because they are small text results, even though they sit in the index folder.
9. **The public `run.log` was re-copied from the original after the 15:48:12 entry was added,** so it now ends with that entry. The new line holds no home path, hostname, username, email or IP, so the counts did not change (run.log still 10, total still 35). It mentions `~/trim-logs/…` as prose and `$HOME` as text describing the rule. The CLAUDE.md entry at 15:41:20 is also in the copy.
10. **Day 2 / synthetic statement.** README.md "Read this first" says plainly that Day 2 results are not yet run and that the smoke test used synthetic data. The copied `status.md` and `DAY1.md` say the same in their own words. They were not reworded.
