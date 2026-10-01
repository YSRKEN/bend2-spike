# 題 2: 空でないリストの最大値。
# max(x, xs) は「先頭 x と残り xs」の最大値。
# 停止性の検査はリストを先頭引数に置く必要があるので、max.go に委ねる。
import Base

# go(xs, x) = x と xs の要素の最大値。xs が縮むので停止する。
def max.go(xs: List<&2, Nat>, x: Nat) -> Nat:
  match xs:
    case Nil{}:
      x
    case Con{h, t}:
      Nat.max(x, max.go(t, h))

def max(x: Nat, xs: List<&2, Nat>) -> Nat:
  max.go(xs, x)
