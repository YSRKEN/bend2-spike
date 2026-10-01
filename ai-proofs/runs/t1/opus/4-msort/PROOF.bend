import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# 算術の補題
# ==========

def add_zero_r(+n: Nat) -> {Nat.add(n, 0n) == n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero_r(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ_r(+n: Nat, +m: Nat) -> {Nat.add(n, 1n+m) == 1n+Nat.add(n, m) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_succ_r(p, m) : {1n+Nat.add(p, 1n+m) == 1n+_ : Nat}
      {==}

def add_bump_l(b: Bool, +n: Nat, +m: Nat) ->
  {Nat.add(Laws.Spec.bump(b, n), m) == Laws.Spec.bump(b, Nat.add(n, m)) : Nat}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def add_bump_r(+n: Nat, b: Bool, +m: Nat) ->
  {Nat.add(n, Laws.Spec.bump(b, m)) == Laws.Spec.bump(b, Nat.add(n, m)) : Nat}:
  match b:
    case True{}:
      add_succ_r(n, m)
    case False{}:
      {==}

def add_cong(-a: Nat, -a2: Nat, -b: Nat, -b2: Nat,
  e1: {a == a2 : Nat}, e2: {b == b2 : Nat}) ->
  {Nat.add(a, b) == Nat.add(a2, b2) : Nat}:
  %e1 : {Nat.add(a, b) == Nat.add(_, b2) : Nat}
  %e2 : {Nat.add(a, b) == Nat.add(a, _) : Nat}
  {==}

def bump_cong(-c: Bool, -a: Nat, -b: Nat, e: {a == b : Nat}) ->
  {Laws.Spec.bump(c, a) == Laws.Spec.bump(c, b) : Nat}:
  %e : {Laws.Spec.bump(c, a) == Laws.Spec.bump(c, _) : Nat}
  {==}

# 個数の補題
# ==========

def split_count(+x: Nat, +xs: List<&2, Nat>) ->
  {Nat.add(Laws.Spec.count(x, M.evens(xs)), Laws.Spec.count(x, M.odds(xs)))
    == Laws.Spec.count(x, xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{+h, Nil{}}:
      add_zero_r(Laws.Spec.bump(Nat.is_eq(x, h), 0n))
    case Con{+h, Con{+h2, +t}}:
      +e1 = Nat.is_eq(x, h)
      +e2 = Nat.is_eq(x, h2)
      +ce = Laws.Spec.count(x, M.evens(t))
      +co = Laws.Spec.count(x, M.odds(t))
      +ct = Laws.Spec.count(x, t)
      Equal.trans(Nat,
        Nat.add(Laws.Spec.bump(e1, ce), Laws.Spec.bump(e2, co)),
        Laws.Spec.bump(e1, Nat.add(ce, Laws.Spec.bump(e2, co))),
        Laws.Spec.bump(e1, Laws.Spec.bump(e2, ct)),
        add_bump_l(e1, ce, Laws.Spec.bump(e2, co)),
        bump_cong(e1, Nat.add(ce, Laws.Spec.bump(e2, co)), Laws.Spec.bump(e2, ct),
          Equal.trans(Nat,
            Nat.add(ce, Laws.Spec.bump(e2, co)),
            Laws.Spec.bump(e2, Nat.add(ce, co)),
            Laws.Spec.bump(e2, ct),
            add_bump_r(ce, e2, co),
            bump_cong(e2, Nat.add(ce, co), ct, split_count(x, t)))))

def go_count(+x: Nat, +xt: List<&2, Nat>, +yt: List<&2, Nat>, +a: Nat, +b: Nat, le: Bool) ->
  {Laws.Spec.count(x, M.merge.go(xt, yt, a, b, le))
    == Nat.add(Laws.Spec.count(x, a <> xt), Laws.Spec.count(x, b <> yt)) : Nat}:
  match xt yt le:
    case Nil{} +ys True{}:
      Equal.sym(Nat,
        Nat.add(Laws.Spec.bump(Nat.is_eq(x, a), 0n), Laws.Spec.count(x, b <> ys)),
        Laws.Spec.bump(Nat.is_eq(x, a), Laws.Spec.count(x, b <> ys)),
        add_bump_l(Nat.is_eq(x, a), 0n, Laws.Spec.count(x, b <> ys)))
    case Con{+x2, +xt2} +ys True{}:
      +ea = Nat.is_eq(x, a)
      +cx = Laws.Spec.count(x, x2 <> xt2)
      +cy = Laws.Spec.count(x, b <> ys)
      +g = Laws.Spec.count(x, M.merge.go(xt2, ys, x2, b, Nat.is_le(x2, b)))
      Equal.trans(Nat,
        Laws.Spec.bump(ea, g),
        Laws.Spec.bump(ea, Nat.add(cx, cy)),
        Nat.add(Laws.Spec.bump(ea, cx), cy),
        bump_cong(ea, g, Nat.add(cx, cy), go_count(x, xt2, ys, x2, b, Nat.is_le(x2, b))),
        Equal.sym(Nat, Nat.add(Laws.Spec.bump(ea, cx), cy), Laws.Spec.bump(ea, Nat.add(cx, cy)),
          add_bump_l(ea, cx, cy)))
    case +xs Nil{} False{}:
      +eb = Nat.is_eq(x, b)
      +cx = Laws.Spec.count(x, a <> xs)
      Equal.sym(Nat,
        Nat.add(cx, Laws.Spec.bump(eb, 0n)),
        Laws.Spec.bump(eb, cx),
        Equal.trans(Nat,
          Nat.add(cx, Laws.Spec.bump(eb, 0n)),
          Laws.Spec.bump(eb, Nat.add(cx, 0n)),
          Laws.Spec.bump(eb, cx),
          add_bump_r(cx, eb, 0n),
          bump_cong(eb, Nat.add(cx, 0n), cx, add_zero_r(cx))))
    case +xs Con{+y2, +yt2} False{}:
      +eb = Nat.is_eq(x, b)
      +cx = Laws.Spec.count(x, a <> xs)
      +cy = Laws.Spec.count(x, y2 <> yt2)
      +g = Laws.Spec.count(x, M.merge.go(xs, yt2, a, y2, Nat.is_le(a, y2)))
      Equal.trans(Nat,
        Laws.Spec.bump(eb, g),
        Laws.Spec.bump(eb, Nat.add(cx, cy)),
        Nat.add(cx, Laws.Spec.bump(eb, cy)),
        bump_cong(eb, g, Nat.add(cx, cy), go_count(x, xs, yt2, a, y2, Nat.is_le(a, y2))),
        Equal.sym(Nat, Nat.add(cx, Laws.Spec.bump(eb, cy)), Laws.Spec.bump(eb, Nat.add(cx, cy)),
          add_bump_r(cx, eb, cy)))

def merge_count(+x: Nat, +xs: List<&2, Nat>, +ys: List<&2, Nat>) ->
  {Laws.Spec.count(x, M.merge(xs, ys))
    == Nat.add(Laws.Spec.count(x, xs), Laws.Spec.count(x, ys)) : Nat}:
  match xs ys:
    case Nil{} Nil{}:
      {==}
    case Nil{} Con{+b, +yt}:
      {==}
    case Con{+a, +xt} Nil{}:
      Equal.sym(Nat, Nat.add(Laws.Spec.count(x, a <> xt), 0n), Laws.Spec.count(x, a <> xt),
        add_zero_r(Laws.Spec.count(x, a <> xt)))
    case Con{+a, +xt} Con{+b, +yt}:
      go_count(x, xt, yt, a, b, Nat.is_le(a, b))

def msort_count(+x: Nat, +fuel: Nat, +xs: List<&2, Nat>) ->
  {Laws.Spec.count(x, M.msort(fuel, xs)) == Laws.Spec.count(x, xs) : Nat}:
  match fuel:
    case 0n:
      {==}
    case 1n+(+f):
      match xs:
        case Nil{}:
          {==}
        case Con{+h, Nil{}}:
          {==}
        case Con{+h, Con{+h2, +t}}:
          +la = {h <> M.evens(t) : List<&2, Nat>}
          +lb = {h2 <> M.odds(t) : List<&2, Nat>}
          +ma = M.msort(f, la)
          +mb = M.msort(f, lb)
          Equal.trans(Nat,
            Laws.Spec.count(x, M.merge(ma, mb)),
            Nat.add(Laws.Spec.count(x, ma), Laws.Spec.count(x, mb)),
            Laws.Spec.count(x, h <> h2 <> t),
            merge_count(x, ma, mb),
            Equal.trans(Nat,
              Nat.add(Laws.Spec.count(x, ma), Laws.Spec.count(x, mb)),
              Nat.add(Laws.Spec.count(x, la), Laws.Spec.count(x, lb)),
              Laws.Spec.count(x, h <> h2 <> t),
              add_cong(Laws.Spec.count(x, ma), Laws.Spec.count(x, la),
                Laws.Spec.count(x, mb), Laws.Spec.count(x, lb),
                msort_count(x, f, la), msort_count(x, f, lb)),
              split_count(x, h <> h2 <> t)))

def Laws.sort_perm(x, xs):
  msort_count(x, List.length(&2, Nat, xs), xs)

# 順序の補題
# ==========

def DiscT(b: Bool) -> Type:
  match b:
    case False{}:
      Empty
    case True{}:
      Unit

def DiscF(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def le_refl(+n: Nat) -> Laws.Spec.LE(n, n):
  match n:
    case 0n:
      Unit{}
    case 1n+p:
      le_refl(p)

def le_succ(+a: Nat, +b: Nat, p: Laws.Spec.LE(a, b)) -> Laws.Spec.LE(a, 1n+b):
  match a b:
    case 0n b0:
      Unit{}
    case 1n+(+a1) 0n:
      match p:
    case 1n+(+a1) 1n+(+b1):
      le_succ(a1, b1, p)

def le_trans(+a: Nat, +b: Nat, +c: Nat, p: Laws.Spec.LE(a, b), q: Laws.Spec.LE(b, c)) ->
  Laws.Spec.LE(a, c):
  match a b c:
    case 0n b0 c0:
      Unit{}
    case 1n+(+a1) 0n c0:
      match p:
    case 1n+(+a1) 1n+(+b1) 0n:
      match q:
    case 1n+(+a1) 1n+(+b1) 1n+(+c1):
      le_trans(a1, b1, c1, p, q)

def le_of_true(+a: Nat, +b: Nat, e: {True{} == Nat.is_le(a, b) : Bool}) -> Laws.Spec.LE(a, b):
  match a b:
    case 0n b0:
      Unit{}
    case 1n+(+a1) 0n:
      %e : DiscT(_)
      Unit{}
    case 1n+(+a1) 1n+(+b1):
      le_of_true(a1, b1, e)

def le_of_false(+a: Nat, +b: Nat, e: {False{} == Nat.is_le(a, b) : Bool}) -> Laws.Spec.LE(b, a):
  match a b:
    case 0n 0n:
      Unit{}
    case 0n 1n+(+b1):
      %e : DiscF(_)
      Unit{}
    case 1n+(+a1) 0n:
      Unit{}
    case 1n+(+a1) 1n+(+b1):
      le_of_false(a1, b1, e)

def evens_len(+xs: List<&2, Nat>) ->
  Laws.Spec.LE(List.length(&2, Nat, M.evens(xs)), List.length(&2, Nat, xs)):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+h, Nil{}}:
      Unit{}
    case Con{+h, Con{+h2, +t}}:
      le_succ(List.length(&2, Nat, M.evens(t)), List.length(&2, Nat, t), evens_len(t))

def odds_len(+xs: List<&2, Nat>) ->
  Laws.Spec.LE(List.length(&2, Nat, M.odds(xs)), List.length(&2, Nat, xs)):
  match xs:
    case Nil{}:
      Unit{}
    case Con{+h, Nil{}}:
      Unit{}
    case Con{+h, Con{+h2, +t}}:
      le_succ(List.length(&2, Nat, M.odds(t)), List.length(&2, Nat, t), odds_len(t))

# 整列の補題
# ==========

def go_sorted(+xt: List<&2, Nat>, +yt: List<&2, Nat>, -lo: Nat, +a: Nat, +b: Nat, le: Bool,
  e: {le == Nat.is_le(a, b) : Bool},
  pa: Laws.Spec.LE(lo, a), pb: Laws.Spec.LE(lo, b),
  sa: Laws.Spec.Sorted.from(a, xt), sb: Laws.Spec.Sorted.from(b, yt)) ->
  Laws.Spec.Sorted.from(lo, M.merge.go(xt, yt, a, b, le)):
  match xt yt le:
    case Nil{} +ys True{}:
      (pa, (le_of_true(a, b, e), sb))
    case Con{+x2, +xt2} +ys True{}:
      (p1, s2) = sa
      (pa, go_sorted(xt2, ys, a, x2, b, Nat.is_le(x2, b), {==}, p1, le_of_true(a, b, e), s2, sb))
    case +xs Nil{} False{}:
      (pb, (le_of_false(a, b, e), sa))
    case +xs Con{+y2, +yt2} False{}:
      (q1, s2) = sb
      (pb, go_sorted(xs, yt2, b, a, y2, Nat.is_le(a, y2), {==}, le_of_false(a, b, e), q1, sa, s2))

def merge_sorted(-lo: Nat, +xs: List<&2, Nat>, +ys: List<&2, Nat>,
  sx: Laws.Spec.Sorted.from(lo, xs), sy: Laws.Spec.Sorted.from(lo, ys)) ->
  Laws.Spec.Sorted.from(lo, M.merge(xs, ys)):
  match xs ys:
    case Nil{} Nil{}:
      Unit{}
    case Nil{} Con{+b, +yt}:
      sy
    case Con{+a, +xt} Nil{}:
      sx
    case Con{+a, +xt} Con{+b, +yt}:
      (pa, sa) = sx
      (pb, sb) = sy
      go_sorted(xt, yt, lo, a, b, Nat.is_le(a, b), {==}, pa, pb, sa, sb)

def msort_sorted(+fuel: Nat, +xs: List<&2, Nat>,
  +p: Laws.Spec.LE(List.length(&2, Nat, xs), fuel)) ->
  Laws.Spec.Sorted(M.msort(fuel, xs)):
  match fuel:
    case 0n:
      match xs:
        case Nil{}:
          Unit{}
        case Con{h, t}:
          match p:
    case 1n+(+f):
      match xs:
        case Nil{}:
          Unit{}
        case Con{+h, Nil{}}:
          (Unit{}, Unit{})
        case Con{+h, Con{+h2, +t}}:
          +la = {h <> M.evens(t) : List<&2, Nat>}
          +lb = {h2 <> M.odds(t) : List<&2, Nat>}
          +lt = List.length(&2, Nat, t)
          pa = le_trans(List.length(&2, Nat, la), 1n+lt, f, evens_len(t), p)
          pb = le_trans(List.length(&2, Nat, lb), 1n+lt, f, odds_len(t), p)
          merge_sorted(0n, M.msort(f, la), M.msort(f, lb),
            msort_sorted(f, la, pa), msort_sorted(f, lb, pb))

def Laws.sort_sorted(xs):
  msort_sorted(List.length(&2, Nat, xs), xs, le_refl(List.length(&2, Nat, xs)))
