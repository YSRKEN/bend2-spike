import Base
import ./LAWS.bend as Laws

def prove_le_refl(n):
  match n:
    case 0n:
      Unit{}
    case 1n+p:
      prove_le_refl(p)

def Laws.max_upper(x, xs):
  match xs:
    case Nil{}:
      (prove_le_refl(x), Unit{})
    case Con{h, t}:
      ih = Laws.max_upper(h, t)
      (prove_le_refl(x), ih)

def Laws.max_elem(x, xs):
  match xs:
    case Nil{}:
      Inl{({==})}
    case Con{h, t}:
      Inr{(ih : ih)}
      prove_le_refl(h)
