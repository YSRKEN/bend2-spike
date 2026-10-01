# 題 4: 並列マージソートの証明。
import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# Nat の補題
# ---------

def P.add_zero(n: Nat) -> {n == Nat.add(n, 0n) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %P.add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def P.add_succ(n: Nat, m: Nat) -> {1n+Nat.add(n, m) == Nat.add(n, 1n+m) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %P.add_succ(p, m) : {2n+Nat.add(p, m) == 1n+_ : Nat}
      {==}

def P.add_comm(+n: Nat, +m: Nat) -> {Nat.add(m, n) == Nat.add(n, m) : Nat}:
  match n:
    case 0n:
      %P.add_zero(m) : {_ == m : Nat}
      {==}
    case 1n+p:
      %P.add_succ(m, p) : {_ == 1n+Nat.add(p, m) : Nat}
      %P.add_comm(p, m) : {1n+Nat.add(m, p) == 1n+_ : Nat}
      {==}

def P.add_bump_l(e: Bool, n: Nat, m: Nat) ->
  {Laws.Spec.bump(e, Nat.add(n, m)) == Nat.add(Laws.Spec.bump(e, n), m) : Nat}:
  match e:
    case True{}:
      {==}
    case False{}:
      {==}

def P.add_bump_r(e: Bool, n: Nat, m: Nat) ->
  {Laws.Spec.bump(e, Nat.add(n, m)) == Nat.add(n, Laws.Spec.bump(e, m)) : Nat}:
  match e n:
    case _ 0n:
      {==}
    case True{} 1n+p:
      %P.add_succ(p, m) : {2n+Nat.add(p, m) == 1n+_ : Nat}
      {==}
    case False{} 1n+p:
      {==}

# 個数の補題（並べ替えであること）
# -------------------------------

# merge.pick の個数: ka, kb の個数が分かっていれば、どちらを選んでも個数は保たれる
def P.pick_count(
  le: Bool, +x: Nat, +h: Nat, xt: List<&2, Nat>, +y: Nat, yt: List<&2, Nat>,
  -ka: Unit -> List<&2, Nat>, -kb: Unit -> List<&2, Nat>,
  ea: {Nat.add(Laws.Spec.count(x, xt), Laws.Spec.count(x, y <> yt))
       == Laws.Spec.count(x, ka(Unit{})) : Nat},
  eb: {Nat.add(Laws.Spec.count(x, h <> xt), Laws.Spec.count(x, yt))
       == Laws.Spec.count(x, kb(Unit{})) : Nat}
) -> {Nat.add(Laws.Spec.count(x, h <> xt), Laws.Spec.count(x, y <> yt))
      == Laws.Spec.count(x, M.merge.pick(le, h, ka, y, kb)) : Nat}:
  match le:
    case True{}:
      %ea : {Nat.add(Laws.Spec.count(x, h <> xt), Laws.Spec.count(x, y <> yt))
             == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      %P.add_bump_l(Nat.is_eq(x, h), Laws.Spec.count(x, xt), Laws.Spec.count(x, y <> yt)) :
        {_ == Laws.Spec.bump(Nat.is_eq(x, h), Nat.add(Laws.Spec.count(x, xt), Laws.Spec.count(x, y <> yt))) : Nat}
      {==}
    case False{}:
      %eb : {Nat.add(Laws.Spec.count(x, h <> xt), Laws.Spec.count(x, y <> yt))
             == Laws.Spec.bump(Nat.is_eq(x, y), _) : Nat}
      %P.add_bump_r(Nat.is_eq(x, y), Laws.Spec.count(x, h <> xt), Laws.Spec.count(x, yt)) :
        {_ == Laws.Spec.bump(Nat.is_eq(x, y), Nat.add(Laws.Spec.count(x, h <> xt), Laws.Spec.count(x, yt))) : Nat}
      {==}

# merge の個数は、両方の個数の和
def P.merge_count(+xs: List<&2, Nat>, +ys: List<&2, Nat>, +x: Nat) ->
  {Nat.add(Laws.Spec.count(x, xs), Laws.Spec.count(x, ys))
   == Laws.Spec.count(x, M.merge(xs, ys)) : Nat}:
  match xs ys:
    case Nil{} _:
      {==}
    case Con{h, xt} Nil{}:
      %P.add_zero(Laws.Spec.count(x, xs)) : {_ == Laws.Spec.count(x, xs) : Nat}
      {==}
    case Con{+h, xt} Con{+y, yt}:
      P.pick_count(Nat.is_le(h, y), x, h, xt, y, yt,
        u => M.merge(xt, ys), u => M.merge(xs, yt),
        P.merge_count(xt, ys, x), P.merge_count(xs, yt, x))

# half で 2 つに分けても、個数の和は変わらない
def P.half_count(+xs: List<&2, Nat>, +x: Nat) ->
  {Laws.Spec.count(x, xs)
   == Nat.add(Laws.Spec.count(x, M.half(xs, True{})), Laws.Spec.count(x, M.half(xs, False{}))) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, t}:
      %P.add_bump_l(Nat.is_eq(x, h), Laws.Spec.count(x, M.half(t, False{})), Laws.Spec.count(x, M.half(t, True{}))) :
        {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, t)) == _ : Nat}
      %P.add_comm(Laws.Spec.count(x, M.half(t, False{})), Laws.Spec.count(x, M.half(t, True{}))) :
        {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, t)) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      %P.half_count(t, x) :
        {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, t)) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      {==}

