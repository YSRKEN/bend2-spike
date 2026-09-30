# N クイーンの解の数を数える。列と 2 本の斜めの利きをビットで持つ、よくある形。
# 候補の列ごとに「置いた場合」と「次の列を試す場合」を並列に分けるので、
# 枝の重さが揃わない（ガイドが GPU より CPU が速いとする、分岐の多い仕事の例）。
#   bend nqueens.bend -o nqueens && ./nqueens 12        # 引数は N（既定 12、16 まで）
import Base

def size.read(m: Maybe<&2, U32>) -> Nat:
  match m:
    case Some{n}:
      U32.to_nat(n)
    case None{}:
      12n

def size(args: List<String>) -> Nat:
  match args:
    case Con{_, Con{a, _}}:
      size.read(U32.read(a))
    case _:
      12n

# 列 c - 1 が利き m に掛かっていないか。c = 0 なら試す列が無いので False
def okat(c: Nat, +m: U32) -> Bool:
  match c:
    case 0n:
      False{}
    case 1n+q:
      U32.is_eq((m .&. (1 << q : U32) : U32), 0)

def b2u(c: Bool) -> U32:
  match c:
    case True{}:
      1
    case False{}:
      0

# k: 残りの行数。c: この行でまだ試していない列の数（次に試すのは列 c - 1）。
# ok: 列 c - 1 に置けるか。cols・l・r: 列と 2 本の斜めの利き。
def go(+k: Nat, c: Nat, ok: Bool, +n: Nat, +cols: U32, +l: U32, +r: U32) -> U32:
  match k c ok:
    case 0n _ _:
      1
    case 1n+p 0n _:
      0
    case 1n+p 1n++q True{}:
      +b = (1 << q : U32)
      +nc = (cols .|. b : U32)
      +nl = U32.shl((l .|. b : U32))
      +nr = U32.shr((r .|. b : U32))
      +m = ((cols .|. l : U32) .|. r : U32)
      a e = go(p, n, okat(n, ((nc .|. nl : U32) .|. nr : U32)), n, nc, nl, nr) go(k, q, okat(q, m), n, cols, l, r)
      (a + e : U32)
    case 1n+p 1n++q False{}:
      +m = ((cols .|. l : U32) .|. r : U32)
      go(k, q, okat(q, m), n, cols, l, r)

def solve(+n: Nat) -> U32:
  go!(n, n, okat(n, 0), n, 0, 0, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(U32.show(solve(size(args))))
