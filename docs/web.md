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

## Artifact で公開したもの

`web/` と同じ計算を、手書きの JS と速さを比べるボタン付きの 1 枚の HTML にして、claude.ai の Artifact として公開した。
bend が書き出した JS のうち Bend 由来の部分（約 1 KB）を、ページにそのまま埋め込んでいる。上の表の「手書きの JS との速さ」はこのページで測った。

---

最終更新: 2026-10-01
