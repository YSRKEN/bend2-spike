import Base
import ./LAWS.bend as Laws
import ./main.bend as M

def pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def Disc(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Empty

# 0 /= 1+q
def zero_ne_succ(+q: Nat, e: {0n == 1n+q : Nat}) -> Empty:
  %e : Disc(_)
  Unit{}

def succ_ne_zero(+p: Nat, e: {1n+p == 0n : Nat}) -> Empty:
  zero_ne_succ(p, Equal.sym(Nat, 1n+p, 0n, e))

def succ_inj(+p: Nat, +q: Nat, e: {1n+p == 1n+q : Nat}) -> {p == q : Nat}:
  Equal.cong(Nat, Nat, pred, 1n+p, 1n+q, e)

# eq の結果 b に応じた証拠
def EqR(b: Bool, +x: Nat, +y: Nat) -> Type:
  match b:
    case True{}:
      {x == y : Nat}
    case False{}:
      {x != y : Nat}

def succ_ok(b: Bool, +p: Nat, +q: Nat, h: EqR(b, p, q)) -> EqR(b, 1n+p, 1n+q):
  match b:
    case True{}:
      %h : {1n+p == 1n+_ : Nat}
      {==}
    case False{}:
      e => h(succ_inj(p, q, e))

def eq_ok(+x: Nat, +y: Nat) -> EqR(M.eq(x, y), x, y):
  match x y:
    case 0n 0n:
      {==}
    case 0n 1n+q:
      e => zero_ne_succ(q, e)
    case 1n+p 0n:
      e => succ_ne_zero(p, e)
    case 1n+p 1n+q:
      succ_ok(M.eq(p, q), p, q, eq_ok(p, q))

def diff_cong(+x: Nat, +y: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, e: {x == y : Nat}, d: Laws.Spec.Diff(y, t)) -> Laws.Spec.Diff(x, t):
  %Equal.sym(Nat, x, y, e) : Laws.Spec.Diff(_, t)
  d

def pushgo_runs(b: Bool, +x: Nat, +y: Nat, m: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, h: EqR(b, x, y), r: Laws.Spec.Runs((y, m) <> t)) -> Laws.Spec.Runs(M.pushgo(x, y, m, t, b)):
  match b:
    case True{}:
      (pm, dr) = r
      (d, rt) = dr
      (Unit{}, (diff_cong(x, y, t, h, d), rt))
    case False{}:
      (Unit{}, (h, r))

def push_runs(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, r: Laws.Spec.Runs(ps)) -> Laws.Spec.Runs(M.push(x, ps)):
  match ps:
    case Nil{}:
      (Unit{}, (Unit{}, Unit{}))
    case Con{q, t}:
      (+y, m) = q
      pushgo_runs(M.eq(x, y), x, y, m, t, eq_ok(x, y), r)

def Laws.rle_canonical(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      push_runs(h, M.encode(t), Laws.rle_canonical(t))

def pushgo_decode(b: Bool, +x: Nat, +y: Nat, m: Nat, t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, h: EqR(b, x, y)) -> {Laws.Spec.decode(M.pushgo(x, y, m, t, b)) == x <> Laws.Spec.decode((y, m) <> t) : List<&2, Nat>}:
  match b:
    case True{}:
      %h : {x <> Laws.Spec.rep(m, x, Laws.Spec.decode(t)) == x <> Laws.Spec.rep(m, _, Laws.Spec.decode(t)) : List<&2, Nat>}
      {==}
    case False{}:
      {==}

def push_decode(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> {Laws.Spec.decode(M.push(x, ps)) == x <> Laws.Spec.decode(ps) : List<&2, Nat>}:
  match ps:
    case Nil{}:
      {==}
    case Con{q, t}:
      (+y, m) = q
      pushgo_decode(M.eq(x, y), x, y, m, t, eq_ok(x, y))

def Laws.rle_roundtrip(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Laws.rle_roundtrip(t) : {Laws.Spec.decode(M.push(h, M.encode(t))) == h <> _ : List<&2, Nat>}
      push_decode(h, M.encode(t))
