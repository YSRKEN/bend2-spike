# Apple M2（macOS 26.6.2）、2026-10-06 の計測

`bench/run.sh` で測った。bend は 2.0.35（公式の darwin-arm64 版を `BEND_HOME` で指した）。GPU の行も 2.0.35。
AC 電源・省電力モードなしで、題材の前ごとに CPU の空きが 80% 以上の状態が 30 秒続くのを待ち、Docker Desktop は止めた。

`mandel.tsv`・`nqueens.tsv`・`threads.tsv`・`sort.tsv` は `BEND_GPU=off`、`*-gpu.tsv` は GPU ありで回した。
`threads.tsv` は既定のスレッド数（1・2・4・8）だけで、2.0.34 のように 1〜8 を 1 ずつは変えていない。

条件と読み方は [docs/benchmarks.md](../../../../docs/benchmarks.md) の「macOS（Apple M2）」にある。
