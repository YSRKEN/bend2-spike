# 並列マージソート: 2^d 個の Nat を葉に持つ完全二分木を、左右の部分木を
# parallel let で並列に整列してリストにし、merge で 1 本にまとめる。
# LAWS.bend が「出力は整列済み」「各値の個数が入力と等しい」を述べ、
# PROOF.bend がそれを証明する。main は 2^16 個の逆順の入力を整列し、
# 結果が 0, 1, ..., 2^16 - 1 になったかを出力する。
#
#   bend main.bend -o sort && ./sort

import Base

# 木
# --

# 深さ 0 は葉（Nat 1 個）、それより深ければ同じ深さの部分木 2 つの組
# （pure_par_sort の Tree(d) と同じ形。出典: Bend 2 公式 demo pure_par_sort, Apache-2.0）
def Tree(d: Nat) -> Data:
  match d:
    case 0n:
      Nat
    case 1n+p:
      Sigma<&2, &2, Tree(p), _ => Tree(p)>

# 葉を左から順に並べたリスト（仕様で入力の中身を述べるのに使う）
def leaves(d: Nat, t: Tree(d)) -> List<&2, Nat>:
  match d:
    case 0n:
      [t]
    case 1n++p:
      (x, y) = t
      List.append(&2, Nat, leaves(p, x), leaves(p, y))

# 順序
# ----
# LE は公式 demo proof_insertion_sort からの書き写し（Apache-2.0）。比較そのものは
# Base の Nat.is_le（Bool を返す）で行い、LE は仕様と証明の側だけで使う。

# LE(a, b) は a <= b の証明の型。成り立てば Unit、成り立たなければ Empty
def LE(a: Nat, b: Nat) -> Data:
  match a b:
    case 0n b0:
      Unit
    case 1n+a1 0n:
      Empty
    case 1n+a1 1n+b1:
      LE(a1, b1)

# 整列
# ----

# 判定 c に従って k1 か k2 の一方だけを呼ぶ。計算した値は match できないので、
# 判定を引数に受けるこの関数で分岐する。両方の枝をあらかじめ計算してしまわない
# よう、枝は関数として受け取る
def branch(-A: Type, c: Bool, k1: Unit -> A, k2: Unit -> A) -> A:
  match c:
    case True{}:
      k1(Unit{})
    case False{}:
      k2(Unit{})

# 整列済みの 2 本を 1 本にまとめる。再帰のたびにどちらかのリストが 1 つ短くなる
def merge(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs ys:
    case Nil{} ys:
      ys
    case +x <> xt Nil{}:
      x <> xt
    case +x <> xt +y <> yt:
      branch(List<&2, Nat>, Nat.is_le(x, y),
        u => x <> merge(xt, y <> yt),
        u => y <> merge(x <> xt, yt))

# 左右の部分木を並列に整列し（parallel let）、結果をまとめる
def sort(d: Nat, t: Tree(d)) -> List<&2, Nat>:
  match d:
    case 0n:
      [t]
    case 1n++p:
      (x, y) = t
      a b = sort(p, x) sort(p, y)
      merge(a, b)

# 仕様: 整列済みと個数
# ------------------
# Sorted.from・Sorted・bump・count は proof_insertion_sort と同じ定義（Apache-2.0）

# Sorted.from(lo, xs): どの要素も lo 以上で、リストは昇順
def Sorted.from(lo: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case h <> t:
      (LE(lo, h) & Sorted.from(h, t))

def Sorted(xs: List<&2, Nat>) -> Type:
  Sorted.from(0n, xs)

# b が真なら n + 1
def bump(b: Bool, n: Nat) -> Nat:
  match b:
    case True{}:
      1n+n
    case False{}:
      n

# xs の中に x が何回現れるか
def count(+x: Nat, xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      bump(Cmp.is_eq(Nat.cmp(x, h)), count(x, t))

# 実行
# ----

# 数 i*2^d .. i*2^d + 2^d - 1 を降順に並べた木（入力は逆順になる）
def gen(d: Nat, +i: Nat) -> Tree(d):
  match d:
    case 0n:
      i
    case 1n++p:
      a b = gen(p, 1n+Nat.double(i)) gen(p, Nat.double(i))
      (a, b)

# xs が i, i+1, i+2, ... と 1 ずつ増える列か
def ascending_from(xs: List<&2, Nat>, +i: Nat) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> t:
      Bool.and(Nat.is_eq(h, i), ascending_from(t, 1n+i))

# 整列した結果が、ちょうど 0, 1, ..., 2^d - 1 か
def check(+d: Nat) -> Bool:
  +out = sort(d, gen(d, 0n))
  Bool.and(ascending_from(out, 0n), Nat.is_eq(List.length(&2, Nat, out), Nat.pow(2n, d)))

def verdict(ok: Bool) -> String:
  match ok:
    case True{}:
      "sorted"
    case False{}:
      "unsorted"

def main() -> IO(Unit):
  IO.print(verdict(check(16n)))
