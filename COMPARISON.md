# Paper vs my results

> **Skeleton.** I fill this in on Day 3. Every "my value" must cite a file in `results/` or `logs/`. Every "paper value" must cite a table, figure or page of the paper (doi:10.1145/3769838). Anything without a source is marked **unverified**.
> I took the settings below from the upstream README commands as a starting list. I will check them against the paper on Day 3.

How to read the tables:
- **recall@10** is the share of the true 10 nearest neighbours that the search finds.
- **QPS** is queries per second.
- **Speedup** compares TRIM with the same index without TRIM.
- **Pruning ratio** is the share of candidates TRIM skips without computing an exact distance.
- **gamma** sets how tight TRIM's distance bound is.

## tHNSW — GIST-960, k=10 (`results/QPSDCRecall_GIST_tHNSW_KNN_k10.csv`)

| setting | paper value | my value | difference | claim holds |
|---|---|---|---|---|
| QPS at recall@10 ≈ PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |
| Speedup over plain HNSW (hnswlib) at the same recall | PLACEHOLDER | PLACEHOLDER (needs a baseline run) | PLACEHOLDER | PLACEHOLDER |
| Pruning ratio (gamma=0.67) | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |
| Distance computations per query | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |
| Index build time | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |

## tIVFPQ — GIST-960, k=10 (`results/QPSDCRecall_GIST_tIVFPQ_KNN_k10.csv`)

| setting | paper value | my value | difference | claim holds |
|---|---|---|---|---|
| QPS at recall@10 ≈ PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |
| Speedup over plain FAISS IVFPQ at the same recall | PLACEHOLDER | PLACEHOLDER (needs a baseline run) | PLACEHOLDER | PLACEHOLDER |
| Pruning ratio (gamma=0.62) | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |
| Distance computations per query | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER | PLACEHOLDER |

## Out of scope

| setting | paper value | my value | difference | claim holds |
|---|---|---|---|---|
| tIVFPQfs (any) | PLACEHOLDER | not run: needs AVX-512 (see README) | — | not tested |

## Sources

- My values: PLACEHOLDER (file + row for each number)
- Paper values: PLACEHOLDER (table / figure / page for each number)

## Why results differ

PLACEHOLDER (Day 3). Possible reasons to check, none confirmed yet: different CPU (no AVX-512, AVX2 code paths), WSL2 instead of native Linux, library versions (faiss-cpu 1.16.0 vs bundled 1.11.0), Python-loop timing in bench.py.
