# Notice

This package repeats results from the TRIM code and builds on it. The code was written by its original authors:

**Yitong Song, Pengcheng Zhang, Chao Gao, Bin Yao, Kai Wang, Zongyuan Wu, Lin Qu.**
*TRIM: Accelerating High-Dimensional Vector Similarity Search with Enhanced Triangle-Inequality-Based Pruning.*
Proceedings of the ACM on Management of Data 3(6), 2025 (SIGMOD 2026).
DOI: [10.1145/3769838](https://doi.org/10.1145/3769838)

- Upstream code: https://github.com/petrizhang/TRIM, commit 481811b7d0315b45d24fcfdeb05543f454f3b6da
- License: Apache License 2.0. The copy in [LICENSE](LICENSE) is taken unchanged from that commit.
- Upstream also includes code from faiss, hnswlib and glass, each under its own license (see `licenses/` in the upstream repository). This package does not redistribute that code.

## Changes made in this package

This package does **not** include any upstream source files. It contains:

- `fixes.patch`: a change to the upstream file `include/trim/trim-forwards.h` (Apache 2.0). With it, the AVX-512-only tIVFPQfs code is compiled only when building for CPUs that have AVX-512. It was written for this reproduction and is not part of upstream. The patch header explains it.
- Scripts and documentation written for this reproduction (CMKL 41-634 course report).

The original authors have not reviewed this package and are not responsible for it.
