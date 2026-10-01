# 題 2: 空でないリストの最大値。
# リストは「先頭 x と残り xs」で受け取る。
import Base

# 残りのリスト ys と先頭 x から最大値を求める。
# 停止性の検査のため、縮む引数（リスト）を先に置く。
def max.go(+ys: List<&2, Nat>, +x: Nat) -> Nat:
  match ys:
    case Nil{}:
      x
    case Con{h, t}:
      Nat.max(x, max.go(t, h))

# 空でないリスト x <> xs の最大値
def max(+x: Nat, +xs: List<&2, Nat>) -> Nat:
  max.go(xs, x)
