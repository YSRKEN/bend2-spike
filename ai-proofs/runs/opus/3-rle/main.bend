# 題 3 の実装: 連長圧縮。右から畳み、先頭の組に同じ値なら個数を足す。
import Base

# Nat の等しさを Bool で答える
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

# h を先頭の組 (y, m) の前に置く。b は h と y が等しいか
def pushc(
  b: Bool, +h: Nat, +y: Nat, m: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match b:
    case True{}:
      (y, 1n+m) <> t
    case False{}:
      (h, 1n) <> ((y, m) <> t)

# h を組のリストの前に置く
def push(+h: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) ->
  List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match ps:
    case Nil{}:
      (h, 1n) <> Nil{}
    case Con{+p, t}:
      (y, m) = p
      pushc(eq(h, y), h, y, m, t)

def encode(xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{+h, t}:
      push(h, encode(t))
