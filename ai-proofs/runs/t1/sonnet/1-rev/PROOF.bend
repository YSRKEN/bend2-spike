import Base
import ./LAWS.bend as Laws
import ./main.bend as M

def app_nil(+xs: List<&2, Nat>) -> {M.app(xs, Nil{}) == xs : List<&2, Nat>}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %app_nil(t) : {Con{h, M.app(t, Nil{})} == Con{h, _} : List<&2, Nat>}
      {==}

def app_assoc(+xs: List<&2, Nat>, +ys: List<&2, Nat>, +zs: List<&2, Nat>) -> {M.app(M.app(xs, ys), zs) == M.app(xs, M.app(ys, zs)) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %app_assoc(t, ys, zs) : {Con{h, M.app(M.app(t, ys), zs)} == Con{h, _} : List<&2, Nat>}
      {==}

def rev_app(+xs: List<&2, Nat>, +ys: List<&2, Nat>) -> {M.rev(M.app(xs, ys)) == M.app(M.rev(ys), M.rev(xs)) : List<&2, Nat>}:
  match xs:
    case Nil{}:
      %app_nil(M.rev(ys)) : {_ == M.app(M.rev(ys), Nil{}) : List<&2, Nat>}
      {==}
    case Con{h, t}:
      %app_assoc(M.rev(ys), M.rev(t), Con{h, Nil{}}) : {M.app(M.rev(M.app(t, ys)), Con{h, Nil{}}) == _ : List<&2, Nat>}
      %rev_app(t, ys) : {M.app(M.rev(M.app(t, ys)), Con{h, Nil{}}) == M.app(_, Con{h, Nil{}}) : List<&2, Nat>}
      {==}

def Laws.rev_rev(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Laws.rev_rev(t) : {M.rev(M.app(M.rev(t), Con{h, Nil{}})) == Con{h, _} : List<&2, Nat>}
      %rev_app(M.rev(t), Con{h, Nil{}}) : {M.rev(M.app(M.rev(t), Con{h, Nil{}})) == _ : List<&2, Nat>}
      {==}

def len_snoc(+xs: List<&2, Nat>, +h: Nat) -> {Laws.Spec.len(M.app(xs, Con{h, Nil{}})) == 1n+Laws.Spec.len(xs) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case Con{x, t}:
      %len_snoc(t, h) : {1n+Laws.Spec.len(M.app(t, Con{h, Nil{}})) == 1n+_ : Nat}
      {==}

def Laws.rev_len(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Equal.sym(Nat, Laws.Spec.len(M.app(M.rev(t), Con{h, Nil{}})), 1n+Laws.Spec.len(M.rev(t)), len_snoc(M.rev(t), h)) : {_ == 1n+Laws.Spec.len(t) : Nat}
      %Laws.rev_len(t) : {1n+Laws.Spec.len(M.rev(t)) == 1n+_ : Nat}
      {==}
