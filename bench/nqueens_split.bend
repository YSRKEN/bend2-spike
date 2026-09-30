# N クイーンの解の数を、仕事を均等に割って数える版。nqueens.bend と比べるためのもの。
# 最初の 2 行の置き方（N * N 通り）を 256 枚の葉に割り当て、深さ 8 の均等な二分木で並列に配る。
# 葉の中は並列にせず、逐次に数える（C 版 nqueens.c と同じ割り方）。
#   bend nqueens_split.bend -o nqueens_split && ./nqueens_split 12    # 引数は N（既定 12、16 まで）
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

# nqueens.bend の go と同じ数え方を、並列にせずに行う
def seq(+k: Nat, c: Nat, ok: Bool, +n: Nat, +cols: U32, +l: U32, +r: U32) -> U32:
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
      +a = seq(p, n, okat(n, ((nc .|. nl : U32) .|. nr : U32)), n, nc, nl, nr)
      (a + seq(k, q, okat(q, m), n, cols, l, r) : U32)
    case 1n+p 1n++q False{}:
      +m = ((cols .|. l : U32) .|. r : U32)
      seq(k, q, okat(q, m), n, cols, l, r)

# 1 行目に b0、2 行目に b1 を置いた局面から、残りの行を数える。2 つがぶつかるなら 0
def pair.go(ok: Bool, +n: Nat, +b0: U32, +b1: U32) -> U32:
  match ok:
    case False{}:
      0
    case True{}:
      +cols = (b0 .|. b1 : U32)
      +l = U32.shl((U32.shl(b0) .|. b1 : U32))
      +r = U32.shr((U32.shr(b0) .|. b1 : U32))
      +k = Nat.sub(n, 2n)
      seq(k, n, okat(n, ((cols .|. l : U32) .|. r : U32)), n, cols, l, r)

def pair(+n: Nat, +b0: U32, +b1: U32) -> U32:
  +hit = ((b0 .|. U32.shl(b0) : U32) .|. U32.shr(b0) : U32)
  pair.go(U32.is_eq((hit .&. b1 : U32), 0), n, b0, b1)

# 葉 i が受け持つのは、1 行目を列 i / N、2 行目を列 i % N に置いた局面。i が N * N 以上なら仕事は無い
def leaf.go(ok: Bool, +n: Nat, +i: U32) -> U32:
  match ok:
    case False{}:
      0
    case True{}:
      +nu = U32.from_nat(n)
      pair(n, (1 << U32.to_nat(U32.div(i, nu)) : U32), (1 << U32.to_nat(U32.mod(i, nu)) : U32))

def leaf(+n: Nat, +i: U32) -> U32:
  +nu = U32.from_nat(n)
  leaf.go(U32.is_lt(i, (nu * nu : U32)), n, i)

# 深さ d の均等な二分木。葉の番号は、根から左を 0、右を 1 と読んだ 2 進数
def split(d: Nat, +n: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      leaf(n, i)
    case 1n++p:
      +j = U32.shl(i)
      a e = split(p, n, j) split(p, n, (j + 1 : U32))
      (a + e : U32)

def solve(+n: Nat) -> U32:
  split!(8n, n, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(U32.show(solve(size(args))))
