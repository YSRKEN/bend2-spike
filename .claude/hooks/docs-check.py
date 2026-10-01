"""docs と実物の食い違いを見つける。commit 前のフック（pre-commit-check.sh）から呼ぶ。

見るもの:
- LAWS.bend の法則（`law 名前:`）と、docs/proofs.md の法則の表（1 列目が `名前` の行）が一致するか
- README.md と docs/*.md の相対リンク（[文字](パス)）の先が実在するか
- README.md と docs/*.md に `server/server.bend` のように書いたリポジトリ内のパスが実在するか
  （リポジトリの直下にある名前で始まるものだけを見る）

使い方: python docs-check.py <リポジトリのルート>
食い違いがあれば 1 行ずつ出して終了コード 1、無ければ何も出さずに 0。
"""
import pathlib
import re
import sys

LAW = re.compile(r"^law\s+([A-Za-z_][\w]*)\s*:", re.M)
TABLE_LAW = re.compile(r"^\|\s*`([A-Za-z_]\w*)`\s*\|", re.M)
LINK = re.compile(r"\]\(([^)\s]+)\)")
CODE = re.compile(r"`([^`\s]+)`")


def main(root):
    problems = []
    docs = [root / "README.md"] + sorted((root / "docs").glob("*.md"))
    docs = [d for d in docs if d.exists()]

    # ai-proofs/ は AI に解かせた実験の記録で、題ごとの法則と、通らなかった証明もそのまま残している
    laws = {m for f in root.rglob("LAWS.bend")
            if not any(p.startswith(".") for p in f.relative_to(root).parts)
            and f.relative_to(root).parts[0] != "ai-proofs"
            for m in LAW.findall(f.read_text(encoding="utf-8"))}
    proofs = root / "docs" / "proofs.md"
    if laws and proofs.exists():
        table = set(TABLE_LAW.findall(proofs.read_text(encoding="utf-8")))
        for name in sorted(laws - table):
            problems.append(f"docs/proofs.md: 法則 `{name}` が LAWS.bend にあるのに、法則の表に無い")
        for name in sorted(table - laws):
            problems.append(f"docs/proofs.md: 法則の表の `{name}` が LAWS.bend に無い")

    top = {p.name for p in root.iterdir() if p.name != ".git"}
    for doc in docs:
        rel = doc.relative_to(root).as_posix()
        text = doc.read_text(encoding="utf-8")
        for target in LINK.findall(text):
            if re.match(r"[a-z]+:", target) or target.startswith("#"):
                continue
            path = target.split("#", 1)[0]
            if path and not (doc.parent / path).exists():
                problems.append(f"{rel}: リンク先 {target} が無い")
        for token in CODE.findall(text):
            first = token.split("/", 1)[0]
            if "/" not in token or first not in top or any(c in token for c in "<>*${}"):
                continue
            if not (root / token.rstrip("/")).exists():
                problems.append(f"{rel}: パス `{token}` が無い")

    for p in problems:
        print(p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(pathlib.Path(sys.argv[1]).resolve()))
