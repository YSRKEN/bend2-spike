```
結果: PASS
検査の回数: 2（bend PROOF.bend を 1 回で ALL PROOFS CHECK。--verdict を 1 回試したが、コンテナに Lean が無く検査は走らなかった。ファイルは Bash の heredoc で書いたので、フックの自動検査は走っていない）
main.bend の行数 / PROOF.bend の行数: 13 / 64
補題の数: 4（add_zero_r, add_succ_r, go_go, go_len）
方針: rev は累積引数つきの rev.go(xs, acc) で線形時間に反転する。rev_rev は、acc を一般化した補題 go_go「rev.go(rev.go(xs, acc), Nil) == rev.go(acc, xs)」を xs の帰納で示し、acc = Nil で使う（帰納段の右辺 rev.go(h<>acc, t) が rev.go(acc, h<>t) に簡約されるので、帰納法の仮定がそのまま答えになる）。rev_len は、補題 go_len「len(rev.go(xs, acc)) == len(xs) + len(acc)」を add_succ_r による書き換えで示し、最後に add_zero_r で + 0 を消す。
詰まった点:
- なし（初回で ALL PROOFS CHECK）。
- --verdict は「Error: the kernel did not build (lean: Executable not found in $PATH: "lean")」で走らなかった。完成の条件には含まれない。
自己申告: なし
```
