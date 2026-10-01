import Base

# 連長圧縮。末尾から順に作り、先頭の値が次の組の値と等しければ個数を足す。

def push2(+x: Nat, +y: Nat, m: Nat, r: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, c: Cmp) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match c:
    case EQ{}:
      (x, 1n+m) <> r
    case LT{}:
      (x, 1n) <> ((y, m) <> r)
    case GT{}:
      (x, 1n) <> ((y, m) <> r)

def push(+x: Nat, rs: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match rs:
    case Nil{}:
      (x, 1n) <> Nil{}
    case Con{q, r}:
      (+y, m) = q
      push2(x, y, m, r, Nat.cmp(x, y))

def encode(+xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{x, t}:
      push(x, encode(t))
