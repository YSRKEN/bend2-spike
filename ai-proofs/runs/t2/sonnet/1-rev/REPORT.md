結果: PASS
検査の回数: 約 6(フック分を含む)
main.bend の行数 / PROOF.bend の行数: 11 / 62
補題の数: 4(go_go, add_succ_r, len_go, add_zero_r)
方針: 実装は累積引数つきの rev_go(xs, acc) と rev = rev_go(xs, Nil)。rev_rev は一般化した補題 rev_go(rev_go(xs, ys), Nil) == rev_go(ys, xs) を xs の帰納法で証明。rev_len は len(rev_go(xs, acc)) == add(len xs, len acc) を帰納法で示し、add_succ_r と add_zero_r で整える。
詰まった点:
- 初回、rev_len で「expected: ...len(xs) / observed: ...Nat.add(len(xs), 0n)」の不一致 -> add_zero_r を足して書き換えで解決。
自己申告: なし
