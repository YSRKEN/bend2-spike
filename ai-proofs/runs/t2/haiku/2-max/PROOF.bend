import Base
import ./LAWS.bend as Laws

# Proof of max_upper law
def Laws.max_upper(x, xs):
  match xs:
    case Nil{}:
      match x:
        case 0n:
          (Unit{}, Unit{})
        case 1n+p:
          % Laws.max_upper(p, Nil{}) : Spec.All(M.max(p, Nil{}), p <> Nil{})
          ?TODO
    case Con{h, t}:
      ?TODO

# Proof of max_elem law
def Laws.max_elem(x, xs):
  match xs:
    case Nil{}:
      Inl{{==}}
    case Con{h, t}:
      Inr{Laws.max_elem(h, t)}
