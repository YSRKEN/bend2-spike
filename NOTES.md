# Bend 2 検証ノート

Bend 2（v2.0.34）を Claude Code のクラウド VM で試して得た知見の記録。作業のたびに追記する。
将来スキル（手順・規約）やフック（自動検査）へ移すことを想定し、節を分けてある。

- 記録開始: 2026-09-30
- 環境: Ubuntu 24.04.4 LTS / x86_64 / 4 コア / GPU なし / clang 18.1.3 / Lean 4.34.0
- 一次情報: 同梱ガイド `~/.bend/guide/GUIDE.md`・`EFFECTS.md`（本文取得済み）、
  公式リポジトリ https://github.com/bendlang/bend（commit 0187512 を clone して読んだ）
- 検証コード: このディレクトリの `server.bend` / `LAWS.bend` / `PROOF.bend`

凡例: 【確認】= この環境で実行して確かめた / 【文書】= ガイド等の記述のみ / 【未確認】

---

## 1. 環境構築（→ SessionStart フックとして作成済み。7 章）

- 【確認】Windows ネイティブ版はない。公式インストーラは Windows で `Bend needs Linux, macOS or WSL.` を出して止まる（install.sh の該当行を読んだ）。
- 【確認】クラウド VM では公式インストーラがそのまま動く。中身を読んでから実行した。SHA256（linux-x64）`78106a97af242429dcc057258eb8d10f69cddebcd5e263022185a52d003e09bf` が一致。
  ```sh
  curl -fsSL https://bend-lang.com/install.sh | sh
  export PATH="$HOME/.bend/bin:$PATH" BEND_NO_TELEMETRY=1
  ```
- 【確認】clang 18 のままでネイティブビルドも `!` 付きのビルドも通った（GPU がないので `!` は CPU で実行）。ガイドの要件は「clang 14+; 19+ with `!`」。19 が必要になる条件は【未確認】。
- 【確認】`--verdict` には Lean v4.34.0 が要る。
  ```sh
  curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o elan-init.sh
  sh elan-init.sh -y --default-toolchain leanprover/lean4:v4.34.0
  export PATH="$HOME/.elan/bin:$PATH"
  ```
  初回の `--verdict` はカーネルをビルドするので約 27 秒かかる（`~/.bend/bendtt` ができる）。2 回目以降は 0.2〜0.4 秒。
- 【確認】コンテナが回収されると `~/.bend`・`~/.elan`・`~/.bend/bendtt` は消える。毎回入れ直すことになる → SessionStart フックで自動化するとよい。
- 【確認】アプリから開けるのは `/home/user` 配下（と作業用の一時フォルダ）だけ。`~`（= `/root`）に置いたファイルは見えない。成果物は `/home/user` に置く。

## 2. 言語の落とし穴（→ スキル化候補: コーディング規約）

- 【確認】呼ばれる def を呼ぶ側より上に書く。逆順だと `expected : a filled definition (an unfilled law is a dead claim ...)` というエラーになり、原因がわかりにくい。
- 【文書】`if` はない。`Bool` に対して `match` する。`match` できるのは引数かパターン変数だけで、計算した値を直接 `match` できない → Bool を引数に取る補助 def（`route.root(path, String.eq(path, "/"))` のような形）を作る。
- 【確認】変数を 2 回使うには `+` が要る。証明の中でも数えられる（`consumed more than once`）。型の中にしか出てこない変数は `-`（消去）でよい。ただし、実行時に使う計算（例: `(c < 65536 : U32)`）に出る変数を `-` にすると `expected : -c` で失敗する。
- 【確認】`String.length` は文字数を返し、バイト数ではない。HTTP の `Content-Length` などに使うと非 ASCII 文字でずれる。Base には UTF-8 のバイト数を数える関数がない（`bend base` で探した）ので自作した（`utf8.bytes`）。
- 【確認】`IO.pass` は `Fail` を受け取ると `IO.die` でプログラム全体を終了させる。サーバーの接続処理で使うと、クライアントのリセット 1 回でプロセスごと落ちる（終了コード 104 を再現）。接続ごとの失敗は `match` で分けて `Socket.close` する（公式 demo の書き方）。
- 【確認】`bend x.bend -o x` がリンカに渡すライブラリは `-lpthread -lm`（と、ヘッダーを使った場合だけ X11 / alsa）に固定されている。外部ライブラリを使うには:
  ```sh
  bend main.bend -o main.c && clang -std=c11 -O3 main.c -lpthread -lm -lz -o main
  ```
  ビルド処理は環境変数 `CC` を優先して使うので、ラッパーで `-l` を足す方法もありそう【未確認】。
