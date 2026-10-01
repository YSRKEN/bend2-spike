import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# rev_go(rev_go(xs, ys), Nil) == rev_go(ys, xs)
law go_go:
  for +xs: List<&2, Nat>
  for +ys: List<&2, Nat>
  {M.rev_go(M.rev_go(xs, ys), Nil{}) == M.rev_go(ys, xs) : List<&2, Nat>}

def go_go(xs, ys):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      go_go(t, Con{h, ys})

def Laws.rev_rev(xs):
  go_go(xs, Nil{})

law add_succ_r:
  for +a: Nat
  for +n: Nat
  {Nat.add(a, 1n+n) == 1n+Nat.add(a, n) : Nat}

def add_succ_r(a, n):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ_r(p, n) : {1n+Nat.add(p, 1n+n) == 1n+_ : Nat}
      {==}

# len(rev_go(xs, acc)) == add(len xs, len acc)
law len_go:
  for +xs: List<&2, Nat>
  for +acc: List<&2, Nat>
  {Laws.Spec.len(M.rev_go(xs, acc)) == Nat.add(Laws.Spec.len(xs), Laws.Spec.len(acc)) : Nat}

def len_go(xs, acc):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %add_succ_r(Laws.Spec.len(t), Laws.Spec.len(acc)) : {Laws.Spec.len(M.rev_go(t, Con{h, acc})) == _ : Nat}
      len_go(t, Con{h, acc})

law add_zero_r:
  for +a: Nat
  {Nat.add(a, 0n) == a : Nat}

def add_zero_r(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero_r(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def Laws.rev_len(xs):
  %add_zero_r(Laws.Spec.len(xs)) : {Laws.Spec.len(M.rev_go(xs, Nil{})) == _ : Nat}
  len_go(xs, Nil{})
