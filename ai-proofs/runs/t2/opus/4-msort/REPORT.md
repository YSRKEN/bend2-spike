結果: PASS
検査の回数: 約 13 回（フックが自動で走らせた分と手で走らせた bend を含む。うち 1 回は --verdict で、コンテナに Lean が無いため走らなかった）
main.bend の行数 / PROOF.bend の行数: 72 / 208
補題の数: 15（le_true・le_false・add_zero・add_succ・add_comm2・bump_add_l1・bump_add_l2・add_bump_r・merge_sorted・merge_count・isort_sorted・isort_count・alt_count・sort_go_sorted・sort_go_count）。このほかに、矛盾を導くための型 IsTrue・IsFalse の 2 つがある
方針: sort はリストの長さを燃料にした sort.go で書いた。リストを交互に 2 つへ振り分け（alt）、parallel let で両方を整列してから、線形時間のマージをする。Bend は計算した値で match できないので、マージ（merge.go）は比較の結果 c を 3 つ目の引数で受け取り、再帰呼び出しの側で次の比較 le_heads(..) を計算して渡す形にした。証明では merge.go について 2 つを示した。「c == le_heads(xs, ys) が成り立てば、下限 lo からの昇順を保つ」と「c が何であっても、個数は両方の個数の和になる」である。これに alt の個数の補題と、Nat.add の交換則などの小さな補題を組み合わせた。燃料が尽きたときの予備には、merge で書いた挿入整列を置いた。そのため、燃料が足りることは証明しなくて済んだ。
詰まった点:
- 計算した値を分解できない（`(a, b) = split(t)` で）: `a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)`。タプルを返す split をやめ、Bool で偶数番目と奇数番目のどちらを取るか選ぶ alt(xs, b) に替えて避けた。
- ラムダの中で match できない: `a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)`。比較の結果を merge.go の引数にして避けた。
- 燃料を 2 回使った: `f (consumed more than once)`。`+fuel` にして解決した。
- 証明の中の、2 つの値に対する match でタプルのパターンが使えない: `expected : 2 patterns (one per scrutinee)` / `observed : '(lx, sxt) (ly, syt)'`。`(lx, sxt) = sx` という分解の let に替えて解決した。
- 書き換え `%e : P` の向きを一度取り違えた。Equal.sym で向きを揃えて解決した。
自己申告: 燃料が尽きたときの予備として、挿入整列（isort）を置いた。燃料にはリストの長さを渡すので、予備に落ちるのは空のリストのときだけのはずだが、そのことは証明していない。つまり、並列マージソートの経路を必ず通ることは証明の対象外である。証明したのは、予備の経路も含めて法則（昇順・並べ替え）が成り立つことである。また merge.go はどんな c でも受け付ける。c が正しい比較の結果であることは、merge が le_heads を渡すことで保っている（証明では c == le_heads(..) を仮定にしている）。
（この REPORT.md は、被験者の Write ツールが報告ファイルの作成を拒まれたため、親が被験者の報告をそのまま置いた）
