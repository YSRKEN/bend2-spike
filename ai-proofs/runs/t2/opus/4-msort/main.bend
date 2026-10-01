import Base

# x <= (ys の先頭)。空なら True（使われない）
def le_head(+x: Nat, ys: List<&2, Nat>) -> Bool:
  match ys:
    case Nil{}:
      True{}
    case Con{y, yt}:
      Nat.is_le(x, y)

# (xs の先頭) <= (ys の先頭)。どちらかが空なら True（使われない）
def le_heads(xs: List<&2, Nat>, +ys: List<&2, Nat>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case Con{x, xt}:
      le_head(x, ys)

# 2 つの昇順のリストを 1 つにまとめる。c は「xs の先頭 <= ys の先頭」
def merge.go(+xs: List<&2, Nat>, +ys: List<&2, Nat>, c: Bool) -> List<&2, Nat>:
  match xs ys c:
    case Nil{} _ _:
      ys
    case Con{x, xt} Nil{} _:
      xs
    case Con{x, xt} Con{y, yt} True{}:
      Con{x, merge.go(xt, ys, le_heads(xt, ys))}
    case Con{x, xt} Con{y, yt} False{}:
      Con{y, merge.go(xs, yt, le_heads(xs, yt))}

# 2 つの昇順のリストを 1 つにまとめる
def merge(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  merge.go(xs, ys, le_heads(xs, ys))

# 交互に振り分ける。b が True なら 0, 2, 4, ... 番目、False なら 1, 3, 5, ... 番目
def alt(xs: List<&2, Nat>, b: Bool) -> List<&2, Nat>:
  match xs b:
    case Nil{} _:
      Nil{}
    case Con{h, t} True{}:
      Con{h, alt(t, False{})}
    case Con{h, t} False{}:
      alt(t, True{})

# 燃料が尽きたときの予備（燃料に長さを渡すので、実際には空のリストにしか使われない）
def isort(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      merge([h], isort(t))

# 2 つに分け、両方を並列に整列してからマージする
def sort.go(+fuel: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match fuel:
    case 0n:
      isort(xs)
    case 1n+f:
      match xs:
        case Nil{}:
          Nil{}
        case Con{h, Nil{}}:
          [h]
        case Con{h, Con{h2, t}}:
          a b = sort.go(f, alt(xs, True{})) sort.go(f, alt(xs, False{}))
          merge(a, b)

def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  sort.go(List.length(&2, Nat, xs), xs)

def main() -> List<&2, Nat>:
  sort([5n, 3n, 9n, 1n, 3n, 0n, 7n, 2n, 8n, 3n])
