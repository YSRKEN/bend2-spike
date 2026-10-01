# Bend 2 検証

[Bend 2](https://github.com/bendlang/bend)（v2.0.34）で、証明付きの小さな HTTP サーバーを書いて動かした記録です。
Linux（Claude Code のクラウド環境）と、Windows の WSL コンテナ（wslc）の両方で動作を確かめました。
そのあと macOS（Apple M2）でも、コンテナなしで動くことを確かめました。
そのあと、Windows の機（Ryzen 5 3600、RTX 5060 Ti）で、Bend の売り文句を一つずつ試しました。

## 試したこと

| 問い | 答え | 詳しく |
|---|---|---|
| Windows の GeForce で `!`（GPU 実行）は動くか | 公式の手順では動かない（WSL2 に concurrent managed access が無く、黙って CPU で走る）。生成した C の判定を 1 行外すと動き、答えも合う | [docs/gpu.md](docs/gpu.md) |
| 「C 並みの速さ」は本当か | mandelbrot では C とほぼ同じ速さで、スレッド数にも同じように伸びる。n-queens では C の 3〜4 倍遅く、仕事を均等に割らないとスレッド数に伸びない。Apple M2 でも同じ傾向 | [docs/benchmarks.md](docs/benchmarks.md) |
| GPU はどれだけ速いか | mandelbrot（反復 4096 回）で CPU 12 スレッドの約 8 倍。ただし毎回約 1.7 秒の固定費がある。n-queens では CPU の 7 倍遅い。公式のレイトレーサーでは CPU 12 スレッドの約半分の速さ | [docs/benchmarks.md](docs/benchmarks.md) |
| 並列に走るソートの正しさを証明できるか | できた。parallel let で並列に走るマージソートについて、出力が整列済みで入力の並べ替えであることを証明した。最初の版は自前の比較のせいで遅かったが、法則を変えずに実装を Base の比較に替えて証明し直し、2^17 個が 30 秒から 65 ms になった | [docs/proofs.md](docs/proofs.md) |
| `--verdict`（Lean のカーネル）は証明の誤りを捕まえるか | カーネル自体は捕まえる。手で偽に書き換えた主張も、停止しない自己参照や循環による「証明」も拒んだ。ただし定義のすり替えは見抜けず、2.0.34 には `--verdict` がカーネルに見せないまま通す def もある（bendlang/bend#1186）。法則がカーネルに渡っていることは commit 前のフックで確かめる | [docs/proofs.md](docs/proofs.md) |
| AI に法則だけ渡して、実装と証明を書かせられるか | Sonnet・Opus・Fable は 4 題すべてを解き、Lean のカーネルでも通った。Haiku は 1 題も解けず、禁じた `@unsafe` にも手を出した。ただし証明が通っても、指数時間や 2 乗の遅い実装が混じった（法則は速さを縛らない） | [docs/ai-proofs.md](docs/ai-proofs.md) |
| 証明付きのサーバーは実用の速さか | 最小のサーバーで毎秒 1.7〜2.0 万件。Go の 8 割前後で、Node.js の 2.5 倍以上 | [docs/benchmarks.md](docs/benchmarks.md) |
| 重い計算の最中に、ほかの接続を待たせずに済むか | 済む。計算を区切って `IO.sleep(0)` で譲るか、子プロセスに回す。`IO.fork` では避けられない | [docs/language.md](docs/language.md) |
| Mac で動くか | GPU 以外は公式インストーラだけで動く。GPU（Metal）は 2.0.34 では Apple のコンパイラが落ちてビルドできず、2.0.27 なら動き、mandelbrot（反復 4096 回）で同じ版の CPU 8 スレッドの約 12 倍速い | [docs/environments.md](docs/environments.md)、GPU は [docs/gpu.md](docs/gpu.md) |
| ブラウザで動くか | 動く。まとめた JS は 2.1 KB、速さは手書きの JS とほぼ同じで、値もネイティブ版と一致した。画面のあるアプリも、`App.run` の代わりの受け皿を書けば動き、公式の pong が遊べた | [docs/web.md](docs/web.md) |

## 構成

| パス | 内容 |
|---|---|
| `server/server.bend` | 小さな HTTP サーバー（`/`、`/hello/<name>`、`/pow2/<d>`、それ以外は 404） |
| `server/LAWS.bend` | サーバーの純粋な部分についての法則（人間が書く仕様） |
| `server/PROOF.bend` | 法則の証明。`bend PROOF.bend` が `ALL PROOFS CHECK` なら通過 |
| `effects/zlib_crc_example.c` | 自作 effect から zlib を呼ぶ C 側の例 |
| `container/Containerfile` | Bend を入れたコンテナ。既定は最小構成、`--target native` で clang 入り、`--target gpu` で CUDA 入り |
| `bench/` | 速さの比較の題材（mandelbrot、n-queens。Bend と C の両方。公式のレイトレーサー、HTTP サーバーの比較）と計測のスクリプト、生の結果 |
| `concurrency/` | 重い計算の最中に接続を待たせない方法を比べるサーバーと、計測のスクリプト |
| `ai-proofs/` | AI に法則だけ渡して実装と証明を書かせた実験。題（`problems/`）、各モデルの成果物と報告（`runs/`）、渡した指示（`PROMPT.md`） |
| `sort/` | 並列マージソートと、その正しさ（整列と並べ替え）の法則・証明 |
| `web/` | Bend で書いた mandelbrot をブラウザで描くページと、Bend の App（公式の pong）をブラウザで動かす受け皿 |
| `docs/` | 分かったことの記録（下の「もっと知るには」） |
| `docs/bend2-spike-slides.pdf` | 検証の解説スライド（15 枚。クラウド環境での初回の検証の時点） |
| `.claude/hooks/` | Claude Code のフック（Bend の導入、`.bend` の編集後の検査、commit 前の証明と docs の検査） |

## 動かし方

### Linux・macOS

Bend の導入は [docs/environments.md](docs/environments.md) を参照してください（公式インストーラ、Linux・macOS 用）。
macOS では、`!` を含むプログラムや、公式の pong のような画面のあるアプリを `-o` でネイティブビルドすると失敗します（2.0.34。原因と回避は [docs/gpu.md](docs/gpu.md) の「macOS」）。

```sh
cd server
bend server.bend                            # インタプリタで起動。http://127.0.0.1:8080
bend server.bend -o server && ./server      # ネイティブビルド（clang 14 以上が必要）
```

待ち受け先は環境変数 `BEND_HOST` で変えられます（既定は `127.0.0.1`）。

### Windows（wslc）

Bend には Windows 版がありません。WSL に同梱のコンテナ CLI `wslc`（WSL 2.9.3 以上）を使うと、
Linux ディストリビューションや Docker を入れずに動かせます。PowerShell で、リポジトリのルートから実行します。

```powershell
# イメージを作る（最小構成。--check-only と実行まで）
wslc build -t bend2-slim -f container/Containerfile container

# 証明を検査する
wslc run --rm -v ${PWD}:/work -w /work/server bend2-slim bend PROOF.bend --check-only

# サーバーを起動する（止めるまで戻らない）
wslc run --rm --name bend-server -p 8080:8080 -v ${PWD}:/work -w /work/server bend2-slim bend server.bend
```

サーバーを起動したまま、別の PowerShell から接続し、終わったら止めます。

```powershell
curl.exe http://127.0.0.1:8080/hello/Bend
wslc stop bend-server
```

ネイティブビルドには clang 入りのイメージを使います（約 565 MB）。接続と停止は上と同じです。

```powershell
wslc build -t bend2-native --target native -f container/Containerfile container
wslc run --rm --name bend-server -p 8080:8080 -v ${PWD}:/work -w /work/server bend2-native sh -c "bend server.bend -o /tmp/server && /tmp/server"
```

## 証明の検査

```sh
cd server
bend PROOF.bend --check-only    # 型検査による証明の検査
bend PROOF.bend --verdict       # Lean で証明済みのカーネルによる再検査（Lean v4.34.0 が必要）
```

`LAWS.bend` を単体で検査すると、証明の無い法則が未解決として扱われ、必ず失敗します。検査は `PROOF.bend` に対して行います。
Windows では、Lean 入りのイメージを作ると `--verdict` も使えます（約 3.4 GB、初回のビルドは約 2 分）。

```powershell
wslc build -t bend2-verdict --target verdict -f container/Containerfile container
wslc run --rm -v ${PWD}:/work -w /work/server bend2-verdict bend PROOF.bend --verdict
```

Linux と macOS での Lean の導入は [docs/environments.md](docs/environments.md) にあります。

## もっと知るには

| 文書 | 読む人と中身 |
|---|---|
| [docs/language.md](docs/language.md) | Bend を書く人へ。つまずいたこと（例: 重い純粋計算の最中は、ほかの接続がその計算の終わりまで待たされる） |
| [docs/proofs.md](docs/proofs.md) | 法則と証明を書く人へ。書き方のこつ、毎回の確かめ方、このサーバーで証明したこととしなかったこと |
| [docs/gpu.md](docs/gpu.md) | GPU を試したい人へ。Windows（wslc）で `!` を GPU に載せる手順と公式に動かない理由、macOS の Metal で 2.0.34 が落ちる件と回避 |
| [docs/benchmarks.md](docs/benchmarks.md) | 速さが気になる人へ。Bend の CPU・GPU と C の比較 |
| [docs/web.md](docs/web.md) | ブラウザで動かしたい人へ。JS への書き出しと、ページのまとめ方 |
| [docs/ai-proofs.md](docs/ai-proofs.md) | AI に証明を書かせたい人へ。4 モデル × 4 題の結果と、証明が通っても見落とすもの |
| [docs/environments.md](docs/environments.md) | 動かす環境を用意する人へ。Linux、Windows（wslc）、macOS、何にどれだけ容量が要るか |
| [docs/claude-code.md](docs/claude-code.md) | このリポジトリを Claude Code で開発する人へ。フックの仕組みとクラウド環境の癖 |
