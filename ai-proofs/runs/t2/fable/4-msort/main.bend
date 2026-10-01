# 題 4: 並列マージソート
import Base

# 整列済みの x <> xt と y <> yt を併合する。le は Nat.is_le(x, y) の値を呼び手が渡す
def merge.go(xt: List<&2, Nat>, yt: List<&2, Nat>, le: Bool, +x: Nat, +y: Nat) -> List<&2, Nat>:
  match xt yt le:
    case Nil{} ys True{}:
      x <> y <> ys
    case +x2 <> xt2 ys True{}:
      x <> merge.go(xt2, ys, Nat.is_le(x2, y), x2, y)
    case xs Nil{} False{}:
      y <> x <> xs
    case xs +y2 <> yt2 False{}:
      y <> merge.go(xs, yt2, Nat.is_le(x, y2), x, y2)

# 整列済みの 2 つのリストを併合する
def merge(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs ys:
    case Nil{} ys2:
      ys2
    case x <> xt Nil{}:
      x <> xt
    case +x <> xt +y <> yt:
      merge.go(xt, yt, Nat.is_le(x, y), x, y)

# 偶数番目の要素
def evens(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> Nil{}:
      h <> Nil{}
    case h <> h2 <> t:
      h <> evens(t)

# 奇数番目の要素
def odds(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> Nil{}:
      Nil{}
    case h <> h2 <> t:
      h2 <> odds(t)

# リストを交互に 2 つに分ける
def split(+xs: List<&2, Nat>) -> Sigma<&2, &2, List<&2, Nat>, _ => List<&2, Nat>>:
  (evens(xs), odds(xs))

# 燃料が尽きたときの予備（挿入ソート）。実際には長さ 1 以下のリストにしか届かない
def isort(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      merge(h <> Nil{}, isort(t))

# 2 つに分けた半分ずつを並列に整列してから併合する。燃料は再帰の深さの上限
def sort.go(+fuel: Nat, lr: Sigma<&2, &2, List<&2, Nat>, _ => List<&2, Nat>>) -> List<&2, Nat>:
  match fuel:
    case 0n:
      (l, r) = lr
      merge(isort(l), isort(r))
    case 1n+f:
      (l, r) = lr
      match l r:
        case Nil{} r2:
          isort(r2)
        case x <> xt Nil{}:
          isort(x <> xt)
        case x <> xt y <> yt:
          a b = sort.go(f, split(x <> xt)) sort.go(f, split(y <> yt))
          merge(a, b)

def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  sort.go(List.length(&2, Nat, xs), split(xs))
