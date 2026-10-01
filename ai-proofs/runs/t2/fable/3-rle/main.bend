# 題 3: 連長圧縮（run-length encoding）の実装
import Base

# 一つの組
def Run() -> Data:
  Sigma<&2, &2, Nat, _ => Nat>

# 先頭の組 (y, m) が x と同じ値（same）なら個数を 1 増やし、違えば (x, 1) を前に置く
def encode.put(+x: Nat, +y: Nat, m: Nat, t: List<&2, Run()>, same: Bool) -> List<&2, Run()>:
  match same:
    case True{}:
      (y, 1n+m) <> t
    case False{}:
      (x, 1n) <> ((y, m) <> t)

# 符号化済みのリスト ps の前に x を 1 個足す
def encode.push(+x: Nat, ps: List<&2, Run()>) -> List<&2, Run()>:
  match ps:
    case Nil{}:
      [(x, 1n)]
    case Con{q, t}:
      (+y, m) = q
      encode.put(x, y, m, t, Nat.is_eq(x, y))

# 連長圧縮: 右から順に push していく
def encode(xs: List<&2, Nat>) -> List<&2, Run()>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, t}:
      encode.push(x, encode(t))
