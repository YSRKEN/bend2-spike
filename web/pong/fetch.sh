#!/bin/bash
# 公式の demo app_pong_game_2d の main.bend（Apache-2.0）を、commit を固定して取ってくる。
# リポジトリには写さず、手元の web/pong/main.bend に置く（.gitignore で外してある）。
#
#   bash web/pong/fetch.sh
set -euo pipefail
commit=519d9b0c25dc8bce2234d80fa774a6e9ca2cc831
sha=b22314aec40b5a1f47a8a53450663c292d6932cc35ea8ffa8531cc4e464816c0
out="$(dirname "$0")/main.bend"
curl -fsSL -o "$out" "https://raw.githubusercontent.com/bendlang/bend/$commit/demos/app_pong_game_2d/main.bend"
echo "$sha  $out" | sha256sum -c -
