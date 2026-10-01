# 担当に渡した指示

`ai-proofs/` の実験で、各担当（サブエージェント）に渡した指示の全文。`{TRIAL}`（回: t1・t2）、`{MODEL}`、`{PROBLEM}` だけを差し替え、どの担当にも同じ文面を渡した。
1 回目（t1）は、作業フォルダに回の段が無く（`runs\{MODEL}\{PROBLEM}\`）、読まないものに `docs/ai-proofs.md` が無かった。この文書は 1 回目のあとに書いたもので、1 回目の時点では存在しなかった。
担当は Claude Code の Agent ツールで、モデルを指定して起動した。
公開にあたり、手元の機のパスは `<リポジトリ>`（このリポジトリの置き場）と `<作業用の一時フォルダ>`（`bend guide` の本文と Base を書き出した場所）に置き換えた。

---

Bend 2（v2.0.34）で、人が書いた法則（`LAWS.bend`）を満たす実装と、その証明を書いてほしい。これは「法則だけを渡されたとき、AI がどこまで実装と証明を書けるか」を測る実験で、あなたはその被験者の一人である。応答は日本語で。

## 作業の場所

- 作業フォルダ: `<リポジトリ>\ai-proofs\runs\{TRIAL}\{MODEL}\{PROBLEM}\`
- そこにある `LAWS.bend` が仕様。冒頭のコメントに、何を実装するかが書いてある。
- あなたが書くのは、同じフォルダの `main.bend`（実装）と `PROOF.bend`（証明）の 2 つだけ。`LAWS.bend` は `main.bend` を `M` として import している。
- `PROOF.bend` は `LAWS.bend` を import し、各法則を同じ名前の def で証明する（法則 `rev_rev` なら `def Laws.rev_rev(...)`。`import ./LAWS.bend as Laws` とした場合）。

## 道具

- bend は Windows に無い。wslc のコンテナで動かす。Bash ツール（Git Bash）から、次の形で呼ぶ（`MSYS_NO_PATHCONV=1` が無いとパスが壊れる）:
  `MSYS_NO_PATHCONV=1 wslc run --rm -v "<リポジトリ>:/work" -w /work/ai-proofs/runs/{TRIAL}/{MODEL}/{PROBLEM} bend2-slim bend PROOF.bend`
- `.bend` を Write/Edit すると、リポジトリのフックが自動で `--check-only` を走らせ、失敗すれば内容を返す。それを手がかりにしてよい。
- 言語の資料: `<作業用の一時フォルダ>\GUIDE.md`（`bend guide` と同じもの。特に「Laws and Proofs」「Recursion and Termination」「Quantities」）と、同じ場所の `base.bend`（Base の全定義）。

## 完成の条件

1. 作業フォルダで `bend PROOF.bend` が `ALL PROOFS CHECK` を出す。
2. `@unsafe`、`?TODO`、`?名前`、外部のコード（`import "./x.c"` など）を使わない。
3. `LAWS.bend` の冒頭のコメントにある実装の条件を守る（例: 題 4 は parallel let で並列に整列する）。

## 触らないもの、読まないもの

- `LAWS.bend` は変えない。根拠: 仕様そのものなので、変えると何を証明したのか分からなくなる。
- 作業フォルダの外のファイルは書かない。根拠: ほかの被験者が同時に別のフォルダで作業している。
- このリポジトリの既存の証明（`server/`・`sort/`・`ai-proofs/runs/` のほかのフォルダ）、`.scratch/` の公式 demo、`docs/proofs.md`・`docs/ai-proofs.md` は読まない。web で Bend の証明の例を探すこともしない。根拠: 手がかりの有無で結果が変わらないよう、全員を同じ資料（上の GUIDE.md と base.bend）で比べるため。
- git の commit・push はしない。根拠: 公開リポジトリへの送出は、利用者の承認を得てから親が行う。
- ファイルを消すときは `rm` を使わない（フックが止める）。要らなくなったファイルは空にするか、報告に書く。

## 打ち切り

`bend` の検査を 60 回走らせても通らなければ（フックが自動で走らせた分も数える）、そこで止めて、どこで詰まったかを報告する。法則が偽、または証明できないと考えたら、その理由を報告して止めてよい。

## 利用者が決めること

- なし。題材・モデル・規模は利用者が決めた。実装の方針（どういうアルゴリズムで書くか、補題をどう立てるか）はあなたが決めてよい。

## 報告（この形で、最後にまとめて）

```
結果: PASS / FAIL / GAVE_UP
検査の回数: <bend を走らせた回数。フックの分も含む概数でよい>
main.bend の行数 / PROOF.bend の行数: <数> / <数>
補題の数: <数>
方針: <実装と証明の方針を 2〜4 文で>
詰まった点: <エラー文の原文を含めて、箇条書きで>
自己申告: <法則を満たすために、意図と違う抜け道を使ったと思う箇所があれば書く。無ければ「なし」>
```
