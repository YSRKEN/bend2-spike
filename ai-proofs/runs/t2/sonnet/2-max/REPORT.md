結果: PASS
検査の回数: 約 12（フックの分を含む概数。--verdict は Lean が無く走らなかった）
main.bend の行数 / PROOF.bend の行数: 12 / 91
補題の数: 10（LE_refl, LE_trans, max_l, max_r, max_or_succ, max_or, upper_step, go_upper, elem_step, go_elem。法則本体の 2 def を除く）
方針: 実装は、先頭から最大値 acc を持ち回る末尾再帰 max.go(xs, acc) を Nat.max で書き、max(x, xs) = max.go(xs, x) とした。証明は、acc と xs を一般化した補題 go_upper・go_elem を xs の帰納法で示し、法則はそれを x, xs で呼ぶだけ。Spec.LE の反射律・推移律・Nat.max との関係、「Nat.max(a, b) は a か b」の補題を土台にした。
詰まった点:
- 「a match on a parameter or field (this name is a def or a consumed binder...)」: 先に e を match した後で o を match したため。`match o e:` と同時に match して解決。
- 「expected : Either<...> observed : {1n+Nat.max(a, b) == 1n+a : Nat}」: rewrite の motive を等式だけにしていた。ゴール全体（Or(...)）を motive に書いて解決。
- 「expected : p / observed : p (consumed more than once)」: 対の分解で p を 2 回使った。`(+p, q) = ih` で解決。
自己申告: なし