# sort.go は fuel によらず個数を保つ
def P.go_count(+fuel: Nat, +xs: List<&2, Nat>, +x: Nat) ->
  {Laws.Spec.count(x, xs) == Laws.Spec.count(x, M.sort.go(fuel, xs)) : Nat}:
  match fuel:
    case 0n:
      {==}
    case 1n+f:
      match xs:
        case Nil{}:
          {==}
        case Con{h, Nil{}}:
          {==}
        case Con{h, Con{h2, t}}:
          %P.merge_count(M.sort.go(f, M.half(xs, True{})), M.sort.go(f, M.half(xs, False{})), x) :
            {Laws.Spec.count(x, xs) == _ : Nat}
          %P.go_count(f, M.half(xs, True{}), x) :
            {Laws.Spec.count(x, xs)
             == Nat.add(_, Laws.Spec.count(x, M.sort.go(f, M.half(xs, False{})))) : Nat}
          %P.go_count(f, M.half(xs, False{}), x) :
            {Laws.Spec.count(x, xs)
             == Nat.add(Laws.Spec.count(x, M.half(xs, True{})), _) : Nat}
          P.half_count(xs, x)

def Laws.sort_perm(x, xs):
  Equal.sym(Nat, Laws.Spec.count(x, xs), Laws.Spec.count(x, M.sort(xs)),
    P.go_count(List.length(&2, Nat, xs), xs, x))

# 順序の補題（昇順であること）
# ---------------------------

def P.LE_refl(n: Nat) -> Laws.Spec.LE(n, n):
  match n:
    case 0n:
      Unit{}
    case 1n+p:
      P.LE_refl(p)

def P.LE_succ_r(a: Nat, b: Nat, p: Laws.Spec.LE(a, b)) -> Laws.Spec.LE(a, 1n+b):
  match a b:
    case 0n _:
      Unit{}
    case 1n+a1 0n:
      match p:
    case 1n+a1 1n+b1:
      P.LE_succ_r(a1, b1, p)

def P.LE_trans(a: Nat, b: Nat, c: Nat, ab: Laws.Spec.LE(a, b), bc: Laws.Spec.LE(b, c)) ->
  Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+a1 0n _:
      match ab:
    case 1n+a1 1n+b1 0n:
      match bc:
    case 1n+a1 1n+b1 1n+c1:
      P.LE_trans(a1, b1, c1, ab, bc)

# le が True なら x <= y、False なら y <= x
def P.LE.of(le: Bool, x: Nat, y: Nat) -> Data:
  match le:
    case True{}:
      Laws.Spec.LE(x, y)
    case False{}:
      Laws.Spec.LE(y, x)

def P.LE.of_succ(le: Bool, x: Nat, y: Nat, p: P.LE.of(le, x, y)) -> P.LE.of(le, 1n+x, 1n+y):
  match le:
    case True{}:
      p
    case False{}:
      p

# Nat.is_le の結果は、P.LE.of の意味で正しい
def P.is_le_spec(+x: Nat, +y: Nat) -> P.LE.of(Nat.is_le(x, y), x, y):
  match x y:
    case 0n 0n:
      Unit{}
    case 0n 1n+y1:
      Unit{}
    case 1n+x1 0n:
      Unit{}
    case 1n+x1 1n+y1:
      P.LE.of_succ(Nat.is_le(x1, y1), x1, y1, P.is_le_spec(x1, y1))

