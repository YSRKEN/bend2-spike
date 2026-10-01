# 題 2 の証明。max.go を累積値について一般化した補題を立て、法則はその特殊化で閉じる。
import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# Spec.LE の反射律
def Lemma.le_refl(a: Nat) -> Laws.Spec.LE(a, a):
  match a:
    case 0n:
      Unit{}
    case 1n+p:
      Lemma.le_refl(p)

# Spec.LE の推移律
def Lemma.le_trans(a: Nat, b: Nat, c: Nat, ab: Laws.Spec.LE(a, b), bc: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+a1 0n _:
      match ab:
    case 1n+a1 1n+b1 0n:
      match bc:
    case 1n+a1 1n+b1 1n+c1:
      Lemma.le_trans(a1, b1, c1, ab, bc)

# a <= Nat.max(a, b)
def Lemma.max_le_l(+a: Nat, +b: Nat) -> Laws.Spec.LE(a, Nat.max(a, b)):
  match a b:
    case 0n _:
      Unit{}
    case 1n+ap 0n:
      Lemma.le_refl(ap)
    case 1n+ap 1n+bp:
      Lemma.max_le_l(ap, bp)

# b <= Nat.max(a, b)
def Lemma.max_le_r(+a: Nat, +b: Nat) -> Laws.Spec.LE(b, Nat.max(a, b)):
  match a b:
    case 0n _:
      Lemma.le_refl(b)
    case 1n+ap 0n:
      Unit{}
    case 1n+ap 1n+bp:
      Lemma.max_le_r(ap, bp)

# Nat.max(a, b) は a か b のどちらか（後者の段を 1n+ で持ち上げる）
def Lemma.max_pick.step(-ap: Nat, -bp: Nat, r: Or({Nat.max(ap, bp) == ap : Nat}, {Nat.max(ap, bp) == bp : Nat})) -> Or({1n+Nat.max(ap, bp) == 1n+ap : Nat}, {1n+Nat.max(ap, bp) == 1n+bp : Nat}):
  match r:
    case Inl{e}:
      %e : Or({1n+Nat.max(ap, bp) == 1n+_ : Nat}, {1n+Nat.max(ap, bp) == 1n+bp : Nat})
      Inl{{==}}
    case Inr{e}:
      %e : Or({1n+Nat.max(ap, bp) == 1n+ap : Nat}, {1n+Nat.max(ap, bp) == 1n+_ : Nat})
      Inr{{==}}

def Lemma.max_pick(+a: Nat, +b: Nat) -> Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat}):
  match a b:
    case 0n _:
      Inr{{==}}
    case 1n+ap 0n:
      Inl{{==}}
    case 1n+ap 1n+bp:
      Lemma.max_pick.step(ap, bp, Lemma.max_pick(ap, bp))

# acc <= max.go(xs, acc)
def Lemma.go_ge(+xs: List<&2, Nat>, +acc: Nat) -> Laws.Spec.LE(acc, M.max.go(xs, acc)):
  match xs:
    case Nil{}:
      Lemma.le_refl(acc)
    case Con{+h, t}:
      Lemma.le_trans(acc, Nat.max(acc, h), M.max.go(t, Nat.max(acc, h)), Lemma.max_le_l(acc, h), Lemma.go_ge(t, Nat.max(acc, h)))

# xs のどの要素も max.go(xs, acc) 以下
def Lemma.go_all(+xs: List<&2, Nat>, +acc: Nat) -> Laws.Spec.All(M.max.go(xs, acc), xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+h, +t}:
      (Lemma.le_trans(h, Nat.max(acc, h), M.max.go(t, Nat.max(acc, h)), Lemma.max_le_r(acc, h), Lemma.go_ge(t, Nat.max(acc, h))), Lemma.go_all(t, Nat.max(acc, h)))

# max.go(xs, acc) は acc か xs の要素のどれか（Con の段の組み立て）
def Lemma.go_elem.step(-t: List<&2, Nat>, -acc: Nat, -h: Nat, r: Or({M.max.go(t, Nat.max(acc, h)) == Nat.max(acc, h) : Nat}, Laws.Spec.Elem(M.max.go(t, Nat.max(acc, h)), t)), p: Or({Nat.max(acc, h) == acc : Nat}, {Nat.max(acc, h) == h : Nat})) -> Or({M.max.go(t, Nat.max(acc, h)) == acc : Nat}, Or({M.max.go(t, Nat.max(acc, h)) == h : Nat}, Laws.Spec.Elem(M.max.go(t, Nat.max(acc, h)), t))):
  match r p:
    case Inl{e} Inl{q}:
      Inl{Equal.trans(Nat, M.max.go(t, Nat.max(acc, h)), Nat.max(acc, h), acc, e, q)}
    case Inl{e} Inr{q}:
      Inr{Inl{Equal.trans(Nat, M.max.go(t, Nat.max(acc, h)), Nat.max(acc, h), h, e, q)}}
    case Inr{e} _:
      Inr{Inr{e}}

def Lemma.go_elem(+xs: List<&2, Nat>, +acc: Nat) -> Or({M.max.go(xs, acc) == acc : Nat}, Laws.Spec.Elem(M.max.go(xs, acc), xs)):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{+h, +t}:
      Lemma.go_elem.step(t, acc, h, Lemma.go_elem(t, Nat.max(acc, h)), Lemma.max_pick(acc, h))

# 法則: 結果は、どの要素以上でもある
def Laws.max_upper(x, xs):
  (Lemma.go_ge(xs, x), Lemma.go_all(xs, x))

# 法則: 結果は、リストの要素の一つである
def Laws.max_elem(x, xs):
  Lemma.go_elem(xs, x)
