#!/bin/bash
# PostToolUse フック（Write|Edit）: .bend ファイルが変わったら bend --check-only を走らせ、
# 失敗したら出力の先頭を Claude に返す（decision: block）。成功時は何も出さない。
#
# 検査対象:
# - 編集したファイル自体。ただし LAWS.bend は単体だと未証明の法則で必ず失敗するので、
#   同じディレクトリに PROOF.bend があればそちらを代わりに検査する
# - 同じディレクトリに PROOF.bend があれば、それも検査する（本体の変更で証明が壊れていないか）
set -uo pipefail

export BEND_NO_TELEMETRY=1
export PATH="$HOME/.bend/bin:$PATH"

file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
case "$file" in
  *.bend) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

if ! command -v bend >/dev/null 2>&1; then
  jq -n '{systemMessage: "bend-check: bend が見つからないので検査を飛ばした（SessionStart フックが未実行の可能性）"}'
  exit 0
fi

dir=$(dirname "$file")
base=$(basename "$file")

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
  out=$(cd "$dir" && timeout 50 bend "$t" --check-only 2>&1)
  code=$?
  if [ $code -ne 0 ]; then
    head_out=$(printf '%s\n' "$out" | head -n 25 | cut -c1-400)
    report+="bend $t --check-only が失敗（exit $code、$dir）:"$'\n'"$head_out"$'\n\n'
  fi
done

if [ -n "$report" ]; then
  jq -n --arg r "$report" '{decision: "block", reason: $r}'
fi
exit 0
