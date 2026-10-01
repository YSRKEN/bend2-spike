# Bend 2 を書くときの落とし穴

Bend 2（v2.0.34）で小さな HTTP サーバー（`server/server.bend`）と、メールボックスを読む MCP サーバー（[mcp-app.md](mcp-app.md)）を書いたときに、実際につまずいたことをまとめた。
同梱のガイド（`bend guide` で表示される GUIDE.md）を一度読んだ人を想定している。
上から順に読む必要はない。見出しを拾って、書いているコードに関係する節だけ読めばよい。

特に断りのない記述は、実際に動かして確かめたこと。ガイドなどの記述だけに基づくものには「（文書のみ）」、
確かめていないものには「（未確認）」と書いた。

## 構文と型

### 呼ばれる関数を、呼ぶ側より上に書く

順番を逆にすると `expected : a filled definition (an unfilled law is a dead claim ...)` というエラーになる。
文面から原因を推測しにくいので、このエラーが出たらまず定義の順番を疑う。

### `if` は無い。Bool を引数に取る補助関数を作って `match` する（文書のみ）

`match` できるのは引数かパターン変数だけで、計算した値は直接 `match` にかけられない。
条件の値を引数として渡す補助関数を作り、その中で分ける。

```
def route(+path: String) -> String:
  route.root(path, String.eq(path, "/"))   # 比較の結果を引数として渡す

def route.root(+path: String, hit: Bool) -> String:
  match hit:
    case True{}:
      respond("200 OK", "Hello from Bend!\n")
    case False{}:
      route.hello(path, String.starts_with(path, "/hello/"))
```

### 2 回使う変数には `+` を付ける

変数は既定で 1 回しか使えない。2 回使うと `consumed more than once` になり、証明の中でも数えられる。
型の中にしか出てこない変数は `-`（消去）にできる。ただし、実行時に使う計算（`(c < 65536 : U32)` など）に
出てくる変数を `-` にすると、`expected : -c` で失敗する。

### `match` は引数を宣言した順にしか使えない

`Byte{b0, b1, ..., b7}` を分解したあと、`match b7:` の中で `match b6:` と書くと、
`a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)` で落ちる。
先に束縛した `b6` より後の `b7` を先に場合分けできない（ガイドの「Scrutinees follow binder order」）。
上位のビットから判定したいときは、`cont.bits(b7, b6, ..., b0)` のように、場合分けしたい順に並べた引数を取る補助の def に渡す。
同じ文面は、使い終わった変数を場合分けしたときや、証明で書き換え（`%e : P`）のあとに場合分けしたときにも出る。

### 相互再帰は書けない。3 つの形で避ける

互いに呼び合う 2 つの def は、上の「呼ばれる関数を上に書く」と同じ `a filled definition` で落ちる。次のどれかで 1 方向の呼び出しにする。

- もう一方の結果を先に求めて、引数で渡す（表を引く `find(rest, c)` の結果を、当たったかで分ける `pick` に渡す）
- 続きを関数（クロージャ）で渡す（帰納法の仮定を `o => rt(t, o)` として補助の def に渡す）
- 選択子の引数を取る 1 つの def にまとめる（JSON の値・配列の要素・オブジェクトのフィールドの生成を `s` で切り替える）

### 数（`Nat`）のパターンの中身を 2 回使うには、場合分けする値の側を `+` にする

`match k: case 1n+q:` の `q` を 2 回使うと `consumed more than once` で落ちる。パターンの中に `+` を書く方法は見つからなかったが、
引数を `+k: Nat` にすると通った。再利用できる値を場合分けすると、取り出した中身も再利用できる（ガイドの「Matching a + value hands out + fields」）。

### 組（`A & B`）は再利用できる種類にならない。リストに入れるなら `Data` の型を作る

