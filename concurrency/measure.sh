#!/bin/bash
# stall.bend の 4 通りの呼び方を比べる。リポジトリのルートで実行する。
#
#   bash concurrency/measure.sh [深さ]    # 既定 30
#
# サーバーをネイティブビルドして起動し、手元の curl で叩く。経路ごとに、重い要求を 1 本投げた 0.3 秒後から
# / を 5 回続けて叩き、それぞれの応答時間を出す。
#
# サーバーの動かし方（環境変数 BENCH_RUNNER で選べる。既定は上から順に、使えるもの）:
# - native: bend が PATH にある（Linux、macOS）。手元でビルドして起動する
# - wslc:   Windows の Git Bash から、wslc のコンテナ（bend2-native）で起動する
# - docker: docker のコンテナ（bend2-native）で起動する
set -euo pipefail
depth=${1:-30}
name=bend-stall
export PATH="$HOME/.bend/bin:$PATH" BEND_NO_TELEMETRY=1
tmp=$(mktemp -d "${TMPDIR:-/tmp}/bend-stall.XXXXXX")

runner=${BENCH_RUNNER:-}
if [ -z "$runner" ]; then
  if command -v bend >/dev/null 2>&1; then runner=native
  elif command -v wslc >/dev/null 2>&1; then runner=wslc
  elif command -v docker >/dev/null 2>&1; then runner=docker
  else echo "bend も wslc も docker も見つからない" >&2; exit 1
  fi
fi

case $runner in
  native)
    bend concurrency/stall.bend -o "$tmp/stall" > /dev/null
    "$tmp/stall" > "$tmp/server.log" 2>&1 &
    server=$!
    disown "$server"  # 止めたときに、シェルが Terminated と知らせないように
    trap 'kill "$server" 2>/dev/null || true; rm -rf "$tmp"' EXIT
    logs() { cat "$tmp/server.log"; }
    ;;
  wslc|docker)
    "$runner" rm -f "$name" >/dev/null 2>&1 || true
    # MSYS_NO_PATHCONV: Git Bash が "/work" などを Windows のパスに書き換えるのを止める（ほかの環境では効かない）
    MSYS_NO_PATHCONV=1 "$runner" run -d --rm --name "$name" -p 8080:8080 -v "$(pwd -W 2>/dev/null || pwd):/work" \
      -w /work/concurrency bend2-native sh -c "bend stall.bend -o /tmp/stall && /tmp/stall" >/dev/null
    trap '"$runner" stop "$name" >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT
    logs() { "$runner" logs "$name" 2>/dev/null; }
    ;;
  *)
    echo "BENCH_RUNNER は native・wslc・docker のどれか" >&2
    exit 2
    ;;
esac
# 待ち受けを始める前に curl で叩くと、その後も接続が通らなくなった（wslc のポート転送が詰まると推定）。
# そのため、ログに listening の行が出るのを待ってから叩く
until logs | grep -q listening; do sleep 0.5; done
echo "[measure.sh] サーバー: $runner、深さ: $depth" >&2

t() { curl -s -m 120 -o /dev/null -w '%{time_total}' "http://127.0.0.1:8080$1"; }

printf '経路\t重い要求の応答（秒）\t最中の / の応答（秒、5 回）\n'
for route in pure step proc fork; do
  t "/$route/$depth" > "$tmp/heavy.txt" &
  heavy=$!
  sleep 0.3
  probes=""
  for i in 1 2 3 4 5; do probes+="$(t /) "; done
  wait "$heavy"
  printf '%s\t%s\t%s\n' "$route" "$(cat "$tmp/heavy.txt")" "$probes"
done
