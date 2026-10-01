import Base

# 偶数番目（0, 2, 4, ...）の要素
def evens(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, Nil{}}:
      h <> Nil{}
    case Con{h, Con{h2, t}}:
      h <> evens(t)

# 奇数番目（1, 3, 5, ...）の要素
def odds(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, Nil{}}:
      Nil{}
    case Con{h, Con{h2, t}}:
      h2 <> odds(t)

# 先頭 x, y を取り出した 2 本の整列済みリストのマージ。le は Nat.is_le(x, y)
def merge.go(xt: List<&2, Nat>, yt: List<&2, Nat>, +x: Nat, +y: Nat, le: Bool) -> List<&2, Nat>:
  match xt yt le:
    case Nil{} ys True{}:
      x <> y <> ys
    case Con{+x2, xt2} ys True{}:
      x <> merge.go(xt2, ys, x2, y, Nat.is_le(x2, y))
    case xs Nil{} False{}:
      y <> x <> xs
    case xs Con{+y2, yt2} False{}:
      y <> merge.go(xs, yt2, x, y2, Nat.is_le(x, y2))

def merge(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs ys:
    case Nil{} Nil{}:
      Nil{}
    case Nil{} Con{y, yt}:
      y <> yt
    case Con{x, xt} Nil{}:
      x <> xt
    case Con{+x, xt} Con{+y, yt}:
      merge.go(xt, yt, x, y, Nat.is_le(x, y))

# fuel は残りの分割の深さの上限。sort は長さを渡すので尽きない
def msort(fuel: Nat, xs: List<&2, Nat>) -> List<&2, Nat>:
  match fuel:
    case 0n:
      xs
    case 1n+(+f):
      match xs:
        case Nil{}:
          Nil{}
        case Con{h, Nil{}}:
          h <> Nil{}
        case Con{h, Con{h2, +t}}:
          a b = msort(f, h <> evens(t)) msort(f, h2 <> odds(t))
          merge(a, b)

def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  msort(List.length(&2, Nat, xs), xs)
