#!/bin/bash
# Bend・Node.js・Go の最小の HTTP サーバーを、毎秒さばける要求の数で比べる。Windows の Git Bash から、リポジトリのルートで実行する。
#
#   bash bench/server/run.sh > bench/results/<機の名前>/server.tsv
#
# どのサーバーも、同じコンテナの中で負荷ツール hey（Go 製）と一緒に動かす。要求ごとに接続を閉じる（-disable-keepalive）。
# hey は golang の公式イメージの中で作り、.scratch/tools/hey に置く（git の管理外）。
set -euo pipefail
root=$(pwd -W 2>/dev/null || pwd)
n=${BENCH_N:-20000}
c=${BENCH_C:-50}
if [ ! -f .scratch/tools/hey ]; then
  mkdir -p .scratch/tools
  MSYS_NO_PATHCONV=1 wslc run --rm -v "$root/.scratch/tools:/out" golang:1.23-bookworm \
    sh -c 'CGO_ENABLED=0 GOBIN=/out go install github.com/rakyll/hey@v0.1.4' >&2
fi
# サーバーを裏で起こし、待ち受けを始めたら hey で叩く。hey の要約から毎秒の要求数と、遅延の 50・99 パーセンタイルを抜く
load='i=0; until (echo > /dev/tcp/127.0.0.1/8080) 2>/dev/null; do i=$((i+1)); [ $i -gt 200 ] && exit 1; sleep 0.1; done
/hey -n '"$n"' -c '"$c"' -disable-keepalive http://127.0.0.1:8080/ > /tmp/hey.txt
rps=$(awk "/Requests\/sec/{print \$2}" /tmp/hey.txt)
p50=$(awk "/ 50% in/{print \$3}" /tmp/hey.txt); p99=$(awk "/ 99% in/{print \$3}" /tmp/hey.txt)
ok=$(awk "/\[200\]/{print \$2}" /tmp/hey.txt)
printf "%s\t%s\t%s\t%s\n" "$rps" "$p50" "$p99" "${ok:-0}"'
run() {  # run <名前> <イメージ> <サーバーを起こすコマンド>
  printf '%s\t' "$1"
  MSYS_NO_PATHCONV=1 wslc run --rm -v "$root:/work" -v "$root/.scratch/tools/hey:/hey" -e BEND_HOST=127.0.0.1 "$2" \
    bash -c "$3 > /dev/null 2>&1 & $load"
}
printf '%s\t%s\t%s\t%s\t%s\n' 'サーバー' '毎秒の要求数' '遅延 50%（秒）' '遅延 99%（秒）' '200 の数'
for rep in 1 2; do
  run bend bend2-native 'cd /work/concurrency && bend stall.bend -o /tmp/stall > /dev/null && /tmp/stall'
  run node node:22-bookworm-slim 'node /work/bench/server/node.js'
  run go golang:1.23-bookworm 'cd /work/bench/server && go build -o /tmp/srv main.go && /tmp/srv'
done
