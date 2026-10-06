# Ryzen 5 3600・RTX 5060 Ti（Windows 10 の wslc）、2026-10-01 の計測

bend は 2.0.34。`mandel.tsv`・`threads.tsv`・`nqueens.tsv`・`sort.tsv` は `bench/run.sh` の以前の版を `bend2-gpu` イメージの中で、
`raytrace.tsv` は `bench/raytrace/run.sh`、`server.tsv` は `bench/server/run.sh` で測った。

`nqueens-2026-10-06.tsv`・`sort-2026-10-06.tsv` は、2.0.35 と比べるために、同じ 2.0.34（`bend2-gpu:2.0.34`）で 2026-10-06 に
2.0.35 の計測の直後に測った値。GPU は外した（`BEND_GPU=off`）。

条件と読み方は [docs/benchmarks.md](../../../../docs/benchmarks.md) にある。
