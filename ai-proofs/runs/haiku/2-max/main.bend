import Base

# 蓄積変数を用いた補助関数（パラメータ順序を調整）
def max_acc(xs: List<&2, Nat>, acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      max_acc(t, Nat.max(acc, h))

# 空でないリスト (先頭 x と残り xs) の最大値を返す
def max(x: Nat, xs: List<&2, Nat>) -> Nat:
  max_acc(xs, x)
