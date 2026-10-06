# Apple M2（macOS 26.6.2）、2026-10-01 の計測

`bench/run.sh` で測った。bend は 2.0.34。ただし `mandel-gpu.tsv`・`nqueens-gpu.tsv` の `bend gpu` の行だけは、
2.0.34 では Metal のコンパイラが落ちるため、2.0.27 を `BEND_GPU_HOME` で指して測った（[docs/gpu.md](../../../../docs/gpu.md) の「macOS」）。

条件と読み方は [docs/benchmarks.md](../../../../docs/benchmarks.md) の「macOS（Apple M2）」にある。
