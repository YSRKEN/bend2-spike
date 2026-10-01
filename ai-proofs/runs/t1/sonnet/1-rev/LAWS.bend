# 題 1: リストの反転。main.bend に rev を書き、PROOF.bend で次の法則を証明する。
# このファイルは人が書いた仕様。変えてはいけない。
import Base
import ./main.bend as M

# 仕様のための長さ
def Spec.len(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      1n+Spec.len(t)

# 法則: 2 回反転すると元に戻る
law rev_rev:
  for +xs: List<&2, Nat>
  {M.rev(M.rev(xs)) == xs : List<&2, Nat>}

# 法則: 反転しても長さは変わらない
law rev_len:
  for +xs: List<&2, Nat>
  {Spec.len(M.rev(xs)) == Spec.len(xs) : Nat}
