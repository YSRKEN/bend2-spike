import Base
import ./LAWS.bend as Laws
import ./main.bend as M

# 補題: a + 0 == a
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

# 補題: a + (1 + b) == 1 + (a + b)
law add_succ_r:
  for +a: Nat
  for +b: Nat
  {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}

def add_succ_r(a, b):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_succ_r(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

# 補題: 累積引数つきの反転を 2 回かけると、acc の反転の続きに xs が戻る
law go_go:
  for +xs: List<&2, Nat>
  for +acc: List<&2, Nat>
  {M.rev.go(M.rev.go(xs, acc), Nil{}) == M.rev.go(acc, xs) : List<&2, Nat>}

def go_go(xs, acc):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      go_go(t, Con{h, acc})

# 補題: 累積引数つきの反転の長さ
law go_len:
  for +xs: List<&2, Nat>
  for +acc: List<&2, Nat>
  {Laws.Spec.len(M.rev.go(xs, acc)) == Nat.add(Laws.Spec.len(xs), Laws.Spec.len(acc)) : Nat}

def go_len(xs, acc):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %add_succ_r(Laws.Spec.len(t), Laws.Spec.len(acc)) : {Laws.Spec.len(M.rev.go(t, Con{h, acc})) == _ : Nat}
      go_len(t, Con{h, acc})

def Laws.rev_rev(xs):
  go_go(xs, Nil{})

def Laws.rev_len(xs):
  %add_zero_r(Laws.Spec.len(xs)) : {Laws.Spec.len(M.rev(xs)) == _ : Nat}
  go_len(xs, Nil{})
