import Base
import ./LAWS.bend as Laws
import ./main.bend as M

def le_refl(+a: Nat) -> Laws.Spec.LE(a, a):
  match a:
    case 0n:
      Unit{}
    case 1n+p:
      le_refl(p)

def le_trans(a: Nat, b: Nat, c: Nat, ab: Laws.Spec.LE(a, b), bc: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+a1 0n _:
      match ab:
    case 1n+a1 1n+b1 0n:
      match bc:
    case 1n+a1 1n+b1 1n+c1:
      le_trans(a1, b1, c1, ab, bc)

def le_max_l(+a: Nat, +b: Nat) -> Laws.Spec.LE(a, Nat.max(a, b)):
  match a b:
    case 0n _:
      Unit{}
    case 1n+a1 0n:
      le_refl(a1)
    case 1n+a1 1n+b1:
      le_max_l(a1, b1)

def le_max_r(+a: Nat, +b: Nat) -> Laws.Spec.LE(b, Nat.max(a, b)):
  match a b:
    case 0n _:
      le_refl(b)
    case 1n+a1 0n:
      Unit{}
    case 1n+a1 1n+b1:
      le_max_r(a1, b1)

def choice_succ(+a: Nat, +b: Nat, c: Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat})) -> Or({1n+Nat.max(a, b) == 1n+a : Nat}, {1n+Nat.max(a, b) == 1n+b : Nat}):
  match c:
    case Inl{e}:
      Inl{
        %e : {1n+Nat.max(a, b) == 1n+_ : Nat}
        {==}
      }
    case Inr{e}:
      Inr{
        %e : {1n+Nat.max(a, b) == 1n+_ : Nat}
        {==}
      }

def max_choice(+a: Nat, +b: Nat) -> Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat}):
  match a b:
    case 0n _:
      Inr{{==}}
    case 1n+a1 0n:
      Inl{{==}}
    case 1n+a1 1n+b1:
      choice_succ(a1, b1, max_choice(a1, b1))

def all_mono(+xs: List<&2, Nat>, +m: Nat, +n: Nat, +mn: Laws.Spec.LE(m, n), all: Laws.Spec.All(m, xs)) -> Laws.Spec.All(n, xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      (hm, rest) = all
      (le_trans(h, m, n, hm, mn), all_mono(t, m, n, mn, rest))

def all_go(+xs: List<&2, Nat>, +x: Nat) -> Laws.Spec.All(M.go(xs, x), x <> xs):
  match xs:
    case Nil{}:
      (le_refl(x), Unit{})
    case Con{h, t}:
      (le_max_l(x, M.go(t, h)), all_mono(h <> t, M.go(t, h), Nat.max(x, M.go(t, h)), le_max_r(x, M.go(t, h)), all_go(t, h)))

def elem_step(+x: Nat, +g: Nat, +h: Nat, +t: List<&2, Nat>, c: Or({Nat.max(x, g) == x : Nat}, {Nat.max(x, g) == g : Nat}), ih: Laws.Spec.Elem(g, h <> t)) -> Laws.Spec.Elem(Nat.max(x, g), x <> h <> t):
  match c:
    case Inl{e}:
      Inl{e}
    case Inr{e}:
      Inr{
        %Equal.sym(Nat, Nat.max(x, g), g, e) : Laws.Spec.Elem(_, h <> t)
        ih
      }

def elem_go(+xs: List<&2, Nat>, +x: Nat) -> Laws.Spec.Elem(M.go(xs, x), x <> xs):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{h, t}:
      elem_step(x, M.go(t, h), h, t, max_choice(x, M.go(t, h)), elem_go(t, h))

def Laws.max_upper(x, xs):
  all_go(xs, x)

def Laws.max_elem(x, xs):
  elem_go(xs, x)
