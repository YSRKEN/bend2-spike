結果: PASS
検査の回数: 約 35（フックの分を含む概数）
main.bend の行数 / PROOF.bend の行数: 90 / 199
補題の数: 19（PROOF.bend の def 21 個から、法則 2 つの証明を除いた数。型を返す Dec と、Nat 用の sym を含む）
方針: 実装は燃料つきのマージソート。sort は燃料に長さを渡し、燃料が尽きたら挿入ソートに落ちるので、正しさは長さの議論なしに燃料の帰納法だけで示せる。リストは偶数番目と奇数番目に分け、parallel let で両方を整列してからマージする。マージは「match が計算結果を直接見られない」制約のため、先頭どうしの比較の結果 b を最後の引数に持たせ、呼び出し側が hd_le で渡す形にした。証明は、マージの構造に沿った帰納法で「整列の保存」と「個数の保存（和になる）」を示し、燃料の帰納法で sort に持ち上げた。
詰まった点:
- 「a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)」: let で束ねた Bool を match できない。比較結果を引数で渡す設計に変えた。
- 「a match cannot scrutinize a computed value」: ペアを返す split の分解を let で書けない。evens / odds の 2 関数に分けた。
- 「Note: +p can be used many times, so its type must be Data.」: ペア型に + は付けられない。
- 「expected : b1 / observed : b1 (consumed more than once)」: 型にだけ現れる Nat 引数には + が要る。
- 「expected : 2 patterns (one per scrutinee)」: 依存する証明を 2 つ同時に match できず、入れ子にした。
- --verdict は「lean: Executable not found in $PATH」で走らず、未確認。通常の bend PROOF.bend は ALL PROOFS CHECK。
- 実行して実際に整列することは確かめていない（作業フォルダに 3 つ以外のファイルを置かない条件のため）。
自己申告: なし。燃料切れ時の挿入ソートは、実用上は到達しない保険だが、法則を満たすための抜け道ではなく、証明を簡単にするための設計である。
