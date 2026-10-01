import Base

# split_pair: helper to extract pair and continue
def split_pair(h: Nat, h2: Nat, rest: List<&2, Nat> & List<&2, Nat>) -> List<&2, Nat> & List<&2, Nat>:
  (l, r) = rest
  (Con{h, l}, Con{h2, r})

# split_go: recursive helper for split
def split_go(+xs: List<&2, Nat>) -> List<&2, Nat> & List<&2, Nat>:
  match xs:
    case Nil{}:
      (Nil{}, Nil{})
    case Con{h, Nil{}}:
      (Con{h, Nil{}}, Nil{})
    case Con{h, Con{h2, t2}}:
      split_pair(h, h2, split_go(t2))

# split: divide list into two halves
def split(+xs: List<&2, Nat>) -> List<&2, Nat> & List<&2, Nat>:
  split_go(xs)

# is_le: compare a <= b
def is_le(a: Nat, b: Nat) -> Bool:
  match a:
    case 0n:
      True{}
    case 1n+a1:
      match b:
        case 0n:
          False{}
        case 1n+b1:
          is_le(a1, b1)

# merge_cmp: merge after computing comparison
def merge_cmp(x: Nat, +xt: List<&2, Nat>, y: Nat, +yt: List<&2, Nat>, le_xy: Bool) -> List<&2, Nat>:
  match le_xy:
    case True{}:
      Con{x, merge(xt, Con{y, yt})}
    case False{}:
      Con{y, merge(Con{x, xt}, yt)}

# merge: merge two sorted lists
def merge(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      ys
    case Con{x, xt}:
      match ys:
        case Nil{}:
          xs
        case Con{y, yt}:
          merge_cmp(x, xt, y, yt, is_le(x, y))

# sort_continue_with_split: continue sort after extracting from split result
def sort_continue_with_split(st: List<&2, Nat> & List<&2, Nat>) -> List<&2, Nat>:
  (l, r) = st
  a b = sort(l) sort(r)
  merge(a, b)

# sort: merge sort with parallel split
def sort(+xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, Nil{}}:
      Con{h, Nil{}}
    case Con{h, Con{h2, t}}:
      sort_continue_with_split(split(Con{h, Con{h2, t}}))