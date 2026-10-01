# 題 2: 空でないリストの最大値。
# 先頭 x を累積値にして、残り xs を左から畳み込む（末尾再帰）。
import Base

# 累積値 acc と xs の要素すべての最大値
def max.go(+xs: List<&2, Nat>, +acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{+h, t}:
      max.go(t, Nat.max(acc, h))

# 先頭 x と残り xs の最大値
def max(+x: Nat, +xs: List<&2, Nat>) -> Nat:
  max.go(xs, x)
