import Base
import ./LAWS.bend as Laws
import ./main.bend as M

def add_zero(+n: Nat) -> {Nat.add(n, 0n) == n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def add_succ(+a: Nat, +b: Nat) -> {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

def add_comm(+a: Nat, +b: Nat) -> {Nat.add(a, b) == Nat.add(b, a) : Nat}:
  match a:
    case 0n:
      Equal.sym(Nat, Nat.add(b, 0n), b, add_zero(b))
    case 1n+p:
      %Equal.sym(Nat, Nat.add(b, 1n+p), 1n+Nat.add(b, p), add_succ(b, p)) : {1n+Nat.add(p, b) == _ : Nat}
      %add_comm(p, b) : {1n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def bump_add(e: Bool, +p: Nat, +q: Nat) -> {Laws.Spec.bump(e, Nat.add(p, q)) == Nat.add(Laws.Spec.bump(e, p), q) : Nat}:
  match e:
    case True{}:
      {==}
    case False{}:
      {==}

def bump_add_r(e: Bool, +p: Nat, +q: Nat) -> {Laws.Spec.bump(e, Nat.add(p, q)) == Nat.add(p, Laws.Spec.bump(e, q)) : Nat}:
  match e:
    case True{}:
      %add_succ(p, q) : {_ == Nat.add(p, 1n+q) : Nat}
      {==}
    case False{}:
      {==}

def Cn(+x: Nat, xs: List<&2, Nat>) -> Nat:
  Laws.Spec.count(x, xs)

def add_cong(+p: Nat, +p2: Nat, +q: Nat, +q2: Nat, e1: {p == p2 : Nat}, e2: {q == q2 : Nat}) -> {Nat.add(p, q) == Nat.add(p2, q2) : Nat}:
  %e2 : {Nat.add(p, q) == Nat.add(p2, _) : Nat}
  %e1 : {Nat.add(p, q) == Nat.add(_, q) : Nat}
  {==}

def pick_count(+x: Nat, c: Bool, +a: Nat, +at: List<&2, Nat>, +b: Nat, +bs: List<&2, Nat>, r1: List<&2, Nat>, r2: List<&2, Nat>,
    e1: {Cn(x, r1) == Nat.add(Cn(x, at), Cn(x, Con{b, bs})) : Nat},
    e2: {Cn(x, r2) == Nat.add(Cn(x, Con{a, at}), Cn(x, bs)) : Nat}
  ) -> {Cn(x, M.pick(c, a, b, r1, r2)) == Nat.add(Cn(x, Con{a, at}), Cn(x, Con{b, bs})) : Nat}:
  match c:
    case True{}:
      %Equal.sym(Nat, Cn(x, r1), Nat.add(Cn(x, at), Cn(x, Con{b, bs})), e1) : {Laws.Spec.bump(Nat.is_eq(x, a), _) == Nat.add(Laws.Spec.bump(Nat.is_eq(x, a), Cn(x, at)), Cn(x, Con{b, bs})) : Nat}
      bump_add(Nat.is_eq(x, a), Cn(x, at), Cn(x, Con{b, bs}))
    case False{}:
      %Equal.sym(Nat, Cn(x, r2), Nat.add(Cn(x, Con{a, at}), Cn(x, bs)), e2) : {Laws.Spec.bump(Nat.is_eq(x, b), _) == Nat.add(Cn(x, Con{a, at}), Laws.Spec.bump(Nat.is_eq(x, b), Cn(x, bs))) : Nat}
      bump_add_r(Nat.is_eq(x, b), Cn(x, Con{a, at}), Cn(x, bs))

def merge_count(+xs: List<&2, Nat>, +ys: List<&2, Nat>, +x: Nat) -> {Cn(x, M.merge(xs, ys)) == Nat.add(Cn(x, xs), Cn(x, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{a, at}:
      match ys:
        case Nil{}:
          Equal.sym(Nat, Nat.add(Cn(x, Con{a, at}), 0n), Cn(x, Con{a, at}), add_zero(Cn(x, Con{a, at})))
        case Con{b, bs}:
          pick_count(x, Nat.is_le(a, b), a, at, b, bs, M.merge(at, ys), M.merge(xs, bs),
            merge_count(at, ys, x), merge_count(xs, bs, x))

def half_count(+xs: List<&2, Nat>, +x: Nat) -> {Nat.add(Cn(x, M.half(xs, True{})), Cn(x, M.half(xs, False{}))) == Cn(x, xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %half_count(t, x) : {Nat.add(Laws.Spec.bump(Nat.is_eq(x, h), Cn(x, M.half(t, False{}))), Cn(x, M.half(t, True{}))) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      %add_comm(Cn(x, M.half(t, False{})), Cn(x, M.half(t, True{}))) : {Nat.add(Laws.Spec.bump(Nat.is_eq(x, h), Cn(x, M.half(t, False{}))), Cn(x, M.half(t, True{}))) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      Equal.sym(Nat, Laws.Spec.bump(Nat.is_eq(x, h), Nat.add(Cn(x, M.half(t, False{})), Cn(x, M.half(t, True{})))), Nat.add(Laws.Spec.bump(Nat.is_eq(x, h), Cn(x, M.half(t, False{}))), Cn(x, M.half(t, True{}))), bump_add(Nat.is_eq(x, h), Cn(x, M.half(t, False{})), Cn(x, M.half(t, True{}))))

def isort_count(+xs: List<&2, Nat>, +x: Nat) -> {Cn(x, M.isort(xs)) == Cn(x, xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %isort_count(t, x) : {Cn(x, M.merge(Con{h, Nil{}}, M.isort(t))) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      Equal.trans(Nat, Cn(x, M.merge(Con{h, Nil{}}, M.isort(t))), Nat.add(Cn(x, Con{h, Nil{}}), Cn(x, M.isort(t))), Laws.Spec.bump(Nat.is_eq(x, h), Cn(x, M.isort(t))),
        merge_count(Con{h, Nil{}}, M.isort(t), x),
        Equal.sym(Nat, Laws.Spec.bump(Nat.is_eq(x, h), Nat.add(0n, Cn(x, M.isort(t)))), Nat.add(Laws.Spec.bump(Nat.is_eq(x, h), 0n), Cn(x, M.isort(t))), bump_add(Nat.is_eq(x, h), 0n, Cn(x, M.isort(t)))))

def ms_count(+x: Nat, +sa: List<&2, Nat>, +sb: List<&2, Nat>, +ca: List<&2, Nat>, +cb: List<&2, Nat>, +k: Nat,
    e1: {Cn(x, sa) == Cn(x, ca) : Nat}, e2: {Cn(x, sb) == Cn(x, cb) : Nat},
    e3: {Nat.add(Cn(x, ca), Cn(x, cb)) == k : Nat}) -> {Cn(x, M.merge(sa, sb)) == k : Nat}:
  Equal.trans(Nat, Cn(x, M.merge(sa, sb)), Nat.add(Cn(x, sa), Cn(x, sb)), k,
    merge_count(sa, sb, x),
    Equal.trans(Nat, Nat.add(Cn(x, sa), Cn(x, sb)), Nat.add(Cn(x, ca), Cn(x, cb)), k, add_cong(Cn(x, sa), Cn(x, ca), Cn(x, sb), Cn(x, cb), e1, e2), e3))

def sortF_count(+n: Nat, +xs: List<&2, Nat>, +x: Nat) -> {Cn(x, M.sortF(n, xs)) == Cn(x, xs) : Nat}:
  match n:
    case 0n:
      isort_count(xs, x)
    case 1n+p:
      match xs:
        case Nil{}:
          {==}
        case Con{h, t}:
          match t:
            case Nil{}:
              {==}
            case Con{h2, r}:
              ms_count(x, M.sortF(p, M.half(xs, True{})), M.sortF(p, M.half(xs, False{})), M.half(xs, True{}), M.half(xs, False{}), Cn(x, xs),
                sortF_count(p, M.half(xs, True{}), x), sortF_count(p, M.half(xs, False{}), x), half_count(xs, x))

def Laws.sort_perm(x, xs):
  sortF_count(List.length(&2, Nat, xs), xs, x)

type SPair<-A: Data, -B: Data> is Data:
  SP{fst: A, snd: B}

def Srt(lo: Nat, xs: List<&2, Nat>) -> Data:
  match xs:
    case Nil{}:
      Unit
    case Con{h, t}:
      SPair<Laws.Spec.LE(lo, h), Srt(h, t)>

def Bool.disc(b: Bool) -> Type:
  match b:
    case False{}:
      Empty
    case True{}:
      Unit

def true_false(e: {True{} == False{} : Bool}) -> Empty:
  %e : Bool.disc(_)
  Unit{}

def le_true(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == True{} : Bool}) -> Laws.Spec.LE(a, b):
  match a b:
    case 0n b0:
      Unit{}
    case 1n+a1 0n:
      Empty.absurd(Empty, true_false(Equal.sym(Bool, Nat.is_le(1n+a1, 0n), True{}, e)))
    case 1n+a1 1n+b1:
      le_true(a1, b1, e)

def le_false(+a: Nat, +b: Nat, e: {Nat.is_le(a, b) == False{} : Bool}) -> Laws.Spec.LE(b, a):
  match a b:
    case 0n 0n:
      Empty.absurd(Unit, true_false(e))
    case 0n 1n+b1:
      Empty.absurd(Empty, true_false(e))
    case 1n+a1 0n:
      Unit{}
    case 1n+a1 1n+b1:
      le_false(a1, b1, e)

def pick_sorted(+lo: Nat, +a: Nat, +b: Nat, r1: List<&2, Nat>, r2: List<&2, Nat>, c: Bool,
    e: {Nat.is_le(a, b) == c : Bool}, la: Laws.Spec.LE(lo, a), lb: Laws.Spec.LE(lo, b),
    h1: Laws.Spec.LE(a, b) -> Srt(a, r1), h2: Laws.Spec.LE(b, a) -> Srt(b, r2)) -> Srt(lo, M.pick(c, a, b, r1, r2)):
  match c:
    case True{}:
      SP{la, h1(le_true(a, b, e))}
    case False{}:
      SP{lb, h2(le_false(a, b, e))}

def merge_sorted(+xs: List<&2, Nat>, +ys: List<&2, Nat>, +lo: Nat, +sx: Srt(lo, xs), +sy: Srt(lo, ys)) -> Srt(lo, M.merge(xs, ys)):
  match xs:
    case Nil{}:
      sy
    case Con{a, at}:
      match ys:
        case Nil{}:
          sx
        case Con{b, bs}:
          SP{la, sa} = sx
          SP{lb, sb} = sy
          pick_sorted(lo, a, b, M.merge(at, ys), M.merge(xs, bs), Nat.is_le(a, b), {==}, la, lb,
            leab => merge_sorted(at, ys, a, sa, SP{leab, sb}),
            leba => merge_sorted(xs, bs, b, SP{leba, sa}, sb))

def isort_sorted(+xs: List<&2, Nat>) -> Srt(0n, M.isort(xs)):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      merge_sorted(Con{h, Nil{}}, M.isort(t), 0n, SP{Unit{}, Unit{}}, isort_sorted(t))

def sortF_sorted(+n: Nat, +xs: List<&2, Nat>) -> Srt(0n, M.sortF(n, xs)):
  match n:
    case 0n:
      isort_sorted(xs)
    case 1n+p:
      match xs:
        case Nil{}:
          Unit{}
        case Con{h, t}:
          match t:
            case Nil{}:
              SP{Unit{}, Unit{}}
            case Con{h2, r}:
              merge_sorted(M.sortF(p, M.half(xs, True{})), M.sortF(p, M.half(xs, False{})), 0n,
                sortF_sorted(p, M.half(xs, True{})), sortF_sorted(p, M.half(xs, False{})))

def srt_to_spec(+xs: List<&2, Nat>, +lo: Nat, +s: Srt(lo, xs)) -> Laws.Spec.Sorted.from(lo, xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      SP{l, s2} = s
      (l, srt_to_spec(t, h, s2))

def Laws.sort_sorted(xs):
  srt_to_spec(M.sort(xs), 0n, sortF_sorted(List.length(&2, Nat, xs), xs))