対応表を `List<&2, Char & Kind>` と書くと `expected : Data`、`observed : Type` で落ちた。
`type Row is Data: Row{c: Char, k: Kind}` のように 1 行を表す型を作り、`List<&2, Row>` にすると通る。
入れ子の組をパターンで分けるとき、内側の要素に `+` を付けると `an annotated term (cannot infer)` で落ちる（`case (+a, (+b, +c))`）。
内側は `+` なしで受け取る。

### 構成子の名前は全体で 1 つ。Base と重なると落ちる

`type Low is Data: LT{} ...` と書くと `duplicate declaration: LT` で落ちた。Base の比較の結果 `Cmp` の構成子 `LT` と重なる。
`EQ` も同じで、`type Enc is Data: EB{} EQ{}` は落ち、`EncB`・`EncQ` にすると通った。構成子の名前は型ごとの名前空間を持たない。

### 型のフィールドを取り出す関数は、自動では作られない

`type Msg is Data: Msg{subject: ..., ...}` に対して `Msg.subject(m)` と書くと `expected : a defined name` で落ちる。
`match m: case Msg{s, fr, d, mi}:` で取り出す。

### 関数（クロージャ）も 1 回しか使えない

ファイルを読むループで、読み終えたときに呼ぶ `done` を、次の読み取りへ進む続きの関数 `f2 => sp2 => loop(..., done)` にも持たせると、
`consumed more than once` で落ちた。続きの関数を `f2 => sp2 => d2 => loop(..., d2)` にして、`done` は呼ぶ側から 1 回だけ渡し直す。

### `do` の中では、束縛した結果を分解できない

```
do IO<Unit>:
  r : File & Result<&1, &1, U32 & String, String> <- File.read(f, 4)
  (g, res) = r
```

は `expected : a pattern (a binder or a constructor)` で落ちる。結果を引数として受け取る def を作り、そこで `match` する。

### リストと構成子を入れ子にしたパターンは書ける

Base64 の 4 文字の組を、リストの要素の構成子まで 1 つのパターンで分けられた。最後に `case _:` を置けば、ほかの形は全部そこへ落ちる。

```
def dec(xs: List<&2, B64>) -> Maybe<&2, List<&2, U32>>:
  match xs:
    case Nil{}:
      Some{[]}
    case BSix{p0, p1, p2, p3, p4, p5} <> BSix{q0, q1, q2, q3, q4, q5} <> BPad{} <> BPad{} <> Nil{}:
      ...
    case _:
      None{}
```

### `U32` は 32 個のビットの並びで、`match` で直接分解できる

`U32` は `U32{data: Word(32n)}`、`Word` は下位のビットから並べた `WCon{bit, rest}` の連なり。実行時の値もこの形のまま分解できる。
`match x: case U32{WCon{b, t}}: b` は最下位のビットを返し、5・6・2^32−1 に対して `True`・`False`・`True` を返した。
証明で計算を止めないためにこの形を使う話は [proofs.md](proofs.md) にある。

## 文字列と入出力

### `String.length` は文字数を返す。Content-Length には UTF-8 のバイト数を自分で数える

`String.length` を HTTP の `Content-Length` に使うと、日本語などの非 ASCII 文字でずれる。
Base には UTF-8 のバイト数を数える関数が無い（`bend base` で探した）ので、`utf8.bytes` を自作した。
この関数が正しいことは証明してある（[proofs.md](proofs.md) の `utf8_bytes`）。

### `IO.pass` は失敗を受けると、プログラム全体を止める

`IO.pass` は `Fail` を受け取ると `IO.die` を呼ぶ。サーバーの接続処理で使うと、クライアントが接続を 1 回
切っただけでプロセスごと落ちる（終了コード 104 を再現した）。接続ごとの失敗は `match` で分けて
`Socket.close` する。公式のデモ（`io_http_server`）もこの書き方をしている。

### 環境変数は `IO.get_env` で読める

`server.bend` は待ち受け先を `BEND_HOST` から読む（無ければ 127.0.0.1）。インタプリタでも
ネイティブビルドでも同じように動いた。

### パスのパーセントエンコードは戻さない

