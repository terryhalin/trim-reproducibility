# Notice

This package reproduces results from, and is built on, the TRIM code by its original authors:

**Yitong Song, Pengcheng Zhang, Chao Gao, Bin Yao, Kai Wang, Zongyuan Wu, Lin Qu.**
*TRIM: Accelerating High-Dimensional Vector Similarity Search with Enhanced Triangle-Inequality-Based Pruning.*
Proceedings of the ACM on Management of Data 3(6), 2025 (SIGMOD 2026).
DOI: [10.1145/3769838](https://doi.org/10.1145/3769838)

- Upstream code: https://github.com/petrizhang/TRIM, commit 481811b7d0315b45d24fcfdeb05543f454f3b6da
- License: Apache License 2.0. The copy in [LICENSE](LICENSE) is taken unchanged from that commit.
- Upstream also bundles code from faiss, hnswlib and glass under their own licenses (see `licenses/` in the upstream repository). This package does not redistribute that code.

## Changes made in this package

This package does **not** include upstream source files. It contains:

- `fixes.patch`: a modification to upstream `include/trim/trim-forwards.h` (Apache 2.0). It compiles the AVX-512-only tIVFPQfs code only when building for AVX-512 CPUs. It was written for this reproduction and is not part of upstream. The patch header explains it.
- Scripts and documentation written for this reproduction (CMKL 41-634 course report).

The original authors are not responsible for, and have not reviewed, this package.
