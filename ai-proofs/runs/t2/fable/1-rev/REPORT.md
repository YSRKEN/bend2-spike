```
結果: PASS
検査の回数: 4（フックの分 2 回、手動 2 回。うち 1 回は --verdict で、Lean が無く走らず）
main.bend の行数 / PROOF.bend の行数: 17 / 80
補題の数: 4（app_nil、app_assoc、rev_app、len_snoc）
方針: 実装は、連結 app を自分で書き、rev を「rev(t) の末尾に [h] を付ける」素朴な形にした（蓄積引数の形より証明が短いと見た）。rev_rev は、rev_app（連結の反転は反転の逆順の連結）で rev(app(rev(t), [h])) を app(rev([h]), rev(rev(t))) に直し、これが計算で h <> rev(rev(t)) に落ちるので帰納法の仮定で閉じた。rev_app は app_nil と app_assoc から、rev_len は len_snoc（末尾に 1 つ付けると Spec.len が 1 増える）と帰納法の仮定から出した。書き換え %e : P は「P の _ に e の右辺を入れたものが今の目標、左辺を入れたものが次の目標」なので、右辺が目標に現れない所は Equal.sym で向きを返した。
詰まった点:
- 書き換えの向きを逆に読んでいた。1 回目の検査で `expected : {M.rev(ys) == M.app(M.rev(ys), []) : List<&2, Nat>}` / `observed : {M.rev(ys) == M.rev(ys) : List<&2, Nat>}`（rev_app の Nil の場合）が出て、_ が印すのは「今の目標に現れる右辺」だと分かり、3 か所を Equal.sym で返して通った。
- `bend PROOF.bend --verdict` はコンテナに Lean が無く走らなかった（`lean: Executable not found in $PATH`）。完成の条件には含まれていないのでそのまま報告する。
自己申告: なし
```
