import Base
import ./LAWS.bend as Laws
import ./main.bend as M

def LE_refl(+a: Nat) -> Laws.Spec.LE(a, a):
  match a:
    case 0n:
      Unit{}
    case 1n+p:
      LE_refl(p)

def LE_trans(+a: Nat, +b: Nat, +c: Nat, p: Laws.Spec.LE(a, b), q: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+a1 0n _:
      match p:
    case 1n+a1 1n+b1 0n:
      match q:
    case 1n+a1 1n+b1 1n+c1:
      LE_trans(a1, b1, c1, p, q)

def max_l(+a: Nat, +b: Nat) -> Laws.Spec.LE(a, Nat.max(a, b)):
  match a b:
    case 0n _:
      Unit{}
    case 1n+a1 0n:
      LE_refl(a1) 
    case 1n+a1 1n+b1:
      max_l(a1, b1)

def max_r(+a: Nat, +b: Nat) -> Laws.Spec.LE(b, Nat.max(a, b)):
  match a b:
    case 0n _:
      LE_refl(b)
    case 1n+a1 0n:
      Unit{}
    case 1n+a1 1n+b1:
      max_r(a1, b1)

# 結果は a か b のどちらか
def max_or_succ(+a: Nat, +b: Nat, o: Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat})) -> Or({1n+Nat.max(a, b) == 1n+a : Nat}, {1n+Nat.max(a, b) == 1n+b : Nat}):
  match o:
    case Inl{e}:
      %e : Or({1n+Nat.max(a, b) == 1n+_ : Nat}, {1n+Nat.max(a, b) == 1n+b : Nat})
      Inl{{==}}
    case Inr{e}:
      %e : Or({1n+Nat.max(a, b) == 1n+a : Nat}, {1n+Nat.max(a, b) == 1n+_ : Nat})
      Inr{{==}}

def max_or(+a: Nat, +b: Nat) -> Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat}):
  match a b:
    case 0n _:
      Inr{{==}}
    case 1n+a1 0n:
      Inl{{==}}
    case 1n+a1 1n+b1:
      max_or_succ(a1, b1, max_or(a1, b1))

def upper_step(+a: Nat, +h: Nat, +t: List<&2, Nat>, +r: Nat, ih: Laws.Spec.All(r, Nat.max(a, h) <> t)) -> Laws.Spec.All(r, a <> h <> t):
  (+p, q) = ih
  (LE_trans(a, Nat.max(a, h), r, max_l(a, h), p), (LE_trans(h, Nat.max(a, h), r, max_r(a, h), p), q))

def go_upper(+xs: List<&2, Nat>, +acc: Nat) -> Laws.Spec.All(M.max.go(xs, acc), acc <> xs):
  match xs:
    case Nil{}:
      (LE_refl(acc), Unit{})
    case Con{h, t}:
      upper_step(acc, h, t, M.max.go(t, Nat.max(acc, h)), go_upper(t, Nat.max(acc, h)))

def Laws.max_upper(x, xs):
  go_upper(xs, x)

def elem_step(+r: Nat, +m: Nat, +a: Nat, +h: Nat, +t: List<&2, Nat>, o: Or({m == a : Nat}, {m == h : Nat}), e: Laws.Spec.Elem(r, m <> t)) -> Laws.Spec.Elem(r, a <> h <> t):
  match o e:
    case Inl{ma} Inl{rm}:
      Inl{Equal.trans(Nat, r, m, a, rm, ma)}
    case Inr{mh} Inl{rm}:
      Inr{Inl{Equal.trans(Nat, r, m, h, rm, mh)}}
    case _ Inr{et}:
      Inr{Inr{et}}

def go_elem(+xs: List<&2, Nat>, +acc: Nat) -> Laws.Spec.Elem(M.max.go(xs, acc), acc <> xs):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{h, t}:
      elem_step(M.max.go(t, Nat.max(acc, h)), Nat.max(acc, h), acc, h, t, max_or(acc, h), go_elem(t, Nat.max(acc, h)))

def Laws.max_elem(x, xs):
  go_elem(xs, x)
