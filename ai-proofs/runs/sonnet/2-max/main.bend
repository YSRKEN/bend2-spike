import Base

# xs を先に取り、x（先頭）と xs の最大値を返す。再帰は xs の縮小で止まる
def go(+xs: List<&2, Nat>, +x: Nat) -> Nat:
  match xs:
    case Nil{}:
      x
    case Con{h, t}:
      Nat.max(x, go(t, h))

# 空でないリスト（先頭 x と残り xs）の最大値
def max(+x: Nat, +xs: List<&2, Nat>) -> Nat:
  go(xs, x)
