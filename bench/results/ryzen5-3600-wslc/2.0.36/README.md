# Ryzen 5 3600・RTX 5060 Ti（Windows 10 の wslc）、2026-10-12 の計測

bend は 2.0.36。`container/Containerfile` で作り直した `bend2-gpu` イメージの中で、`bench/run.sh`（GPU は WSL の回避つき）と
`bench/raytrace/run.sh` を、`bend2-native` イメージで `bench/server/run.sh` を回した。

同じ時間帯に 2.0.35 で測った比較用の値は `../2.0.35/*-2026-10-12.tsv` にある。題材ごとに 2.0.35 → 2.0.36 の順で続けて測った。
2.0.35 のサーバーは、2.0.36 の型に書き直す前の `concurrency/stall.bend`（commit cc7b2d5）で測った。
条件と読み方は [docs/benchmarks.md](../../../../docs/benchmarks.md) の「2.0.36 で測り直した結果」にある。
