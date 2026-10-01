結果: PASS
検査の回数: 6（フック 3 回 + 手動 3 回。うち 1 回は --verdict で、コンテナに Lean が無く「the kernel did not build」で動かなかった。通常の `bend PROOF.bend` は ALL PROOFS CHECK）
main.bend の行数 / PROOF.bend の行数: 31 / 120
補題の数: 11（Bool.disc（判別子の motive）、false_ne_true、true_ne_false、is_eq_true、is_eq_refl、is_eq_true_of、is_eq_false、push_if_decode、push_decode、push_if_runs、push_runs）
方針: encode は右畳み込みで、`encode(x <> t) = push(x, encode(t))` とし、push は先頭の組 (y, n) と x を `Nat.is_eq(x, y)` で比べて合流（(y, 1+n)）か新規（(x, 1)）かを選ぶ。計算値には match できないので、Bool を受け取る `encode.push.if` に分けた。証明は両法則とも xs の帰納法で、本体は「push が decode / Runs を保つ」補題に落とし、その補題は same: Bool と `{Nat.is_eq(x, y) == same}` を引数に取る helper で場合分けし、True 側は `Nat.is_eq(x,y) == True → x == y`（Nat の二重帰納 + Bool.disc による矛盾導出）、False 側は `x != y`（is_eq_refl と Equal.trans で True == False に落として矛盾）で埋めた。
詰まった点:
- 1 回だけ。補題の並び順の誤りで `expected : a filled definition (an unfilled law is a dead claim: live code cannot use it) / observed : is_eq_true_of`（is_eq_false が下にある is_eq_true_of を呼んでいた）。順序を入れ替えて解決。
自己申告: なし。encode は実際に連長圧縮を行い（[5,5,7] → [(5,2),(7,1)]）、法則は仕様どおりの decode / Runs に対して証明している。
（実行時間 218 秒、ツール呼び出し 16 回、サブエージェントのトークン 118,893）
