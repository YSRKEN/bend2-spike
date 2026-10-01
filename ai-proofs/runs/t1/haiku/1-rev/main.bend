import Base

# ヘルパー関数: アキュムレータ付きの反転
def rev.go(xs: List<&2, Nat>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      rev.go(t, Con{h, acc})

# リストを反転する関数
def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  rev.go(xs, Nil{})
