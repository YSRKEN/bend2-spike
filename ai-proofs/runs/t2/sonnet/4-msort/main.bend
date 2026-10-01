import Base

# a <= b（Spec.LE と同じ形で再帰する）
def le(+a: Nat, +b: Nat) -> Bool:
  match a b:
    case 0n _:
      True{}
    case 1n+a1 0n:
      False{}
    case 1n+a1 1n+b1:
      le(a1, b1)

# 両方の先頭があれば、その比較。どちらかが空なら True（使われない）
def hd_le(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> Bool:
  match xs ys:
    case Nil{} _:
      True{}
    case Con{h, t} Nil{}:
      True{}
    case Con{h, t} Con{g, u}:
      le(h, g)

# 昇順の 2 リストのマージ。b は「先頭どうしの比較」の結果（呼び出し側が保つ）
def merge(+xs: List<&2, Nat>, +ys: List<&2, Nat>, +b: Bool) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      match ys:
        case Nil{}:
          xs
        case Con{g, u}:
          match b:
            case True{}:
              h <> merge(t, ys, hd_le(t, ys))
            case False{}:
              g <> merge(xs, u, hd_le(xs, u))

def mg(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  merge(xs, ys, hd_le(xs, ys))

# 偶数番目・奇数番目の要素
def evens(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      match t:
        case Nil{}:
          h <> Nil{}
        case Con{g, u}:
          h <> evens(u)

def odds(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      match t:
        case Nil{}:
          Nil{}
        case Con{g, u}:
          g <> odds(u)

# 挿入ソート（燃料切れの保険）
def isort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      mg(h <> Nil{}, isort(t))

def sort_fuel(+n: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n:
      isort(xs)
    case 1n+p:
      match xs:
        case Nil{}:
          xs
        case Con{h, t}:
          match t:
            case Nil{}:
              xs
            case Con{h2, t2}:
              c d = sort_fuel(p, evens(xs)) sort_fuel(p, odds(xs))
              mg(c, d)

def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  sort_fuel(List.length(&2, Nat, xs), xs)
