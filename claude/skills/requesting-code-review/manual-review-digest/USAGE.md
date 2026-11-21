# 手動のreview対象一致確認

このディレクトリは追加の手動補助ツールです。既存SKILL.md、review-package、レビュー回数・承認基準・Superset設定は変更しません。自動起動・自動合格・コードの受渡しはしません。

## 用途

指定したworking-file内容/modeとHEADのdigestを取り、後で同じ対象か確認します。commit-only review-packageに未コミット内容を勝手に混ぜず、対象一致状態を別添する用途です。staged/index版とは異なります。

Claude/Codexともskillの発見や呼出しに依存せず、同じローカルPythonファイルを明示的に手動実行できます。エージェントCLIやSupersetを起動する必要はありません。実レビューを依頼する場合も、読むpathと対象範囲・未確認状態を明示してください。

## 実行前の条件

信頼できるローカルterminal/Python/Git環境で、本人が許可した明示pathだけを選びます。資格情報・秘密・原本ログを選択しないでください。digestは暗号化や匿名化ではなく、相関・推測の余地があります。

sourceは正規化されたgitroot。実行中に他writerがいない隔離コピーを推奨します。並行変更を排除できなければ結果は未確認のままです。stdoutをsource内fileへredirectしたり、外部送信・ログ収集・自動CI合格へ接続しないでください。callerによる転送やOSの記録はこのツールでは防げません。

## 起動と入力

このファイルと同じディレクトリの `review_digest.py` を `python3 -B /absolute/path/review_digest.py` で手動起動し、stdinへmetadata JSONを1件だけ渡します。-Bはbytecode書込み防止です。下は構文例で、placeholderのまま実行せず、許可済みの使い捨てrepoへ置換してください。

```json
{"action":"snapshot","source":"/absolute/disposable-repo","paths":["src/example.py","tests/example_test.py"]}
```

stdoutは `SNAPSHOT_UNVERIFIED` とschema2 packet。コード本文・pathは出ません。packetはローカル呼出し側のメモリで保持し、次のcheckに渡します。ツール自身はfileへ保存しません。

```json
{"action":"check","source":"/absolute/disposable-repo","paths":["src/example.py","tests/example_test.py"],"packet":{"schema":2,"repository_digest":"...","revision":"...","scope_digest":"...","atomicity":"UNVERIFIED","packet_digest":"..."}}
```

receiptを渡す場合はcheck入力へ追加します。receiptは任意の申告で、真正性は確認できません。

```json
{"schema":2,"packet_digest":"...","outcome":"PASS","provenance":"declared, not authenticated"}
```

## 表示の読み方

- `SNAPSHOT_UNVERIFIED`: 二重readの観測が一致しただけ。snapshotの原子性・検査成功ではありません。
- `STALE`: HEAD・選択内容/mode・対象repo、またはreceipt対象が不一致。旧結果を使いません。
- `NOT_RUN`: 検査結果なし。
- `UNVERIFIED`: evidence schema等が不明。
- `BOUND_UNVERIFIED`: packetの申告上の一致のみ。receiptのPASSを真の合格にしません。
- `REFUSED`: 不正path/link/途中変化/上限/不正入力等。

snapshot成功だけexit0。他はexit2。exit0も安全・test・review合格ではありません。人間承認や既存レビューを置き換えません。

## 保証しないこと

ABA、最終観測後変更、祖先namespace交換、複数file原子性、真正なrunner実行、証拠偽造、未選択依存の変更、敵対的OS/Python起動環境、callerのstdout転送。全て未確認です。packetとreceipt双方を書ける相手はdigestを再計算できます。

ツールは外部通信・資格情報参照・任意command実行・fileoutputをしません。固定のread-only git rev-parseは実行します。symlink/特殊file/hardlink/path逸脱/検出した途中変更を拒否。stdin1MiB/5秒、各Git5秒、100paths/1file1MiB/合計8MiB。filesystem停止を含む全体wallclockの保証はありません。

## テストと取り消し

このディレクトリだけを対象に、`python3 -B -m unittest discover -s /absolute/path/manual-review-digest -p 'test_*.py' -q`。テストは/tmpの使い捨て合成Gitrepoだけを作り、実sourceや資格情報は使いません。19ケースは別実行者でも成功。モデル品質・実務改善は未評価です。

取り消しは追加されたこの `manual-review-digest` ディレクトリの3ファイルだけを、保存時receiptのhash一致を確かめて削除します。後続変更があれば削除を止めます。既存SKILL.md等をgit reset/checkoutしないでください。
