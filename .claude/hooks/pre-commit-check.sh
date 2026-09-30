#!/bin/bash
# PreToolUse フック（Bash|PowerShell）: git commit の前に、証明と docs を検査する。
# 落ちたら理由を標準エラーに出して終了コード 2 で止める（Claude に差し戻される）。
#
# 1. docs と実物の食い違い（docs-check.py）: 法則の一覧と docs/proofs.md の表、リンクとパスの実在
# 2. 証明: .bend に変更（ステージ済み・未ステージ・未追跡）があるときだけ、各 PROOF.bend を --check-only で検査する。
#    bend がそのまま使えて Lean もある環境（クラウド）では --verdict も走らせる
#
# 検査するのは作業ツリーの中身（commit されるステージの中身とは限らない）。
# 編集後フック（bend-check.sh）が拾えない、ファイルの移動などの変更を commit の前に拾うためのもの。
set -uo pipefail

# すべての Bash・PowerShell の前に走るので、commit と無関係なら何も起こさずに抜ける
input=$(cat)
case "$input" in
  *commit*) ;;
  *) exit 0 ;;
esac
source "$(dirname "${BASH_SOURCE[0]}")/lib-bend.sh"

cmd=$(printf '%s' "$input" | json_get tool_input.command) || exit 0
# git commit を含むコマンドだけを見る（git -C … commit などのオプションを挟んでもよい）
printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([^[:alnum:]_-]|$)' || exit 0

root=$(to_slash "${CLAUDE_PROJECT_DIR:-}")
[ -n "$root" ] && [ -d "$root/.git" ] || exit 0

report=""

# ---- 1. docs と実物の食い違い ----
py=""
for cand in python3 python; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys' >/dev/null 2>&1; then py="$cand"; break; fi
done
if [ -n "$py" ]; then
  out=$(PYTHONIOENCODING=utf-8 "$py" "$root/.claude/hooks/docs-check.py" "$root" 2>&1)
  if [ $? -ne 0 ]; then
    report+="docs と実物が食い違っている（.claude/hooks/docs-check.py）:"$'\n'"$out"$'\n\n'
  fi
fi

# ---- 2. 証明 ----
if [ -n "$(git -C "$root" status --porcelain --untracked-files=all -- '*.bend' 2>/dev/null)" ]; then
  bend_detect
  if [ "$BEND_RUNNER" = none ]; then
    report+="証明を検査できない（$BEND_WHY）。.bend を変えた commit の前には検査が要る"$'\n\n'
  else
    modes=("--check-only")
    if [ "$BEND_RUNNER" = native ] && command -v lean >/dev/null 2>&1; then
      modes+=("--verdict")
    fi
    while IFS= read -r proof; do
      dir=$(dirname "$proof")
      for m in "${modes[@]}"; do
        out=$(bend_run "$dir" PROOF.bend "$m")
        code=$?
        if [ $code -ne 0 ]; then
          head_out=$(printf '%s\n' "$out" | head -n 25 | cut -c1-400)
          report+="bend PROOF.bend $m が失敗（exit $code、${dir#"$root"/}）:"$'\n'"$head_out"$'\n\n'
        fi
      done
    done < <(find "$root" -name PROOF.bend -not -path '*/.*/*')
  fi
fi

if [ -n "$report" ]; then
  printf 'commit 前の検査で止めた（.claude/hooks/pre-commit-check.sh）。直してから commit し直す。\n\n%s' "$report" >&2
  exit 2
fi
exit 0