# half の長さは、元の長さ以下
def P.half_le(+xs: List<&2, Nat>, take: Bool) ->
  Laws.Spec.LE(List.length(&2, Nat, M.half(xs, take)), List.length(&2, Nat, xs)):
  match xs take:
    case Nil{} _:
      Unit{}
    case Con{h, t} True{}:
      P.half_le(t, False{})
    case Con{h, t} False{}:
      P.LE_succ_r(List.length(&2, Nat, M.half(t, True{})), List.length(&2, Nat, t),
        P.half_le(t, True{}))

# merge.pick の整列: 選ばれた側の続きが整列していれば、全体も整列している
def P.pick_sorted(
  le: Bool, lo: Nat, +x: Nat, xt: List<&2, Nat>, +y: Nat, yt: List<&2, Nat>,
  -ka: Unit -> List<&2, Nat>, -kb: Unit -> List<&2, Nat>,
  p: P.LE.of(le, x, y),
  lx: Laws.Spec.LE(lo, x), ly: Laws.Spec.LE(lo, y),
  sxt: Laws.Spec.Sorted.from(x, xt), syt: Laws.Spec.Sorted.from(y, yt),
  iha: Laws.Spec.Sorted.from(x, xt) -> Laws.Spec.Sorted.from(x, y <> yt)
       -> Laws.Spec.Sorted.from(x, ka(Unit{})),
  ihb: Laws.Spec.Sorted.from(y, x <> xt) -> Laws.Spec.Sorted.from(y, yt)
       -> Laws.Spec.Sorted.from(y, kb(Unit{}))
) -> Laws.Spec.Sorted.from(lo, M.merge.pick(le, x, ka, y, kb)):
  match le:
    case True{}:
      (lx, iha(sxt, (p, syt)))
    case False{}:
      (ly, ihb((p, sxt), syt))

# 両方が lo 以上で整列していれば、merge の結果も lo 以上で整列している
def P.merge_sorted(
  +xs: List<&2, Nat>, +ys: List<&2, Nat>, +lo: Nat,
  sx: Laws.Spec.Sorted.from(lo, xs), sy: Laws.Spec.Sorted.from(lo, ys)
) -> Laws.Spec.Sorted.from(lo, M.merge(xs, ys)):
  match xs ys:
    case Nil{} _:
      sy
    case Con{x, xt} Nil{}:
      sx
    case Con{+x, xt} Con{+y, yt}:
      (lx, sxt) = sx
      (ly, syt) = sy
      P.pick_sorted(Nat.is_le(x, y), lo, x, xt, y, yt,
        u => M.merge(xt, ys), u => M.merge(xs, yt),
        P.is_le_spec(x, y), lx, ly, sxt, syt,
        a => b => P.merge_sorted(xt, ys, x, a, b),
        a => b => P.merge_sorted(xs, yt, y, a, b))

# fuel が長さ以上なら、sort.go の結果は整列している
def P.go_sorted(+fuel: Nat, +xs: List<&2, Nat>, +b: Laws.Spec.LE(List.length(&2, Nat, xs), fuel)) ->
  Laws.Spec.Sorted.from(0n, M.sort.go(fuel, xs)):
  match fuel:
    case 0n:
      match xs:
        case Nil{}:
          Unit{}
        case Con{h, t}:
          match b:
    case 1n+f:
      match xs:
        case Nil{}:
          Unit{}
        case Con{h, Nil{}}:
          (Unit{}, Unit{})
        case Con{h, Con{h2, t}}:
          P.merge_sorted(M.sort.go(f, M.half(xs, True{})), M.sort.go(f, M.half(xs, False{})), 0n,
            P.go_sorted(f, M.half(xs, True{}),
              P.LE_trans(1n+List.length(&2, Nat, M.half(t, True{})), 1n+List.length(&2, Nat, t), f,
                P.half_le(t, True{}), b)),
            P.go_sorted(f, M.half(xs, False{}),
              P.LE_trans(1n+List.length(&2, Nat, M.half(t, False{})), 1n+List.length(&2, Nat, t), f,
                P.half_le(t, False{}), b)))

def Laws.sort_sorted(xs):
  P.go_sorted(List.length(&2, Nat, xs), xs, P.LE_refl(List.length(&2, Nat, xs)))
