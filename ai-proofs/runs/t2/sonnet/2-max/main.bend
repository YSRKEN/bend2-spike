import Base

# 先頭から順に、ここまでの最大値 acc を持ち回る
def max.go(+xs: List<&2, Nat>, +acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      max.go(t, Nat.max(acc, h))

def max(+x: Nat, +xs: List<&2, Nat>) -> Nat:
  max.go(xs, x)
