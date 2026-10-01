# 題 2: 空でないリストの最大値。main.bend に max を書き、PROOF.bend で次の法則を証明する。
# リストは「先頭 x と残り xs」で渡す（空のリストは渡らない）。このファイルは人が書いた仕様。変えてはいけない。
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

# xs のどの要素も m 以下
def Spec.All(+m: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case Con{h, t}:
      (Spec.LE(h, m) & Spec.All(m, t))

# m は xs の要素の一つ
def Spec.Elem(+m: Nat, xs: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Empty
    case Con{h, t}:
      Or({m == h : Nat}, Spec.Elem(m, t))

# 法則: 結果は、どの要素以上でもある
law max_upper:
  for +x: Nat
  for +xs: List<&2, Nat>
  Spec.All(M.max(x, xs), x <> xs)

# 法則: 結果は、リストの要素の一つである
law max_elem:
  for +x: Nat
  for +xs: List<&2, Nat>
  Spec.Elem(M.max(x, xs), x <> xs)
