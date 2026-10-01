import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# 判別子: 0n と 1n+p、False と True を型で見分ける
def NDisc(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Empty

def BDisc(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def Pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def zero_ne_succ(-p: Nat, h: {0n == 1n+p : Nat}) -> Empty:
  %h : NDisc(_)
  Unit{}

def false_ne_true(h: {False{} == True{} : Bool}) -> Empty:
  %h : BDisc(_)
  Unit{}

# Nat.is_eq が True なら等しい
def eq_true(a: Nat, b: Nat, e: {Nat.is_eq(a, b) == True{} : Bool}) -> {a == b : Nat}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+bp:
      Empty.absurd({0n == 1n+bp : Nat}, false_ne_true(e))
    case 1n+ap 0n:
      Empty.absurd({1n+ap == 0n : Nat}, false_ne_true(e))
    case 1n+ap 1n+bp:
      %eq_true(ap, bp, e) : {1n+ap == 1n+_ : Nat}
      {==}

# Nat.is_eq が False なら異なる
def eq_false(a: Nat, b: Nat, e: {Nat.is_eq(a, b) == False{} : Bool}) -> {a != b : Nat}:
  match a b:
    case 0n 0n:
      Empty.absurd({0n != 0n : Nat}, false_ne_true(Equal.sym(Bool, True{}, False{}, e)))
    case 0n 1n+bp:
      h => zero_ne_succ(bp, h)
    case 1n+ap 0n:
      h => zero_ne_succ(ap, Equal.sym(Nat, 1n+ap, 0n, h))
    case 1n+ap 1n+bp:
      ne = eq_false(ap, bp, e)
      h => ne(Equal.cong(Nat, Nat, Pred, 1n+ap, 1n+bp, h))

# sel を展開すると、x を 1 個前に足したものになる
def sel_dec(c: Bool, +x: Nat, +y: Nat, n: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, e: {Nat.is_eq(x, y) == c : Bool}) -> {Laws.Spec.decode(M.sel(c, x, y, n, t)) == x <> Laws.Spec.rep(n, y, Laws.Spec.decode(t)) : List<&2, Nat>}:
  match c:
    case True{}:
      %eq_true(x, y, e) : {_ <> Laws.Spec.rep(n, y, Laws.Spec.decode(t)) == x <> Laws.Spec.rep(n, y, Laws.Spec.decode(t)) : List<&2, Nat>}
      {==}
    case False{}:
      {==}

def push_dec(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> {Laws.Spec.decode(M.push(x, ps)) == x <> Laws.Spec.decode(ps) : List<&2, Nat>}:
  match ps:
    case Nil{}:
      {==}
    case Con{p, t}:
      (+y, n) = p
      sel_dec(Nat.is_eq(x, y), x, y, n, t, {==})

def Laws.rle_roundtrip(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{+h, t}:
      %Laws.rle_roundtrip(t) : {Laws.Spec.decode(M.push(h, M.encode(t))) == h <> _ : List<&2, Nat>}
      push_dec(h, M.encode(t))

# sel の結果は、元が正規形なら正規形
def sel_runs(c: Bool, +x: Nat, +y: Nat, n: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, e: {Nat.is_eq(x, y) == c : Bool}, r: Laws.Spec.Runs((y, n) <> t)) -> Laws.Spec.Runs(M.sel(c, x, y, n, t)):
  match c:
    case True{}:
      (pn, rest) = r
      (Unit{}, rest)
    case False{}:
      (Unit{}, (eq_false(x, y, e), r))

def push_runs(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, r: Laws.Spec.Runs(ps)) -> Laws.Spec.Runs(M.push(x, ps)):
  match ps:
    case Nil{}:
      (Unit{}, (Unit{}, Unit{}))
    case Con{p, t}:
      (+y, n) = p
      sel_runs(Nat.is_eq(x, y), x, y, n, t, {==}, r)

def Laws.rle_canonical(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+h, t}:
      push_runs(h, M.encode(t), Laws.rle_canonical(t))
