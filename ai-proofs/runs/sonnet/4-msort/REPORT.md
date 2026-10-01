結果: PASS
検査の回数: 約 17 回（Write/Edit は使わず Bash から手動で走らせたので、フックの分は無い。ほかにスクラッチ側の試走が 2 回）
main.bend の行数 / PROOF.bend の行数: 65 / 219
補題の数: 25 個の def と 1 個の type（法則の証明 2 つを除く）。算術 5、個数 7（Cn, add_cong, pick_count, merge_count, half_count, isort_count, ms_count, sortF_count）、整列 8（Srt/SPair, Bool.disc, true_false, le_true, le_false, pick_sorted, merge_sorted, isort_sorted, sortF_sorted, srt_to_spec）。数え方で前後する。
方針: 実装は、入力を 1 つおきに 2 つへ分け（half）、parallel let で `sortF(p, half(xs,True)) sortF(p, half(xs,False))` を並列に整列してマージする。分割は構造的に小さくならないので、燃料 `n`（初期値は List.length）を第 1 引数に取って停止性を通した。merge は `xs` を変えずに `ys` を縮める形と `xs` を縮める形の 2 通りの再帰で書き、`pick` に両方の再帰結果を渡して選ぶ。証明は、merge・pick・half に沿った帰納で、個数と整列を別々に示した。整列のほうは、Data 種の自前の述語 `Srt`（SPair 型）で証明し、最後に `Laws.Spec.Sorted.from` へ変換した。Type 種のままだと、証明項を 2 回使えず、帰納法が通らなかったため。
詰まった点:
- `--verdict` は Lean が無く動かなかった（ALL PROOFS CHECK は出ている）。
- `expected : p / observed : p (consumed more than once)`（sortF の `n`）。`+n` にして解決した。
- `expected : bs / observed : bs (consumed more than once)`（merge_count）。パラメータを `+xs` `+ys` にして解決した。
- `expected : Data / observed : Type`（`(A & B)` を Data 種にしようとした）。自前の `SPair` 型で解決した。
- `expected : {True{} == False{} : Bool} / observed : {Cmp.is_le(Nat.cmp(0n, b)) == False{} : Bool}`（le_false の `case 0n b0`）。`b` も match して 2 ケースに分けて解決した。
- `expected : a defined name / observed : Spec.bump`（`Laws.` の接頭辞を忘れた）。
- 書き換え `%e : P` の向きを間違えて 2 回直した。`Equal.sym` を挟むのが定石だった。
自己申告:
- sortF は、燃料が 0 になったら挿入ソート `isort`（merge を使う）に落ちる。燃料は List.length で始めるので実行時には届かないが、証明側は燃料の十分性を示していない。燃料に関わらず sorted と perm が成り立つ、という形で示した。
- merge は、`pick` に両方の再帰呼び出し `merge(at, ys)` と `merge(xs, bs)` を渡す形で書いた。評価器が遅延なら線形だが、strict に評価されると指数時間になりうる。コンパイルして走らせる確認はしていない。
（実行時間 447 秒、ツール呼び出し 26 回、サブエージェントのトークン 151,707）
