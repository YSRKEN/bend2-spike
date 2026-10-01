結果: PASS
検査の回数: 5（フックの自動検査 2 回、手で走らせた `bend` 3 回。うち `--verdict` の 1 回はコンテナに Lean が無く、カーネルの再検査は走らなかった）
main.bend の行数 / PROOF.bend の行数: 31 / 120
補題の数: 10（型・小道具の def を別に 3 つ: `Bool.disc`・`Nat.disc`・`Nat.pred`）
方針: 実装は右畳み込みで、`encode(x <> t) = encode.push(x, encode(t))` とし、`push` は先頭の組 (y, m) と x を `Nat.is_eq` で比べ、その Bool を引数に取る `encode.put` が「同じなら (y, 1n+m)、違えば (x, 1n) を前置」を選ぶ（計算値を match できないので Bool を引数に渡す形にした）。証明は `put` の補題を `b: Bool` と `e: {Nat.is_eq(x, y) == b}` で一般化して b で場合分けし、呼ぶ側では `{==}` を e に渡す。True の枝は `Nat.is_eq_true` で x == y を得て書き換え、False の枝は roundtrip では計算だけで閉じ、canonical では `Nat.is_eq_false` で `{x != y}` を作る。`Nat.is_eq_true` / `Nat.is_eq_false` は x y の同時帰納で、矛盾する枝は `disc` 型の motive で書き換えて Empty を出し `Empty.absurd` で閉じ、1n+a と 1n+b の枝は `Equal.cong(Nat.pred)` で a == b に落として帰納法の仮定に渡す。
詰まった点:
- なし。`PROOF.bend` は最初の検査で `ALL PROOFS CHECK` が出た。
- `--verdict` は「Error: the kernel did not build (lean: Executable not found in $PATH: "lean")」で走らなかった（完成の条件には含まれていない）。
自己申告: なし。Runs の証明は merge の枝で元の `Runs((y, m) <> t)` から `Diff(y, t)` と `Runs(t)` をそのまま流用し、`Pos(1n+m)` は `Unit{}` で埋めただけで、法則の意図どおりに閉じている。
