# Apple M2（macOS 26.6.2）、2026-10-01 の計測

`bench/run.sh` で測った。bend は 2.0.34。ただし `mandel-gpu.tsv`・`nqueens-gpu.tsv` の `bend gpu` の行だけは、
2.0.34 では Metal のコンパイラが落ちるため、2.0.27 を `BEND_GPU_HOME` で指して測った（[docs/gpu.md](../../../../docs/gpu.md) の「macOS」）。

`sort.tsv` は、ソートを Base の比較に替える前（commit `1563ac0` より前）の `sort/main.bend` で測った値。
`sort-1563ac0.tsv` は、2.0.35 と比べるために、替えた後の `sort/main.bend` を同じ 2.0.34 で 2026-10-06 に測った値で、
AC 電源・省電力モードなしで測った。

条件と読み方は [docs/benchmarks.md](../../../../docs/benchmarks.md) の「macOS（Apple M2）」にある。
