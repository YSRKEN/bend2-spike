# 公式のレイトレーサー（fly.bend。bash fetch.sh で取ってくる）を、画面を出さずに k コマ描いて、
# 全コマの全画素の色の合計を出す。CPU（--gpu off）と GPU で同じ絵になったかの照合と、1 コマの時間の計測に使う。
# 右矢印キーを押したままにした状態から始めるので、コマごとにカメラが回る。
#   bend frames.bend -o frames && ./frames 10 --gpu off      # 10 コマを CPU で（描くのは 11 コマ）
#   ./frames 10 drop --gpu off                                # 絵を合計せずに捨てる
import Base
import ./fly.bend as F

# 絵の全画素の色の合計（U32 で桁あふれさせる）
def total(img: Image) -> U32:
  match img:
    case Pix{c}:
      c
    case Qua{a, b, c, d}:
      (((total(a) + total(b) : U32) + total(c) : U32) + total(d) : U32)

# 絵を合計せずに捨てる版。公式の App.turn と同じく、GPU の上で捨てる（Image.drop!）。
# CPU が絵を読み出す分を除いた、描くだけの時間を見るためのもの
def run.drop(k: Nat, shown: F.Fly & Image) -> U32:
  match k:
    case 0n:
      0
    case 1n+p:
      (s, img) = shown
      _ = Image.drop!(img)
      run.drop(p, F.Fly.view(F.Fly.step(s)))

# 1 コマ描いた結果（状態と絵の組）を受けて、絵の合計を足し、次のコマへ進める
def run(k: Nat, shown: F.Fly & Image, acc: U32) -> U32:
  match k:
    case 0n:
      acc
    case 1n+p:
      (s, img) = shown
      +acc2 = (acc + total(img) : U32)
      run(p, F.Fly.view(F.Fly.step(s)), acc2)

def start(m: Maybe<F.Fly>) -> F.Fly:
  match m:
    case Some{s}:
      s
    case None{}:
      F.Fly.init()

def frames.read(m: Maybe<&2, U32>) -> Nat:
  match m:
    case Some{n}:
      U32.to_nat(n)
    case None{}:
      1n

def go.pick(k: Nat, drop: Bool, shown: F.Fly & Image) -> U32:
  match drop:
    case True{}:
      run.drop(k, shown)
    case False{}:
      run(k, shown, 0)

# 引数は「コマ数 k」と、任意で「drop」（絵を合計せずに捨てる）
def go(args: List<String>, shown: F.Fly & Image) -> U32:
  match args:
    case Con{_, Con{a, Con{m, _}}}:
      go.pick(frames.read(U32.read(a)), String.eq(m, "drop"), shown)
    case Con{_, Con{a, Nil{}}}:
      run(frames.read(U32.read(a)), shown, 0)
    case _:
      run(1n, shown, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    IO.print(U32.show(go(args, F.Fly.view(start(F.Fly.events([Key{63235, True{}}], F.Fly.init()))))))
