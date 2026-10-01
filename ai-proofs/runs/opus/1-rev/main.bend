import Base

# 累積引数で反転する。xs の先頭を acc の先頭へ順に積み替える。
def rev.go(xs: List<&2, Nat>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      rev.go(t, Con{h, acc})

# リストを反転する。
def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  rev.go(xs, Nil{})
