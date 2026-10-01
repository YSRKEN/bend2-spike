#!/bin/bash
# WSL2（wslc のコンテナ）で `!` を GPU に載せるためのビルド。bend2-gpu イメージの中で使う。
#
#   build-wsl-gpu.sh <x.bend> <出力先>
#
# bend のランタイムは、CUDA の CONCURRENT_MANAGED_ACCESS が 0 の GPU を使わない。
# WSL2 ではこの属性が 0 になるので、bend x.bend -o x で作った実行ファイルは `!` を黙って CPU で走らせる。
# ここでは生成した C の gpu_probe() の検査を外してからビルドする。公式には支えられていない使い方で、
# 実行時には --gpu 1GB のようにヒープを小さく指定する（既定の大きさでは確保に失敗した）。
set -euo pipefail
src=$1
out=$2
bend "$src" -o "$out.c"
grep -q '^  return managed != 0$' "$out.c" || { echo "gpu_probe の検査の行が見つからない（bend の版が違う？）" >&2; exit 1; }
# sed -i は GNU と BSD（macOS）で書き方が違うので、書き出してから置き換える
sed 's/^  return managed != 0$/  return 1/' "$out.c" > "$out.patched.c" && mv "$out.patched.c" "$out.c"
cuda=${CUDA_HOME:-/usr/local/cuda}
clang -DBEND_CUDA=1 -I"$cuda/include" -L"$cuda/lib64" -std=c11 -O3 "$out.c" -lpthread -lm -lcuda -lnvrtc -o "$out"
"$out" --gpu-build
