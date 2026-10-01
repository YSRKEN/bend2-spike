import Base

# 連長圧縮。右から畳み込み、先頭の値を 1 個ずつ push で足す。

# c は Nat.is_eq(x, y)。真なら先頭の組の個数を 1 増やし、偽なら新しい組 (x, 1) を前に置く
def sel(c: Bool, +x: Nat, +y: Nat, n: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match c:
    case True{}:
      (y, 1n+n) <> t
    case False{}:
      (x, 1n) <> ((y, n) <> t)

# 値 x を、組のリスト ps の前に 1 個足す
def push(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match ps:
    case Nil{}:
      (x, 1n) <> Nil{}
    case Con{p, t}:
      (+y, n) = p
      sel(Nat.is_eq(x, y), x, y, n, t)

def encode(xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+h, t}:
      push(h, encode(t))
