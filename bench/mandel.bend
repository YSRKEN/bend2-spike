# マンデルブロ集合の脱出時間を全画素で数え、その合計を出す。
# 画像は 4 分木で 4^7 = 16384 枚のタイルに分け（GPU の 1 レーンに 1 枚）、
# タイルの中は平らなループで画素を回す。`bend guide shaders` の勧める形。
#   bend mandel.bend -o mandel && ./mandel 256         # GPU があれば GPU で。引数は反復の回数
#   ./mandel 256 --gpu off --threads 4                  # CPU の 4 スレッドで
import Base

# 画像の一辺の画素数の半分（一辺は 4096）
def half() -> U32:
  2048

# タイルの一辺の画素数。4096 / 2^7
def tile() -> Nat:
  32n

# 1 画素あたりの反復の回数。第 1 引数で変えられる（既定 256）
def iters.read(m: Maybe<&2, U32>) -> Nat:
  match m:
    case Some{n}:
      U32.to_nat(n)
    case None{}:
      256n

def iters(args: List<String>) -> Nat:
  match args:
    case Con{_, Con{a, _}}:
      iters.read(U32.read(a))
    case _:
      256n

def b2u(c: Bool) -> U32:
  match c:
    case True{}:
      1
    case False{}:
      0

# z <- z^2 + c を k 回まわし、|z|^2 < 4 だった回数を n に足す。
# |z| は一度 2 を超えると増え続けるので、この回数は脱出時間と同じになる。
# 途中で抜けないので、どの画素も同じ手数で終わる（GPU のレーンが揃う）。
def orbit(k: Nat, +cx: F32, +cy: F32, +x: F32, +y: F32, +n: U32) -> U32:
  match k:
    case 0n:
      n
    case 1n+p:
      +xx = (x * x : F32)
      +yy = (y * y : F32)
      nx = ((xx - yy : F32) + cx : F32)
      ny = (((2.0 * x : F32) * y : F32) + cy : F32)
      orbit(p, cx, cy, nx, ny, (n + b2u(F32.is_lt((xx + yy : F32), 4.0)) : U32))

# 画素 (px, py) を複素平面の [-2, 1] x [-1.5, 1.5] に写して数える
def pixel(+px: U32, +py: U32, +k: Nat) -> U32:
  +s = (3.0 / U32.to_f32((half() + half() : U32)) : F32)
  cx = ((U32.to_f32(px) * s : F32) - 2.0 : F32)
  cy = ((U32.to_f32(py) * s : F32) - 1.5 : F32)
  orbit(k, cx, cy, 0.0, 0.0, 0)

# 行 py の、x から k 画素ぶん
def row(k: Nat, +py: U32, +x: U32, +it: Nat, +acc: U32) -> U32:
  match k:
    case 0n:
      acc
    case 1n+p:
      row(p, py, (x + 1 : U32), it, (acc + pixel(x, py, it) : U32))

# タイルの k 行ぶん
def rows(k: Nat, +x0: U32, +y: U32, +it: Nat, +acc: U32) -> U32:
  match k:
    case 0n:
      acc
    case 1n+p:
      rows(p, x0, (y + 1 : U32), it, row(tile(), y, x0, it, acc))

# 左上 (x, y)、一辺 2h の正方形を 4 つに割って並列に数える
def quad(d: Nat, +x: U32, +y: U32, +h: U32, +it: Nat) -> U32:
  match d:
    case 0n:
      rows(tile(), x, y, it, 0)
    case 1n++p:
      +q = U32.shr(h)
      +xh = (x + h : U32)
      +yh = (y + h : U32)
      a b c e = quad(p, x, y, q, it) quad(p, xh, y, q, it) quad(p, x, yh, q, it) quad(p, xh, yh, q, it)
      (((a + b : U32) + c : U32) + e : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(U32.show(quad!(7n, 0, 0, half(), iters(args))))
