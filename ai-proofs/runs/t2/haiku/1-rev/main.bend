import Base

def rev_acc(xs: List<&2, Nat>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      rev_acc(t, Con{h, acc})

def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  rev_acc(xs, Nil{})

# 補助: Nil を cons リストに追加
def cons_nil(xs: List<&2, Nat>) -> List<&2, Nat>:
  xs

# 補助: リストを cons で結合
def append(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, append(t, ys)}
