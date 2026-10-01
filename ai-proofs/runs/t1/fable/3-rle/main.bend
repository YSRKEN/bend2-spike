# 題 3: 連長圧縮。encode は Nat のリストを (値, 個数) の組のリストにする。
import Base

# x を、先頭の組 (y, n) に合流させるか、新しい組として前に置くか。
# same は Nat.is_eq(x, y) の値（match は計算した値を直接見られないので引数で受ける）。
def encode.push.if(
  x: Nat, y: Nat, n: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, same: Bool
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match same:
    case True{}:
      (y, 1n+n) <> t
    case False{}:
      (x, 1n) <> ((y, n) <> t)

# 符号化済みの ps の先頭に x を 1 個足す
def encode.push(
  +x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match ps:
    case Nil{}:
      [(x, 1n)]
    case Con{Tuple{+y, n}, t}:
      encode.push.if(x, y, n, t, Nat.is_eq(x, y))

# 連長圧縮。後ろから組を作り、先頭の要素を一つずつ足していく。
def encode(xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+x, t}:
      encode.push(x, encode(t))
