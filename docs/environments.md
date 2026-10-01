# Bend 2 を動かす環境

Bend 2 には Windows のネイティブ版が無い。公式インストーラは Windows で `Bend needs Linux, macOS or WSL.` を出して止まり、
配布物も Linux と macOS（arm64・x64）用だけだった。この検証では、次の 3 つの環境で動かした。
Linux と macOS では公式インストーラをそのまま使い、Windows では WSL に同梱のコンテナ CLI（wslc）で Bend を入れたコンテナを動かした。

## 確かめた環境

処理時間を比べるときは、この表の CPU とメモリを前提に読む。Windows の数値は、コンテナの中から見えるものも併記した。

| 項目 | Linux（Claude Code のクラウド環境） | Windows（wslc のコンテナ） | macOS（コンテナなし） |
|---|---|---|---|
| OS | Ubuntu 24.04.4 LTS（x86_64）、カーネル 6.18.44 | Windows 10 上の wslc 3.0.1.0。コンテナは Debian 12（bookworm-slim）、WSL 2 のカーネル 6.18 | macOS 26.6.2（arm64、型番 Mac14,7） |
| CPU | Intel Xeon Processor @ 2.10GHz（`lscpu` の表記。KVM 上の仮想 CPU、1 ソケット 4 コア、1 コア 1 スレッド） | AMD Ryzen 5 3600（6 コア 12 スレッド、定格 3.6 GHz） | Apple M2（高性能 4 コア、高効率 4 コア） |
| 使える CPU | 4（`nproc`）。cgroup による CPU の上限はなし（`cpu.cfs_quota_us` が -1） | コンテナから 12（`nproc`） | 8（`hw.ncpu`） |
| メモリ | 約 15.7 GiB（`MemTotal` 16,480,972 kB）、スワップなし。シェルのプロセスには cgroup で約 13.4 GiB（14,345,035,776 バイト）の上限 | 64 GB。コンテナから見えるのは約 31 GiB（WSL の既定で、機のメモリの半分と推定） | 16 GB |
| GPU | なし（`nvidia-smi` が無い） | NVIDIA GeForce RTX 5060 Ti。`--gpus all` でコンテナから見える（[gpu.md](gpu.md)） | M2 の GPU（10 コア、Metal 4）。bend 2.0.34 では使えない（[gpu.md](gpu.md)） |
| clang | 18.1.3 | 14.0.6（`--target native` のイメージ） | Apple clang 21.0.0（Xcode 同梱） |
| Lean | 4.34.0 | 4.34.0（`--target verdict` のイメージ） | 4.34.0（elan で `~/.elan` に導入） |

クラウド環境はセッションごとに割り当てが変わりうる。Linux の列のうち、OS の版と clang は処理時間を測った 2026-09-30 のセッションの値。
カーネルの版・CPU・使える CPU・メモリ・GPU は、同じ 2026-09-30 に別のセッションで調べた値（`uname`、`lscpu`、`nproc`、`free -h`、`/proc/meminfo`、
cgroup v1 の `memory.limit_in_bytes` と `cpu.cfs_quota_us`。cgroup v2 の `cpu.max`・`memory.max` は存在しなかった）で、
処理時間を測ったときの割り当てと同じとは限らない。

手順だけ知りたいなら README の「動かし方」で足りる。この文書は、その手順の裏付けと、選択の理由をまとめたもの。
特に断りのない記述は、実際に動かして確かめたこと。ガイドなどの記述だけに基づくものには「（文書のみ）」、
確かめていないものには「（未確認）」と書いた。

## 何が要るかは、やりたいことで決まる

| やりたいこと | 要るもの | 大きさ |
|---|---|---|
| 実行する（`bend x.bend`）、証明を検査する（`--check-only`） | bend 本体だけ（依存は glibc のみ） | 91 MB |
| ネイティブビルドする（`bend x.bend -o x`） | 上に加えて clang 14 以上 | clang 一式で約 197 MB |
| Lean で証明を再検査する（`--verdict`） | 上に加えて Lean v4.34.0 | 2.9 GB |

重いのは Lean で、OS の違いではない。ベースイメージの差は数 MB しかない（ubuntu:24.04 が約 30 MB、
debian:bookworm-slim が約 28 MB）。大きさはクラウド環境で `dpkg` や `docker image inspect` から測った。

