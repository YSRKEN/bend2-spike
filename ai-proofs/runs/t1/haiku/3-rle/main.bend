import Base

# テイル再帰でエンコード：結果をアキュムレータに格納

# 通常のラン処理での比較（最初に定義）
def encode.go.check_normal(x: Nat, xs_rest: List<&2, Nat>, acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, current_val: Nat, current_count: Nat, cmp: Cmp) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match cmp:
    case EQ{}:
      # current_val == x: ラン長をインクリメント
      encode.go(xs_rest, acc, current_val, ((1n + current_count) : Nat))
    case _:
      # current_val != x: 現在のランを終了し、新しいラン開始
      encode.go(xs_rest, (current_val, current_count) <> acc, x, 1n)

# 初期状態での比較
def encode.go.check_initial(x: Nat, xs_rest: List<&2, Nat>, acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, cmp: Cmp) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  # 初期状態なので、current_count = 0 で新しいラン開始
  encode.go(xs_rest, acc, x, 1n)

# メイン処理ループ
def encode.go(xs: List<&2, Nat>, acc: List<&2, Sigma<&2, &2, Nat, _ => Nat>>, +current_val: Nat, +current_count: Nat) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  match xs:
    case Nil{}:
      # xs の終端：現在のラン（があれば）を追加
      match current_count:
        case 0n:
          # 初期状態のまま終了
          List.reverse(&2, Sigma<&2, &2, Nat, _ => Nat>, acc)
        case _:
          # 現在のランを追加
          List.reverse(&2, Sigma<&2, &2, Nat, _ => Nat>, (current_val, current_count) <> acc)
    case x <> xs_rest:
      match current_count:
        case 0n:
          # 初期状態
          encode.go.check_initial(x, xs_rest, acc, Nat.cmp(current_val, x))
        case _:
          # 通常のラン処理
          encode.go.check_normal(x, xs_rest, acc, current_val, current_count, Nat.cmp(current_val, x))

# エントリポイント
def encode(xs: List<&2, Nat>) -> List<&2, Sigma<&2, &2, Nat, _ => Nat>>:
  encode.go(xs, Nil{}, 0n, 0n)
