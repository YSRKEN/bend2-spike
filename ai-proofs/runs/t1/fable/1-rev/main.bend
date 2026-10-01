import Base

# 連結。rev の補助。
def app(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      h <> app(t, ys)

# 反転。先頭を末尾へ送る素朴な定義。
def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      app(rev(t), h <> Nil{})