`/hello/%E4%B8%96%E7%95%8C` には `Hello, %E4%B8%96%E7%95%8C!` と返す。今のサーバーは受け取ったパスを
そのまま使う。

### 文字列は文字の連結リストで、文字の値は型では縛られていない

`String` は `SCon{head: Char, tail: String}` の連結リスト、`Char` は `Chr{code: U32}` で、型の上では任意の `U32` を持てる。
処理系の入り口（`io_str`）は UTF-8 を復号し、出口は各文字を UTF-8 に符号化する。

### スカラー値でない文字を出力すると、インタプリタは止まり、ネイティブ版は不正な UTF-8 を出す

```
def main() -> IO(Unit):
  IO.print(String.from_list([Char.from_u32(55296)]))   # U+D800
```

`bend x.bend` は `bend: 55296 is not a Unicode scalar value` で止まる。ネイティブ版は検査せずに `ED A0 80 0A` を出し、終了コード 0 で終わる。
`Char.from_u32` は検査しないので、ネイティブ版で外に文字を出すプログラムは、スカラー値であることを自分で守る。

### `File.read` は読んだ範囲を UTF-8 として復号し、末尾で途切れた文字を U+FFFD にする

「日本」（6 バイト）のファイルを `File.read(f, 4)` で読むと、`日` と U+FFFD になる。区切って読むと文字が化けるので、
`File.read_bytes`・`File.read_at` でバイト列（`List<U32>`、1 要素が 1 バイト）を読み、復号は自分で書く。
Base には、バイト列と文字列を変換する純粋な関数が無い（`bend base | grep -i utf` で当たるのは説明のコメントだけ）。
`File.read_at` の位置と `File.size` は `U32` なので、4 GB を超えるファイルは扱えない。

### 標準入力は `/dev/stdin` を `File.open` すれば読める

標準入力専用の effect は無いが、`File.open("/dev/stdin", "r")` で開けば、パイプからも読めた（macOS）。
パイプは 1 回の読み取りで全部が届くとは限らないので、終わり（空のバイト列）まで読み続ける。

### `IO.println` は無い。`IO.die` は終了コードも取る

`IO.print` が改行を付け、`IO.write` は付けない。`IO.println("a")` は `expected : a defined name` で落ちる。
`IO.die` の形は `IO.die(A, code, msg)` で、`IO.die(U32, "msg")` と書くと `expected : U32`、`observed : String` で落ちる（`base.bend` で確かめた）。

### ディレクトリを列挙する effect は無い

`~/.bend/bend2/effs/` に、ディレクトリの中身を返すものが無い。フォルダを自動で探すには、`Process.run` で外部コマンドを呼ぶか、自作の effect が要る。

## 並行性

### 重い純粋計算は、ほかの接続をその計算が終わるまで待たせる

`/pow2/30`（2 の 30 乗を分割統治で数える）の応答を計算している間、ほかの接続への応答が止まる。

| 条件（Windows の wslc、ネイティブビルド。Ryzen 5 3600、コンテナから 12 スレッド） | 時間 |
|---|---|
| 何もしていないときの `/` | 0.002〜0.010 秒 |
| `/pow2/30` を単独で | 2.36 秒 |
| `/pow2/30` を投げた 0.15 秒後の `/`（5 回） | 1.40〜2.12 秒 |
| `--threads 1` で、`/pow2/28`（2.43〜3.07 秒）の最中の `/`（3 回） | 2.27〜2.90 秒 |

スレッドを 1 本にしても同じ形で待たされるので、作業スレッドの取り合いではない。
Claude Code のクラウド環境（4 コア）でも、`/pow2/30` の最中に約 0.84 秒待たされた（1 回だけ測定）。
どちらの環境の CPU とメモリも [environments.md](environments.md) の「確かめた環境」にある。

ガイドを読むと、これは仕様どおりの動きだと分かる。Bend のプログラムは Node.js と同じく一つのイベントループで
複数の計算を交互に進める。各計算は次の入出力に行き着くまで純粋な部分を（全コアで並列に）走らせ、
ソケットなどで待つ計算だけが順番を譲る（文書のみ。GUIDE.md の「A Bend program is a set of computations
interleaved by one event loop, as in Node.js」の段落）。純粋な計算は途中で割り込まれない。

