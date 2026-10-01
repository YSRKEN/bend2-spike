結果: PASS
検査の回数: 6（main.bend の --check-only が 1 回、PROOF.bend が 4 回、--verdict が 1 回。--verdict はコンテナに lean が無いため kernel を組めずに失敗。ファイルは Bash の heredoc で書いたので、フックは走っていない）
main.bend の行数 / PROOF.bend の行数: 41 / 148
補題の数: 9（P.tf, P.ft, P.eq_sound, P.eq_false, P.pushc_rt, P.push_rt, P.bump, P.pushc_runs, P.push_runs。ほかに、動機として使う型関数 P.dT/dF/dZ/dS と P.pred を置いた）
方針: encode は右から畳む形にした。encode(h<>t) = push(h, encode(t)) とし、push は先頭の組 (y, m) と h を自前の Nat 等値判定 M.eq で比べる。等しければ (y, 1+m)、異なれば (h, 1) を前に足す（結果の Bool で分ける処理は、別の def の pushc に渡した）。証明ではまず M.eq の健全性（True なら a==b、False なら a!=b）を Nat の二重帰納で示した。次に pushc と push について「decode すると h が一つ前に足される」「正規形を保つ」を、Bool の値ごとに場合分けして示した。最後に、両法則を xs の帰納法で閉じた。Bool で場合分けしても仮定 e の型が絞り込まれるか分からなかったので、e を戻り値の関数型の側に置いた。
詰まった点:
- ラムダで受けた引数を分解して弾かれた: 「a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)」（`(pm, rest) = r`）。分解する部分を補題 P.bump に切り出して解決した。
- 書き換えの向きを逆にしていた: q : {h == y} で `%q` すると、`_` は y の位置を指す。そのため「expected : {y <> … == h <> …} / observed : {y <> … == y <> …}」で止まった。Equal.sym で向きを反転して解決した。
自己申告: なし
（実行時間 142 秒、ツール呼び出し 12 回、サブエージェントのトークン 112,299）
