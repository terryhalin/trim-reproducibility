"""Make a small synthetic HDF5 dataset in the layout bench.py expects (same keys as the TRIM datasets).

train (n x d float32), test (nq x d float32), neighbors (nq x 100 int32, exact L2 top-100),
ranges (nq x 2 float32: squared-L2 radius that returns 1% / 10% of train),
neighbors_001 / neighbors_01 (ids inside those radii; fixed length n*0.01 / n*0.1).
Range parts are only placeholders for the tHNSW k-NN smoke test (not validated for range search).
"""
import sys
import h5py
import numpy as np
import faiss

out = sys.argv[1]
n, nq, d, k, seed = 10_000, 100, 960, 100, 42
rng = np.random.default_rng(seed)
centers = rng.normal(0, 1, size=(50, d)).astype("float32")           # 50 clusters, so search is not trivial
train = (centers[rng.integers(0, 50, n)] + 0.3 * rng.normal(size=(n, d))).astype("float32")
test = (centers[rng.integers(0, 50, nq)] + 0.3 * rng.normal(size=(nq, d))).astype("float32")

flat = faiss.IndexFlatL2(d)     # exact brute-force search = ground truth
flat.add(train)
n10 = n // 10
D, I = flat.search(test, n10)   # squared L2 distances, sorted
n1 = n // 100
with h5py.File(out, "w") as f:
    f.create_dataset("train", data=train)
    f.create_dataset("test", data=test)
    f.create_dataset("neighbors", data=I[:, :k].astype("int32"))
    f.create_dataset("neighbors_001", data=I[:, :n1].astype("int32"))
    f.create_dataset("neighbors_01", data=I[:, :n10].astype("int32"))
    f.create_dataset("ranges", data=np.stack([D[:, n1 - 1], D[:, n10 - 1]], axis=1).astype("float32"))
with h5py.File(out, "r") as f:
    for key in f:
        print(f"  {key:14s} shape={f[key].shape} dtype={f[key].dtype}")
