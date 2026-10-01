# 題 1: リストの反転。累積引数を使って線形時間で反転する。
import Base

# xs を反転して acc の前に積む
def rev.go(xs: List<&2, Nat>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      rev.go(t, Con{h, acc})

def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  rev.go(xs, Nil{})
