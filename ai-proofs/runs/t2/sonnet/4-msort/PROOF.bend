import Base
import ./LAWS.bend as Laws
import ./main.bend as M

def LE.trans(+a: Nat, +b: Nat, +c: Nat, p: Laws.Spec.LE(a, b), q: Laws.Spec.LE(b, c)) -> Laws.Spec.LE(a, c):
  match a b c:
    case 0n _ _:
      Unit{}
    case 1n+a1 0n _:
      match p:
    case 1n+a1 1n+b1 0n:
      match q:
    case 1n+a1 1n+b1 1n+c1:
      LE.trans(a1, b1, c1, p, q)

# le(a, b) の結果に応じた LE の証拠
def Dec(b: Bool, x: Nat, y: Nat) -> Type:
  match b:
    case True{}:
      Laws.Spec.LE(x, y)
    case False{}:
      Laws.Spec.LE(y, x)

def Dec.succ(+b: Bool, +x: Nat, +y: Nat, d: Dec(b, x, y)) -> Dec(b, 1n+x, 1n+y):
  match b:
    case True{}:
      d
    case False{}:
      d

def le_dec(+a: Nat, +b: Nat) -> Dec(M.le(a, b), a, b):
  match a b:
    case 0n _:
      Unit{}
    case 1n+a1 0n:
      Unit{}
    case 1n+a1 1n+b1:
      Dec.succ(M.le(a1, b1), a1, b1, le_dec(a1, b1))

def dec_true(+x: Nat, +y: Nat, e: {M.le(x, y) == True{} : Bool}) -> Laws.Spec.LE(x, y):
  %e : Dec(_, x, y)
  le_dec(x, y)

def dec_false(+x: Nat, +y: Nat, e: {M.le(x, y) == False{} : Bool}) -> Laws.Spec.LE(y, x):
  %e : Dec(_, x, y)
  le_dec(x, y)

def merge_sorted(+xs: List<&2, Nat>, +ys: List<&2, Nat>, +b: Bool, +lo: Nat, e: {M.hd_le(xs, ys) == b : Bool}, sx: Laws.Spec.Sorted.from(lo, xs), sy: Laws.Spec.Sorted.from(lo, ys)) -> Laws.Spec.Sorted.from(lo, M.merge(xs, ys, b)):
  match xs:
    case Nil{}:
      sy
    case Con{h, t}:
      match ys:
        case Nil{}:
          sx
        case Con{g, u}:
          match b:
            case True{}:
              match sx:
                case (p, r):
                  match sy:
                    case (q, r2):
                      (p, merge_sorted(t, g <> u, M.hd_le(t, g <> u), h, {==}, r, (dec_true(h, g, e), r2)))
            case False{}:
              match sx:
                case (p, r):
                  match sy:
                    case (q, r2):
                      (q, merge_sorted(h <> t, u, M.hd_le(h <> t, u), g, {==}, (dec_false(h, g, e), r), r2))

def mg_sorted(+xs: List<&2, Nat>, +ys: List<&2, Nat>, sx: Laws.Spec.Sorted(xs), sy: Laws.Spec.Sorted(ys)) -> Laws.Spec.Sorted(M.mg(xs, ys)):
  merge_sorted(xs, ys, M.hd_le(xs, ys), 0n, {==}, sx, sy)

def isort_sorted(+xs: List<&2, Nat>) -> Laws.Spec.Sorted(M.isort(xs)):
  match xs:
    case Nil{}:
      Unit{}
    case Con{h, t}:
      mg_sorted(h <> Nil{}, M.isort(t), (Unit{}, Unit{}), isort_sorted(t))

def sort_fuel_sorted(+n: Nat, +xs: List<&2, Nat>) -> Laws.Spec.Sorted(M.sort_fuel(n, xs)):
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
              (Unit{}, Unit{})
            case Con{h2, t2}:
              mg_sorted(M.sort_fuel(p, M.evens(xs)), M.sort_fuel(p, M.odds(xs)), sort_fuel_sorted(p, M.evens(xs)), sort_fuel_sorted(p, M.odds(xs)))

def Laws.sort_sorted(xs):
  sort_fuel_sorted(List.length(&2, Nat, xs), xs)

# ---- 個数の保存 ----

