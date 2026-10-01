結果: PASS
検査の回数: 約13回（フックの分を含む。--verdict は1回試したが、bend2-slim に Lean が無く、カーネルを組み立てられずに止まった）
main.bend の行数 / PROOF.bend の行数: 62 / 323
補題の数: 22（DiscT・DiscF の判別用の型 2 つを含む。Laws.* の 2 つは数えていない）
方針: 実装について。msort(fuel, xs) は、2 要素以上のリスト h<>h2<>t を h<>evens(t) と h2<>odds(t) の 2 本に分け、`a b = msort(f, ..) msort(f, ..)` の parallel let で並列に整列してから merge する。停止性は fuel（sort が長さを渡す）で示した。merge は merge.go(xt, yt, x, y, le) という形で、比較の結果 le を引数で受け取る。こうすると、どちらの再帰でも、左から順に見て最初に変わる引数が構造的に小さくなる。
証明について。sort_perm は、count に関する 3 つの補題（merge は個数を足し合わせる、evens と odds で個数を分け合う、msort の帰納）と、bump・add の算術の補題から示した。sort_sorted は、補題に長さの不変条件 LE(len xs, fuel) を持たせて示した。使った補題は merge.go の整列の帰納（e: {le == Nat.is_le(a,b)} を受ける）、is_le から Spec.LE を導く補題、evens・odds の長さの上界、le_trans、le_succ である。
詰まった点:
- merge.go で le を先に match したところ、「a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)」で拒まれた。`match xt yt le:` と引数の順に一度に match する形に直して通した。
- msort で fuel の f を 2 回使ったところ、「f (consumed more than once)」が出た。`case 1n+(+f):` に直した。
- 証明の中で消去の let（`-co = ...`）を型の中で何度も使ったところ、「co (consumed more than once)」が出た。`+` の let に変えた。証明の def の引数とパターン変数にも、ほぼすべて `+` を付けた。
- `+la = h <> M.evens(t)` には「an annotated term (cannot infer)」が出た。`{.. : List<&2, Nat>}` を付けて直した。
- le_trans の c を消去引数（-c）にしたまま match したところ、「a live scrutinee (a - scrutinee matches only in a dead region)」が出た。`+c` に直した。
自己申告: なし。msort の fuel が 0 のときは xs をそのまま返すが、sort は長さを fuel として渡すので、この分岐は空リストでしか通らない。整列の証明でも、長さが fuel 以下であることをきちんと示して使っている（fuel が 0 で中身のあるリストの場合は、矛盾として閉じている）。動作も確かめた。一時的に main を足して [5,3,9,1,3,0,7,2] を整列させ、[0,1,2,3,3,5,7,9] が返ることを見た。足した main と、そのとき作った一時ファイルはすでに取り除いた（一時ファイルはごみ箱へ送った）。
（実行時間 396 秒、ツール呼び出し 23 回、サブエージェントのトークン 144,780）
