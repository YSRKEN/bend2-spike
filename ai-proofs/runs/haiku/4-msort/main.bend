import Base

# Simple merge that handles the comparison outside the merge function
@unsafe
def merge_cmp_branch(le: Bool, +xh: Nat, xt: List<&2, Nat>, +yh: Nat, yt: List<&2, Nat>) -> List<&2, Nat>:
  match le:
    case True{}:
      Con{xh, merge(xt, Con{yh, yt})}
    case False{}:
      Con{yh, merge(Con{xh, xt}, yt)}

# Cons every other element starting with h_first
def cons_every_other(xs: List<&2, Nat>, h_first: Nat) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Con{h_first, Nil{}}
    case Con{_, rest}:
      match rest:
        case Nil{}:
          Con{h_first, Nil{}}
        case Con{h_next, rest2}:
          Con{h_first, cons_every_other(rest2, h_next)}

# Merge two sorted lists
def merge(xs: List<&2, Nat>, ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs ys:
    case Nil{} _:
      ys
    case _ Nil{}:
      xs
    case Con{+xh, xt} Con{+yh, yt}:
      merge_cmp_branch(Nat.is_le(xh, yh), xh, xt, yh, yt)

# Sort a list using a simple recursive approach
@unsafe
def sort(xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, Nil{}}:
      Con{h, Nil{}}
    case Con{+h1, Con{+h2, +rest}}:
      # h1 goes to left, h2 goes to right, and we recursively split rest
      l = cons_every_other(rest, h1)
      r = cons_every_other(rest, h2)
      a b = sort(l) sort(r)
      merge(a, b)