def add_zero(+n: Nat) -> {Nat.add(n, 0n) == n : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def sym(+a: Nat, +b: Nat, e: {a == b : Nat}) -> {b == a : Nat}:
  %e : {_ == a : Nat}
  {==}

def bump_add(+c: Bool, +n: Nat, +m: Nat) -> {Laws.Spec.bump(c, Nat.add(n, m)) == Nat.add(Laws.Spec.bump(c, n), m) : Nat}:
  match c:
    case True{}:
      {==}
    case False{}:
      {==}

def add_bump(+n: Nat, +c: Bool, +m: Nat) -> {Laws.Spec.bump(c, Nat.add(n, m)) == Nat.add(n, Laws.Spec.bump(c, m)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      match c:
        case True{}:
          %add_bump(p, True{}, m) : {1n+1n+Nat.add(p, m) == 1n+_ : Nat}
          {==}
        case False{}:
          %add_bump(p, False{}, m) : {1n+Nat.add(p, m) == 1n+_ : Nat}
          {==}

def count_merge(+x: Nat, +xs: List<&2, Nat>, +ys: List<&2, Nat>, +b: Bool, e: {M.hd_le(xs, ys) == b : Bool}) -> {Laws.Spec.count(x, M.merge(xs, ys, b)) == Nat.add(Laws.Spec.count(x, xs), Laws.Spec.count(x, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      match ys:
        case Nil{}:
          %add_zero(Laws.Spec.count(x, h <> t)) : {_ == Nat.add(Laws.Spec.count(x, h <> t), 0n) : Nat}
          {==}
        case Con{g, u}:
          match b:
            case True{}:
              %bump_add(Nat.is_eq(x, h), Laws.Spec.count(x, t), Laws.Spec.count(x, g <> u)) : {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, M.merge(t, g <> u, M.hd_le(t, g <> u)))) == _ : Nat}
              %count_merge(x, t, g <> u, M.hd_le(t, g <> u), {==}) : {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, M.merge(t, g <> u, M.hd_le(t, g <> u)))) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
              {==}
            case False{}:
              %add_bump(Laws.Spec.count(x, h <> t), Nat.is_eq(x, g), Laws.Spec.count(x, u)) : {Laws.Spec.bump(Nat.is_eq(x, g), Laws.Spec.count(x, M.merge(h <> t, u, M.hd_le(h <> t, u)))) == _ : Nat}
              %count_merge(x, h <> t, u, M.hd_le(h <> t, u), {==}) : {Laws.Spec.bump(Nat.is_eq(x, g), Laws.Spec.count(x, M.merge(h <> t, u, M.hd_le(h <> t, u)))) == Laws.Spec.bump(Nat.is_eq(x, g), _) : Nat}
              {==}

def count_mg(+x: Nat, +xs: List<&2, Nat>, +ys: List<&2, Nat>) -> {Laws.Spec.count(x, M.mg(xs, ys)) == Nat.add(Laws.Spec.count(x, xs), Laws.Spec.count(x, ys)) : Nat}:
  count_merge(x, xs, ys, M.hd_le(xs, ys), {==})

def count_isort(+x: Nat, +xs: List<&2, Nat>) -> {Laws.Spec.count(x, M.isort(xs)) == Laws.Spec.count(x, xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %sym(Laws.Spec.count(x, M.mg(h <> Nil{}, M.isort(t))), Nat.add(Laws.Spec.count(x, h <> Nil{}), Laws.Spec.count(x, M.isort(t))), count_mg(x, h <> Nil{}, M.isort(t))) : {_ == Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, t)) : Nat}
      %bump_add(Nat.is_eq(x, h), 0n, Laws.Spec.count(x, M.isort(t))) : {_ == Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, t)) : Nat}
      %count_isort(x, t) : {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.count(x, M.isort(t))) == Laws.Spec.bump(Nat.is_eq(x, h), _) : Nat}
      {==}

def count_split(+x: Nat, +xs: List<&2, Nat>) -> {Nat.add(Laws.Spec.count(x, M.evens(xs)), Laws.Spec.count(x, M.odds(xs))) == Laws.Spec.count(x, xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      match t:
        case Nil{}:
          add_zero(Laws.Spec.count(x, h <> Nil{}))
        case Con{g, u}:
          %bump_add(Nat.is_eq(x, h), Laws.Spec.count(x, M.evens(u)), Laws.Spec.bump(Nat.is_eq(x, g), Laws.Spec.count(x, M.odds(u)))) : {_ == Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.bump(Nat.is_eq(x, g), Laws.Spec.count(x, u))) : Nat}
          %add_bump(Laws.Spec.count(x, M.evens(u)), Nat.is_eq(x, g), Laws.Spec.count(x, M.odds(u))) : {Laws.Spec.bump(Nat.is_eq(x, h), _) == Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.bump(Nat.is_eq(x, g), Laws.Spec.count(x, u))) : Nat}
          %count_split(x, u) : {Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.bump(Nat.is_eq(x, g), Nat.add(Laws.Spec.count(x, M.evens(u)), Laws.Spec.count(x, M.odds(u))))) == Laws.Spec.bump(Nat.is_eq(x, h), Laws.Spec.bump(Nat.is_eq(x, g), _)) : Nat}
          {==}

def count_sort_fuel(+x: Nat, +n: Nat, +xs: List<&2, Nat>) -> {Laws.Spec.count(x, M.sort_fuel(n, xs)) == Laws.Spec.count(x, xs) : Nat}:
  match n:
    case 0n:
      count_isort(x, xs)
    case 1n+p:
      match xs:
        case Nil{}:
          {==}
        case Con{h, t}:
          match t:
            case Nil{}:
              {==}
            case Con{h2, t2}:
              %sym(Laws.Spec.count(x, M.mg(M.sort_fuel(p, M.evens(xs)), M.sort_fuel(p, M.odds(xs)))), Nat.add(Laws.Spec.count(x, M.sort_fuel(p, M.evens(xs))), Laws.Spec.count(x, M.sort_fuel(p, M.odds(xs)))), count_mg(x, M.sort_fuel(p, M.evens(xs)), M.sort_fuel(p, M.odds(xs)))) : {_ == Laws.Spec.count(x, xs) : Nat}
              %sym(Laws.Spec.count(x, M.sort_fuel(p, M.evens(xs))), Laws.Spec.count(x, M.evens(xs)), count_sort_fuel(x, p, M.evens(xs))) : {Nat.add(_, Laws.Spec.count(x, M.sort_fuel(p, M.odds(xs)))) == Laws.Spec.count(x, xs) : Nat}
              %sym(Laws.Spec.count(x, M.sort_fuel(p, M.odds(xs))), Laws.Spec.count(x, M.odds(xs)), count_sort_fuel(x, p, M.odds(xs))) : {Nat.add(Laws.Spec.count(x, M.evens(xs)), _) == Laws.Spec.count(x, xs) : Nat}
              count_split(x, xs)

def Laws.sort_perm(x, xs):
  count_sort_fuel(x, List.length(&2, Nat, xs), xs)
