import Base
def test(x, xs):
  match x xs:
    case 0n Nil{}:
      Unit{}
