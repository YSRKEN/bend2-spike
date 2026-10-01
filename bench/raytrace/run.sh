#!/bin/bash
# レイトレーサーの 1 コマの時間を、CPU（1・12 スレッド）と GPU で測る。bend2-gpu イメージの中で、--gpus all を付けて使う。
#   bash bench/raytrace/run.sh > bench/results/<機の名前>/raytrace.tsv
# frames.bend に k を渡すと k+1 コマ描く。k=1 と k=11 の差を 10 で割って、起動の固定費を除いた 1 コマの時間とする。
set -euo pipefail
cd "$(dirname "$0")"
[ -f fly.bend ] || bash fetch.sh
bend frames.bend -o /tmp/frames > /dev/null
bash ../build-wsl-gpu.sh frames.bend /tmp/frames-gpu > /dev/null
t() { local s r; s=$(date +%s%N); r=$("$@"); printf '%s\t%s\n' "$r" "$(( ($(date +%s%N) - s) / 1000000 ))"; }
# 読み出し: sum（毎コマ CPU で全画素を合計する）と drop（合計せずに GPU の上で捨てる。公式の App.turn と同じ）
printf '条件\t読み出し\tk\t合計\tミリ秒\n'
for rep in 1 2; do
  for mode in sum drop; do
    for k in 1 11; do
      printf 'cpu1\t%s\t%s\t' "$mode" "$k"; t /tmp/frames "$k" "$mode" --gpu off --threads 1
      printf 'cpu12\t%s\t%s\t' "$mode" "$k"; t /tmp/frames "$k" "$mode" --gpu off
      printf 'gpu\t%s\t%s\t' "$mode" "$k"; t /tmp/frames-gpu "$k" "$mode" --gpu 1GB --threads 1
    done
  done
done
