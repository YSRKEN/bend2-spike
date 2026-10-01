# 題 4: 並列マージソートの実装。
# sort は、入力を half で 2 つ（偶数番目と奇数番目）に分け、parallel let で両方を
# 並列に整列してから merge する。再帰の停止は fuel（入力の長さ）で保証する。
import Base

# xs の偶数番目（take = True）または奇数番目（take = False）の要素を取り出す
def half(xs: List<&2, Nat>, take: Bool) -> List<&2, Nat>:
  match xs take:
    case Nil{} _:
      Nil{}
    case Con{h, t} True{}:
      h <> half(t, False{})
    case Con{h, t} False{}:
      half(t, True{})

# le に応じて、x か y を先頭に置き、残りの merge は遅延した方だけを続ける
def merge.pick(
  le: Bool, x: Nat, ka: Unit -> List<&2, Nat>, y: Nat, kb: Unit -> List<&2, Nat>
) -> List<&2, Nat>:
  match le:
    case True{}:
      x <> ka(Unit{})
    case False{}:
      y <> kb(Unit{})

# 整列済みの 2 つのリストを 1 つの整列済みリストにまとめる
def merge(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs ys:
    case Nil{} _:
      ys
    case Con{x, xt} Nil{}:
      xs
    case Con{+x, xt} Con{+y, yt}:
      merge.pick(Nat.is_le(x, y), x, u => merge(xt, ys), y, u => merge(xs, yt))

# fuel が尽きたら入力をそのまま返す。sort は fuel に入力の長さを渡すので尽きない
def sort.go(+fuel: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match fuel:
    case 0n:
      xs
    case 1n+f:
      match xs:
        case Nil{}:
          Nil{}
        case Con{h, Nil{}}:
          [h]
        case Con{h, Con{h2, t}}:
          a b = sort.go(f, half(xs, True{})) sort.go(f, half(xs, False{}))
          merge(a, b)

def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  sort.go(List.length(&2, Nat, xs), xs)
