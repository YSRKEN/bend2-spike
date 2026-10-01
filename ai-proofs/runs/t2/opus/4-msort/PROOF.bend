import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# ---- Bool の食い違いを否定するための型 ----

def IsTrue(b: Bool) -> Type:
  match b:
    case True{}:
      Unit
    case False{}:
      Empty

def IsFalse(b: Bool) -> Type:
  match b:
    case True{}:
      Empty
    case False{}:
      Unit

# ---- 比較 ----

# is_le(a, b) が True なら a <= b
def le_true(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == True{} : Bool}) -> Laws.Spec.LE(a, b):
  match a b:
    case 0n _:
      Unit{}
    case 1n+a1 0n:
      %e : IsFalse(_)
      Unit{}
    case 1n+a1 1n+b1:
      le_true(a1, b1, e)

# is_le(a, b) が False なら b <= a
def le_false(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == False{} : Bool}) -> Laws.Spec.LE(b, a):
  match a b:
    case 0n 0n:
      Unit{}
    case 0n 1n+b1:
      %e : IsTrue(_)
      Unit{}
    case 1n+a1 0n:
      Unit{}
    case 1n+a1 1n+b1:
      le_false(a1, b1, e)

# ---- 足し算 ----

def add_zero(+n: Nat) -> {Nat.add(n, 0n) == n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ(+n: Nat, +m: Nat) -> {Nat.add(n, 1n+m) == 1n+Nat.add(n, m) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, m) : {1n+Nat.add(p, 1n+m) == 1n+_ : Nat}
      {==}

def add_comm2(+a: Nat, +b: Nat) -> {Nat.add(b, a) == Nat.add(a, b) : Nat}:
  match a:
    case 0n:
      add_zero(b)
    case 1n+p:
      %add_comm2(p, b) : {Nat.add(b, 1n+p) == 1n+_ : Nat}
      add_succ(b, p)

def bump_add_l1(b: Bool, +n: Nat, +m: Nat) -> {Nat.add(Laws.Spec.bump(b, n), m) == Laws.Spec.bump(b, Nat.add(n, m)) : Nat}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def bump_add_l2(b: Bool, +n: Nat, +m: Nat) -> {Laws.Spec.bump(b, Nat.add(n, m)) == Nat.add(Laws.Spec.bump(b, n), m) : Nat}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def add_bump_r(+n: Nat, b: Bool, +m: Nat) -> {Nat.add(n, Laws.Spec.bump(b, m)) == Laws.Spec.bump(b, Nat.add(n, m)) : Nat}:
  match b:
    case True{}:
      add_succ(n, m)
    case False{}:
      {==}

# ---- merge ----

def merge_sorted(
  +xs: List<&2, Nat>, +ys: List<&2, Nat>, c: Bool, +lo: Nat,
  e: {c == M.le_heads(xs, ys) : Bool},
  sx: Laws.Spec.Sorted.from(lo, xs), sy: Laws.Spec.Sorted.from(lo, ys)
) -> Laws.Spec.Sorted.from(lo, M.merge.go(xs, ys, c)):
  match xs ys c:
    case Nil{} _ _:
      sy
    case Con{x, xt} Nil{} _:
      sx
    case Con{+x, +xt} Con{+y, +yt} True{}:
      (lx, sxt) = sx
      (ly, syt) = sy
      le = le_true(x, y, Equal.sym(Bool, True{}, Nat.is_le(x, y), e))
      (lx, merge_sorted(xt, ys, M.le_heads(xt, ys), x, {==}, sxt, (le, syt)))
    case Con{+x, +xt} Con{+y, +yt} False{}:
      (lx, sxt) = sx
      (ly, syt) = sy
      le = le_false(x, y, Equal.sym(Bool, False{}, Nat.is_le(x, y), e))
      (ly, merge_sorted(xs, yt, M.le_heads(xs, yt), y, {==}, (le, sxt), syt))

def merge_count(
  +xs: List<&2, Nat>, +ys: List<&2, Nat>, c: Bool, +k: Nat
) -> {Nat.add(Laws.Spec.count(k, xs), Laws.Spec.count(k, ys)) == Laws.Spec.count(k, M.merge.go(xs, ys, c)) : Nat}:
  match xs ys c:
    case Nil{} _ _:
      {==}
    case Con{x, xt} Nil{} _:
      add_zero(Laws.Spec.count(k, xs))
    case Con{+x, +xt} Con{+y, +yt} True{}:
      %merge_count(xt, ys, M.le_heads(xt, ys), k) : {Nat.add(Laws.Spec.bump(Nat.is_eq(k, x), Laws.Spec.count(k, xt)), Laws.Spec.count(k, ys)) == Laws.Spec.bump(Nat.is_eq(k, x), _) : Nat}
      bump_add_l1(Nat.is_eq(k, x), Laws.Spec.count(k, xt), Laws.Spec.count(k, ys))
    case Con{+x, +xt} Con{+y, +yt} False{}:
      %merge_count(xs, yt, M.le_heads(xs, yt), k) : {Nat.add(Laws.Spec.count(k, xs), Laws.Spec.bump(Nat.is_eq(k, y), Laws.Spec.count(k, yt))) == Laws.Spec.bump(Nat.is_eq(k, y), _) : Nat}
      add_bump_r(Laws.Spec.count(k, xs), Nat.is_eq(k, y), Laws.Spec.count(k, yt))

# ---- 予備の挿入整列 ----

def isort_sorted(+xs: List<&2, Nat>) -> Laws.Spec.Sorted.from(0n, M.isort(xs)):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+h, +t}:
      merge_sorted([h], M.isort(t), M.le_heads([h], M.isort(t)), 0n, {==}, (Unit{}, Unit{}), isort_sorted(t))

