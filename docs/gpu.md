# Bend の GPU 実行を試す: Windows の GeForce と macOS の Metal

Bend 2 は `f!(x)` と書いた呼び出しを GPU で走らせる（`bend guide` の「Parallelism」）。この文書は、Windows 10 の wslc のコンテナから
RTX 5060 Ti でこれを試した記録と、macOS（Apple M2）の Metal で試した記録（後半の「macOS」の節）。
Windows の数値の比較は [benchmarks.md](benchmarks.md) にある。macOS の機の構成は [environments.md](environments.md) にある。

特に断りのない記述は、実際に動かして確かめたこと。ガイドなどの記述だけに基づくものには「（文書のみ）」、
確かめていないものには「（未確認）」と書いた。

## Windows: 公式の手順では GPU は使われない。パッチを当てると動き、答えも合う

wslc のコンテナから GPU 自体は見える。ところが bend の実行ファイルは、WSL2 の GPU を「使えない」と判定して、`!` を黙って CPU で走らせる。
生成された C の判定の 1 行を書き換えると、GPU で走り、CPU と同じ答えを返した。ただし公式には支えられていない使い方である。

| 段階 | 結果 |
|---|---|
| `wslc run --gpus all nvidia/cuda:12.9.1-base-ubuntu24.04 nvidia-smi` | RTX 5060 Ti が見えた（ドライバ 581.80、CUDA 13.0 まで対応） |
| `bend x.bend -o x`（GPU 用イメージの中） | ビルドは通るが `x.gpu` ができない。`./x` は `!` を CPU で走らせる |
| `./x --gpu on` | `bend: --gpu on, but this binary found no usable GPU (a CUDA GPU needs concurrent managed access, which WSL2's lack)` で終了コード 1 |
| 判定を外したビルド（`bench/build-wsl-gpu.sh`）で `./x --gpu 1GB` | GPU で走り、CPU・C と同じ答え。`--threads 1` にしても速いままなので、計算は GPU でしている |

## GPU を使わない理由: WSL2 には concurrent managed access が無い

bend のランタイムは、CPU と GPU が一つのヒープを共有する設計で、CUDA では managed memory（`cuMemAllocManaged`）を使う。
起動時の `gpu_probe()` は、デバイスの属性 `CU_DEVICE_ATTRIBUTE_CONCURRENT_MANAGED_ACCESS` が 0 なら GPU を使わない。

コンテナの中で属性を直接読むと、次のとおりだった（CUDA ドライバ API の小さな C プログラムで確かめた）。

| 属性 | 値 |
|---|---|
| `MANAGED_MEMORY` | 1 |
| `CONCURRENT_MANAGED_ACCESS` | 0 |
| `PAGEABLE_MEMORY_ACCESS` | 0 |
| compute capability | 12.0 |

NVIDIA の「CUDA on WSL User Guide」の 5.1 節（Known Limitations for Linux CUDA Applications）に、
「Full Managed Memory Support is not available on Windows native and therefore WSL 2 will not support it for the foreseeable future.」とある
（https://docs.nvidia.com/cuda/wsl-user-guide/index.html 、2026-10-01 に取得）。Windows ネイティブにも無い機能なので、
Windows 上で bend の GPU 実行を公式に使う道は、当面無いと考える。

## パッチを当てて GPU で走らせる

`bench/build-wsl-gpu.sh` は、`bend x.bend -o x.c` で C を書き出し、`gpu_probe()` の `return managed != 0` を `return 1` に変えてから、
bend と同じ引数で clang に渡す。最後にできた実行ファイル自身に `--gpu-build` をさせて、NVRTC で `x.gpu` を作る。

```powershell
# GPU 用のイメージを作る（CUDA 12.9 の NVRTC と clang 19 入り）
wslc build -t bend2-gpu --target gpu -f container/Containerfile container

# パッチを当ててビルドし、GPU で走らせる（引数 4096 は反復の回数）
wslc run --rm --gpus all -v ${PWD}:/work -w /work/bench bend2-gpu sh -c "bash build-wsl-gpu.sh mandel.bend /tmp/mandel && /tmp/mandel 4096 --gpu 1GB"
```

分かったことは次のとおり。

- **`--gpu 1GB` のようにヒープの大きさを指定する。** 指定しないと `bend: corpus reservation failed` で止まった。4GB でも同じで、
  256MB では `bend: the GPU span is under the rings, stacks and a page per lane` と小さすぎると言われた。1GB で動いた。
  WSL2 の managed memory で確保できる大きさに上限があるためと推定している（未確認）。
- **RTX 50 系（compute capability 12.0）には CUDA 12.8 以降の NVRTC が要る**（文書のみ。CUDA 12.8 のリリースノートに「adds compiler support for ... SM_100, SM_101, SM_120」とある。
  https://docs.nvidia.com/cuda/archive/12.8.0/cuda-toolkit-release-notes/index.html ）。
  `bend2-gpu` は CUDA 12.9 を入れており、`--gpu-architecture=sm_120` でのコンパイルは 0.7 秒ほどで通った。
- **GPU 用のイメージの bend で作った実行ファイルは、`--gpus all` を付けずに起動すると `libcuda.so.1` が無いと言われて動かない。**
  `--gpu off` で CPU だけを使う場合も、`--gpus all` は付ける。
- **パッチを当てた実行でも、答えは CPU と一致した。** mandelbrot（CPU と C でも測った反復 0〜4,096 回）と n-queens（N=12〜16。どれも既知の解の数）のすべてで一致した。
  ただし、CPU と GPU が同時に managed memory に触れた場合の安全性は保証されていない。bend の `!` の呼び出しは、CPU の側で結果を待つ形なので、
  同時には触れていないと推定している（未確認）。

