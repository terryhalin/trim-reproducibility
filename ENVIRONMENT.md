# Environment

Copied from the Day 1 log `~/trim-logs/run.log` (2026-11-26) only. **UNKNOWN** = not recorded in run.log.

## Machine

| Item | Value | run.log line |
|---|---|---|
| CPU model | UNKNOWN | — (DAY1.md names the CPU, but run.log does not) |
| AVX-512 | UNKNOWN | — (DAY1.md records "no AVX-512", but run.log only implies it via the build error) |
| Cores visible to Linux | 16 (`nproc`) | `[2026-11-26 18:00:39] Environment: ... nproc=16` |
| RAM visible to Linux | 23Gi (`free -h`) | `[2026-11-26 18:00:39] Environment: ... mem=23Gi` |
| OS | UNKNOWN (Ubuntu release not in run.log) | — |
| Kernel | 6.6.87.2-microsoft-standard-WSL2 | `[2026-11-26 18:00:39] Environment: ...` |
| Virtualisation | WSL2 (from kernel name) | same line |

## System packages (apt)

| Package | Version | run.log line |
|---|---|---|
| cmake | 3.28.3-1build7 | `[2026-11-26 18:02:09] apt package versions` |
| gcc | `gcc` package 4:13.2.0-7ubuntu1 (Ubuntu metapackage). Exact compiler version (`gcc --version`): UNKNOWN | same |
| g++ | `g++` package 4:13.2.0-7ubuntu1 (metapackage). Exact version: UNKNOWN | same |
| build-essential | 12.10ubuntu1 | same |
| make | 4.3-4.1build2 | same |
| OpenBLAS (libopenblas-dev) | 0.3.26+ds-1ubuntu0.1 | same |
| LAPACK (liblapack-dev) | 3.12.0-3build1.1 | same |
| libhdf5 (libhdf5-dev) | 1.10.10+repack-3.1ubuntu4 | same |
| git, python3-venv, python3-dev, time | UNKNOWN | — (already installed, not logged) |

## Python (virtual environment)

| Package | Version | run.log line |
|---|---|---|
| Python | 3.12.3 | `[2026-11-26 18:02:57] Python package versions` |
| faiss-cpu | 1.16.0 | same |
| hnswlib | 0.8.0 | same |
| numpy | 2.5.5 | same |
| pandas | 3.1.1 | same |
| scipy | 1.18.1 | same |
| h5py | 3.16.0 (wheel built against HDF5 2.0.0) | same |
| pybind11 | 3.1.0 | same |
| pip | 26.3 | same |
| setuptools | 84.2.1 | same |

## Code

| Item | Value | run.log line |
|---|---|---|
| Upstream commit | 481811b7d0315b45d24fcfdeb05543f454f3b6da (2026-04-02, "Update README.md") | `[2026-11-26 18:00:51] Cloned commit` |
| Libraries bundled in upstream (`include/versions.txt`) | hnswlib 0.8.0, faiss 1.11.0, eigen 3.4.0 | not in run.log (read from the clone) |
| Local fix | fixes.patch (AVX-512 guard) | `[2026-11-26 18:09:09] Fix written to ~/trim-logs/fixes.patch` |
