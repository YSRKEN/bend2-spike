```
結果: PASS
検査の回数: 7（フック 4 回・手動 3 回。別に --verdict を 1 回試したが、コンテナに Lean が無く動かなかった）
main.bend の行数 / PROOF.bend の行数: 15 / 110
補題の数: 10
方針: 実装は `max.go(xs, x)` を補助に置き、Nil なら x、Con{h, t} なら `Nat.max(x, max.go(t, h))` と畳む（停止性の検査が縮む引数を先頭に求めるので、`max(x, xs)` は `max.go(xs, x)` に委ねる）。証明は `Spec.LE` の反射・推移、`Nat.max` が両引数以上であること、`Nat.max(a, b)` が a か b に等しいこと、`Spec.All` の上界に関する単調性を補題にし、`max.go` についての主補題 `Go.all`・`Go.elem` をリストの帰納法で示して、各法則はそれを呼ぶだけにした。`Nat.max` の場合分けを結果に渡す所は、計算した値に match できないので、引数で受ける補助 def（`Nat.max.cases.succ`、`Elem.max`）に分けた。
詰まった点:
- def は使う前に定義しておく必要があった: `expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)` / `observed : Nat.max.cases.succ`。補助 def を呼び出し元の上へ移して解決。
- `%e : P` の P は目標全体でなければならず、部分式だけ書くと `expected : Either<&1, &1, {1n+Nat.max(ap, bp) == 1n+ap : Nat}, ...>` / `observed : {1n+Nat.max(ap, bp) == 1n+ap : Nat}` になった。一方は `Equal.cong` に置き換え、もう一方は `Or(..., Laws.Spec.Elem(_, xs))` と目標全体を書いて解決。
- LAWS 経由で `Laws.M.max.go` と書いても届かない: `expected : a defined name` / `observed : Laws.M.max.go`。PROOF.bend からも `import ./main.bend as M` して `M.max.go` と書いた。
- パターンで束縛した `t` を型と引数で複数回使って `observed : t (consumed more than once)`。`Con{+h, +t}` にして解決。
自己申告: なし
```