## イメージの中身

`container/Containerfile` の `gpu` ターゲットは、`nvidia/cuda:12.9.1-base-ubuntu24.04` に次を足したもの。

| 足したもの | 理由 |
|---|---|
| `clang-19` | bend は `!` を含むプログラムのビルドに clang 19 以上を要求する（bend 本体の `cc_find`） |
| `cuda-nvrtc-dev-12-9` | bend は `$CUDA_HOME/include/nvrtc.h` があるときだけ GPU 用にビルドする |
| `cuda-cudart-dev-12-9` | 生成した C が `cuda.h` を読む。`cuda-driver-dev` には入っていない |
| `libomp-19-dev` | 比較用の C（OpenMP）をビルドするため。bend には要らない |
| `LIBRARY_PATH=/usr/local/cuda/lib64/stubs` | ビルド時に `-lcuda` を解決するため。実体は実行時に `--gpus` で持ち込まれる |

bend 本体は最小構成の段からコピーしている。Debian 12 で作った bend を Ubuntu 24.04 で動かしても問題は無かった。

## macOS: Metal で走るはずだが、2.0.34 では Apple のコンパイラが落ちる

ガイドによると、macOS の `!` は Metal で GPU に載る（文書のみ。`bend guide` の「`on macOS it needs Metal`」の箇所）。
ところが 2.0.34 で `!` を含むプログラムを `-o` でビルドすると、次のエラーで止まった。

```text
bend: Compilation failed due to an interrupted connection: XPC_ERROR_CONNECTION_INTERRUPTED. This error occurred after multiple retries.
```

`~/Library/Logs/DiagnosticReports/MTLCompilerService-*.ips` を読むと、Metal のコンパイラサービスが
`EXC_BAD_ACCESS`（`KERN_INVALID_ADDRESS at 0x0000000000000010`）で落ちていた。落ちた場所は AGXCompilerCore から呼ばれる
LLVM の `MachineFunctionPass::runOnFunction` で、Bend の不具合として報告済みの
[bendlang/bend#1154](https://github.com/bendlang/bend/issues/1154)（M2 Pro、macOS 15.7.4、2.0.32 から）と同じスタックだった。
Claude Code のサンドボックスの外で実行しても同じだったので、サンドボックスが原因ではない。

| 版 | ガイドの最小の例（`pow2!(20n)`） |
|---|---|
| 2.0.27 | ビルドでき、GPU で `1048576` を返した |
| 2.0.28 | ビルドでき、GPU で `1048576` を返した |
| 2.0.29 | 同じクラッシュで失敗 |
| 2.0.30 | 同じクラッシュで失敗 |
| 2.0.31 | 同じクラッシュで失敗 |
| 2.0.34 | 同じクラッシュで失敗。`./pow2 --gpu off` なら `1048576` |

壊れたのは 2.0.29 から。2.0.29 のリリースノートには、型の整理の一部として「one atomic family for the host, Metal and CUDA」とある。
2.0.28 と 2.0.29 で `pow2.bend` から生成した C を比べると（約 970 行が違う）、GPU の共有メモリの原子操作（`GA32`、`threadgroup atomic_uint`、
`g32_*`）が消え、代わりに `TG`（`threadgroup`）が入っていた。この整理（bendlang/bend の commit `87a1e9c`）が、M2 で Apple のコンパイラを
落とす引き金になったと推定している。その commit だけを戻して確かめてはいない。

画面のあるアプリも、Base の `App` が `!` を呼ぶので同じく止まる（[environments.md](environments.md) の pong の小節）。

2.0.34 でも、CPU で走らせるだけなら、C に書き出して自分でビルドすればよい。Metal 用のプログラム（`x.gpu`）は作られず、
`!` は CPU で走る。

```sh
bend bench/mandel.bend -o /tmp/mandel.c
clang -O3 -std=c11 /tmp/mandel.c -o /tmp/mandel -lpthread -lm
/tmp/mandel 1024
```

## macOS: 2.0.27 なら GPU で走り、答えも合う

2.0.27 の darwin-arm64 版を `~/.bend` とは別の場所に展開し、`BEND_HOME` でそこを指して `bench/mandel.bend` をビルドした。
答えは 2.0.34 の CPU 版とも、Windows での記録（`bench/results/ryzen5-3600-wslc/mandel.tsv`）とも一致した。

| 反復回数 | 答え | 2.0.34 の CPU（8 スレッド） | 2.0.27 の CPU（`--gpu off`、8 スレッド） | 2.0.27 の GPU（2 回） |
|---|---|---|---|---|
| 256 | 797303755 | 2.8 秒 | 2.7 秒 | 0.98 秒、0.42 秒 |
| 1024 | 2964681653 | 9.1 秒 | 9.6 秒 | 1.4 秒、1.3 秒 |
| 4096 | 3014046195 | 46.7 秒 | 53.4 秒 | 4.9 秒、4.4 秒 |
| 16384 | 3182515055 | （未計測） | （未計測） | 16.6 秒 |

2.0.34 の CPU 版は、上の `clang -O3 -std=c11` で作った。時間はプロセスの起動から終了まで、各条件 1 回（GPU だけ 2 回）で、[benchmarks.md](benchmarks.md) のように条件を交互に並べてはいない。
目安として読む。

2.0.27 の実行ファイルは、`IO.args` の先頭に実行ファイル名を入れない。`mandel.bend` の `iters` は 2 番目の要素を読むので、
引数の前にダミーを 1 つ置く（`./mandel x 4096`）。置かないと、反復回数が既定の 256 のままになる。

---

最終更新: 2026-10-01
