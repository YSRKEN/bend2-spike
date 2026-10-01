import Base

# リストの最大値をアキュムレータと一緒に計算
# xs: 処理するリスト
# acc: 現在のアキュムレータ（最大値）
def max_acc(xs: List<&2, Nat>, +acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      new_acc = Nat.max(acc, h)
      max_acc(t, new_acc)

# 空でないリストの最大値を計算する
# x: 先頭要素
# xs: 残りの要素
def max(x: Nat, xs: List<&2, Nat>) -> Nat:
  max_acc(xs, x)
