import Base

# リストの連結
def app(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      h <> app(t, ys)

# リストの反転（末尾に付け足す素朴な形。証明しやすさを優先）
def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      app(rev(t), [h])