### 待たせないには、計算を区切って順番を譲るか、子プロセスに回す。`IO.fork` では避けられない

同じ `pow2(30)` を 4 通りの呼び方で受けるサーバー（`concurrency/stall.bend`）を書き、重い要求を投げた 0.3 秒後から `/` を
叩いて比べた（`concurrency/measure.sh`、3 回。生の値は `concurrency/results/` に機ごとにある）。下の表は Windows（Ryzen 5 3600、wslc）の値。
macOS（Apple M2）でも同じ傾向で、最中の `/` の 1 回目は、その場で計算するときと `IO.fork` のときが 0.29〜0.41 秒、
区切って譲るときが 0.013〜0.024 秒、子プロセスに回すときが 0.0005 秒前後だった（`concurrency/results/m2-macos.tsv`）。

| 呼び方 | 重い要求の応答 | 最中の `/` の 1 回目 |
|---|---|---|
| その場で計算する（今の `server.bend` と同じ） | 1.47〜1.49 秒 | 1.13〜1.17 秒 |
| `IO.fork` に渡して `IO.join` で待つ | 1.47〜1.49 秒 | 1.14〜1.16 秒 |
| 64 個に区切り、区切りごとに `IO.sleep(0)` で順番を譲る | 1.57〜1.62 秒 | 0.03〜0.05 秒 |
| 自分自身を `Process.run` で子プロセスとして起こし、計算させる | 1.51〜1.56 秒 | 0.001〜0.003 秒 |

- **`IO.fork` は効かない。** 渡した計算の純粋な部分も、同じイベントループの上で、次の入出力まで割り込まれずに走る。
  ほかの言語のスレッドのつもりで使うと外れる。
- **区切って譲ると、待ちは区切り 1 つ分に縮む。** 代わりに重い要求が約 8% 遅くなった。区切りを細かくするほど待ちは縮み、
  重い要求は遅くなると考える（区切りの数は 64 でしか測っていない）。
- **子プロセスに回すと、待たされない。** ガイドによれば、ネイティブビルドの `Process.run` は子を入出力用のスレッドで待つので、
  イベントループは空いたままになる（文書のみ）。子を起こす分、重い要求は 2〜5% 遅くなった。子も全コアを使うので、
  重い要求が同時に何本も来ると、子どうしで CPU を取り合う（未確認）。

この計測では、上の表の旧い計測（`/pow2/30` 単独で 2.36 秒）より重い要求が速く終わっている。機の状態の違いと推定している。
比べるときは、同じ表の中の値どうしで比べる。

wslc で計測するときに踏んだことが 2 つある。サーバーが待ち受けを始める前から `curl` で叩き続けると、その後も接続が通らなくなった
（コンテナのログに `listening` が出るのを待ってから叩くと通る。ポートの転送が詰まると推定）。また、Git Bash で `MSYS_NO_PATHCONV=1` を
export すると、`curl -o /dev/null` が Windows の curl に渡って書き込みに失敗する（終了コード 23）。

### 並列の呼び出しは、スレッド数に応じて速くなる

`a b = pow2(p) pow2(p)` のように 2 つの呼び出しを並べると、ネイティブビルドでは並列に走る。
クラウド環境で `pow2(28n)` を測ると、`--threads` 1・2・4 で実時間が 1.094・0.642・0.321 秒だった（各 1 回）。
ガイドによると、スケジューラは仕事を一度コアに渡したら動かさないので、2 つの呼び出しの重さをそろえておく
必要がある（文書のみ）。

### 受け付けのループは、回数の上限を付けると証明の検査を通る

公式のデモは受け付けのループに `@unsafe` を付けて無限に回すので、ファイル全体は検査を通らない。
回数の上限（`Nat` の燃料）を付けると検査を通る。ガイドもサーバーのループにこの方法を勧めている。
`server.bend` は上限を 100 万回にしている。

