#!/bin/bash
# SessionStart フック: Bend 2 と Lean を入れ、--verdict 用のカーネルを事前ビルドする。
# クラウドセッション（Claude Code on the web）でだけ導入する。何度実行しても同じ状態になる。
# クラウド以外では何も入れず、検査に使う wslc のイメージが無いときだけ知らせる。
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  # bend が無く wslc がある（Windows）のに、検査用のイメージが無ければ知らせる（メッセージに " や \ は入れない）
  image="${BEND_CHECK_IMAGE:-bend2-slim}"
  if ! command -v bend >/dev/null 2>&1 && command -v wslc >/dev/null 2>&1 \
     && ! wslc image inspect "$image" >/dev/null 2>&1; then
    msg="wslc のイメージ $image が無いので、.bend の編集後と commit 前の証明の検査が動かない。リポジトリのルートで wslc build -t $image -f container/Containerfile container を実行する"
    printf '{"systemMessage": "%s", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "%s"}}\n' "$msg" "$msg"
  fi
  exit 0
fi

BEND_VER="2.0.34"
BEND_SHA="78106a97af242429dcc057258eb8d10f69cddebcd5e263022185a52d003e09bf"  # linux-x64
LEAN_TOOLCHAIN="leanprover/lean4:v4.34.0"  # bend 2.0.34 の --verdict が要求する版

BEND_HOME="$HOME/.bend"
ELAN_HOME_DIR="$HOME/.elan"
log() { echo "[bend-hook] $*" >&2; }
# bend は 1 日 1 回 bend-lang.com に最新版を問い合わせる。フック内の呼び出しでも止めておく
export BEND_NO_TELEMETRY=1

# ---- Bend（公式 install.sh と同じ手順を版固定で行う） ----
if [ "$("$BEND_HOME/bin/bend" version 2>/dev/null || true)" = "bend $BEND_VER" ]; then
  log "bend $BEND_VER は導入済み"
else
  [ "$(uname -s)-$(uname -m)" = "Linux-x86_64" ] || { log "Linux x86_64 以外は未対応"; exit 1; }
  log "bend $BEND_VER を導入"
  mkdir -p "$BEND_HOME/bin"
  tmp=$(mktemp -d "$BEND_HOME/tmp.XXXXXX")
  trap 'rm -rf "$tmp"' EXIT
  name="bend-$BEND_VER-linux-x64.tar.gz"
  curl --proto '=https' --tlsv1.2 -fsSL -o "$tmp/$name" \
    "https://github.com/bendlang/bend/releases/download/v$BEND_VER/$name"
  echo "$BEND_SHA  $tmp/$name" | sha256sum -c - >/dev/null \
    || { log "SHA256 が一致しない。導入しない"; exit 1; }
  tar -xzf "$tmp/$name" -C "$tmp"
  rm -rf "$BEND_HOME/bend2" "$BEND_HOME/guide" "$BEND_HOME/bendtt"
  mv "$tmp/bend/bend2" "$tmp/bend/guide" "$BEND_HOME/"
  mv -f "$tmp/bend/bin/bend" "$BEND_HOME/bin/bend"
  rm -rf "$tmp"
  trap - EXIT
fi

# ---- clang（ネイティブビルド用。無ければ警告だけ） ----
if ! command -v clang >/dev/null 2>&1; then
  log "警告: clang が無い。ネイティブビルド（-o）には clang 14+ が要る"
fi

# ---- Lean（--verdict 用） ----
if [ -x "$ELAN_HOME_DIR/bin/lean" ] && "$ELAN_HOME_DIR/bin/elan" toolchain list 2>/dev/null | grep -q "lean4---v4.34.0\|lean4:v4.34.0"; then
  log "$LEAN_TOOLCHAIN は導入済み"
else
  log "$LEAN_TOOLCHAIN を導入"
  init=$(mktemp)
  curl --proto '=https' --tlsv1.2 -fsSL -o "$init" \
    https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh
  sh "$init" -y --no-modify-path --default-toolchain "$LEAN_TOOLCHAIN" >&2
  rm -f "$init"
fi

export PATH="$BEND_HOME/bin:$ELAN_HOME_DIR/bin:$PATH"

# ---- --verdict 用カーネルの事前ビルド（初回は約 30 秒） ----
if [ -d "$BEND_HOME/bendtt" ] && [ -n "$(ls -A "$BEND_HOME/bendtt" 2>/dev/null)" ]; then
  log "カーネルはビルド済み"
else
  log "カーネルをビルド"
  d=$(mktemp -d)
  printf 'import Base\n\ndef main() -> {Nat.add(0n, 1n) == 1n : Nat}:\n  {==}\n' > "$d/k.bend"
  out=$(cd "$d" && bend k.bend --verdict 2>&1) || { log "カーネルのビルドに失敗: $out"; rm -rf "$d"; exit 1; }
  rm -rf "$d"
fi

# ---- セッションの環境変数 ----
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  line="export PATH=\"$BEND_HOME/bin:$ELAN_HOME_DIR/bin:\$PATH\" BEND_NO_TELEMETRY=1"
  grep -qxF "$line" "$CLAUDE_ENV_FILE" 2>/dev/null || echo "$line" >> "$CLAUDE_ENV_FILE"
fi

log "完了: $(bend version) / $(lean --version | cut -d, -f1)"
