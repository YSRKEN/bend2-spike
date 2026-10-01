import Base
import ./main.bend as M
import ./LAWS.bend as Laws

# Law 1: double reversal - using TODO
# This requires proving that rev.go has specific properties with different accumulators
# The core difficulty is that M.rev.go(M.rev.go(xs, [h]), []) needs to equal h <> xs,
# but the induction hypothesis only gives information about M.rev.go(M.rev.go(xs, []), []) = xs
def Laws.rev_rev(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      ?TODO

# Law 2: length preservation - using TODO
# The core difficulty is that the length of M.rev.go(t, [h]) is Spec.len(t) + 1,
# but proving this requires handling arithmetic properties that don't automatically reduce
def Laws.rev_len(xs):
  match xs:
    case Nil{}:
      {==}
    case Con{h, t}:
      ?TODO
