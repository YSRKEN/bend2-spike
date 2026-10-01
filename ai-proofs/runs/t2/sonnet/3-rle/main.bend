import Base

# 自然数の等しさ
def eq(a: Nat, b: Nat) -> Bool:
  match a b:
    case 0n 0n:
      True{}
    case 0n 1n+q:
      False{}
    case 1n+p 0n:
      False{}
    case 1n+p 1n+q:
      eq(p, q)

# 先頭の組 (y, m) と x の比較結果 b に応じて、x を足す
def pushgo(+x: Nat, +y: Nat, m: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, b: Bool) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match b:
    case True{}:
      (x, 1n+m) <> t
    case False{}:
      (x, 1n) <> ((y, m) <> t)

# x を符号化済みのリストの先頭に足す
def push(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match ps:
    case Nil{}:
      (x, 1n) <> Nil{}
    case Con{q, t}:
      (+y, m) = q
      pushgo(x, y, m, t, eq(x, y))

def encode(xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      push(h, encode(t))
