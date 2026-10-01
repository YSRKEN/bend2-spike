#!/bin/bash
# 公式の demo app_ray_tracer_3d の main.bend（Apache-2.0）を、commit を固定して取ってくる。
# リポジトリには写さず、手元の bench/raytrace/fly.bend に置く（.gitignore で外してある）。
#
#   bash bench/raytrace/fetch.sh
set -euo pipefail
commit=519d9b0c25dc8bce2234d80fa774a6e9ca2cc831
sha=1bb4a95bc8c68a6b18e54a1a61164a7a2f1b3c37399ccc6656e9d5271339d4a9
out="$(dirname "$0")/fly.bend"
curl -fsSL -o "$out" "https://raw.githubusercontent.com/bendlang/bend/$commit/demos/app_ray_tracer_3d/main.bend"
echo "$sha  $out" | sha256sum -c -
