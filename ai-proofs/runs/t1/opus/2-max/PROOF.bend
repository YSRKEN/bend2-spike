import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# a <= a
def le_refl(+a: Nat) -> Laws.Spec.LE(a, a):
  match a:
    case 0n:
      Unit{}
    case 1n+p:
      le_refl(p)

# a <= max(a, b)
def le_max_l(+a: Nat, +b: Nat) -> Laws.Spec.LE(a, Nat.max(a, b)):
  match a b:
    case 0n 0n:
      Unit{}
    case 0n 1n+bp:
      Unit{}
    case 1n+ap 0n:
      le_refl(ap)
    case 1n+ap 1n+bp:
      le_max_l(ap, bp)

# b <= max(a, b)
def le_max_r(+a: Nat, +b: Nat) -> Laws.Spec.LE(b, Nat.max(a, b)):
  match a b:
    case 0n 0n:
      Unit{}
    case 0n 1n+bp:
      le_refl(bp)
    case 1n+ap 0n:
      Unit{}
    case 1n+ap 1n+bp:
      le_max_r(ap, bp)

# a <= b, b <= c なら a <= c
def le_trans(+a: Nat, +b: Nat, +c: Nat, p: Laws.Spec.LE(a, b), q: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ 0n:
      Unit{}
    case 0n _ 1n+cp:
      Unit{}
    case 1n+ap 0n _:
      match p:
    case 1n+ap 1n+bp 0n:
      match q:
    case 1n+ap 1n+bp 1n+cp:
      le_trans(ap, bp, cp, p, q)

# ys の全要素が r 以下で r <= s なら、全要素が s 以下
def all_mono(+ys: List<&2, Nat>, +r: Nat, +s: Nat, p: Laws.Spec.All(r, ys), +q: Laws.Spec.LE(r, s)) -> Laws.Spec.All(s, ys):
  match ys:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      (ph, pt) = p
      (le_trans(h, r, s, ph, q), all_mono(t, r, s, pt, q))

# 法則 max_upper の本体
def go_upper(+xs: List<&2, Nat>, +x: Nat) -> Laws.Spec.All(M.max.go(xs, x), x <> xs):
  match xs:
    case Nil{}:
      (le_refl(x), Unit{})
    case Con{h, t}:
      ih = go_upper(t, h)
      +r = M.max.go(t, h)
      (le_max_l(x, r), all_mono(h <> t, r, Nat.max(x, r), ih, le_max_r(x, r)))

def Laws.max_upper(x, xs):
  go_upper(xs, x)

# 1+a == 1+b
def eq_succ(-a: Nat, -b: Nat, e: {a == b : Nat}) -> {1n+a == 1n+b : Nat}:
  %e : {1n+a == 1n+_ : Nat}
  {==}

def or_succ(-a: Nat, -b: Nat, -c: Nat, e: Or({c == a : Nat}, {c == b : Nat})) -> Or({1n+c == 1n+a : Nat}, {1n+c == 1n+b : Nat}):
  match e:
    case Inl{v}:
      Inl{eq_succ(c, a, v)}
    case Inr{v}:
      Inr{eq_succ(c, b, v)}

# max(a, b) は a か b のどちらか
def max_eq(+a: Nat, +b: Nat) -> Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat}):
  match a b:
    case 0n _:
      Inr{{==}}
    case 1n+ap 0n:
      Inl{{==}}
    case 1n+ap 1n+bp:
      or_succ(ap, bp, Nat.max(ap, bp), max_eq(ap, bp))

def elem_inr(-x: Nat, -r: Nat, -ys: List<&2, Nat>, ih: Laws.Spec.Elem(r, ys), e: {Nat.max(x, r) == r : Nat}) -> Laws.Spec.Elem(Nat.max(x, r), ys):
  %Equal.sym(Nat, Nat.max(x, r), r, e) : Laws.Spec.Elem(_, ys)
  ih

def elem_step(-x: Nat, -r: Nat, -ys: List<&2, Nat>, ih: Laws.Spec.Elem(r, ys), c: Or({Nat.max(x, r) == x : Nat}, {Nat.max(x, r) == r : Nat})) -> Or({Nat.max(x, r) == x : Nat}, Laws.Spec.Elem(Nat.max(x, r), ys)):
  match c:
    case Inl{e}:
      Inl{e}
    case Inr{e}:
      Inr{elem_inr(x, r, ys, ih, e)}

# 法則 max_elem の本体
def go_elem(+xs: List<&2, Nat>, +x: Nat) -> Laws.Spec.Elem(M.max.go(xs, x), x <> xs):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{h, t}:
      ih = go_elem(t, h)
      +r = M.max.go(t, h)
      elem_step(x, r, h <> t, ih, max_eq(x, r))

def Laws.max_elem(x, xs):
  go_elem(xs, x)
