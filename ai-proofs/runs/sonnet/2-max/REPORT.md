結果: PASS
検査の回数: 約 12 回（手動 7 回 + フックの自動検査。最初に wslc のマウントエラーが 1 回出て再試行した）
main.bend の行数 / PROOF.bend の行数: 13 / 99
補題の数: 8（le_refl, le_trans, le_max_l, le_max_r, choice_succ, max_choice, all_mono, elem_step）。法則を直接証明する def として all_go と elem_go があり、Laws.max_upper と Laws.max_elem はそれらを呼ぶだけ。
方針: 実装は、Nat.max を使う右畳み込みにした。termination の検査が「縮む引数を先頭に置け」と求めるため、補助関数 go(xs, x) を作り、max(x, xs) = go(xs, x) とした。go は Nil なら x、Con{h, t} なら Nat.max(x, go(t, h)) を返す。証明は xs の帰納法である。All は「le_max_l / le_max_r と、All の単調性 all_mono（le_trans を使う）」で示した。Elem は「Nat.max(a, b) は a か b に等しい」という補題 max_choice で場合分けし、Equal.sym と rewrite で帰納法の仮定を運んだ。
詰まった点:
- 最初の実装は max(x, xs) の再帰で x を h に替えたため、次のエラーになった。"expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks) / observed : max" → xs を先頭に置いた補助関数 go に分けて解決した。
- match の scrutinee に呼び出しを書いたら、次のエラーになった。"a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)" → 補助 def（choice_succ、elem_step）に分けて解決した。
- 引数 mn を 2 回使ったら、次のエラーになった。"expected : mn / observed : mn (consumed more than once)" → `+mn` にして解決した。
- wslc の初回実行で一時的なマウントエラー（ERROR_ALREADY_EXISTS）が出たが、再試行で通った。他の被験者の同時実行によるものと思われる。
- `--verdict` は、コンテナに lean が無いため実行できなかった。`bend PROOF.bend` は `ALL PROOFS CHECK` を出した。
自己申告: なし。@unsafe・?TODO・外部コードは使っていない。実装は Nat.max を使う素直な畳み込みである。
（実行時間 94 秒、ツール呼び出し 13 回、サブエージェントのトークン 105,543）