def isort_count(+k: Nat, +xs: List<&2, Nat>) -> {Laws.Spec.count(k, xs) == Laws.Spec.count(k, M.isort(xs)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      %merge_count([h], M.isort(t), M.le_heads([h], M.isort(t)), k) : {Laws.Spec.bump(Nat.is_eq(k, h), Laws.Spec.count(k, t)) == _ : Nat}
      %isort_count(k, t) : {Laws.Spec.bump(Nat.is_eq(k, h), Laws.Spec.count(k, t)) == Nat.add(Laws.Spec.bump(Nat.is_eq(k, h), 0n), _) : Nat}
      bump_add_l2(Nat.is_eq(k, h), 0n, Laws.Spec.count(k, t))

# ---- 振り分け ----

def alt_count(+k: Nat, +xs: List<&2, Nat>) -> {Laws.Spec.count(k, xs) == Nat.add(Laws.Spec.count(k, M.alt(xs, True{})), Laws.Spec.count(k, M.alt(xs, False{}))) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, +t}:
      +cT = Laws.Spec.count(k, M.alt(t, True{}))
      +cF = Laws.Spec.count(k, M.alt(t, False{}))
      +b = Nat.is_eq(k, h)
      %Equal.sym(Nat, Laws.Spec.count(k, t), Nat.add(cT, cF), alt_count(k, t)) : {Laws.Spec.bump(b, _) == Nat.add(Laws.Spec.bump(b, cF), cT) : Nat}
      %add_comm2(cT, cF) : {Laws.Spec.bump(b, _) == Nat.add(Laws.Spec.bump(b, cF), cT) : Nat}
      bump_add_l2(b, cF, cT)

# ---- 整列 ----

def sort_go_sorted(+fuel: Nat, +xs: List<&2, Nat>) -> Laws.Spec.Sorted.from(0n, M.sort.go(fuel, xs)):
  match fuel:
    case 0n:
      isort_sorted(xs)
    case 1n+f:
      match xs:
        case Nil{}:
          Unit{}
        case Con{h, Nil{}}:
          (Unit{}, Unit{})
        case Con{h, Con{h2, t}}:
          +a = M.sort.go(f, M.alt(xs, True{}))
          +b = M.sort.go(f, M.alt(xs, False{}))
          merge_sorted(a, b, M.le_heads(a, b), 0n, {==}, sort_go_sorted(f, M.alt(xs, True{})), sort_go_sorted(f, M.alt(xs, False{})))

def sort_go_count(+fuel: Nat, +k: Nat, +xs: List<&2, Nat>) -> {Laws.Spec.count(k, xs) == Laws.Spec.count(k, M.sort.go(fuel, xs)) : Nat}:
  match fuel:
    case 0n:
      isort_count(k, xs)
    case 1n+f:
      match xs:
        case Nil{}:
          {==}
        case Con{h, Nil{}}:
          {==}
        case Con{h, Con{h2, t}}:
          +xa = M.alt(xs, True{})
          +xb = M.alt(xs, False{})
          +a = M.sort.go(f, xa)
          +b = M.sort.go(f, xb)
          %merge_count(a, b, M.le_heads(a, b), k) : {Laws.Spec.count(k, xs) == _ : Nat}
          %sort_go_count(f, k, xa) : {Laws.Spec.count(k, xs) == Nat.add(_, Laws.Spec.count(k, b)) : Nat}
          %sort_go_count(f, k, xb) : {Laws.Spec.count(k, xs) == Nat.add(Laws.Spec.count(k, xa), _) : Nat}
          alt_count(k, xs)

# ---- 法則 ----

def Laws.sort_sorted(xs):
  sort_go_sorted(List.length(&2, Nat, xs), xs)

def Laws.sort_perm(x, xs):
  +n = List.length(&2, Nat, xs)
  Equal.sym(Nat, Laws.Spec.count(x, xs), Laws.Spec.count(x, M.sort(xs)), sort_go_count(n, x, xs))
