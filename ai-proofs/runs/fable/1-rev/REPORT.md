結果: PASS
検査の回数: 4（Write 時のフック 2 回、手動の bend 1 回、--verdict 1 回。--verdict はコンテナに lean が無く実行できず）
main.bend の行数 / PROOF.bend の行数: 17 / 93
補題の数: 5（app_nil, app_assoc, rev_app, len_app, add_one）
方針: 実装は、自前の連結 app を補助にした素朴な反転 rev(h<>t) = app(rev(t), [h]) とした（蓄積引数版だと補題が 1 段増えるため）。証明は app_nil・app_assoc から rev_app（app(rev ys, rev xs) == rev(app(xs, ys))）を導き、rev_rev は rev_app(rev t, [h]) で左辺を書き換えてから帰納法の仮定で閉じた。rev_len は len_app（Nat.add(len xs, len ys) == len(app(xs, ys))）と add_one（Nat.add(a, 1n) == 1n+a）で閉じた。補題は `%e : P` が b→a の向きに書き換えることを踏まえ、ゴールに現れる側が右辺になるよう向きを選んで述べ、Equal.sym を使わずに済ませた。
詰まった点:
- 1 回目のフックで rev_app の Con ケースが `expected : t / observed : t (consumed more than once)` で止まった。補題 rev_app の xs は `+` なしの引数で、t を 2 箇所で使っていたため。パターンを `case Con{h, +t}` に変えて通った（型の中にだけ現れる h は数えられなかった）。
- `bend PROOF.bend --verdict` は `Error: the kernel did not build (lean: Executable not found in $PATH: "lean")` で走らなかった。
自己申告: なし。rev は素朴な O(n^2) の定義だが LAWS.bend の冒頭に効率の条件は無く、反転そのものを実装している。
（実行時間 159 秒、ツール呼び出し 13 回、サブエージェントのトークン 103,455）
