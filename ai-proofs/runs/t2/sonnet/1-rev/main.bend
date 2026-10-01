import Base

def rev_go(xs: List<&2, Nat>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      rev_go(t, Con{h, acc})

def rev(xs: List<&2, Nat>) -> List<&2, Nat>:
  rev_go(xs, Nil{})
