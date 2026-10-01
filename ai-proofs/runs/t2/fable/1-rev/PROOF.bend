import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# 補題 1: 右に Nil を付けても変わらない
law app_nil:
  for +xs: List<&2, Nat>
  {M.app(xs, Nil{}) == xs : List<&2, Nat>}

def app_nil(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %app_nil(t) : {h <> M.app(t, Nil{}) == h <> _ : List<&2, Nat>}
      {==}

# 補題 2: 連結の結合法則
law app_assoc:
  for +xs: List<&2, Nat>
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

# 補題 3: 連結の反転は、反転の逆順の連結
law rev_app:
  for +xs: List<&2, Nat>
  for +ys: List<&2, Nat>
  {M.rev(M.app(xs, ys)) == M.app(M.rev(ys), M.rev(xs)) : List<&2, Nat>}

def rev_app(xs, ys):
  match xs:
    case Nil{}:
      %Equal.sym(List<&2, Nat>, M.app(M.rev(ys), Nil{}), M.rev(ys), app_nil(M.rev(ys))) : {M.rev(ys) == _ : List<&2, Nat>}
      {==}
    case Con{h, t}:
      %Equal.sym(List<&2, Nat>, M.rev(M.app(t, ys)), M.app(M.rev(ys), M.rev(t)), rev_app(t, ys)) : {M.app(_, [h]) == M.app(M.rev(ys), M.app(M.rev(t), [h])) : List<&2, Nat>}
      app_assoc(M.rev(ys), M.rev(t), [h])

# 補題 4: 末尾に 1 つ付けると長さが 1 増える
law len_snoc:
  for +xs: List<&2, Nat>
  for +y: Nat
  {Laws.Spec.len(M.app(xs, [y])) == 1n+Laws.Spec.len(xs) : Nat}

def len_snoc(xs, y):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %len_snoc(t, y) : {1n+Laws.Spec.len(M.app(t, [y])) == 1n+_ : Nat}
      {==}

# 法則: 2 回反転すると元に戻る
def Laws.rev_rev(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Equal.sym(List<&2, Nat>, M.rev(M.app(M.rev(t), [h])), M.app(M.rev([h]), M.rev(M.rev(t))), rev_app(M.rev(t), [h])) : {_ == h <> t : List<&2, Nat>}
      %Laws.rev_rev(t) : {h <> M.rev(M.rev(t)) == h <> _ : List<&2, Nat>}
      {==}

# 法則: 反転しても長さは変わらない
def Laws.rev_len(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Equal.sym(Nat, Laws.Spec.len(M.app(M.rev(t), [h])), 1n+Laws.Spec.len(M.rev(t)), len_snoc(M.rev(t), h)) : {_ == 1n+Laws.Spec.len(t) : Nat}
      %Laws.rev_len(t) : {1n+Laws.Spec.len(M.rev(t)) == 1n+_ : Nat}
      {==}