- 【確認】自作 effect の C 側で zlib を include すると、ランタイムの `FAR` マクロとぶつかる → `#pragma push_macro("FAR")` / `#undef FAR` / `#pragma pop_macro("FAR")` で囲む。`io_cstr` の長さ引数は `u64*`（EFFECTS.md の例は `u32` と読める書き方だが、実物は u64）。
- 【文書】C 側の effect には ABI の保証がない（「There is no ABI promise」）。Bend を更新するたびに作り直す。
- 【確認】`bend x.bend`（インタプリタ）は effect の JS 側、`-o x` は C 側を使う。時刻などは両者で値の意味が違いうる。
- 【確認】重い純粋計算（`/pow2/30`）の最中は、ほかの接続への応答が約 0.84 秒待たされた（1 回だけ測定）。ガイドの説明とは合わない印象がある。原因は【未確認】。

## 3. 法則と証明の書き方（→ スキル化候補: 証明パターン集）

構成は公式の慣習に従う。`LAWS.bend`（人間が書く仕様）が本体を import し、`PROOF.bend` が `LAWS.bend` を import して `def Laws.<法則名>` で証明する。

- 【確認】計算で両辺が一致するものは `{==}` で済む。変数が止まって計算が進まないとき（例: `String.starts_with(name, "")`）は、その変数で `match` して場合分けすれば、各場合が `{==}` で通る（`hello_echo`）。
- 【確認】Base に基本的な補題はほぼない（`Equal.cong/sym/trans` などだけ）。`Nat.add` の結合法則、`add_zero`、`s ++ "" == s` は自作した。
- 【確認】書き換え `%e : P` の向き: `e : {a == b}` のとき、`P` はゴールの `b` の位置を `_` にしたもので、書き換え後のゴールはそこが `a` になる。つまり「ゴールの中にある b を a に変える」。向きが逆なら法則の左右を入れ替えて書く（`split_prefix` はそうした）か、`Equal.sym` を使う。
- 【確認】補題を組み合わせるときは `Equal.trans` と `Equal.cong` をそのまま使えば、書き換えより読みやすい（`hello_request`）。
- 【確認】累積引数のある再帰（`utf8.bytes(s, acc)`）は、`acc` を一般化した補題 `acc + f(s) == g(s, acc)` を立てて帰納法で示す。停止性の検査は引数を左から見るので、小さくなる引数を先頭に置く。
- 【確認】「空白を含まない」のような前提は、各要素の証拠を並べた型で書くと扱いやすい（`Spec.NoSpace`: 1 文字ごとに `{False{} == Char.is_eq(c, ' ')}` を並べる）。証明側はペアを分解して書き換えに使う。等式の向きは、書き換えで使う向きに合わせて定義しておく。
- 【確認】`LAWS.bend` だけを import すると「TODOs found」で実行できない。`LAWS.bend` と `PROOF.bend` の両方を import すれば仕様の関数も実行できる。
- 【確認】失敗時のメッセージは文字列を 1 文字ずつ展開した形で出るので長い。`| cut -c1-200` などで先頭だけ見る。

## 4. 検証の方法（→ フック候補: 保存時・コミット前の自動検査）

証明が通っただけでは、法則が十分とは言えない。次を毎回行う。

1. `bend PROOF.bend` と `bend PROOF.bend --verdict` の両方が `ALL PROOFS CHECK` になる。
2. **壊して確かめる**: 実装や仕様をわざと 1 か所壊し、証明が失敗することを確かめる。
   - 教訓（M3）: `utf8.bytes` が正しいことを証明しても、`respond` が `String.length` に戻っても証明は通った。「部品が正しい」法則だけでは「部品を使っている」ことは保証されない → 応答全体の形式の法則（`response_format`）を足して塞いだ。
   - 教訓（M7・M9）: 置換が当たっていなかったり、別の理由で失敗していたりすることがある。壊した箇所が実際に変わったこと（grep）と、失敗の理由を必ず確かめる。
