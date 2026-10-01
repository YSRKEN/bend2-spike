# 題 2 の証明。
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

# a <= b かつ b <= c なら a <= c
def le_trans(a: Nat, b: Nat, c: Nat, p: Laws.Spec.LE(a, b), q: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+ap 0n _:
      match p:
    case 1n+ap 1n+bp 0n:
      match q:
    case 1n+ap 1n+bp 1n+cp:
      le_trans(ap, bp, cp, p, q)

# a <= max(a, b)
def le_max_l(+a: Nat, +b: Nat) -> Laws.Spec.LE(a, Nat.max(a, b)):
  match a b:
    case 0n _:
      Unit{}
    case 1n+ap 0n:
      le_refl(ap)
    case 1n+ap 1n+bp:
      le_max_l(ap, bp)

# b <= max(a, b)
def le_max_r(+a: Nat, +b: Nat) -> Laws.Spec.LE(b, Nat.max(a, b)):
  match a b:
    case 0n _:
      le_refl(b)
    case 1n+ap 0n:
      Unit{}
    case 1n+ap 1n+bp:
      le_max_r(ap, bp)

# 1 を足しても等式の選言は保たれる
def or_succ(-a: Nat, -b: Nat, -c: Nat, o: Or({a == b : Nat}, {a == c : Nat})) -> Or({1n+a == 1n+b : Nat}, {1n+a == 1n+c : Nat}):
  match o:
    case Inl{e}:
      %e : Or({1n+a == 1n+_ : Nat}, {1n+a == 1n+c : Nat})
      Inl{{==}}
    case Inr{e}:
      %e : Or({1n+a == 1n+b : Nat}, {1n+a == 1n+_ : Nat})
      Inr{{==}}

# max(a, b) は a か b のどちらか
def max_cases(+a: Nat, +b: Nat) -> Or({Nat.max(a, b) == a : Nat}, {Nat.max(a, b) == b : Nat}):
  match a b:
    case 0n _:
      Inr{{==}}
    case 1n+ap 0n:
      Inl{{==}}
    case 1n+ap 1n+bp:
      or_succ(Nat.max(ap, bp), ap, bp, max_cases(ap, bp))

# 畳み込みの結果は、出発点の acc 以上
def ge_acc(+xs: List<&2, Nat>, +acc: Nat) -> Laws.Spec.LE(acc, M.max.go(xs, acc)):
  match xs:
    case Nil{}:
      le_refl(acc)
    case Con{h, t}:
      le_trans(acc, Nat.max(acc, h), M.max.go(t, Nat.max(acc, h)), le_max_l(acc, h), ge_acc(t, Nat.max(acc, h)))

# 畳み込みの結果は、xs のどの要素以上でもある
def all_acc(+xs: List<&2, Nat>, +acc: Nat) -> Laws.Spec.All(M.max.go(xs, acc), xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      (le_trans(h, Nat.max(acc, h), M.max.go(t, Nat.max(acc, h)), le_max_r(acc, h), ge_acc(t, Nat.max(acc, h))), all_acc(t, Nat.max(acc, h)))

# 帰納法の 1 段: m が max(acc, h) か t の要素なら、m は acc か h か t の要素
def elem_step(-m: Nat, -acc: Nat, -h: Nat, -t: List<&2, Nat>, ih: Or({m == Nat.max(acc, h) : Nat}, Laws.Spec.Elem(m, t)), mc: Or({Nat.max(acc, h) == acc : Nat}, {Nat.max(acc, h) == h : Nat})) -> Or({m == acc : Nat}, Or({m == h : Nat}, Laws.Spec.Elem(m, t))):
  match ih:
    case Inl{e}:
      match mc:
        case Inl{f}:
          Inl{Equal.trans(Nat, m, Nat.max(acc, h), acc, e, f)}
        case Inr{f}:
          Inr{Inl{Equal.trans(Nat, m, Nat.max(acc, h), h, e, f)}}
    case Inr{e}:
      Inr{Inr{e}}

# 畳み込みの結果は、acc そのものか xs の要素
def elem_go(+xs: List<&2, Nat>, +acc: Nat) -> Or({M.max.go(xs, acc) == acc : Nat}, Laws.Spec.Elem(M.max.go(xs, acc), xs)):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{h, t}:
      elem_step(M.max.go(t, Nat.max(acc, h)), acc, h, t, elem_go(t, Nat.max(acc, h)), max_cases(acc, h))

def Laws.max_upper(x, xs):
  (ge_acc(xs, x), all_acc(xs, x))

def Laws.max_elem(x, xs):
  elem_go(xs, x)
