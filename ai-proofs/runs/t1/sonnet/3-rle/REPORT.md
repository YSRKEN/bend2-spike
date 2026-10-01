結果: PASS
検査の回数: 約 12 回（フックの自動検査を含む）。`bend PROOF.bend` は `ALL PROOFS CHECK` を出した。`--verdict` は、コンテナに lean が無く走らなかった。
main.bend の行数 / PROOF.bend の行数: 27 / 123
補題の数: 12（disc、pred、Rel（型）、zero_ne_succ、succ_ne_zero、succ_inj、succ_rel、cmp_ok、push2_rt、push_rt、diff_eq、push2_runs、push_runs。Rel は型を返す def）
方針: encode は末尾から作る。先頭の値 x を、再帰で得た残りの先頭の組 (y,m) と Nat.cmp で比べる。EQ なら (x,1+m) に併合し、それ以外なら (x,1) を前に足す。証明の鍵は、cmp の結果 c ごとの事実を返す型 Rel(c,x,y) と、補題 cmp_ok : Rel(Nat.cmp(x,y),x,y)（x と y を同時に潰す帰納法）。計算結果の match は禁止されているので、補助関数 push2 が c を引数に取り、証明も c を一般化して match した。この c を一般化した形で、roundtrip（push_rt）と canonical（push_runs）を xs の帰納法で示した。
詰まった点:
- main.bend の `(y, m) = q` で「expected : y / observed : y (consumed more than once)」と出た。`(+y, m) = q` にして解決した。
- succ_ne_zero の `%e : disc(_)` で「expected : Empty / observed : Unit」と出た。向きが逆だったため、zero_ne_succ に Equal.sym を渡す形に直した。
自己申告: なし。@unsafe・?TODO・外部コードは使っていない。encode は Nat.cmp を使う通常の実装で、法則は証明を通して満たしている。
（実行時間 124 秒、ツール呼び出し 14 回、サブエージェントのトークン 109,136）
