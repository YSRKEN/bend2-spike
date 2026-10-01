import Base
import ./main.bend as M
import ./LAWS.bend as Laws

def Laws.rev_rev(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Laws.rev_rev(t) : {M.rev(M.rev(t)) == t : List<&2, Nat>}
      ?TODO

def Laws.rev_len(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      %Laws.rev_len(t) : {Laws.Spec.len(M.rev(t)) == Laws.Spec.len(t) : Nat}
      ?TODO
