import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# --- 自然数の補題 ---

def disc(n: Nat) -> Type:
  match n:
    case 0n:
      Unit
    case 1n+p:
      Empty

def pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

# cmp の結果 c に応じた事実
def Rel(c: Cmp, +x: Nat, +y: Nat) -> Type:
  match c:
    case EQ{}:
      {x == y : Nat}
    case LT{}:
      {x != y : Nat}
    case GT{}:
      {x != y : Nat}

def zero_ne_succ(q: Nat) -> {0n != 1n+q : Nat}:
  e => (
    %e : disc(_)
    Unit{}
  )

def succ_ne_zero(p: Nat) -> {1n+p != 0n : Nat}:
  e => zero_ne_succ(p)(Equal.sym(Nat, 1n+p, 0n, e))

def succ_inj(p: Nat, q: Nat, e: {1n+p == 1n+q : Nat}) -> {p == q : Nat}:
  Equal.cong(Nat, Nat, pred, 1n+p, 1n+q, e)

def succ_rel(c: Cmp, +p: Nat, +q: Nat, h: Rel(c, p, q)) -> Rel(c, 1n+p, 1n+q):
  match c:
    case EQ{}:
      %h : {1n+p == 1n+_ : Nat}
      {==}
    case LT{}:
      e => h(succ_inj(p, q, e))
    case GT{}:
      e => h(succ_inj(p, q, e))

def cmp_ok(+x: Nat, +y: Nat) -> Rel(Nat.cmp(x, y), x, y):
  match x y:
    case 0n 0n:
      {==}
    case 0n 1n+q:
      zero_ne_succ(q)
    case 1n+p 0n:
      succ_ne_zero(p)
    case 1n+p 1n+q:
      succ_rel(Nat.cmp(p, q), p, q, cmp_ok(p, q))

# --- 展開して戻る ---

def push2_rt(+x: Nat, +y: Nat, m: Nat, +r: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, c: Cmp, h: Rel(c, x, y)) -> {Laws.Spec.decode(M.push2(x, y, m, r, c)) == x <> Laws.Spec.decode((y, m) <> r) : List<&2, Nat>}:
  match c:
    case EQ{}:
      %h : {x <> Laws.Spec.rep(m, x, Laws.Spec.decode(r)) == x <> Laws.Spec.rep(m, _, Laws.Spec.decode(r)) : List<&2, Nat>}
      {==}
    case LT{}:
      {==}
    case GT{}:
      {==}

def push_rt(+x: Nat, +rs: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> {Laws.Spec.decode(M.push(x, rs)) == x <> Laws.Spec.decode(rs) : List<&2, Nat>}:
  match rs:
    case Nil{}:
      {==}
    case Con{(+y, m), r}:
      push2_rt(x, y, m, r, Nat.cmp(x, y), cmp_ok(x, y))

def Laws.rle_roundtrip(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{x, t}:
      %Laws.rle_roundtrip(t) : {Laws.Spec.decode(M.push(x, M.encode(t))) == x <> _ : List<&2, Nat>}
      push_rt(x, M.encode(t))

# --- 正規形 ---

def diff_eq(+x: Nat, +y: Nat, +r: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, e: {y == x : Nat}, hd: Laws.Spec.Diff(y, r)) -> Laws.Spec.Diff(x, r):
  match r:
    case Nil{}:
      Unit{}
    case Con{(+z, k), t}:
      %e : {_ != z : Nat}
      hd

def push2_runs(+x: Nat, +y: Nat, m: Nat, +r: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, c: Cmp, h: Rel(c, x, y), hp: Laws.Spec.Pos(m), hd: Laws.Spec.Diff(y, r), hr: Laws.Spec.Runs(r)) -> Laws.Spec.Runs(M.push2(x, y, m, r, c)):
  match c:
    case EQ{}:
      (Unit{}, (diff_eq(x, y, r, Equal.sym(Nat, x, y, h), hd), hr))
    case LT{}:
      (Unit{}, (h, (hp, (hd, hr))))
    case GT{}:
      (Unit{}, (h, (hp, (hd, hr))))

def push_runs(+x: Nat, +rs: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, h: Laws.Spec.Runs(rs)) -> Laws.Spec.Runs(M.push(x, rs)):
  match rs:
    case Nil{}:
      (Unit{}, (Unit{}, Unit{}))
    case Con{(+y, m), r}:
      (hp, (hd, hr)) = h
      push2_runs(x, y, m, r, Nat.cmp(x, y), cmp_ok(x, y), hp, hd, hr)

def Laws.rle_canonical(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{x, t}:
      push_runs(x, M.encode(t), Laws.rle_canonical(t))