3. **前提が満たせることを確かめる**: 前提付きの法則は、具体例に適用して前提の証拠を実際に作る（`main` の型に具体的な等式を書いて通す）。作れなければ、法則が空虚に成り立っているおそれがある。
4. **仕様そのものを外部と照合する**: 法則側に書いた仕様（`Spec.encode`）は、Python など別の実装と出力を比べる（`"Aé日😀"` で一致を確認）。
5. **証明の範囲外を書き出す**: I/O、受信の分割、ランタイム、変換処理（ガイドに「the translation has no proof」）など。

## 5. 証明済みの法則と、範囲外として残したもの（server.bend）

| 法則 | 内容 |
|---|---|
| `root_page` | `/` への応答は決まった挨拶 |
| `hello_echo` | `/hello/<name>` の応答は name をそのまま埋め込んだ 200 |
| `utf8_bytes` | `utf8.bytes` は仕様どおり符号化したバイト列の長さ |
| `response_format` | 応答の形式全体（Content-Length が本文のバイト数、空行の後に本文） |
| `path_of_request` | 空白を含まない method と path なら、`path_of` は path を取り出す |
| `hello_request` | `<method> /hello/<name> <rest>` を受けると name 入りの 200 を返す（`path_of` と `route` をつないだもの） |

範囲外として残したもの:
- `handle` などの I/O 部分。法則が述べているのは `route(path_of(req))` という純粋な部分だけで、handler が実際にこの組み合わせを呼んでいることは述べていない。
- `TCP.recv` を 1 回（4096 バイト）読むだけなので、リクエスト行が分割されて届く場合。
- `/pow2` と 404 のルーティング。
- メソッドの区別（GET 以外にも同じ応答を返す）。

## 6. 公式 demo（io_http_server）との比較で得たこと

- 公式は受け付けループに `@unsafe` を付けて無限に回す。そのため、ファイル全体は検査を通らない。代わりに回数の上限（`Nat` の燃料）を付けると検査を通る。ガイドはサーバーのループにこの方法を勧めている。
- 公式が証明しているのは、純粋な関数 `http_response` だけ（「空行の後に本文」「応答が同じなら元のページも同じ」）。

## 7. SessionStart フック（作成済み: `.claude/hooks/session-start.sh`）

登録は `.claude/settings.json`。クラウドセッション（`CLAUDE_CODE_REMOTE=true`）でだけ動く同期実行のフック。

やること:
1. Bend 2.0.34 を版を固定して導入する。公式 install.sh と同じ手順（tarball の取得 → SHA256 照合 → `~/.bend` に配置）をフック内で行う。公式 install.sh は最新版を入れるので、版の固定のため使っていない。
2. clang が無ければ警告だけ出す。
3. elan で Lean v4.34.0 を導入する（`--no-modify-path`）。
4. 小さな証明に `--verdict` を 1 回かけて、カーネルを事前にビルドする。
5. `CLAUDE_ENV_FILE` に PATH と `BEND_NO_TELEMETRY=1` を書く（同じ行は 2 回書かない）。

各段階は「導入済みなら飛ばす」ので、何度実行しても同じ状態になる。

検証結果【確認】:
| 状況 | 結果 |
|---|---|
| 何も入っていない状態（空の HOME で再現） | 54 秒で完了。その環境変数だけで `--check-only` と `PROOF.bend --verdict` が通った |
| 導入済みの状態 | 0.12〜0.17 秒 |
| クラウド以外（`CLAUDE_CODE_REMOTE` なし） | 何もせず終了 |
| SHA256 を書き換えた場合 | 「SHA256 が一致しない。導入しない」で exit 1、何も置かない |

