# 並列マージソートの法則。人間が仕様として読む主張で、PROOF.bend が証明する。
# 並べ替えであることは、各値の個数で述べる（公式 demo proof_insertion_sort と同じ述べ方）。

import Base
import ./main.bend as Sort

# 法則: sort の出力は整列済み（0n から始めて昇順）
law sort_sorted:
  for +d: Nat
  for t: Sort.Tree(d)
  Sort.Sorted(Sort.sort(d, t))

# 法則: sort は入力の並べ替え。どの値 x も、出力の中に、入力の木の葉と同じ回数だけ現れる
law sort_perm:
  for +x: Nat
  for +d: Nat
  for +t: Sort.Tree(d)
  {Sort.count(x, Sort.sort(d, t)) == Sort.count(x, Sort.leaves(d, t)) : Nat}