## Linux: 公式インストーラがそのまま使える

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
export PATH="$HOME/.bend/bin:$PATH" BEND_NO_TELEMETRY=1
```

実行する前にスクリプトの中身を読み、linux-x64 版の SHA256（`78106a97af242429dcc057258eb8d10f69cddebcd5e263022185a52d003e09bf`）が
一致することを確かめた。公式インストーラは最新版を入れるので、版を固定したいときは、同じ手順（tarball の取得、SHA256 の照合、
`~/.bend` への配置）を自分で行う。このリポジトリのフック（`.claude/hooks/session-start.sh`）はそうしている。

`BEND_NO_TELEMETRY=1` を付けておくと、`bend` の初回の呼び出しが速くなる。付けないと 8 秒かかり、付けると 0.2 秒未満だった。
bend が 1 日 1 回行う更新の確認の通信が原因と推測しているが、切り分けてはいない。

### clang は 14 以上。`!` 付きの並列呼び出しには 19 以上とされる

ガイドの要件は「clang 14+; 19+ with `!`」（文書のみ）。実際には clang 18 でも、`!` 付きのビルドを含めて通った
（GPU が無いので `!` は CPU で走った）。19 が必要になる条件は未確認。Windows のコンテナの clang 14 でも、
`server.bend` のネイティブビルドは通った。

### `--verdict` には Lean v4.34.0 を入れる

```sh
curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o elan-init.sh
sh elan-init.sh -y --default-toolchain leanprover/lean4:v4.34.0
export PATH="$HOME/.elan/bin:$PATH"
```

初回の `--verdict` はカーネルをビルドするので約 27 秒かかる（`~/.bend/bendtt` ができる）。2 回目以降は 0.2〜0.4 秒。

### musl の Alpine では動かない

bend は glibc に動的リンクしている。alpine:3.20 では `exec /root/.bend/bin/bend: no such file or directory` で起動しなかった。

## macOS: GPU 以外は公式インストーラだけで動く

Apple M2 の Mac で、Linux と同じ公式インストーラを使い、2.0.34 を `~/.bend` に入れた（darwin-arm64 版。
インストーラに書かれた SHA256 と、GitHub のリリースの digest が一致することを確かめた）。コンテナは要らない。
macOS 26 には `sha256sum` があるので、`web/pong/fetch.sh` もそのまま通った。

| 試したこと | 結果 |
|---|---|
| `server/server.bend` をインタプリタで起動 | `/`・`/hello/Bend`・`/pow2/20`・404 がすべて期待どおり |
| 同じくネイティブビルド（`bend server.bend -o server`） | 1.4 秒でビルドでき、応答も同じ。Apple clang 21 で通った |
| `bend PROOF.bend --check-only`（`server/`・`sort/`） | どちらも `ALL PROOFS CHECK`、各 0.1 秒 |
| `bend PROOF.bend --verdict`（`server/`・`sort/`） | どちらも `ALL PROOFS CHECK`。カーネルのビルドを含む初回は 18.7 秒、2 回目からは 0.14〜0.26 秒（下の小節） |
| `concurrency/stall.bend` の 4 経路（深さ 30） | Windows と同じ傾向。pure と fork では最中の `/` が 0.46 秒待たされ、step と proc では待たされない |
| `bend web/index.html -o web/dist`、pong のまとめ | どちらもでき、ブラウザで描かれた。コンソールのエラーは無し |
| `!` を含むプログラムのビルド | 2.0.34 では `-o` が失敗する。原因と回避、2.0.27 で GPU を動かした結果は [gpu.md](gpu.md) の「macOS」 |
| 公式の pong のネイティブのウィンドウ版 | `--gpu off` を付ければ動き、キーで遊べる（下の「pong」の小節） |

速さの計測（`bench/run.sh`）は macOS でも動く。M2 で測った結果は [benchmarks.md](benchmarks.md) の「macOS（Apple M2）」にある。
C 版には OpenMP が要り、Apple clang は `-fopenmp` を直接は受け付けないので、Homebrew の libomp（`brew install libomp`）を入れる。
`bench/run.sh` はそれを見つけて使う。

### `--verdict` は Lean を入れれば Linux と同じく通る

Linux と同じ elan の手順で、Lean v4.34.0（darwin_aarch64 版）を入れた。`~/.elan` は 2.7 GB になった。
シェルの設定ファイルを書き換えたくなかったので `--no-modify-path` を付け、PATH は使うときに足している。

```sh
curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -o elan-init.sh
sh elan-init.sh -y --no-modify-path --default-toolchain leanprover/lean4:v4.34.0
export PATH="$HOME/.bend/bin:$HOME/.elan/bin:$PATH" BEND_NO_TELEMETRY=1
```

`server/` と `sort/` で `bend PROOF.bend --verdict` を実行すると、どちらも `ALL PROOFS CHECK` で終了コード 0 だった。
初回の `server/` はカーネル（`~/.bend/bendtt/`、4.6 MB）のビルドを含めて 18.7 秒、そのあとは `server/` が 0.26 秒、`sort/` が 0.14 秒。
`--check-only` のときに出る `Use --verdict for mathematical validity.` の行は出なかった。

bend は Lean を PATH から探さず、`~/.elan/toolchains/` の下の `lean` を直接呼ぶ（下の Windows の節）。そのため、PATH に `~/.elan/bin` が
無くても `--verdict` は通る。PATH が要るのは、Lean の有無を `lean` コマンドで調べるこのリポジトリのフックのほうで、
`.claude/hooks/lib-bend.sh` が足している（[claude-code.md](claude-code.md)）。

`1n + 1n == 3n` を `{==}` で証明したファイルに `--verdict` をかけると、終了コード 1 で落ちた。ただし落ちたのは手前の型検査の段で、
Lean のカーネルが誤りを捕まえるところまでは確かめていない。

### pong はネイティブのウィンドウで動く。GPU は切っておく

公式の pong（`web/pong/fetch.sh` で取ってくる `main.bend`）は、自分では `!` を書いていないのに、ネイティブビルドが Metal のエラー（[gpu.md](gpu.md) の「macOS」）で止まった。
画面を受け持つ Base の `App` が、コマごとに `Image.drop!` を呼ぶためである（`bend base App` で確かめた）。
画面のあるアプリは、どれも同じ理由で GPU 用のビルドに入ると推定している。

`-o` はエラーで終わるが、実行ファイル自体はでき、`.gpu` だけが作られない。そのまま起動すると GPU 用のプログラムを作り直そうとして
同じエラーになるので、`--gpu off` を付けて CPU で描かせる。

```sh
bash web/pong/fetch.sh
bend web/pong/main.bend -o /tmp/pong    # エラーで終わるが /tmp/pong はできる
/tmp/pong --gpu off
```

「Pong」という 512×512 のウィンドウが開き、左右のパドルとボールが描かれた。1 秒おいて画面を 2 回撮ると、ボールとパドルの位置が
変わっていて、ゲームが進んでいた。キーの操作は、利用者が手で W/S と ↑/↓ を押して効くことを確かめた（2026-10-01）。
Claude Code から osascript でキーを送ろうとしたときは、macOS のアクセシビリティの許可が無く、
`osascriptには補助アクセスは許可されません。 (-1719)` で止まった。Windows では表示先が無くてネイティブのウィンドウ版を動かせなかったが
（[web.md](web.md)）、macOS ではそのまま動く。

### Docker でも arm64 のまま動くが、素の macOS より遅い

Docker Desktop 29.7.2 の VM は arm64 で、`container/Containerfile` は BuildKit が渡す `TARGETARCH` を見て、arm64 なら linux-arm64 版の bend を、
amd64 なら linux-x64 版を取る（それぞれの SHA256 を照合する）。`--platform` を付けなければ arm64 で作られ、エミュレーションを通らない。

```sh
docker build -t bend2-slim -f container/Containerfile container
docker run --rm -v "$PWD":/work -w /work/server bend2-slim bend PROOF.bend --check-only
```

| 作り方 | ビルド | `--check-only`（コンテナの起動を含む、3 回） |
|---|---|---|
| arm64（既定） | 29 秒 | 1.07 秒、0.92 秒、0.97 秒 |
| `--platform linux/amd64`（x64 のエミュレーション） | 66 秒 | 6.9 秒、6.0 秒、7.0 秒 |

素の macOS では同じ検査が 0.1 秒で済む。amd64 は、Containerfile が x64 版しか取らなかったころに 1 回だけ測ったときは 1.9 秒で、
今回の 6〜7 秒との差は追っていない。clang 入りの `--target native` も arm64 で作れ（26 秒、`docker image inspect` で 573 MB）、
`-p 8080:8080` で起動した `server.bend` のネイティブビルドに Mac から 4 経路とも期待どおりに届いた。
VM に割り当てられていたのは CPU 4・メモリ 4 GB で、GPU 用の `--target gpu` は CUDA が要るので Mac では使えない。
素の macOS で動かすほうがよい。

TARGETARCH を見る形に変えたあと、Windows の wslc で作り直してはいない。wslc が `TARGETARCH` を渡さない場合も、空なら x64 版を取るので、
以前と同じ動きになるはずである（未確認）。

Claude Code のサンドボックスの中から `docker build` を実行すると、1 分で `DeadlineExceeded: context deadline exceeded` になった。
サンドボックスの外で実行すると通った。

## Windows: wslc のコンテナで動かす

wslc は WSL に同梱のコンテナ CLI で、別のコンテナエンジンを入れなくても使える。WSL 2.9.3 以上が要り、コンテナは WSL 2 の
Linux カーネルの上で動く（文書のみ。Microsoft Learn「Get started with WSL container」
https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers 、本文取得済み、2026-09-29 更新の版）。

確かめたことは次のとおり。

- **Windows 10 でも動いた。** 検索結果の抜粋（Phoronix など）では、対象は Windows 11 とされていた。
- **一般の Linux ディストリビューションが無くても動いた。** 確かめた機の WSL に登録されていたのは Docker Desktop の内部用のもの
  （`docker-desktop`）だけで、wslc で Bend を動かしている間も停止したままだった。ディストリビューションが 1 つも
  登録されていない状態は未確認。
- **Docker Compose や、WSL ディストリビューションの中から wslc を使う場合には制約がある。** endjin の記事
  https://endjin.com/blog/trying-out-wsl-containers の抜粋による（本文は未取得）。
- **GPU はコンテナから見える。** `wslc run --gpus all` で `nvidia-smi` が通った。ただし bend の GPU 実行には制限がある（[gpu.md](gpu.md)）。

### コンテナは 4 種類作れる: 最小構成、clang 入り、Lean 入り、GPU 用

`container/Containerfile` は debian:bookworm-slim に bend を入れる（SHA256 の照合つき）。多段にしてあり、`--target` を付けないと
最小構成、`--target native` を付けると clang 入り、`--target verdict` を付けると Lean 入りになる。
GPU 用の `--target gpu` もあり、使い方と制限は [gpu.md](gpu.md) にある。

| イメージ | 入っているもの | `wslc image list` での大きさ | 初回のビルド |
|---|---|---|---|
| 最小構成（例: `bend2-slim`） | bend | 179 MB | （未計測） |
| `--target native`（例: `bend2-native`） | bend、clang 14.0.6 | 565 MB | 40 秒 |
| `--target verdict`（例: `bend2-verdict`） | bend、Lean 4.34.0（elan で導入）、ビルド済みのカーネル | 3.35 GB | 127 秒 |
| `--target gpu`（例: `bend2-gpu`） | bend、clang 19.1.1、CUDA 12.9 の NVRTC と cuda.h、libomp。ベースは nvidia/cuda の Ubuntu 24.04 | 1.5 GB | 92 秒（libomp を足す前の版） |

最小構成で `--check-only` を 1 回走らせると、コンテナの起動を含めて約 0.8 秒かかる。

### Lean 入りのイメージでは、カーネルをビルドした状態で持っておく

`--target verdict` は、最小構成に elan で Lean v4.34.0 を入れ、小さなファイルに `--verdict` を 1 回かけて、カーネル
（`~/.bend/bendtt/<ハッシュ>/`）をビルドした状態で保存する。こうしておくと、コンテナを起こすたびの `--verdict` が
`server/` で 0.55 秒、`sort/` で 0.28 秒で済む。カーネルが無い状態から作ると 32 秒かかった。

bend は Lean を PATH から探さない。`~/.elan/toolchains/leanprover--lean4---v4.34.0/bin` の `lean` と `leanc` を直接呼ぶ
（bend 本体の JS を読んで確かめた）。PATH から elan を外してもカーネルを作り直せたのはこのためで、`~/.elan` ごと隠すと
`Error: the kernel did not build (lean: Executable not found in $PATH: "lean"); --verdict needs Lean v4.34.0 ...` で失敗した。
Lean を別の場所に置くなら、ビルドしたカーネルを環境変数 `BENDTT` で指せばよい（エラー文による。未確認）。

同じ最小構成を、クラウド環境の Docker で作ると `docker image inspect` の Size は約 69 MB だった。wslc の 179 MB と違うのは、
圧縮後か展開後かといった数え方の違いだと推測している（未確認）。

### サーバーに Windows から接続するには、コンテナの中で 0.0.0.0 に待ち受ける

コンテナの中で 127.0.0.1 に待ち受けると、`-p 8080:8080` でポートを公開しても Windows からは届かない
（`curl` が終了コード 56 で切られる）。ポートの転送が、コンテナの 127.0.0.1 ではなく外側のアドレスに届くためだと推定している。

そこで `server.bend` は待ち受け先を環境変数 `BEND_HOST` から読み（無ければ 127.0.0.1）、Containerfile で `BEND_HOST=0.0.0.0` を
設定した。これで Windows の `curl.exe` から `/`・`/hello/Bend`・`/pow2/20`・404 がすべて期待どおりに返った。
起動・接続・停止のコマンドは README の「動かし方」にある。

### クラウド環境でコンテナを作るときは、プロキシの CA 証明書が要る

Claude Code のクラウド環境の Docker でこの Containerfile を作ると、コンテナの中にプロキシの CA 証明書が無いため、
curl が終了コード 60 で止まった。確認のときだけ CA を足した派生版で作った。公開している Containerfile には CA の記述を入れていない。

---

最終更新: 2026-10-01
