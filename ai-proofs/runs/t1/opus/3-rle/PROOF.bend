# 題 3 の証明
import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# True と False の食い違いから Empty を出すための動機
def P.dT(b: Bool) -> Type:
  match b:
    case False{}:
      Empty
    case True{}:
      Unit

def P.dF(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def P.dZ(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Empty

def P.dS(n: Nat) -> Type:
  match n:
    case 0n:
      Empty
    case 1n+p:
      Unit

def P.pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def P.tf(e: {True{} == False{} : Bool}) -> Empty:
  %e : P.dT(_)
  Unit{}

def P.ft(e: {False{} == True{} : Bool}) -> Empty:
  %e : P.dF(_)
  Unit{}

# M.eq が True なら等しい
def P.eq_sound(a: Nat, b: Nat) -> {M.eq(a, b) == True{} : Bool} -> {a == b : Nat}:
  match a b:
    case 0n 0n:
      e => {==}
    case 0n 1n+q:
      e => Empty.absurd({0n == 1n+q : Nat}, P.ft(e))
    case 1n+p 0n:
      e => Empty.absurd({1n+p == 0n : Nat}, P.ft(e))
    case 1n+p 1n+q:
      e =>
        h = P.eq_sound(p, q)(e)
        %h : {1n+p == 1n+_ : Nat}
        {==}

# M.eq が False なら異なる
def P.eq_false(a: Nat, b: Nat) -> {M.eq(a, b) == False{} : Bool} -> {a != b : Nat}:
  match a b:
    case 0n 0n:
      e => d => P.tf(e)
    case 0n 1n+q:
      e => d =>
        %d : P.dZ(_)
        Unit{}
    case 1n+p 0n:
      e => d =>
        %d : P.dS(_)
        Unit{}
    case 1n+p 1n+q:
      e => d =>
        P.eq_false(p, q)(e)(Equal.cong(Nat, Nat, P.pred, 1n+p, 1n+q, d))

# pushc は h を一つ前に足したものに展開される
def P.pushc_rt(
  b: Bool, +h: Nat, +y: Nat, +m: Nat, +t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>
) -> {M.eq(h, y) == b : Bool} ->
  {Laws.Spec.decode(M.pushc(b, h, y, m, t)) == h <> Laws.Spec.rep(m, y, Laws.Spec.decode(t)) : List<&2, Nat>}:
  match b:
    case True{}:
      e =>
        q = Equal.sym(Nat, h, y, P.eq_sound(h, y)(e))
        %q : {y <> Laws.Spec.rep(m, y, Laws.Spec.decode(t)) == _ <> Laws.Spec.rep(m, y, Laws.Spec.decode(t)) : List<&2, Nat>}
        {==}
    case False{}:
      e => {==}

def P.push_rt(+h: Nat, +ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) ->
  {Laws.Spec.decode(M.push(h, ps)) == h <> Laws.Spec.decode(ps) : List<&2, Nat>}:
  match ps:
    case Nil{}:
      {==}
    case Con{p, t}:
      (y, m) = p
      P.pushc_rt(M.eq(h, y), h, y, m, t)({==})

def Laws.rle_roundtrip(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      ih = Laws.rle_roundtrip(t)
      r = P.push_rt(h, M.encode(t))
      %ih : {Laws.Spec.decode(M.push(h, M.encode(t))) == h <> _ : List<&2, Nat>}
      r

# 先頭の組の個数を 1 増やしても正規形のまま
def P.bump(
  +y: Nat, +m: Nat, +t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, r: Laws.Spec.Runs((y, m) <> t)
) -> Laws.Spec.Runs((y, 1n+m) <> t):
  (pm, rest) = r
  (Unit{}, rest)

def P.pushc_runs(
  b: Bool, +h: Nat, +y: Nat, +m: Nat, +t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>
) -> {M.eq(h, y) == b : Bool} ->
  Laws.Spec.Runs((y, m) <> t) ->
  Laws.Spec.Runs(M.pushc(b, h, y, m, t)):
  match b:
    case True{}:
      e => r => P.bump(y, m, t, r)
    case False{}:
      e => r =>
        (Unit{}, (P.eq_false(h, y)(e), r))

def P.push_runs(+h: Nat, +ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) ->
  Laws.Spec.Runs(ps) -> Laws.Spec.Runs(M.push(h, ps)):
  match ps:
    case Nil{}:
      r => (Unit{}, (Unit{}, Unit{}))
    case Con{p, t}:
      (y, m) = p
      r => P.pushc_runs(M.eq(h, y), h, y, m, t)({==})(r)

def Laws.rle_canonical(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      P.push_runs(h, M.encode(t))(Laws.rle_canonical(t))
