import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# 補題 1: 右に Nil を連結しても変わらない
law app_nil:
  for xs: List<&2, Nat>
  {M.app(xs, Nil{}) == xs : List<&2, Nat>}

def app_nil(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %app_nil(t) : {h <> M.app(t, Nil{}) == h <> _ : List<&2, Nat>}
      {==}

# 補題 2: 連結の結合律
law app_assoc:
  for xs: List<&2, Nat>
  for +ys: List<&2, Nat>
  for +zs: List<&2, Nat>
  {M.app(M.app(xs, ys), zs) == M.app(xs, M.app(ys, zs)) : List<&2, Nat>}

def app_assoc(xs, ys, zs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %app_assoc(t, ys, zs) : {h <> M.app(M.app(t, ys), zs) == h <> _ : List<&2, Nat>}
      {==}

# 補題 3: 連結の反転は、反転の逆順の連結（書き換えに使いやすい向きで述べる）
law rev_app:
  for xs: List<&2, Nat>
  for +ys: List<&2, Nat>
  {M.app(M.rev(ys), M.rev(xs)) == M.rev(M.app(xs, ys)) : List<&2, Nat>}

def rev_app(xs, ys):
  match xs:
    case Nil{}:
      app_nil(M.rev(ys))
    case Con{h, +t}:
      %app_assoc(M.rev(ys), M.rev(t), h <> Nil{}) : {_ == M.app(M.rev(M.app(t, ys)), h <> Nil{}) : List<&2, Nat>}
      %rev_app(t, ys) : {M.app(M.app(M.rev(ys), M.rev(t)), h <> Nil{}) == M.app(_, h <> Nil{}) : List<&2, Nat>}
      {==}

# 法則 1: 2 回反転すると元に戻る
def Laws.rev_rev(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %rev_app(M.rev(t), h <> Nil{}) : {_ == h <> t : List<&2, Nat>}
      %Laws.rev_rev(t) : {h <> M.rev(M.rev(t)) == h <> _ : List<&2, Nat>}
      {==}

# 補題 4: 連結の長さは長さの和
law len_app:
  for xs: List<&2, Nat>
  for +ys: List<&2, Nat>
  {Nat.add(Laws.Spec.len(xs), Laws.Spec.len(ys)) == Laws.Spec.len(M.app(xs, ys)) : Nat}

def len_app(xs, ys):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %len_app(t, ys) : {1n+Nat.add(Laws.Spec.len(t), Laws.Spec.len(ys)) == 1n+_ : Nat}
      {==}

# 補題 5: 1 を右から足すのは後者を取ること
law add_one:
  for a: Nat
  {Nat.add(a, 1n) == 1n+a : Nat}

def add_one(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %add_one(p) : {1n+Nat.add(p, 1n) == 1n+_ : Nat}
      {==}

# 法則 2: 反転しても長さは変わらない
def Laws.rev_len(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %len_app(M.rev(t), h <> Nil{}) : {_ == 1n+Laws.Spec.len(t) : Nat}
      %Laws.rev_len(t) : {Nat.add(Laws.Spec.len(M.rev(t)), 1n) == 1n+_ : Nat}
      add_one(Laws.Spec.len(M.rev(t)))
