import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# 補題: 累積引数つきの反転を 2 回かけると、累積に xs を積み替えた結果になる
law rev_go_go:
  for +xs: List<&2, Nat>
  for +acc: List<&2, Nat>
  {M.rev.go(M.rev.go(xs, acc), Nil{}) == M.rev.go(acc, xs) : List<&2, Nat>}

def rev_go_go(xs, acc):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      rev_go_go(t, Con{h, acc})

# 補題: a + 0 = a
law add_zero:
  for +a: Nat
  {Nat.add(a, 0n) == a : Nat}

def add_zero(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

# 補題: a + (1 + b) = 1 + (a + b)
law add_succ:
  for +a: Nat
  for +b: Nat
  {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}

def add_succ(a, b):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

# 補題: 累積引数つきの反転の長さは、二つの長さの和
law len_go:
  for +xs: List<&2, Nat>
  for +acc: List<&2, Nat>
  {Laws.Spec.len(M.rev.go(xs, acc)) == Nat.add(Laws.Spec.len(xs), Laws.Spec.len(acc)) : Nat}

def len_go(xs, acc):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %add_succ(Laws.Spec.len(t), Laws.Spec.len(acc)) : {Laws.Spec.len(M.rev.go(t, Con{h, acc})) == _ : Nat}
      len_go(t, Con{h, acc})

def Laws.rev_rev(xs):
  rev_go_go(xs, Nil{})

def Laws.rev_len(xs):
  %add_zero(Laws.Spec.len(xs)) : {Laws.Spec.len(M.rev.go(xs, Nil{})) == _ : Nat}
  len_go(xs, Nil{})
