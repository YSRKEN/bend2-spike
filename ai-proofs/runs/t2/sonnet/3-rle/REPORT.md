結果: PASS
検査の回数: 約 20（フック分を含む）
main.bend の行数 / PROOF.bend の行数: 37 / 107
補題の数: 13（型を返す補助 def の pred・Disc・EqR を含む。法則そのものの 2 つは除く）
方針: encode は、後ろから再帰して結果の先頭に push で 1 つ足す形。push は先頭の組の値と等しければ個数を 1 増やし、違えば新しい組を作る。比較は自前の再帰 eq（Nat.is_eq は使わない）。eq の結果 b を引数に取る pushgo を挟んで、match が計算結果を直接見ない制約を回避した。証明は、eq の結果ごとの証拠 EqR(b, x, y) を eq_ok で作り、pushgo の補題（正規形・展開）を b の場合分けで証明、push の補題を経て、xs の帰納法で 2 法則を閉じた。
詰まった点:
- `(y, m) = q` で y を 2 回使うと "expected : y / observed : y (consumed more than once)"。`(+y, m) = q` にして解決。
- `Equal.cong(Nat, Nat, Nat.succ, ...)` は "expected : a defined name / observed : Nat.succ"。Nat.succ が無いので、`%h : {1n+p == 1n+_ : Nat}` の書き換えに替えた。
- `--verdict` は lean が無く "the kernel did not build (lean: Executable not found in $PATH: "lean")" で実行できなかった（通常の検査は ALL PROOFS CHECK）。
自己申告: なし
