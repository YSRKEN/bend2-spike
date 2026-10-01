# 並列マージソートの証明。merge についての 2 つの補題（整列を保つ、個数を
# 足し合わせる）を merge と同じ形の再帰で示し、sort の法則は木の深さについての
# 帰納法で、左右の帰納法の仮定を merge の補題に渡して示す。
#
# merge は Nat.is_le の Bool で枝を選ぶ。計算した値は match できないので、補題の
# 側は判定 c を引数に受ける .fin を用意し、そこで c を match する。整列の証明には
# 「c が True なら LE(x, y)、False なら LE(y, x)」という証拠が要るので、それを
# 型 IsLe で表し、Nat.is_le がこの証拠を伴うこと（is_le_ev）を先に示す。

import Base
import ./main.bend as Sort
import ./LAWS.bend as Laws

# 比較の判定と証拠
# ----------------

# 判定 c が x <= y を言い当てていることの証拠の型
def IsLe(c: Bool, x: Nat, y: Nat) -> Type:
  match c:
    case True{}:
      Sort.LE(x, y)
    case False{}:
      Sort.LE(y, x)

# 両方に 1 を足しても証拠はそのまま（LE(1+a, 1+b) は LE(a, b) に簡約される）
def is_le_ev.succ(c: Bool, -a: Nat, -b: Nat) -> IsLe(c, a, b) -> IsLe(c, 1n+a, 1n+b):
  match c:
    case True{}:
      e => e
    case False{}:
      e => e

# Nat.is_le(x, y) は、その判定どおりの証拠を伴う（Nat.cmp と同じく 2 つを同時に減らす）
def is_le_ev(+x: Nat, +y: Nat) -> IsLe(Nat.is_le(x, y), x, y):
  match x y:
    case 0n 0n:
      Unit{}
    case 0n 1n+b:
      Unit{}
    case 1n+a 0n:
      Unit{}
    case 1n+a 1n+b:
      is_le_ev.succ(Nat.is_le(a, b), a, b, is_le_ev(a, b))

# 整列
# ----

# 判定 c ごとに、先頭に来る側の下限の証拠と、残りを merge した結果の整列の
# 証拠を組にする。帰納法の仮定 r1・r2 は、残りの 2 本の整列の証拠を受け取る
def merge_sorted.fin(-lo: Nat, -x: Nat, -xt: List<&2, Nat>, -y: Nat, -yt: List<&2, Nat>,
  sx: Sort.Sorted.from(lo, x <> xt), sy: Sort.Sorted.from(lo, y <> yt),
  r1: Sort.Sorted.from(x, xt) -> Sort.Sorted.from(x, y <> yt) -> Sort.Sorted.from(x, Sort.merge(xt, y <> yt)),
  r2: Sort.Sorted.from(y, x <> xt) -> Sort.Sorted.from(y, yt) -> Sort.Sorted.from(y, Sort.merge(x <> xt, yt)),
  c: Bool)
  -> IsLe(c, x, y) -> Sort.Sorted.from(lo, Sort.branch(List<&2, Nat>, c,
       u => x <> Sort.merge(xt, y <> yt),
       u => y <> Sort.merge(x <> xt, yt))):
  (lx, sxt) = sx
  (ly, syt) = sy
  match c:
    case True{}:
      e => (lx, r1(sxt, (e, syt)))
    case False{}:
      e => (ly, r2((e, sxt), syt))

# 下限 lo 以上で整列済みの 2 本を merge すると、下限 lo 以上で整列済み
def merge_sorted(+xs: List<&2, Nat>, +ys: List<&2, Nat>, -lo: Nat)
  -> Sort.Sorted.from(lo, xs) -> Sort.Sorted.from(lo, ys) -> Sort.Sorted.from(lo, Sort.merge(xs, ys)):
  match xs ys:
    case Nil{} ys:
      sx => sy => sy
    case +x <> xt Nil{}:
      sx => sy => sx
    case +x <> xt +y <> yt:
      sx => sy => merge_sorted.fin(lo, x, xt, y, yt, sx, sy,
        merge_sorted(xt, y <> yt, x),
        merge_sorted(x <> xt, yt, y),
        Nat.is_le(x, y),
        is_le_ev(x, y))

# 葉 1 つのリストは整列済み。それより深い木は、左右の整列済みのリストを merge したもの
def Laws.sort_sorted(d, t):
  match d:
    case 0n:
      (Unit{}, Unit{})
    case 1n++p:
      (+x, +y) = t
      merge_sorted(Sort.sort(p, x), Sort.sort(p, y), 0n)(Laws.sort_sorted(p, x), Laws.sort_sorted(p, y))

# 並べ替え
# --------

