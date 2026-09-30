# Bend 2 を動かす環境

Bend 2 には Windows のネイティブ版が無い。公式インストーラは Windows で `Bend needs Linux, macOS or WSL.` を出して止まり、
配布物も Linux と macOS（arm64・x64）用だけだった。この検証では、次の 2 つの環境で動かした。
Linux では公式インストーラをそのまま使い、Windows では WSL に同梱のコンテナ CLI（wslc）で Bend を入れたコンテナを動かした。

## 確かめた環境

処理時間を比べるときは、この表の CPU とメモリを前提に読む。Windows の数値は、コンテナの中から見えるものも併記した。

| 項目 | Linux（Claude Code のクラウド環境） | Windows（wslc のコンテナ） |
|---|---|---|
| OS | Ubuntu 24.04.4 LTS（x86_64）、カーネル 6.18.44 | Windows 10 上の wslc 3.0.1.0。コンテナは Debian 12（bookworm-slim）、WSL 2 のカーネル 6.18 |
| CPU | Intel Xeon Processor @ 2.10GHz（`lscpu` の表記。KVM 上の仮想 CPU、1 ソケット 4 コア、1 コア 1 スレッド） | AMD Ryzen 5 3600（6 コア 12 スレッド、定格 3.6 GHz） |
| 使える CPU | 4（`nproc`）。cgroup による CPU の上限はなし（`cpu.cfs_quota_us` が -1） | コンテナから 12（`nproc`） |
| メモリ | 約 15.7 GiB（`MemTotal` 16,480,972 kB）、スワップなし。シェルのプロセスには cgroup で約 13.4 GiB（14,345,035,776 バイト）の上限 | 64 GB。コンテナから見えるのは約 31 GiB（WSL の既定で、機のメモリの半分と推定） |
| GPU | なし（`nvidia-smi` が無い） | NVIDIA GeForce RTX 5060 Ti。ただしコンテナからは使っていない（使えるかは未確認） |
| clang | 18.1.3 | 14.0.6（`--target native` のイメージ） |
| Lean | 4.34.0 | なし |

クラウド環境はセッションごとに割り当てが変わりうる。Linux の列のうち、OS と clang は処理時間を測った 2026-09-30 のセッションの値。
CPU・使える CPU・メモリ・GPU は、同じ 2026-09-30 に別のセッションで調べた値（`lscpu`、`nproc`、`free -h`、`/proc/meminfo`、
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
- **GPU をコンテナから使えるかは未確認。** `wslc run` には `--gpus` オプションがある。

### コンテナは 2 種類作れる: 最小構成と、clang 入り

`container/Containerfile` は debian:bookworm-slim に bend を入れる（SHA256 の照合つき）。多段にしてあり、`--target` を付けないと
最小構成、`--target native` を付けると clang 入りになる。どちらにも Lean は入れていないので、`--verdict` は Linux で行う。

| イメージ | 入っているもの | `wslc image list` での大きさ | 初回のビルド |
|---|---|---|---|
| 最小構成（例: `bend2-slim`） | bend | 179 MB | （未計測） |
| `--target native`（例: `bend2-native`） | bend、clang 14.0.6 | 565 MB | 40 秒 |

最小構成で `--check-only` を 1 回走らせると、コンテナの起動を含めて約 0.8 秒かかる。

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

最終更新: 2026-09-30
