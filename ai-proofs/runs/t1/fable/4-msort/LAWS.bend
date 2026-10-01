# 題 4: 並列マージソート。main.bend に sort を書き、PROOF.bend で次の法則を証明する。
# sort はリストを 2 つに分け、両方を parallel let（a b = sort(..) sort(..)）で並列に整列してからマージすること。
# このファイルは人が書いた仕様。変えてはいけない。
import Base
import ./main.bend as M

# a <= b の証明の型。成り立てば Unit、成り立たなければ Empty
def Spec.LE(a: Nat, b: Nat) -> Data:
  match a b:
    case 0n b0:
      Unit
    case 1n+a1 0n:
      Empty
    case 1n+a1 1n+b1:
      Spec.LE(a1, b1)

# どの要素も lo 以上で、昇順に並んでいる
def Spec.Sorted.from(lo: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case Con{h, t}:
      (Spec.LE(lo, h) & Spec.Sorted.from(h, t))

def Spec.Sorted(xs: List<&2, Nat>) -> Type:
  Spec.Sorted.from(0n, xs)

# b が成り立てば n + 1、でなければ n
def Spec.bump(b: Bool, n: Nat) -> Nat:
  match b:
    case True{}:
      1n+n
    case False{}:
      n

# xs の中の x の個数
def Spec.count(+x: Nat, xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case Con{h, t}:
      Spec.bump(Nat.is_eq(x, h), Spec.count(x, t))

# 法則: 出力は昇順に並んでいる
law sort_sorted:
  for +xs: List<&2, Nat>
  Spec.Sorted(M.sort(xs))

# 法則: どの値も、出力の中に入力と同じ個数だけ現れる（並べ替えである）
law sort_perm:
  for +x: Nat
  for +xs: List<&2, Nat>
  {Spec.count(x, M.sort(xs)) == Spec.count(x, xs) : Nat}
