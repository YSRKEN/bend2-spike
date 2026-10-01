# 題 3: 連長圧縮の証明
import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# --- 矛盾を導く道具 ---

# False{} == True{} から Empty
def Bool.disc(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def Bool.false_true(e: {False{} == True{} : Bool}) -> Empty:
  %e : Bool.disc(_)
  Unit{}

def Bool.true_false(e: {True{} == False{} : Bool}) -> Empty:
  Bool.false_true(Equal.sym(Bool, True{}, False{}, e))

# 0n == 1n+p から Empty
def Nat.disc(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Empty

def Nat.zero_succ(-p: Nat, e: {0n == 1n+p : Nat}) -> Empty:
  %e : Nat.disc(_)
  Unit{}

def Nat.succ_zero(-p: Nat, e: {1n+p == 0n : Nat}) -> Empty:
  Nat.zero_succ(p, Equal.sym(Nat, 1n+p, 0n, e))

def Nat.pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

# --- Nat.is_eq と等式の対応 ---

def Nat.is_eq_true(+x: Nat, +y: Nat, e: {Nat.is_eq(x, y) == True{} : Bool}) -> {x == y : Nat}:
  match x y:
    case 0n 0n:
      {==}
    case 0n 1n+b:
      Empty.absurd({0n == 1n+b : Nat}, Bool.false_true(e))
    case 1n+a 0n:
      Empty.absurd({1n+a == 0n : Nat}, Bool.false_true(e))
    case 1n+a 1n+b:
      %Nat.is_eq_true(a, b, e) : {1n+a == 1n+_ : Nat}
      {==}

def Nat.is_eq_false(+x: Nat, +y: Nat, e: {Nat.is_eq(x, y) == False{} : Bool}) -> {x != y : Nat}:
  match x y:
    case 0n 0n:
      eq => Bool.true_false(e)
    case 0n 1n+b:
      eq => Nat.zero_succ(b, eq)
    case 1n+a 0n:
      eq => Nat.succ_zero(a, eq)
    case 1n+a 1n+b:
      eq => Nat.is_eq_false(a, b, e)(Equal.cong(Nat, Nat, Nat.pred, 1n+a, 1n+b, eq))

# --- 法則 1: 展開すると元に戻る ---

def put_roundtrip(+x: Nat, +y: Nat, m: Nat, t: List<&2, M.Run()>, b: Bool, e: {Nat.is_eq(x, y) == b : Bool}) -> {x <> Laws.Spec.decode((y, m) <> t) == Laws.Spec.decode(M.encode.put(x, y, m, t, b)) : List<&2, Nat>}:
  match b:
    case True{}:
      %Nat.is_eq_true(x, y, e) : {x <> Laws.Spec.rep(m, y, Laws.Spec.decode(t)) == _ <> Laws.Spec.rep(m, y, Laws.Spec.decode(t)) : List<&2, Nat>}
      {==}
    case False{}:
      {==}

def push_roundtrip(+x: Nat, ps: List<&2, M.Run()>) -> {x <> Laws.Spec.decode(ps) == Laws.Spec.decode(M.encode.push(x, ps)) : List<&2, Nat>}:
  match ps:
    case Nil{}:
      {==}
    case Con{q, t}:
      (+y, m) = q
      put_roundtrip(x, y, m, t, Nat.is_eq(x, y), {==})

def Laws.rle_roundtrip(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{x, t}:
      %push_roundtrip(x, M.encode(t)) : {_ == x <> t : List<&2, Nat>}
      %Laws.rle_roundtrip(t) : {x <> Laws.Spec.decode(M.encode(t)) == x <> _ : List<&2, Nat>}
      {==}

# --- 法則 2: 出力は正規形 ---

def put_runs(+x: Nat, +y: Nat, m: Nat, t: List<&2, M.Run()>, b: Bool, e: {Nat.is_eq(x, y) == b : Bool}, r: Laws.Spec.Runs((y, m) <> t)) -> Laws.Spec.Runs(M.encode.put(x, y, m, t, b)):
  match b:
    case True{}:
      (p, rest) = r
      (Unit{}, rest)
    case False{}:
      (Unit{}, (Nat.is_eq_false(x, y, e), r))

def push_runs(+x: Nat, ps: List<&2, M.Run()>, r: Laws.Spec.Runs(ps)) -> Laws.Spec.Runs(M.encode.push(x, ps)):
  match ps:
    case Nil{}:
      (Unit{}, (Unit{}, Unit{}))
    case Con{q, t}:
      (+y, m) = q
      put_runs(x, y, m, t, Nat.is_eq(x, y), {==}, r)

def Laws.rle_canonical(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{x, t}:
      push_runs(x, M.encode(t), Laws.rle_canonical(t))
