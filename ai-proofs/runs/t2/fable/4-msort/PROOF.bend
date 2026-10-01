import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# Nat の算術
# ----------

def add_zero(n: Nat) -> {n == Nat.add(n, 0n) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def add_succ(n: Nat, -m: Nat) -> {1n+Nat.add(n, m) == Nat.add(n, 1n+m) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, m) : {1n+1n+Nat.add(p, m) == 1n+_ : Nat}
      {==}

def bump_add(b: Bool, -n: Nat, -m: Nat) ->
  {Laws.Spec.bump(b, Nat.add(n, m)) == Nat.add(Laws.Spec.bump(b, n), m) : Nat}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def add_bump(n: Nat, b: Bool, -m: Nat) ->
  {Laws.Spec.bump(b, Nat.add(n, m)) == Nat.add(n, Laws.Spec.bump(b, m)) : Nat}:
  match b:
    case True{}:
      add_succ(n, m)
    case False{}:
      {==}

# 比較
# ----

# True なら Empty。{x == True} で x が False に計算されるときの矛盾に使う
def Clash(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def is_le_true(a: Nat, b: Nat, e: {Nat.is_le(a, b) == True{} : Bool}) -> Laws.Spec.LE(a, b):
  match a b:
    case 0n b2:
      Unit{}
    case 1n+ap 0n:
      %e : Clash(_)
      Unit{}
    case 1n+ap 1n+bp:
      is_le_true(ap, bp, e)

def is_le_false(a: Nat, b: Nat, e: {Nat.is_le(a, b) == False{} : Bool}) -> Laws.Spec.LE(b, a):
  match a b:
    case 0n 0n:
      Unit{}
    case 0n 1n+bp:
      %e : Clash(Bool.not(_))
      Unit{}
    case 1n+ap 0n:
      Unit{}
    case 1n+ap 1n+bp:
      is_le_false(ap, bp, e)

# 併合は整列を保つ
# ----------------

def merge_go_sorted(
  xt: List<&2, Nat>, yt: List<&2, Nat>, le: Bool, +x: Nat, +y: Nat, +lo: Nat,
  e: {le == Nat.is_le(x, y) : Bool},
  lx: Laws.Spec.LE(lo, x), ly: Laws.Spec.LE(lo, y),
  sx: Laws.Spec.Sorted.from(x, xt), sy: Laws.Spec.Sorted.from(y, yt)
) -> Laws.Spec.Sorted.from(lo, M.merge.go(xt, yt, le, x, y)):
  match xt yt le:
    case Nil{} ys True{}:
      (lx, (is_le_true(x, y, Equal.sym(Bool, True{}, Nat.is_le(x, y), e)), sy))
    case +x2 <> xt2 ys True{}:
      (hx, sx2) = sx
      (lx, merge_go_sorted(xt2, ys, Nat.is_le(x2, y), x2, y, x, {==},
        hx, is_le_true(x, y, Equal.sym(Bool, True{}, Nat.is_le(x, y), e)), sx2, sy))
    case xs Nil{} False{}:
      (ly, (is_le_false(x, y, Equal.sym(Bool, False{}, Nat.is_le(x, y), e)), sx))
    case xs +y2 <> yt2 False{}:
      (hy, sy2) = sy
      (ly, merge_go_sorted(xs, yt2, Nat.is_le(x, y2), x, y2, y, {==},
        is_le_false(x, y, Equal.sym(Bool, False{}, Nat.is_le(x, y), e)), hy, sx, sy2))

def merge_sorted(
  xs: List<&2, Nat>, ys: List<&2, Nat>, +lo: Nat,
  sx: Laws.Spec.Sorted.from(lo, xs), sy: Laws.Spec.Sorted.from(lo, ys)
) -> Laws.Spec.Sorted.from(lo, M.merge(xs, ys)):
  match xs ys:
    case Nil{} ys2:
      sy
    case x <> xt Nil{}:
      sx
    case +x <> xt +y <> yt:
      (lx, sx2) = sx
      (ly, sy2) = sy
      merge_go_sorted(xt, yt, Nat.is_le(x, y), x, y, lo, {==}, lx, ly, sx2, sy2)

# 併合は個数を保つ
# ----------------

def merge_go_count(
  +xt: List<&2, Nat>, +yt: List<&2, Nat>, le: Bool, +x: Nat, +y: Nat, +z: Nat
) -> {Nat.add(Laws.Spec.count(z, x <> xt), Laws.Spec.count(z, y <> yt))
      == Laws.Spec.count(z, M.merge.go(xt, yt, le, x, y)) : Nat}:
  match xt yt le:
    case Nil{} ys True{}:
      %bump_add(Nat.is_eq(z, x), 0n, Laws.Spec.count(z, y <> ys))
        : {_ == Laws.Spec.bump(Nat.is_eq(z, x), Laws.Spec.count(z, y <> ys)) : Nat}
      {==}
    case +x2 <> xt2 ys True{}:
      %merge_go_count(xt2, ys, Nat.is_le(x2, y), x2, y, z)
        : {Nat.add(Laws.Spec.count(z, x <> x2 <> xt2), Laws.Spec.count(z, y <> ys))
           == Laws.Spec.bump(Nat.is_eq(z, x), _) : Nat}
      %bump_add(Nat.is_eq(z, x), Laws.Spec.count(z, x2 <> xt2), Laws.Spec.count(z, y <> ys))
        : {_ == Laws.Spec.bump(Nat.is_eq(z, x),
             Nat.add(Laws.Spec.count(z, x2 <> xt2), Laws.Spec.count(z, y <> ys))) : Nat}
      {==}
    case xs Nil{} False{}:
      %add_bump(Laws.Spec.count(z, x <> xs), Nat.is_eq(z, y), 0n)
        : {_ == Laws.Spec.bump(Nat.is_eq(z, y), Laws.Spec.count(z, x <> xs)) : Nat}
      %add_zero(Laws.Spec.count(z, x <> xs))
        : {Laws.Spec.bump(Nat.is_eq(z, y), _)
           == Laws.Spec.bump(Nat.is_eq(z, y), Laws.Spec.count(z, x <> xs)) : Nat}
      {==}
    case xs +y2 <> yt2 False{}:
      %merge_go_count(xs, yt2, Nat.is_le(x, y2), x, y2, z)
        : {Nat.add(Laws.Spec.count(z, x <> xs), Laws.Spec.count(z, y <> y2 <> yt2))
           == Laws.Spec.bump(Nat.is_eq(z, y), _) : Nat}
      %add_bump(Laws.Spec.count(z, x <> xs), Nat.is_eq(z, y), Laws.Spec.count(z, y2 <> yt2))
        : {_ == Laws.Spec.bump(Nat.is_eq(z, y),
             Nat.add(Laws.Spec.count(z, x <> xs), Laws.Spec.count(z, y2 <> yt2))) : Nat}
      {==}

def merge_count(xs: List<&2, Nat>, ys: List<&2, Nat>, +z: Nat) ->
  {Nat.add(Laws.Spec.count(z, xs), Laws.Spec.count(z, ys)) == Laws.Spec.count(z, M.merge(xs, ys)) : Nat}:
  match xs ys:
    case Nil{} ys2:
      {==}
    case x <> xt Nil{}:
      %add_zero(Laws.Spec.count(z, x <> xt)) : {_ == Laws.Spec.count(z, x <> xt) : Nat}
      {==}
    case +x <> xt +y <> yt:
      merge_go_count(xt, yt, Nat.is_le(x, y), x, y, z)

# 分割は個数を保つ
# ----------------

def split_count(+z: Nat, +xs: List<&2, Nat>) ->
  {Laws.Spec.count(z, xs) == Nat.add(Laws.Spec.count(z, M.evens(xs)), Laws.Spec.count(z, M.odds(xs))) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> Nil{}:
      add_zero(Laws.Spec.count(z, h <> Nil{}))
    case h <> h2 <> t:
      %bump_add(Nat.is_eq(z, h), Laws.Spec.count(z, M.evens(t)), Laws.Spec.count(z, h2 <> M.odds(t)))
        : {Laws.Spec.bump(Nat.is_eq(z, h), Laws.Spec.bump(Nat.is_eq(z, h2), Laws.Spec.count(z, t))) == _ : Nat}
      %add_bump(Laws.Spec.count(z, M.evens(t)), Nat.is_eq(z, h2), Laws.Spec.count(z, M.odds(t)))
        : {Laws.Spec.bump(Nat.is_eq(z, h), Laws.Spec.bump(Nat.is_eq(z, h2), Laws.Spec.count(z, t)))
           == Laws.Spec.bump(Nat.is_eq(z, h), _) : Nat}
      %split_count(z, t)
        : {Laws.Spec.bump(Nat.is_eq(z, h), Laws.Spec.bump(Nat.is_eq(z, h2), Laws.Spec.count(z, t)))
           == Laws.Spec.bump(Nat.is_eq(z, h), Laws.Spec.bump(Nat.is_eq(z, h2), _)) : Nat}
      {==}

# 予備の挿入ソート
# ----------------

def isort_sorted(+xs: List<&2, Nat>) -> Laws.Spec.Sorted(M.isort(xs)):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      merge_sorted(h <> Nil{}, M.isort(t), 0n, (Unit{}, Unit{}), isort_sorted(t))

def isort_count(+z: Nat, +xs: List<&2, Nat>) ->
  {Laws.Spec.count(z, xs) == Laws.Spec.count(z, M.isort(xs)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %merge_count(h <> Nil{}, M.isort(t), z)
        : {Laws.Spec.bump(Nat.is_eq(z, h), Laws.Spec.count(z, t)) == _ : Nat}
      %isort_count(z, t)
        : {Laws.Spec.bump(Nat.is_eq(z, h), Laws.Spec.count(z, t))
           == Nat.add(Laws.Spec.bump(Nat.is_eq(z, h), 0n), _) : Nat}
      bump_add(Nat.is_eq(z, h), 0n, Laws.Spec.count(z, t))

# 本体
# ----

def cnt2(+z: Nat, lr: Sigma<&2, &2, List<&2, Nat>, _ => List<&2, Nat>>) -> Nat:
  (l, r) = lr
  Nat.add(Laws.Spec.count(z, l), Laws.Spec.count(z, r))

def go_sorted(+fuel: Nat, +lr: Sigma<&2, &2, List<&2, Nat>, _ => List<&2, Nat>>) -> Laws.Spec.Sorted(M.sort.go(fuel, lr)):
  match fuel:
    case 0n:
      (l, r) = lr
      merge_sorted(M.isort(l), M.isort(r), 0n, isort_sorted(l), isort_sorted(r))
    case 1n+f:
      (l, r) = lr
      match l r:
        case Nil{} r2:
          isort_sorted(r2)
        case x <> xt Nil{}:
          isort_sorted(x <> xt)
        case x <> xt y <> yt:
          merge_sorted(M.sort.go(f, M.split(x <> xt)), M.sort.go(f, M.split(y <> yt)), 0n,
            go_sorted(f, M.split(x <> xt)), go_sorted(f, M.split(y <> yt)))

def go_count(+fuel: Nat, +lr: Sigma<&2, &2, List<&2, Nat>, _ => List<&2, Nat>>, +z: Nat) ->
  {cnt2(z, lr) == Laws.Spec.count(z, M.sort.go(fuel, lr)) : Nat}:
  match fuel:
    case 0n:
      (l, r) = lr
      %merge_count(M.isort(l), M.isort(r), z)
        : {Nat.add(Laws.Spec.count(z, l), Laws.Spec.count(z, r)) == _ : Nat}
      %isort_count(z, l)
        : {Nat.add(Laws.Spec.count(z, l), Laws.Spec.count(z, r))
           == Nat.add(_, Laws.Spec.count(z, M.isort(r))) : Nat}
      %isort_count(z, r)
        : {Nat.add(Laws.Spec.count(z, l), Laws.Spec.count(z, r))
           == Nat.add(Laws.Spec.count(z, l), _) : Nat}
      {==}
    case 1n+f:
      (l, r) = lr
      match l r:
        case Nil{} r2:
          isort_count(z, r2)
        case x <> xt Nil{}:
          %add_zero(Laws.Spec.count(z, x <> xt)) : {_ == Laws.Spec.count(z, M.isort(x <> xt)) : Nat}
          isort_count(z, x <> xt)
        case x <> xt y <> yt:
          %merge_count(M.sort.go(f, M.split(x <> xt)), M.sort.go(f, M.split(y <> yt)), z)
            : {Nat.add(Laws.Spec.count(z, x <> xt), Laws.Spec.count(z, y <> yt)) == _ : Nat}
          %go_count(f, M.split(x <> xt), z)
            : {Nat.add(Laws.Spec.count(z, x <> xt), Laws.Spec.count(z, y <> yt))
               == Nat.add(_, Laws.Spec.count(z, M.sort.go(f, M.split(y <> yt)))) : Nat}
          %go_count(f, M.split(y <> yt), z)
            : {Nat.add(Laws.Spec.count(z, x <> xt), Laws.Spec.count(z, y <> yt))
               == Nat.add(cnt2(z, M.split(x <> xt)), _) : Nat}
          %split_count(z, x <> xt)
            : {Nat.add(Laws.Spec.count(z, x <> xt), Laws.Spec.count(z, y <> yt))
               == Nat.add(_, cnt2(z, M.split(y <> yt))) : Nat}
          %split_count(z, y <> yt)
            : {Nat.add(Laws.Spec.count(z, x <> xt), Laws.Spec.count(z, y <> yt))
               == Nat.add(Laws.Spec.count(z, x <> xt), _) : Nat}
          {==}

# 法則
# ----

def Laws.sort_sorted(xs):
  go_sorted(List.length(&2, Nat, xs), M.split(xs))

def Laws.sort_perm(x, xs):
  %go_count(List.length(&2, Nat, xs), M.split(xs), x) : {_ == Laws.Spec.count(x, xs) : Nat}
  %split_count(x, xs) : {_ == Laws.Spec.count(x, xs) : Nat}
  {==}
