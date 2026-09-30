# ブラウザで描く mandelbrot の、画素ひとつぶんの計算。
# bench/mandel.bend の orbit と同じ式で、座標は JS の側で計算して渡す。
#   bend web/index.html -o web/dist    # ページと、この .bend をまとめて 1 つの JS にする
import Base

def b2u(c: Bool) -> U32:
  match c:
    case True{}:
      1
    case False{}:
      0

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

# 点 c = cx + cy i で、k 回のうち |z|^2 < 4 だった回数（脱出時間）
def escape(k: Nat, +cx: F32, +cy: F32) -> U32:
  orbit(k, cx, cy, 0.0, 0.0, 0)
