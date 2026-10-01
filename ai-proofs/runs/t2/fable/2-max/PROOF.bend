# 題 2 の証明。LAWS.bend の max_upper・max_elem を証明する。
import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# --- Spec.LE の補題 -------------------------------------------------------

# a <= a
def LE.refl(+a: Nat) -> Laws.Spec.LE(a, a):
  match a:
    case 0n:
      Unit{}
    case 1n+p:
      LE.refl(p)

# a <= b, b <= c なら a <= c
def LE.trans(+a: Nat, +b: Nat, +c: Nat, ab: Laws.Spec.LE(a, b), bc: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+ap 0n _:
      match ab:
    case 1n+ap 1n+bp 0n:
      match bc:
    case 1n+ap 1n+bp 1n+cp:
      LE.trans(ap, bp, cp, ab, bc)

# a <= Nat.max(a, b)
def LE.max_l(+a: Nat, +b: Nat) -> Laws.Spec.LE(a, Nat.max(a, b)):
  match a b:
    case 0n _:
      Unit{}
    case 1n+ap 0n:
      LE.refl(ap)
    case 1n+ap 1n+bp:
      LE.max_l(ap, bp)

# b <= Nat.max(a, b)
def LE.max_r(+a: Nat, +b: Nat) -> Laws.Spec.LE(b, Nat.max(a, b)):
  match a b:
    case 0n _:
      LE.refl(b)
    case 1n+ap 0n:
      Unit{}
    case 1n+ap 1n+bp:
      LE.max_r(ap, bp)

# 1n+ を両辺に足す（計算した値には match できないので、引数で受ける）
def Nat.max.cases.succ(-ap: Nat, -bp: Nat, c: Or({Nat.max(ap, bp) == ap : Nat}, {Nat.max(ap, bp) == bp : Nat})) -> Or({1n+Nat.max(ap, bp) == 1n+ap : Nat}, {1n+Nat.max(ap, bp) == 1n+bp : Nat}):
  match c:
    case Inl{e}:
      Inl{Equal.cong(Nat, Nat, p => 1n+p, Nat.max(ap, bp), ap, e)}
    case Inr{e}:
      Inr{Equal.cong(Nat, Nat, p => 1n+p, Nat.max(ap, bp), bp, e)}

# Nat.max(a, b) は a か b のどちらかに等しい
def Nat.max.cases(+a: Nat, +b: Nat) -> Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat}):
  match a b:
    case 0n _:
      Inr{{==}}
    case 1n+ap 0n:
      Inl{{==}}
    case 1n+ap 1n+bp:
      Nat.max.cases.succ(ap, bp, Nat.max.cases(ap, bp))

# --- Spec.All・Spec.Elem の補題 ------------------------------------------

# m <= n なら、All(m, xs) から All(n, xs)
def All.mono(+m: Nat, +n: Nat, xs: List<&2, Nat>, +le: Laws.Spec.LE(m, n), all: Laws.Spec.All(m, xs)) -> Laws.Spec.All(n, xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+h, t}:
      (lh, lt) = all
      (LE.trans(h, m, n, lh, le), All.mono(m, n, t, le, lt))

# Elem(g, xs) で、Nat.max(x, g) が x か g なら、Elem の形の結論が出る
def Elem.max(+x: Nat, +g: Nat, xs: List<&2, Nat>, c: Or({Nat.max(x, g) == x : Nat}, {Nat.max(x, g) == g : Nat}), e: Laws.Spec.Elem(g, xs)) -> Or({Nat.max(x, g) == x : Nat}, Laws.Spec.Elem(Nat.max(x, g), xs)):
  match c:
    case Inl{p}:
      Inl{p}
    case Inr{p}:
      %Equal.sym(Nat, Nat.max(x, g), g, p) : Or({Nat.max(x, g) == x : Nat}, Laws.Spec.Elem(_, xs))
      Inr{e}

# --- max.go についての主補題 ----------------------------------------------

# go(xs, x) は x と xs のどの要素以上でもある
def Go.all(xs: List<&2, Nat>, +x: Nat) -> Laws.Spec.All(M.max.go(xs, x), x <> xs):
  match xs:
    case Nil{}:
      (LE.refl(x), Unit{})
    case Con{+h, +t}:
      (LE.max_l(x, M.max.go(t, h)), All.mono(M.max.go(t, h), Nat.max(x, M.max.go(t, h)), h <> t, LE.max_r(x, M.max.go(t, h)), Go.all(t, h)))

# go(xs, x) は x か xs の要素の一つ
def Go.elem(xs: List<&2, Nat>, +x: Nat) -> Laws.Spec.Elem(M.max.go(xs, x), x <> xs):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{+h, +t}:
      Elem.max(x, M.max.go(t, h), h <> t, Nat.max.cases(x, M.max.go(t, h)), Go.elem(t, h))

# --- 法則 -----------------------------------------------------------------

def Laws.max_upper(x, xs):
  Go.all(xs, x)

def Laws.max_elem(x, xs):
  Go.elem(xs, x)
