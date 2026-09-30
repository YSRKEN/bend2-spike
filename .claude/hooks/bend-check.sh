#!/bin/bash
# PostToolUse フック（Write|Edit）: .bend ファイルが変わったら bend --check-only を走らせ、
# 失敗したら出力の先頭を Claude に返す（decision: block）。成功時は何も出さない。
#
# 検査対象:
# - 編集したファイル自体。ただし LAWS.bend は単体だと未証明の法則で必ず失敗するので、
#   同じディレクトリに PROOF.bend があればそちらを代わりに検査する
# - 同じディレクトリに PROOF.bend があれば、それも検査する（本体の変更で証明が壊れていないか）
#
# bend の動かし方:
# - bend が PATH にあれば、それを使う（クラウドセッション。SessionStart フックが入れる）
# - 無くて wslc があれば、container/Containerfile から作ったイメージ（既定 bend2-slim）の中で動かす
#   （Windows。イメージ名は環境変数 BEND_CHECK_IMAGE で変えられる）
# - どちらも無ければ、知らせて何もしない
set -uo pipefail

export BEND_NO_TELEMETRY=1
export PATH="$HOME/.bend/bin:$PATH"
IMAGE="${BEND_CHECK_IMAGE:-bend2-slim}"

# JSON の読み書き。クラウドには jq がある。Windows の Git Bash には無いので Python で代える
if command -v jq >/dev/null 2>&1; then
  json_file() { jq -r '.tool_input.file_path // .tool_response.filePath // empty'; }
  json_msg() { jq -n --arg m "$1" '{systemMessage: $m}'; }
  json_block() { jq -n --arg r "$1" '{decision: "block", reason: $r}'; }
else
  # 見つかっても起動できない Python（壊れたランチャーなど）は飛ばし、実際に動くものを使う
  PY=""
  for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import json' >/dev/null 2>&1; then
      PY="$cand"; break
    fi
  done
  if [ -z "$PY" ]; then
    echo "bend-check: 入力の JSON を読む道具（jq か Python）が動かないので検査を飛ばした" >&2
    exit 1
  fi
  # 標準入出力は UTF-8 のバイトで扱う（Windows の既定の CP932 だと日本語が化ける）
  json_file() {
    "$PY" -c 'import json,sys; d=json.loads(sys.stdin.buffer.read().decode("utf-8"))
p=(d.get("tool_input") or {}).get("file_path") or (d.get("tool_response") or {}).get("filePath") or ""
sys.stdout.buffer.write(p.encode("utf-8"))'
  }
  json_msg() {
    "$PY" -c 'import json,sys; sys.stdout.buffer.write(json.dumps({"systemMessage": sys.argv[1]}, ensure_ascii=False).encode("utf-8"))' "$1"
  }
  json_block() {
    "$PY" -c 'import json,sys; sys.stdout.buffer.write(json.dumps({"decision": "block", "reason": sys.argv[1]}, ensure_ascii=False).encode("utf-8"))' "$1"
  }
fi

if ! file=$(json_file); then
  echo "bend-check: 入力の JSON を読めなかったので検査を飛ばした" >&2
  exit 1
fi
# Windows のパス（ドライブ文字で始まる）だけ、区切りを / にそろえる。Linux では \ も名前に使えるので触らない
to_slash() { case "$1" in [A-Za-z]:\\*) printf '%s' "${1//\\//}" ;; *) printf '%s' "$1" ;; esac; }
file=$(to_slash "$file")
case "$file" in
  *.bend) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if command -v bend >/dev/null 2>&1; then
  runner=native
elif command -v wslc >/dev/null 2>&1; then
  if ! wslc image inspect "$IMAGE" >/dev/null 2>&1; then
    json_msg "bend-check: wslc のイメージ $IMAGE が無いので検査を飛ばした。リポジトリのルートで wslc build -t $IMAGE -f container/Containerfile container を実行すると使えるようになる"
    exit 0
  fi
  runner=wslc
else
  json_msg "bend-check: bend が見つからないので検査を飛ばした（SessionStart フックが未実行の可能性）"
  exit 0
fi

dir=$(dirname "$file")
base=$(basename "$file")

# wslc では、プロジェクトのルートを /work に見せ、編集したファイルのディレクトリで動かす
# （../ で上の階層を import しても届くように）。プロジェクトの外のファイルなら、そのディレクトリだけを見せる
root=$(to_slash "${CLAUDE_PROJECT_DIR:-}")
if [ -n "$root" ] && [ "${dir#"$root"/}" != "$dir" ]; then
  mount="$root"; workdir="/work/${dir#"$root"/}"
elif [ -n "$root" ] && [ "$dir" = "$root" ]; then
  mount="$root"; workdir="/work"
else
  mount="$dir"; workdir="/work"
fi

run_check() {
  if [ "$runner" = native ]; then
    (cd "$dir" && timeout 50 bend "$1" --check-only 2>&1)
  else
    # MSYS_NO_PATHCONV: Git Bash が "C:/x:/work" や "/work" を Windows のパスに書き換えるのを止める
    MSYS_NO_PATHCONV=1 timeout 50 wslc run --rm -v "$mount:/work" -w "$workdir" "$IMAGE" bend "$1" --check-only 2>&1
  fi
}

targets=()
if [ "$base" = "LAWS.bend" ] && [ -f "$dir/PROOF.bend" ]; then
  targets+=("PROOF.bend")
else
  targets+=("$base")
  if [ "$base" != "PROOF.bend" ] && [ -f "$dir/PROOF.bend" ]; then
    targets+=("PROOF.bend")
  fi
fi

report=""
for t in "${targets[@]}"; do
  # 失敗時のメッセージは文字列を 1 文字ずつ展開するので長い。行数と幅を切り詰める
  out=$(run_check "$t")
  code=$?
  if [ $code -ne 0 ]; then
    head_out=$(printf '%s\n' "$out" | head -n 25 | cut -c1-400)
    report+="bend $t --check-only が失敗（exit $code、$dir）:"$'\n'"$head_out"$'\n\n'
  fi
done

if [ -n "$report" ]; then
  json_block "$report"
fi
exit 0
