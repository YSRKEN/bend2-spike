# Windows の GeForce で Bend の GPU 実行を試す

Bend 2 は `f!(x)` と書いた呼び出しを GPU で走らせる（`bend guide` の「Parallelism」）。この文書は、Windows 10 の wslc のコンテナから
RTX 5060 Ti でこれを試した記録。数値の比較は [benchmarks.md](benchmarks.md) にある。

特に断りのない記述は、実際に動かして確かめたこと。ガイドなどの記述だけに基づくものには「（文書のみ）」、
確かめていないものには「（未確認）」と書いた。

## 結論: 公式の手順では GPU は使われない。パッチを当てると動き、答えも合う

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

---

最終更新: 2026-10-01
