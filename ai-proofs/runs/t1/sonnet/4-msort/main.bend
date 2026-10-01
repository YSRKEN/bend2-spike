import Base

# 先頭の要素を、keep が True のときだけ r の前に付ける
def keepif(keep: Bool, h: Nat, r: List<&2, Nat>) -> List<&2, Nat>:
  match keep:
    case True{}:
      Con{h, r}
    case False{}:
      r

# xs を 1 つおきに取り出す。keep が True なら先頭から、False なら 2 番目から。
def half(xs: List<&2, Nat>, +keep: Bool) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      keepif(keep, h, half(t, Bool.not(keep)))

# マージの 1 手: c が True なら a を、False なら b を先頭に置く
def pick(c: Bool, a: Nat, b: Nat, r1: List<&2, Nat>, r2: List<&2, Nat>) -> List<&2, Nat>:
  match c:
    case True{}:
      Con{a, r1}
    case False{}:
      Con{b, r2}

# 昇順の 2 つのリストを、昇順のまま 1 つにする
def merge(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{a, at}:
      match ys:
        case Nil{}:
          xs
        case Con{b, bs}:
          pick(Nat.is_le(a, b), a, b, merge(at, ys), merge(xs, bs))

# 燃料が尽きたときの予備（挿入ソート）。燃料はリストの長さで始めるので、実際には使われない。
def isort(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      merge(Con{h, Nil{}}, isort(t))

# 燃料つきのマージソート。2 つに分け、parallel let で並列に整列してからマージする。
def sortF(+n: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n:
      isort(xs)
    case 1n+p:
      match xs:
        case Nil{}:
          Nil{}
        case Con{h, t}:
          match t:
            case Nil{}:
              Con{h, Nil{}}
            case Con{h2, r}:
              a b = sortF(p, half(xs, True{})) sortF(p, half(xs, False{}))
              merge(a, b)

def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  sortF(List.length(&2, Nat, xs), xs)