## 速さとメモリ

### 読んだバイト列は 1 バイトあたり約 32 バイトのメモリを食う。区切りは 64 KiB にする

`File.read_at` は読んだ分を一度に `List<U32>` の連結リストにして返す。223 MB のファイルを区切って読むと、ネイティブ版の最大メモリは
区切り 64 KiB で 4 MB、1 MiB で 35 MB、16 MiB で 530 MB だった。区切りを 4 KiB まで小さくすると読み取りの往復が効いて倍ほど遅くなり、
64 KiB で 0.6 秒が最も速かった（Apple M2）。

### 1 バイトずつの状態機械は、読み取りだけの 7〜10 倍かかる

同じ 223 MB を 1 バイトずつ状態機械に通すと、区切り行を探すだけで 4.3 秒、見出しを集める状態を足すと 7.1 秒かかった（読み取りだけは 0.6 秒）。
1 バイトごとに状態のレコードを組み直す分と推定する。行が終わったときにしか変わらない部分は別のレコードに分けて、
毎バイト組み直すフィールドを減らしたが、分けない形と比べてはいない（未確認）。

### `bend x.bend` はネイティブ版より大きくメモリを使う

同じ読み取りで、`bend x.bend` は約 280 MB、ネイティブ版は 4 MB だった。型検査の分が含まれるうえ、実行を JavaScript 側で行っていると推定する
（上のスカラー値の項で、インタプリタのエラーの文面が JavaScript 側の関数にしか無かった）。常駐させるサーバーはネイティブ版にする。

## C と外部ライブラリ

### インタプリタは effect の JS 側、ネイティブビルドは C 側を使う

`bend x.bend`（インタプリタ）と `bend x.bend -o x`（ネイティブビルド）では、入出力の実装が別になる。
時刻などは両者で値の意味が違いうる。

### ネイティブビルドがリンクするのは `-lpthread -lm` だけ

`bend x.bend -o x` がリンカに渡すライブラリは `-lpthread -lm`（ヘッダーを使ったときだけ X11 や ALSA も）に
固定されている。zlib などを使うときは、C を書き出してから自分でリンクする。

```sh
bend main.bend -o main.c && clang -std=c11 -O3 main.c -lpthread -lm -lz -o main
```

ビルド処理は環境変数 `CC` を優先して使うので、ラッパーで `-l` を足しても通る。macOS（Apple clang 21）で、clang の引数の最後に `-lz` を足す
シェルスクリプトを `CC` に指定し、`bend main.bend -o main` で zlib を使う effect をビルドできた。bend はこの `CC` に `--version` も渡して
clang の版を調べるので、ラッパーは引数をそのまま clang に渡す形にしておく。

```sh
printf '#!/bin/sh\nexec clang "$@" -lz\n' > cc-lz && chmod +x cc-lz
CC=$PWD/cc-lz bend main.bend -o main
```

### 自作 effect の C 側で zlib を読み込むと、`FAR` マクロがぶつかる

ランタイムの `FAR` マクロと zlib のヘッダーが衝突する。`#pragma push_macro("FAR")`・`#undef FAR`・
`#pragma pop_macro("FAR")` で囲む。例は `effects/zlib_crc_example.c`（crc32 を呼び、Python と同じ値を得た）。macOS でも、標準の zlib にリンクして同じ値を得た
（`"hello, bend"` で `697224591`）。Bend 側では、effect の def の本体に `import "./zlib_crc.c"` を書く（`bend guide effects`）。
`-lz` を付けずに `-o` でビルドすると、リンクで `_crc32` が見つからずに失敗する。

`io_cstr` の長さの引数は `u64*`。EFFECTS.md の例は `u32` と読める書き方だが、実物は u64 だった。
C 側の effect には ABI の保証が無い（文書のみ。「There is no ABI promise」）ので、Bend を更新するたびに作り直す。

---

最終更新: 2026-10-02
