#!/bin/bash
# フックが共有する部品。各フックから source して使う。
#
# - JSON の読み書き: クラウドには jq がある。Windows の Git Bash には無いので Python で代える
# - bend の動かし方: bend が PATH にあればそれを使う（クラウド）。無くて wslc があれば、
#   container/Containerfile から作ったイメージ（既定 bend2-slim、環境変数 BEND_CHECK_IMAGE で変更）の中で動かす（Windows）。
#   --verdict には Lean 入りのイメージ（既定 bend2-verdict、環境変数 BEND_VERDICT_IMAGE で変更）を使う

export BEND_NO_TELEMETRY=1
export PATH="$HOME/.bend/bin:$PATH"
BEND_IMAGE="${BEND_CHECK_IMAGE:-bend2-slim}"
# --verdict 用の Lean 入りイメージ（wslc build --target verdict で作る）。無ければ --verdict は飛ばす
BEND_VERDICT_IMAGE="${BEND_VERDICT_IMAGE:-bend2-verdict}"

# ---- JSON ----
# json_get <フィールド...>: 入力の JSON から、最初に見つかった文字列のフィールドを出す（"tool_input.file_path" の形）
if command -v jq >/dev/null 2>&1; then
  json_get() {
    local filter="" f
    for f in "$@"; do filter="${filter:+$filter // }.$f"; done
    jq -r "$filter // empty"
  }
  json_msg() { jq -n --arg m "$1" '{systemMessage: $m}'; }
  json_block() { jq -n --arg r "$1" '{decision: "block", reason: $r}'; }
  # json_warn <イベント名> <文>: 止めずに、利用者（systemMessage）と Claude（additionalContext）の両方に知らせる
  json_warn() { jq -n --arg e "$1" --arg m "$2" '{systemMessage: $m, hookSpecificOutput: {hookEventName: $e, additionalContext: $m}}'; }
else
  # 見つかっても起動できない Python（壊れたランチャーなど）は飛ばし、実際に動くものを使う
  BEND_PY=""
  for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import json' >/dev/null 2>&1; then
      BEND_PY="$cand"; break
    fi
  done
  if [ -z "$BEND_PY" ]; then
    echo "bend フック: 入力の JSON を読む道具（jq か Python）が動かないので検査を飛ばした" >&2
    exit 1
  fi
  # 標準入出力は UTF-8 のバイトで扱う（Windows の既定の CP932 だと日本語が化ける）
  json_get() {
    "$BEND_PY" -c 'import json,sys
d=json.loads(sys.stdin.buffer.read().decode("utf-8"))
for path in sys.argv[1:]:
    v=d
    for k in path.split("."):
        v=v.get(k) if isinstance(v, dict) else None
    if isinstance(v, str) and v:
        sys.stdout.buffer.write(v.encode("utf-8")); break' "$@"
  }
  json_msg() {
    "$BEND_PY" -c 'import json,sys; sys.stdout.buffer.write(json.dumps({"systemMessage": sys.argv[1]}, ensure_ascii=False).encode("utf-8"))' "$1"
  }
  json_block() {
    "$BEND_PY" -c 'import json,sys; sys.stdout.buffer.write(json.dumps({"decision": "block", "reason": sys.argv[1]}, ensure_ascii=False).encode("utf-8"))' "$1"
  }
  json_warn() {
    "$BEND_PY" -c 'import json,sys; sys.stdout.buffer.write(json.dumps({"systemMessage": sys.argv[2], "hookSpecificOutput": {"hookEventName": sys.argv[1], "additionalContext": sys.argv[2]}}, ensure_ascii=False).encode("utf-8"))' "$1" "$2"
  }
fi

# Windows のパス（ドライブ文字で始まる）だけ、区切りを / にそろえる。Linux では \ も名前に使えるので触らない
to_slash() { case "$1" in [A-Za-z]:\\*) printf '%s' "${1//\\//}" ;; *) printf '%s' "$1" ;; esac; }

# ---- bend の動かし方 ----
# bend_detect: BEND_RUNNER に native / wslc / none を入れる。none のときは BEND_WHY に理由を入れる
bend_detect() {
  BEND_WHY=""
  if command -v bend >/dev/null 2>&1; then
    BEND_RUNNER=native
  elif command -v wslc >/dev/null 2>&1; then
    if wslc image inspect "$BEND_IMAGE" >/dev/null 2>&1; then
      BEND_RUNNER=wslc
    else
      BEND_RUNNER=none
      BEND_WHY="wslc のイメージ $BEND_IMAGE が無い。リポジトリのルートで wslc build -t $BEND_IMAGE -f container/Containerfile container を実行すると使えるようになる"
    fi
  else
    BEND_RUNNER=none
    BEND_WHY="bend が見つからない（SessionStart フックが未実行の可能性）"
  fi
}

# bend_run <ディレクトリ> <bend の引数...>: そのディレクトリで bend を動かし、出力と終了コードを返す
# wslc では、プロジェクトのルートを /work に見せ、指定のディレクトリで動かす（../ で上の階層を import しても届くように）。
# プロジェクトの外なら、そのディレクトリだけを見せる
bend_run() {
  local dir="$1"; shift
  if [ "$BEND_RUNNER" = native ]; then
    (cd "$dir" && timeout 50 bend "$@" 2>&1)
    return
  fi
  local root mount workdir
  root=$(to_slash "${CLAUDE_PROJECT_DIR:-}")
  if [ -n "$root" ] && [ "${dir#"$root"/}" != "$dir" ]; then
    mount="$root"; workdir="/work/${dir#"$root"/}"
  elif [ -n "$root" ] && [ "$dir" = "$root" ]; then
    mount="$root"; workdir="/work"
  else
    mount="$dir"; workdir="/work"
  fi
  # MSYS_NO_PATHCONV: Git Bash が "C:/x:/work" や "/work" を Windows のパスに書き換えるのを止める
  MSYS_NO_PATHCONV=1 timeout 50 wslc run --rm -v "$mount:/work" -w "$workdir" "$BEND_IMAGE" bend "$@" 2>&1
}
