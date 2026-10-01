# Bend をブラウザで動かす

Bend 2 は JavaScript にも書き出せる。`bend page.html -o dir` は、`.bend` を import した web ページを 1 つの JS にまとめる
（`bend --help`）。この文書は、mandelbrot の画素の計算を Bend で書き、ブラウザの canvas に描いた記録。ページは `web/` にある。

特に断りのない記述は、実際に動かして確かめたこと。ガイドなどの記述だけに基づくものには「（文書のみ）」、
確かめていないものには「（未確認）」と書いた。

## 結論: 動く。速さは手書きの JS とほぼ同じで、値もネイティブ版と一致した

| 確かめたこと | 結果 |
|---|---|
| まとめた JS の大きさ | 2.1 KB（ページの JS を含む。Bend 由来の部分は約 1 KB で、数個の小さな補助関数のほかにランタイムは入らない） |
| 手書きの JS との速さ | 640×480 画素・反復 256 回で、Bend 由来 598 ms、手書き 574 ms（1.04 倍。Chromium 系の内蔵ブラウザで 1 回） |
| ネイティブ版との比べ | 反復 1 回あたり約 7.5〜7.8 ns。ネイティブの 1 スレッド（約 2.4 ns）の約 3 倍 |
| 値の一致 | 4096×4096 の格子の先頭 64 行・反復 256 回の合計が、C と同じ 467,323 |

JS に出した Bend は、ガイドのとおり逐次に走る（「The JavaScript target ignores all that and just runs sequentially.」）。
parallel let も `!` も、ブラウザでは並列にならない（文書のみ）。

## 動かし方

```powershell
# ページをまとめる（出力は web/dist。git の管理からは外してある）
wslc run --rm -v ${PWD}:/work -w /work bend2-slim bend web/index.html -o web/dist
```

`web/dist/index.html` は ES モジュールを読むので、ファイルを直接開くのではなく、HTTP で配る。
このリポジトリを Claude Code のデスクトップアプリで開いているなら、`.claude/launch.json` の `web-dist` がそれをする
（`python -m http.server` で `web/dist` を配る）。

ページは画素ごとに Bend の `escape` を呼び、クリックした点を中心に 4 倍に拡大する。開発者ツールのコンソールでは
`bend.escape(256n, -0.5, 0)` のように、Bend の関数を直接呼べる。

## 書き出された JS を読むと分かること

`web/mandel.bend` の `orbit`（末尾で自分を呼ぶ再帰）は、JS では `for(;;)` のループになっていた。F32 の演算は一つずつ
`Math.fround` で包まれ、32 ビット浮動小数点の丸めがそのまま再現される。ネイティブ版・GPU 版と値が一致するのはこのためである。

JS との受け渡しは、ガイドの「IO and Concurrency」の最後の段落のとおりだった。`U32` と `F32` は number、`Nat` は BigInt で渡す（`escape(256n, …)`）。
JS の number を F32 の引数に渡すと、関数の中の最初の演算で丸められる。値をネイティブ版と完全に揃えたいときは、渡す前に `Math.fround` をかける。

## ページの形のまとめ方

- `index.html` に `<script type="module" src="./app.js">` を書き、`app.js` で `import M from "./mandel.bend"` とする。
  `M` の下に、`.bend` の IO 以外の def が名前どおりに並ぶ（`M.escape`、`M.orbit`、`M.b2u`）。
- まとめる処理の実体は Bun のバンドラ（`Bun.build`、`target: "browser"`、`minify: true`）で、`.bend` を読むプラグインを足したもの
  （bend 本体の `cli_bundle` を読んで確かめた）。
- 出力先を消さずにまとめ直すと、古い `chunk-*.js` が残る。`index.html` は新しいほうを指すので、動きには関わらない。

## 画面のあるアプリ（App）も、受け皿を書けばブラウザで動く

Bend の `App.run` は、ネイティブビルドでは X11（Linux）か Metal（macOS）のウィンドウを開く。JS に書き出すと、
`Window.open` は `Window.open: no display (build a native binary ... and run it from a desktop session)` を返すだけの仮の実装になる
（bend 2.0.34 の `effs/window_open.js`）。wslc のコンテナには WSLg の表示先（`DISPLAY`、`/tmp/.X11-unix`、`/mnt/wslg`）も無かった。
macOS ではネイティブのウィンドウ版が `--gpu off` を付ければ動いた（[environments.md](environments.md) の「macOS」）。

そこで、`App.run` の代わりをブラウザで書いた（`web/app/host.js`）。`App{view, tick}` の 2 つの関数を毎コマ呼び、
`view` が返す画像の 4 分木を canvas に塗り、キーとマウスの入力を `Event` の値にして `tick` に渡す。公式の demo
`app_pong_game_2d` を、中身に手を入れずにこれで動かした（`web/pong/`）。

```powershell
bash web/pong/fetch.sh    # 公式の main.bend を commit を固定して取ってくる（Apache-2.0 なので、リポジトリには写していない）
wslc run --rm -v ${PWD}:/work -w /work bend2-slim bend web/pong/index.html -o web/dist/pong
```

確かめたこと:

- 動く。まとめた JS は 6.9 KB で、1 コマの計算と描画は 0.1〜0.3 ms だった。
- 入力が効く。canvas に S と ↑ を送ると、左のパドルが下へ（y 座標 208 → 394）、右のパドルが上へ（208 → 22）動いた（canvas の画素を読んで確かめた）。
- Esc で `tick` が `None` を返して終わり、始め直せる。

受け皿は、公開された約束ではない次の 2 点に頼っている。bend を更新したら確かめ直す。

- `view(state)` は `{$: "Tuple", fst: 次の状態, snd: 画像}` を返す。
- `tick(events, state)` が返す IO は、「結果を受け取る関数」を渡すと結果を返す関数として書き出されている。`tick` が `IO.pure` だけで
  書かれていれば、`Some{次の状態}` か `None` が返る。音や `IO.sleep` などの入出力を使う `tick` は、この受け皿では動かない。

キーの番号は、ネイティブ版（`effs/window.c`）と同じく Mac の決まりに合わせた。文字キーは小文字の文字コード、矢印は 63232〜63235、
Esc は 27 である。ブラウザの枠が画面に出ていないと `requestAnimationFrame` が止まり、そのあいだの入力は次のコマにまとめて届く。

## Artifact で公開したもの

`web/` と同じ計算を、手書きの JS と速さを比べるボタン付きの 1 枚の HTML にして、claude.ai の Artifact として公開した。
bend が書き出した JS のうち Bend 由来の部分（約 1 KB）を、ページにそのまま埋め込んでいる。上の表の「手書きの JS との速さ」はこのページで測った。

pong も、キーの代わりに押せるボタン付きの 1 枚の HTML にして、Artifact として公開した。

---

最終更新: 2026-10-01
