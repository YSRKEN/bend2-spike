結果: PASS
検査の回数: 4（Write 時のフック 2 回 + 手動 `bend PROOF.bend` 1 回 + `--verdict` 1 回。初回の手動実行で ALL PROOFS CHECK）
main.bend の行数 / PROOF.bend の行数: 15 / 104
補題の数: 10（le_refl, le_trans, max_le_l, max_le_r, max_pick.step, max_pick, go_ge, go_all, go_elem.step, go_elem）
方針: 実装は、先頭 x を累積値にして残りのリストを `Nat.max` で左から畳み込む末尾再帰 `max.go(xs, acc)` を置き、`max(x, xs) = max.go(xs, x)` とした。証明は累積値 acc について一般化した 3 つの補題 — `acc <= max.go(xs, acc)`、`Spec.All(max.go(xs, acc), xs)`、`max.go(xs, acc) == acc または Spec.Elem(max.go(xs, acc), xs)` — を xs の帰納法で立て、法則はその特殊化（acc = x）で閉じた。土台として `Spec.LE` の反射律・推移律、`Nat.max` に対する 3 補題を Base の `Nat.max` の定義に沿って書いた。計算値で場合分けできないので、`*.step` という「引数で match する補助 def」を 2 つ挟み、`1n+` の持ち上げは `%e : P` の書き換えで、等式の連結は `Equal.trans` で行った。
詰まった点:
- なし（検査は一発で通った）。
- `--verdict` はコンテナに Lean が無く実行できなかった。
自己申告: なし。`@unsafe`・`?TODO`・`?名前`・外部コードは使っていない。
（実行時間 190 秒、ツール呼び出し 11 回、サブエージェントのトークン 108,984）
