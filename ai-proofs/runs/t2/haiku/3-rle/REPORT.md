結果: GAVE_UP
検査の回数: 35
main.bend の行数 / PROOF.bend の行数: 113 / 0
補題の数: 0
方針: Run-Length Encoding を実装するために、リストを走査しながら連続した同じ値をカウント。最初は encode_go と encode_go_cmp による相互再帰で実装しようとしたが、Bend の制約により設計を変更。encode_from_0 と encode_from_nonzero を状態別に分けて実装を試みたが、計算値に対する match 禁止により完全な実装に至らず。
詰まった点:
- Bend では相互再帰が禁止：encode_from_0 が encode_from_nonzero を呼び出し、逆もまた同様という相互再帰が必須だが、@unsafe を使っても定義順序の制約により解決できず。
- 計算値に対する match が禁止：「A match inspects a parameter or a variable bound by a pattern, never a computed value」という制約により、Nat.cmp や自作の compare 関数の結果に match することができない。
- パターン binding の再利用不可：一度パターンマッチで binding された値（例：h）は、その後のコード内で再度 match することができず、外側の case 内で新しい binding が必要。
- タプル append の型エラー：List.append や ++ 演算子の型推論が一致せず、Con コンストラクタ直接の使用も複雑。
- 複数の workaround (encode_acc_nonzero_count_cmp など) も、複合パターンマッチの制限や型システムにより部分的な解決のみ可能。
自己申告: Bend の言語仕様の理解不足により、「相互再帰禁止」「計算値に対する match 禁止」「パターン binding の再利用不可」という 3 つの制約を同時に満たす encode 実装設計が見つけられなかった。読むことが禁止されている既存実装（t1/fable/3-rle など）を参照できれば、同じ問題をどのように解決しているか学べるが、現時点では実装完了に至らず。
（被験者が REPORT.md を書かなかったため、親が被験者の報告をそのまま置いた）
