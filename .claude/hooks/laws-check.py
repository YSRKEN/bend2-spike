"""LAWS.bend の法則が、カーネル（--verdict）に渡る入力にすべて載っているかを見る。commit 前のフックから呼ぶ。

--verdict は、bend2 の型検査が通した def を Lean で証明されたカーネルでもう一度検査する。ところが、カーネルへの
入力（bend PROOF.bend -o x.bendtt）に載らない def は、カーネルに見られないまま ALL PROOFS CHECK になることがある
（bendlang/bend#1186。docs/proofs.md の「--verdict は型検査の二重目の網」）。そこで、法則がどれも
`<LAWS のファイル名>.<法則名> :` の形で載っていることを確かめる。

使い方: python laws-check.py <LAWS.bend> <x.bendtt>
載っていない法則があれば 1 行ずつ出して終了コード 1、すべて載っていれば何も出さずに 0。
"""
import pathlib
import re
import sys

LAW = re.compile(r"^law\s+([A-Za-z_]\w*)\s*:", re.M)


def missing_laws(laws_text, bendtt_text, namespace):
    laws = LAW.findall(laws_text)
    emitted = set(re.findall(r"^(\S+) :", bendtt_text, re.M))
    return [name for name in laws if f"{namespace}.{name}" not in emitted]


def main(laws_path, bendtt_path):
    laws = pathlib.Path(laws_path)
    missing = missing_laws(laws.read_text(encoding="utf-8"),
                           pathlib.Path(bendtt_path).read_text(encoding="utf-8"),
                           laws.stem)
    for name in missing:
        print(f"法則 `{name}` がカーネルへの入力に無い（--verdict がこの法則を検査していない）")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1], sys.argv[2]))
