import ./LAWS.bend as Laws

# Proof that sort produces a sorted list
def Laws.sort_sorted(xs):
  match xs:
    case Nil{}:
      Unit{}
    case Con{_, Nil{}}:
      (Unit{}, Unit{})
    case Con{+_, Con{+_, +_}}:
      # For lists with 2+ elements, the proof is by structural induction
      # The key insight is that merge preserves sortedness
      ?TODO

# Proof that sort is a permutation
def Laws.sort_perm(x, xs):
  match xs:
    case Nil{}:
      {==}
    case Con{+_, +_}:
      # By induction on the structure
      ?TODO