# a + 0 = a（server/PROOF.bend と同じ）
def add_zero(a: Nat) -> {Nat.add(a, 0n) == a : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

# a + (1 + b) = 1 + (a + b)
def add_succ(a: Nat, -b: Nat) -> {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

# 足し算の左の項の bump は外へ出せる
def bump_add_l(b: Bool, -n: Nat, -m: Nat) -> {Nat.add(Sort.bump(b, n), m) == Sort.bump(b, Nat.add(n, m)) : Nat}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

# 足し算の右の項の bump も外へ出せる
def bump_add_r(b: Bool, +n: Nat, -m: Nat) -> {Nat.add(n, Sort.bump(b, m)) == Sort.bump(b, Nat.add(n, m)) : Nat}:
  match b:
    case True{}:
      add_succ(n, m)
    case False{}:
      {==}

# 判定 c ごとに、先頭の要素の bump を外へ出してから帰納法の仮定 r1・r2 で書き換える
def count_merge.fin(+z: Nat, +x: Nat, +xt: List<&2, Nat>, +y: Nat, +yt: List<&2, Nat>,
  r1: {Nat.add(Sort.count(z, xt), Sort.count(z, y <> yt)) == Sort.count(z, Sort.merge(xt, y <> yt)) : Nat},
  r2: {Nat.add(Sort.count(z, x <> xt), Sort.count(z, yt)) == Sort.count(z, Sort.merge(x <> xt, yt)) : Nat},
  c: Bool)
  -> {Nat.add(Sort.count(z, x <> xt), Sort.count(z, y <> yt)) == Sort.count(z, Sort.branch(List<&2, Nat>, c,
       u => x <> Sort.merge(xt, y <> yt),
       u => y <> Sort.merge(x <> xt, yt))) : Nat}:
  match c:
    case True{}:
      %r1 : {Nat.add(Sort.count(z, x <> xt), Sort.count(z, y <> yt)) == Sort.bump(Cmp.is_eq(Nat.cmp(z, x)), _) : Nat}
      bump_add_l(Cmp.is_eq(Nat.cmp(z, x)), Sort.count(z, xt), Sort.count(z, y <> yt))
    case False{}:
      %r2 : {Nat.add(Sort.count(z, x <> xt), Sort.count(z, y <> yt)) == Sort.bump(Cmp.is_eq(Nat.cmp(z, y)), _) : Nat}
      bump_add_r(Cmp.is_eq(Nat.cmp(z, y)), Sort.count(z, x <> xt), Sort.count(z, yt))

# merge した結果の中の z の個数は、2 本の中の個数の和
def count_merge(+z: Nat, +xs: List<&2, Nat>, +ys: List<&2, Nat>)
  -> {Nat.add(Sort.count(z, xs), Sort.count(z, ys)) == Sort.count(z, Sort.merge(xs, ys)) : Nat}:
  match xs ys:
    case Nil{} ys:
      {==}
    case +x <> xt Nil{}:
      add_zero(Sort.count(z, x <> xt))
    case +x <> xt +y <> yt:
      count_merge.fin(z, x, xt, y, yt,
        count_merge(z, xt, y <> yt),
        count_merge(z, x <> xt, yt),
        Nat.is_le(x, y))

# つないだリストの中の z の個数は、2 本の中の個数の和
def count_append(+z: Nat, xs: List<&2, Nat>, +ys: List<&2, Nat>)
  -> {Nat.add(Sort.count(z, xs), Sort.count(z, ys)) == Sort.count(z, List.append(&2, Nat, xs, ys)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case +h <> t:
      %count_append(z, t, ys) : {Nat.add(Sort.count(z, h <> t), Sort.count(z, ys)) == Sort.bump(Cmp.is_eq(Nat.cmp(z, h)), _) : Nat}
      bump_add_l(Cmp.is_eq(Nat.cmp(z, h)), Sort.count(z, t), Sort.count(z, ys))

# 深い木では、出力の個数 = 左右の出力の個数の和（count_merge）= 左右の葉の個数の和
# （帰納法の仮定）= 葉を並べたリストの個数（count_append）
def Laws.sort_perm(x, d, t):
  match d:
    case 0n:
      {==}
    case 1n++p:
      (+l, +r) = t
      %count_append(x, Sort.leaves(p, l), Sort.leaves(p, r)) : {Sort.count(x, Sort.merge(Sort.sort(p, l), Sort.sort(p, r))) == _ : Nat}
      %Laws.sort_perm(x, p, l) : {Sort.count(x, Sort.merge(Sort.sort(p, l), Sort.sort(p, r))) == Nat.add(_, Sort.count(x, Sort.leaves(p, r))) : Nat}
      %Laws.sort_perm(x, p, r) : {Sort.count(x, Sort.merge(Sort.sort(p, l), Sort.sort(p, r))) == Nat.add(Sort.count(x, Sort.sort(p, l)), _) : Nat}
      %count_merge(x, Sort.sort(p, l), Sort.sort(p, r)) : {_ == Nat.add(Sort.count(x, Sort.sort(p, l)), Sort.count(x, Sort.sort(p, r))) : Nat}
      {==}
