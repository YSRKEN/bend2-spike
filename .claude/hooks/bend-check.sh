#!/bin/bash
# PostToolUse フック（Write|Edit）: .bend ファイルが変わったら bend --check-only を走らせ、
# 失敗したら出力の先頭を Claude に返す（decision: block）。成功時は何も出さない。
#
# 検査対象:
# - 編集したファイル自体。ただし LAWS.bend は単体だと未証明の法則で必ず失敗するので、
#   同じディレクトリに PROOF.bend があればそちらを代わりに検査する
# - 同じディレクトリに PROOF.bend があれば、それも検査する（本体の変更で証明が壊れていないか）
#
# bend の動かし方（クラウドは bend、Windows は wslc）と JSON の扱いは lib-bend.sh にある
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib-bend.sh"

if ! file=$(json_get tool_input.file_path tool_response.filePath); then
  echo "bend-check: 入力の JSON を読めなかったので検査を飛ばした" >&2
  exit 1
fi
file=$(to_slash "$file")
case "$file" in
  *.bend) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

bend_detect
if [ "$BEND_RUNNER" = none ]; then
  json_msg "bend-check: 検査を飛ばした（$BEND_WHY）"
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
  out=$(bend_run "$dir" "$t" --check-only)
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
