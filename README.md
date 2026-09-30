# Bend 2 検証メモ

[Bend 2](https://github.com/bendlang/bend)（v2.0.34）を Claude Code のクラウド環境（Ubuntu 24.04 / x86_64 / GPU なし）で試した記録です。

| ファイル | 内容 |
|---|---|
| `NOTES.md` | 環境構築・言語の落とし穴・証明の書き方・検証方法などの知見 |
| `server.bend` | 小さな HTTP サーバー（`/`、`/hello/<name>`、`/pow2/<d>`、404） |
| `LAWS.bend` | サーバーの純粋な部分についての法則（仕様） |
| `PROOF.bend` | 法則の証明。`bend PROOF.bend --verdict` で `ALL PROOFS CHECK` |
| `zlib_crc_example.c` | 自作 effect から zlib を呼ぶ C 側の例 |
| `.claude/hooks/session-start.sh` | Bend 2.0.34 と Lean 4.34.0 を導入する SessionStart フック |
| `.claude/hooks/bend-check.sh` | `.bend` の編集後に `--check-only` を走らせる PostToolUse フック |

## 動かし方

```sh
bend server.bend -o server && ./server      # http://127.0.0.1:8080
bend PROOF.bend --verdict                   # 証明の検査（Lean v4.34.0 が必要）
```
