```
結果: PASS
検査の回数: 約 20 回（フック 16 回、手動 4 回。--verdict は Lean が無く走らず）
main.bend の行数 / PROOF.bend の行数: 76 / 272
補題の数: 15（add_zero, add_succ, bump_add, add_bump, is_le_true, is_le_false, merge_go_sorted, merge_sorted, merge_go_count, merge_count, split_count, isort_sorted, isort_count, go_sorted, go_count。ほかに型・補助の def が Clash, cnt2 の 2 つ）
方針: sort は長さを燃料にして sort.go(fuel, (l, r)) を呼び、両半分が空でなければ split（偶数番目 evens と奇数番目 odds）した結果を parallel let で並列に整列してから merge する。燃料が尽きたときと片方が空のときは merge([h], isort(t)) 形の挿入ソートに落ちる（実際には長さ 1 以下のリストにしか届かないが、証明は入力によらず成り立つ）。merge は停止性のため、比較結果 le を呼び手が計算して渡す merge.go(xt, yt, le, x, y) にし、le で分岐してから xt か yt を 1 段くずす。証明は、merge.go に「le == Nat.is_le(x, y)」と「x, y が下限 lo 以上」「xt は x から、yt は y から整列済み」を仮定して Sorted.from(lo, …) を帰納法で示し、個数は Spec.bump と Nat.add の入れ替え補題（bump_add・add_bump）で % 書き換えを重ねて示した。
詰まった点:
- merge.go で `match le:` のあとに `match xt:` と書くと「a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)」。1 つの `match xt yt le:` にして変数パターン（`ys`・`xs`）で素通しする形に直した。
- parallel let `a b = sort.go(f, …) sort.go(f, …)` で「expected : f / observed : f (consumed more than once)」。fuel を `+fuel` にした。
- 証明の対の引数を `+lr` にすると「expected : Data / observed : Type … +lr can be used many times, so its type must be Data」。`List & List` は Type 種なので、main.bend と PROOF.bend の対の型を `Sigma<&2, &2, List<&2, Nat>, _ => List<&2, Nat>>` に替えた。
- `%e : P` の向きを何度か取り違えた（`_` は e の右辺を指し、左辺に置き換わる）。merge_go_count の 3 つの場合と split_count で「expected … observed …」が両辺入れ替わりで出て、書き換えの順を組み替えて通した。
- 書き換えの注釈 `: {…}` や erased 引数に出てくるリスト変数も消費に数えられ、「xt2 (consumed more than once)」。補題のリスト引数を `+` にした。
自己申告: 燃料が尽きたときと片方の半分が空のときに挿入ソート（merge([h], isort(t)) の反復）に落ちる予備経路がある。fuel = 長さ なので実行時に長さ 2 以上のリストがそこへ届くことはなく、通常の入力は必ず split → parallel let → merge を通るが、「2 つに分けて並列に整列してから併合する」以外の経路が実装に存在する点は意図と違う抜け道と見られうる。
```
