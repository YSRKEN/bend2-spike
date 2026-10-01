結果: PASS
検査の回数: 10（フックの自動検査 6 回 + 手動 4 回。うち最終の `bend PROOF.bend` は ALL PROOFS CHECK）
main.bend の行数 / PROOF.bend の行数: 52 / 272
補題の数: 19（Nat の補題 5、個数の補題 4、順序の補題 10）
方針: 実装は `half(xs, take)` で偶数番目・奇数番目に分け、`sort.go(fuel, xs)` が parallel let（`a b = sort.go(f, half(xs, True{})) sort.go(f, half(xs, False{}))`）で両方を整列してから `merge` する。停止は fuel（`sort` が入力の長さを渡す）で保証し、`merge` は計算値の match ができないので、比較結果の Bool を `merge.pick(le, x, u => merge(xt, ys), y, u => merge(xs, yt))` に渡して選ばれた側の閉包だけを続ける形にした。証明は、個数は fuel によらず保たれること（`merge_count`・`half_count`・`go_count`、Nat の add の可換性と bump の補題）、整列は「fuel ≥ 長さ」を不変条件に `half_le`・`LE_trans` で両半分へ受け渡し、`merge_sorted` は `Nat.is_le(x, y)` の意味を `P.LE.of(le, x, y)` という依存型で与えて（`is_le_spec`）、Bool を引数に取る補助補題 `pick_sorted` で場合分けし、帰納法の仮定は閉包（`a => b => merge_sorted(xt, ys, x, a, b)`）で渡した。等式の書き換えは `%e : P` だけで済ませ、`?TODO`・`@unsafe` は使っていない。
詰まった点:
- `- expected : f / - observed : f (consumed more than once)`（sort.go の fuel を 2 つの再帰呼び出しで使ったため。`+fuel` にして解決）
- `- message  : a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)`（`match n:` の中で `match e:` と入れ子にしたときに出た。`match e n:` の 2 値 match に直して解決）
- `- expected : m / - observed : m (consumed more than once)` ほか、`p`・`t` の同種のエラーが計 4 回（該当の引数を `+` にして解決）
- `bend PROOF.bend --verdict` はコンテナに lean が無く実行できなかった。bend2 本体の検査は通っている。
自己申告: 2 点。(1) `sort.go` は fuel が尽きると入力をそのまま返す。`sort` は fuel に入力の長さを渡すので実際には尽きず、証明もその前提（`LE(長さ, fuel)`）で整列を示しているが、`sort.go` 単体は fuel が足りないと整列しない。(2) `merge` の再帰は `merge.pick` に渡した閉包の中にあり、法則が求める「parallel let で並列に整列」は `sort.go` の方で満たしている。作業中に動作確認のため一時的に main を足して走らせ（出力 `[0n, 1n, 1n, 2n, 3n, 4n, 5n, 7n, 9n]`）、元に戻した。バックアップはごみ箱へ送った。
（実行時間 638 秒、ツール呼び出し 18 回、サブエージェントのトークン 154,237）
