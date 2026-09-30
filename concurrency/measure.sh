#!/bin/bash
# stall.bend の 4 通りの呼び方を比べる。Windows の Git Bash から、リポジトリのルートで実行する。
#
#   bash concurrency/measure.sh [深さ]    # 既定 30
#
# サーバーは wslc のコンテナ（bend2-native）でネイティブビルドして動かし、Windows の curl で叩く。
# 経路ごとに、重い要求を 1 本投げた 0.3 秒後から / を 5 回続けて叩き、それぞれの応答時間を出す。
set -euo pipefail
depth=${1:-30}
name=bend-stall

wslc rm -f "$name" >/dev/null 2>&1 || true
# MSYS_NO_PATHCONV: Git Bash が "/work" などを Windows のパスに書き換えるのを止める（curl の /dev/null は書き換えが要るので、この行だけ）
MSYS_NO_PATHCONV=1 wslc run -d --rm --name "$name" -p 8080:8080 -v "$(pwd -W 2>/dev/null || pwd):/work" -w /work/concurrency bend2-native \
  sh -c "bend stall.bend -o /tmp/stall && /tmp/stall" >/dev/null
trap 'wslc stop "$name" >/dev/null 2>&1 || true' EXIT
# 待ち受けを始める前に curl で叩くと、その後も接続が通らなくなった（wslc のポート転送が詰まると推定）。
# そのため、ログに listening の行が出るのを待ってから叩く
until wslc logs "$name" 2>/dev/null | grep -q listening; do sleep 0.5; done

t() { curl -s -m 120 -o /dev/null -w '%{time_total}' "http://127.0.0.1:8080$1"; }

printf '経路\t重い要求の応答（秒）\t最中の / の応答（秒、5 回）\n'
for route in pure step proc fork; do
  t "/$route/$depth" > /tmp/stall-heavy.txt &
  heavy=$!
  sleep 0.3
  probes=""
  for i in 1 2 3 4 5; do probes+="$(t /) "; done
  wait "$heavy"
  printf '%s\t%s\t%s\n' "$route" "$(cat /tmp/stall-heavy.txt)" "$probes"
done
