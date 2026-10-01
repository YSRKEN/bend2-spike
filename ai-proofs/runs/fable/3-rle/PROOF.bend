# 題 3: 連長圧縮の証明。
import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# ---- Bool / Nat.is_eq についての補題 ----

# True{} なら Empty、False{} なら Unit に送る判別子（True == False の矛盾を引き出す道具）
def Bool.disc(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

# False{} == True{} は矛盾
def false_ne_true(e: {False{} == True{} : Bool}) -> Empty:
  %e : Bool.disc(_)
  Unit{}

# True{} == False{} は矛盾
def true_ne_false(e: {True{} == False{} : Bool}) -> Empty:
  false_ne_true(Equal.sym(Bool, True{}, False{}, e))

# Nat.is_eq(x, y) が True{} なら x == y
def is_eq_true(+x: Nat, +y: Nat, e: {Nat.is_eq(x, y) == True{} : Bool}) -> {x == y : Nat}:
  match x y:
    case 0n 0n:
      {==}
    case 0n 1n+yp:
      Empty.absurd({0n == 1n+yp : Nat}, false_ne_true(e))
    case 1n+xp 0n:
      Empty.absurd({1n+xp == 0n : Nat}, false_ne_true(e))
    case 1n+xp 1n+yp:
      %is_eq_true(xp, yp, e) : {1n+xp == 1n+_ : Nat}
      {==}

# Nat.is_eq(x, x) は True{}
def is_eq_refl(+x: Nat) -> {Nat.is_eq(x, x) == True{} : Bool}:
  match x:
    case 0n:
      {==}
    case 1n+p:
      is_eq_refl(p)

# x == y なら Nat.is_eq(x, y) は True{}
def is_eq_true_of(+x: Nat, +y: Nat, q: {x == y : Nat}) -> {Nat.is_eq(x, y) == True{} : Bool}:
  %q : {Nat.is_eq(x, _) == True{} : Bool}
  is_eq_refl(x)

# Nat.is_eq(x, y) が False{} なら x != y
def is_eq_false(+x: Nat, +y: Nat, e: {Nat.is_eq(x, y) == False{} : Bool}) -> {x != y : Nat}:
  q => true_ne_false(Equal.trans(Bool, True{}, Nat.is_eq(x, y), False{},
    Equal.sym(Bool, Nat.is_eq(x, y), True{}, is_eq_true_of(x, y, q)), e))

# ---- 法則 1: 展開すると元に戻る ----

# push.if の展開（same で場合分け）
def push_if_decode(
  +x: Nat, +y: Nat, +n: Nat, +t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>,
  same: Bool, e: {Nat.is_eq(x, y) == same : Bool}
) -> {Laws.Spec.decode(M.encode.push.if(x, y, n, t, same))
      == x <> Laws.Spec.rep(n, y, Laws.Spec.decode(t)) : List<&2, Nat>}:
  match same:
    case True{}:
      %is_eq_true(x, y, e) : {_ <> Laws.Spec.rep(n, y, Laws.Spec.decode(t))
        == x <> Laws.Spec.rep(n, y, Laws.Spec.decode(t)) : List<&2, Nat>}
      {==}
    case False{}:
      {==}

# push の展開
def push_decode(
  +x: Nat, +ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>
) -> {Laws.Spec.decode(M.encode.push(x, ps)) == x <> Laws.Spec.decode(ps) : List<&2, Nat>}:
  match ps:
    case Nil{}:
      {==}
    case Con{Tuple{+y, +n}, +t}:
      push_if_decode(x, y, n, t, Nat.is_eq(x, y), {==})

def Laws.rle_roundtrip(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{+x, +t}:
      %Laws.rle_roundtrip(t) : {Laws.Spec.decode(M.encode.push(x, M.encode(t))) == x <> _ : List<&2, Nat>}
      push_decode(x, M.encode(t))

# ---- 法則 2: 出力は正規形 ----

# push.if の正規性（same で場合分け）
def push_if_runs(
  +x: Nat, +y: Nat, +n: Nat, +t: List<&2, Sigma<&2, &2, Nat, _ => Nat>>,
  same: Bool, e: {Nat.is_eq(x, y) == same : Bool},
  r: Laws.Spec.Runs((y, n) <> t)
) -> Laws.Spec.Runs(M.encode.push.if(x, y, n, t, same)):
  match same:
    case True{}:
      (pn, dr) = r
      (Unit{}, dr)
    case False{}:
      (Unit{}, (is_eq_false(x, y, e), r))

# push の正規性
def push_runs(
  +x: Nat, +ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, r: Laws.Spec.Runs(ps)
) -> Laws.Spec.Runs(M.encode.push(x, ps)):
  match ps:
    case Nil{}:
      (Unit{}, (Unit{}, Unit{}))
    case Con{Tuple{+y, +n}, +t}:
      push_if_runs(x, y, n, t, Nat.is_eq(x, y), {==}, r)

def Laws.rle_canonical(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+x, +t}:
      push_runs(x, M.encode(t), Laws.rle_canonical(t))
