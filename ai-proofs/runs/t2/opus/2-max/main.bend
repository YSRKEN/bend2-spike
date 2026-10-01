# 題 2 の実装: 空でないリスト（先頭 x と残り xs）の最大値。
import Base

# 残りのリストを畳み込み、ここまでの最大値 acc を Nat.max で更新する
def max.go(xs: List<&2, Nat>, +acc: Nat) -> Nat:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      max.go(t, Nat.max(acc, h))

# 空でないリスト x <> xs の最大値
def max(+x: Nat, xs: List<&2, Nat>) -> Nat:
  max.go(xs, x)
