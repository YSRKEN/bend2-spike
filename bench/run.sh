#!/bin/bash
# bench/ の計測を回す。bend2-gpu イメージの中で、bench/ を作業ディレクトリにして使う。
#
#   run.sh mandel|nqueens|threads    # 題材ごと。どれも 10 分以内に終わる大きさにしてある
#
# 各条件を 2 回ずつ、条件を交互に並べて測る（同じ条件を続けて測ると、機の状態の変化が一方に偏るため）。
# 時間はプロセスの起動から終了まで（GPU の場合、CUDA の初期化と .gpu の読み込みを含む）。
set -euo pipefail
cd "$(dirname "$0")"

t() {
  local s out
  s=$(date +%s%N)
  out=$("$@")
  printf '%s\t%s\n' "$out" "$(( ($(date +%s%N) - s) / 1000000 ))"
}

row() {  # row <題材> <条件> <引数> <コマンド...>
  local what=$1 how=$2 arg=$3
  shift 3
  printf '%s\t%s\t%s\t' "$what" "$how" "$arg"
  t "$@"
}

build() {  # build <名前>: Bend の CPU 版（/tmp/<名前>）、GPU 版（/tmp/<名前>-gpu）、C 版（/tmp/<名前>-c）
  bend "$1.bend" -o "/tmp/$1" > /dev/null
  bash build-wsl-gpu.sh "$1.bend" "/tmp/$1-gpu" > /dev/null
  clang -O3 -ffp-contract=off -fopenmp "$1.c" -o "/tmp/$1-c"
}

printf '題材\t条件\t引数\t答え\tミリ秒\n'
case ${1:-} in
  mandel)
    build mandel
    for rep in 1 2; do
      for it in 0 256 1024 4096; do
        row mandel "bend cpu12" "$it" /tmp/mandel "$it" --gpu off
        row mandel "bend gpu" "$it" /tmp/mandel-gpu "$it" --gpu 1GB --threads 1
        row mandel "C cpu12" "$it" env OMP_NUM_THREADS=12 /tmp/mandel-c "$it"
      done
      for it in 16384; do
        row mandel "bend gpu" "$it" /tmp/mandel-gpu "$it" --gpu 1GB --threads 1
      done
    done
    ;;
  threads)
    build mandel
    for rep in 1 2; do
      for th in 1 2 4 6 12; do
        row mandel "bend cpu$th" 256 /tmp/mandel 256 --gpu off --threads "$th"
        row mandel "C cpu$th" 256 env OMP_NUM_THREADS="$th" /tmp/mandel-c 256
      done
    done
    ;;
  nqueens)
    build nqueens
    bend nqueens_split.bend -o /tmp/nqueens_split > /dev/null
    bash build-wsl-gpu.sh nqueens_split.bend /tmp/nqueens_split-gpu > /dev/null
    for rep in 1 2; do
      for n in 13 14 15; do
        row nqueens "bend cpu1" "$n" /tmp/nqueens "$n" --gpu off --threads 1
        row nqueens "bend cpu12" "$n" /tmp/nqueens "$n" --gpu off
        row nqueens "bend gpu" "$n" /tmp/nqueens-gpu "$n" --gpu 1GB --threads 1
        row nqueens "split cpu1" "$n" /tmp/nqueens_split "$n" --gpu off --threads 1
        row nqueens "split cpu12" "$n" /tmp/nqueens_split "$n" --gpu off
        row nqueens "split gpu" "$n" /tmp/nqueens_split-gpu "$n" --gpu 1GB --threads 1
        row nqueens "C cpu1" "$n" env OMP_NUM_THREADS=1 /tmp/nqueens-c "$n"
        row nqueens "C cpu12" "$n" env OMP_NUM_THREADS=12 /tmp/nqueens-c "$n"
      done
    done
    ;;
  *)
    echo "usage: run.sh mandel|nqueens|threads" >&2
    exit 2
    ;;
esac
