import Base

@unsafe
def encode_acc_nonzero_count_cmp(
  xs: List<&2, Nat>,
  acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>,
  +cur: Nat,
  +count: Nat,
  +cur_pred: Nat,
  +hp: Nat
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match cur_pred:
    case 0n:
      match hp:
        case 0n:
          # Same value
          encode_acc_nonzero_count(xs, acc, cur, Nat.add(count, 1n), cur_pred)
        case 1n+_:
          # Different value
          new_acc = List.append(&2, _, acc, Con{Tuple{cur, count}, Nil{}})
          encode_from_nonzero(xs, new_acc, hp)
    case 1n+cp2:
      match hp:
        case 0n:
          # Different value
          new_acc = List.append(&2, _, acc, Con{Tuple{cur, count}, Nil{}})
          encode_from_nonzero(xs, new_acc, hp)
        case 1n+hp2:
          # Recursively compare
          encode_acc_nonzero_count_cmp(xs, acc, cur, count, cp2, hp2)

@unsafe
def encode_acc_nonzero_count(
  xs: List<&2, Nat>,
  acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>,
  +cur: Nat,
  +count: Nat,
  +cur_pred: Nat
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      acc ++ Con{Tuple{cur, count}, Nil{}}
    case Con{h, t}:
      match h:
        case 0n:
          new_acc = acc ++ Con{Tuple{cur, count}, Nil{}}
          encode_from_0(t, new_acc)
        case 1n+hp:
          encode_acc_nonzero_count_cmp(t, acc, cur, count, cur_pred, hp)

@unsafe
def encode_from_nonzero_cmp(
  xs: List<&2, Nat>,
  acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>,
  +cur: Nat,
  +cur_pred: Nat,
  +hp: Nat
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match cur_pred:
    case 0n:
      match hp:
        case 0n:
          # cur_pred == 0 && hp == 0
          encode_acc_nonzero_count(xs, acc, cur, 2n, cur_pred)
        case 1n+_:
          # Different value
          new_acc = acc ++ Con{Tuple{cur, 1n}, Nil{}}
          encode_from_nonzero(xs, new_acc, hp)
    case 1n+cp2:
      match hp:
        case 0n:
          # Different value
          new_acc = acc ++ Con{Tuple{cur, 1n}, Nil{}}
          encode_from_nonzero(xs, new_acc, hp)
        case 1n+hp2:
          # Recursively compare
          encode_from_nonzero_cmp(xs, acc, cur, cp2, hp2)

@unsafe
def encode_from_nonzero(
  xs: List<&2, Nat>,
  acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>,
  +cur_pred: Nat
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      acc ++ Con{Tuple{1n+cur_pred, 1n}, Nil{}}
    case Con{h, t}:
      match h:
        case 0n:
          new_acc = acc ++ Con{Tuple{1n+cur_pred, 1n}, Nil{}}
          encode_from_0(t, new_acc)
        case 1n+hp:
          encode_from_nonzero_cmp(t, acc, 1n+cur_pred, cur_pred, hp)

@unsafe
def encode_from_0(
  xs: List<&2, Nat>,
  acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>
) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      acc ++ Con{Tuple{0n, 1n}, Nil{}}
    case Con{h, t}:
      match h:
        case 0n:
          encode_from_0(t, acc)
        case 1n+hp:
          new_acc = acc ++ Con{Tuple{0n, 1n}, Nil{}}
          encode_from_nonzero(t, new_acc, hp)

def encode(xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      match h:
        case 0n:
          encode_from_0(t, Nil{})
        case 1n+hp:
          encode_from_nonzero(t, Nil{}, hp)
