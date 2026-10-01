# 題 3: 連長圧縮（run-length encoding）。main.bend に encode を書き、PROOF.bend で次の法則を証明する。
# encode は Nat のリストを「(値, 個数)」の組（Sigma<&2, &2, Nat, _ => Nat>）のリストにする。例: [5, 5, 7] → [(5, 2), (7, 1)]
# このファイルは人が書いた仕様。変えてはいけない。
import Base
import ./main.bend as M

# x を n 個並べてから rest を続ける
def Spec.rep(n: Nat, +x: Nat, rest: List<&2, Nat>) -> List<&2, Nat>:
  match n:
    case 0n:
      rest
    case 1n+p:
      x <> Spec.rep(p, x, rest)

# 組のリストを元に戻す
def Spec.decode(ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> List<&2, Nat>:
  match ps:
    case Nil{}:
      Nil{}
    case Con{p, t}:
      (x, n) = p
      Spec.rep(n, x, Spec.decode(t))

# 個数は 1 以上
def Spec.Pos(n: Nat) -> Type:
  match n:
    case 0n:
      Empty
    case 1n+p:
      Unit

# 次の組の値は x と異なる（次が無ければ何も要らない）
def Spec.Diff(+x: Nat, ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> Type:
  match ps:
    case Nil{}:
      Unit
    case Con{q, t}:
      (y, m) = q
      {x != y : Nat}

# 正規形: どの組も個数が 1 以上で、隣り合う組の値が異なる
def Spec.Runs(ps: List<&2, Sigma<&2, &2, Nat, _ => Nat>>) -> Type:
  match ps:
    case Nil{}:
      Unit
    case Con{p, +t}:
      (x, n) = p
      (Spec.Pos(n) & (Spec.Diff(x, t) & Spec.Runs(t)))

# 法則: 展開すると元に戻る
law rle_roundtrip:
  for +xs: List<&2, Nat>
  {Spec.decode(M.encode(xs)) == xs : List<&2, Nat>}

# 法則: 出力は正規形である
law rle_canonical:
  for +xs: List<&2, Nat>
  Spec.Runs(M.encode(xs))