落とし穴:
- 【確認】最初の版は `BEND_NO_TELEMETRY=1` の設定がフックの後半にあり、それより前の `bend version` の呼び出しで 8 秒かかった。先頭に移した後は 0.2 秒未満。bend が 1 日 1 回行う更新確認の通信が原因と推測しているが、切り分けはしていない【未確認】。
- 【確認】Lean のツールチェーンは約 3.0 GB、Bend は約 98 MB。ディスクの割り当てに注意。
- 【確認】空の HOME で elan を入れると `warning: $HOME differs from euid-obtained home directory` が出るが、導入自体は成功する（テスト環境に特有の警告）。
- 【文書】スキルの説明によると、フック完了後のコンテナの状態はキャッシュされる。新しいセッションで実際に 54 秒かかるのか、キャッシュで短くなるのかは【未確認】（新しいセッションでの所要時間は測っていない）。
- フックはリポジトリの既定ブランチに入れて初めて、以後のセッションで使われる。

新しいセッションでの確認【確認】（2026-09-30、YSRKEN/bend2-spike の main `8f2f697` から起動した別セッション。報告はブランチ `claude/hook-check-report` の `report.md`）:
- PATH の先頭に `~/.bend/bin:~/.elan/bin`、`BEND_NO_TELEMETRY=1` が入っていた（フックが `CLAUDE_ENV_FILE` に書く行と一致）。
- bend 2.0.34、Lean 4.34.0、`~/.bend/bendtt` がそろっていた。
- 追加の設定なしで `bend PROOF.bend --verdict` が `ALL PROOFS CHECK`、0.59 秒（カーネルのビルドは起きなかった）。

## 8. 編集後フック（作成済み: `.claude/hooks/bend-check.sh`）

`PostToolUse`（matcher `Write|Edit`）に登録。`.bend` ファイルが変わったときだけ動く。

- 編集したファイルを `bend <file> --check-only` で検査する。
- `LAWS.bend` は単体だと未証明の法則で必ず失敗する（「TODOs found」）【確認】ので、同じディレクトリに `PROOF.bend` があればそちらを代わりに検査する。
- 本体を編集したときも、同じディレクトリの `PROOF.bend` を追加で検査する。本体の変更で証明が壊れたことに、その場で気づける。
- 失敗したら `{"decision": "block", "reason": ...}` で出力の先頭 25 行（1 行 400 文字まで）を Claude に返す。成功時は何も出さない。
- bend が見つからなければ `systemMessage` で知らせて何もしない。

パイプテスト結果【確認】（入力 JSON を直接流した）:
| 入力 | 結果 |
|---|---|
| 正常な `server.bend` | 出力なし |
| `LAWS.bend` | `PROOF.bend` に振り替えて通過 |
| `.bend` 以外（`NOTES.md`） | 何もしない |
| `/hello/` の切り取りを 6 文字にした `server.bend` | 本体は通るが `PROOF.bend` が失敗し、block で期待値の不一致を返す |
| 未定義の名前を使うファイル | block で `expected : a defined name` を返す |
| bend が無い環境 | systemMessage のみ |

落とし穴:
- 【確認】フックを作ったセッションでは、登録後に Edit しても発火しなかった。セッション開始時の作業ディレクトリが `/home/user` で、そこに `.claude/settings.json` がなかったためと考えられる（設定の監視は、開始時に設定ファイルがあったディレクトリだけが対象）。そのセッションで有効にするには `/hooks` を一度開くか、セッションを再起動する。
- 【確認】リポジトリから起動した新しいセッションでは発火した。Edit ツールで `server.bend` の `7n` を `6n` にすると、直後に「PostToolUse:Edit hook blocking error from command: "bend --check-only": bend PROOF.bend --check-only が失敗（exit 1、…）」に続けて `Laws.hello_echo` の期待値不一致が返った。戻す Edit では出力なし。ハーネス上は block が「hook blocking error」と表示される。
- 1 回の検査は 0.2〜0.6 秒【確認】。`PROOF.bend` も検査するので、編集ごとに合計 1 秒前後かかる。

## 9. スキル・フックにするときの候補（案）

- **SessionStart フック**: 7 章のとおり作成済み。
- **編集後フック**: 8 章のとおり作成済み。
- **コミット前フック**: `bend PROOF.bend --verdict` が `ALL PROOFS CHECK` でなければ止める。
- **スキル「Bend の証明」**: 3 章と 4 章の手順（補題の作り方、書き換えの向き、壊して確かめる、前提が満たせることの確認）。
- **スキル「Bend のサーバー・I/O」**: 2 章の落とし穴（IO.pass、Content-Length、リンク、FAR マクロ）。
- いずれも案で、まだ作っていない。
