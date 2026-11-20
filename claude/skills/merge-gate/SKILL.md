---
name: merge-gate
description: >-
  Decide whether a pull request can merge without a human reading the diff. An agent that did not write the change applies path/diff rules, re-runs the evidence, and records a high / medium / low verdict bound to the head commit. Use for 「この PR は自動マージしていい？」「マージ判定して」/ merge gate / 自動マージの精度を測る・段階導入する / agent が書いた fix PR を人が読まずに入れる前. Not for choosing how to integrate your own branch (finishing-a-development-branch), claiming your own work is done (verification-before-completion), or design review (requesting-code-review).
---

# Merge Gate（人が diff を読まずにマージしてよいかの判定）

判定は 4 つの決まりで成り立つ。

- **書いた本人は判定しない。** 書いた側は、自分が意図した物を確かめてしまう。判定するのは、その変更を書いていないエージェントで、書いた側の会話を引き継がない。
- **CI の green と bot の承認は、判定に数えない。** どちらも、変更を利用者のように動かしていない。
- **判定は head のコミットに付く。** コミットが増えたら無効で、やり直す。
- **判定される変更は、判定の決まりを書き換えられない。** 設定は base ブランチの版を読む。

迷ったら低く付ける。高く付けて外すと、人が読まない不具合が入る。低く付けて外しても、人が 1 回読むだけで済む。

## 先に合意しておくこと

判定の精度を上げても、見逃しはゼロにならない。人が読むのをやめるには、次をリポジトリの持ち主と決めておく。決まっていないリポジトリでは、`observe` から先へ進めない。

- どの変更を対象にし、どんな時に人へ回すか（下の設定に書く）。
- 合意した手順どおりに進めて見逃しが出た時、個人の責任にせず、設定とテストを直す。
- レビューが担っていた他の役割（設計の相談、変更の共有）を、どこで続けるか。
- high で入った PR を、時々抜き打ちで読む。

## 段階

設定の `stage` に書く。段階を上げるのは人が決める。

| stage | すること | マージの流れ |
|---|---|---|
| `observe` | 判定を手元に記録するだけ | 変えない |
| `advise` | 判定を PR に書き、low と medium は人が読むよう促す | 人が決める |
| `enforce` | high で、同じコミットの必須 CI が全部通った PR だけ、人が読まずに入れてよい | high 以外は人が読む |

次の段階へ進む材料は、high と付けた PR がその後どうなったか。`scripts/followups.py` で、後から来た修正と revert に突き合わせる。件数が少ないうちは上げない。

## 設定

リポジトリの `.github/merge-gate.toml` に書く。ひな形は [assets/merge-gate.example.toml](assets/merge-gate.example.toml)。対象にする PR の種別、センシティブな path、「単純な変更」の大きさ、差分から読める引き金と確かめることを書く。設定が無いリポジトリでは判定せず、設定を作る所から始める。

## 判定役を起動する

PR を書いたセッションは、新しいサブエージェントを判定役として起動する。渡すのは、リポジトリ、PR の番号、head の SHA、この skill の場所だけ。自分の結論・自信・検証の要約は渡さない。渡すと、判定役はそれを確かめ直すだけになる。

判定役は読み取りとテストの実行だけを行い、PR のブランチには書き込まない。

## 判定の手順

1. **ルールで上限を決める。** モデルは使わない。取得が 1 つでも失敗したら、判定を出さずに止まる。

   ```bash
   set -euo pipefail
   REPO=OWNER/REPO; N=123; SKILL=<この skill のディレクトリ>; D=$(mktemp -d)
   gh pr view "$N" -R "$REPO" --json title,headRefOid,baseRefName,changedFiles > "$D/pr.json"
   SHA=$(jq -r .headRefOid "$D/pr.json")
   gh api "repos/$REPO/contents/.github/merge-gate.toml?ref=$(jq -r .baseRefName "$D/pr.json")" \
     -H "Accept: application/vnd.github.raw" > "$D/merge-gate.toml"
   gh api "repos/$REPO/pulls/$N/files" --paginate \
     --jq '.[] | {filename, previous_filename, additions, deletions, status, has_patch: has("patch")}' > "$D/files.jsonl"
   python3 "$SKILL/scripts/classify_diff.py" --config "$D/merge-gate.toml" --title "$(jq -r .title "$D/pr.json")" \
     --files "$D/files.jsonl" --expect-files "$(jq -r .changedFiles "$D/pr.json")"
   ```

   open の PR にも、マージ済みの PR にも使える。`$SHA` が、この判定が付くコミット。出力の `ceiling` が上限で、以降の手順は上限を下げることしかできない。`low` ならここで終わり、`reasons` を記録して人に回す。`checks` に出た問いには、手順 2 で 1 つずつ答える。スクリプトが 0 以外で終わった時は、判定を付けない。

2. **証拠を自分で実行する。** PR 本文の検証の欄は、信じる対象ではなく、実行し直す対象として読む。実行は、`$SHA` を checkout した使い捨ての worktree で行う。
   - 修正の前に失敗し、後に成功するテストがあるか。base で新しいテストだけを走らせて失敗を見て、`$SHA` で成功を見る。
   - 変えた振る舞いを、実物で動かす（プロジェクトの verify skill、E2E、API の呼び出し、CLI）。ビルドが通ることと unit test が通ることは、ここでは証拠にならない。

3. **テストが弱められていないかを見る。** assertion の削除、skip の追加、期待値の書き換え、snapshot の更新、テストファイルの削除。`signals.test_lines_deleted` が 0 でなければ、必ず中身を読む。

4. **範囲を見る。** 題名と関係のない変更が混ざっていないか。変えた関数に、他の呼び出し元が無いか（blast-radius）。

5. **判定を付ける。** 上から順に当てはめ、最初に当たったものにする。

   | 判定 | 条件 |
   |---|---|
   | low | 上限が low。または、次のどれかに当たる: テストを実行できなかった・実物で動かせなかった（判定不能）、理由が PR から読み取れないテストの弱体化、修正前の失敗を再現できない、題名と関係のない変更が混ざっている |
   | medium | 上限が medium。または、low には当たらないが、high の条件を全部は満たさない（欠けた条件を書く） |
   | high | 上限が high で、次を全部満たす: 修正前の失敗と修正後の成功を自分で見た。実物で動かして確かめた。テストの弱体化が無い。`checks` の問いに全部答えられた |

6. **記録する。** 記録の直前に `gh pr view "$N" -R "$REPO" --json headRefOid` を読み直し、`$SHA` と違っていたら、記録せずに手順 1 からやり直す。
   - 手元: どの段階でも、1 行を追記する。

     ```bash
     mkdir -p ~/.claude/state/merge-gate
     jq -nc --arg repo "$REPO" --argjson pr "$N" --arg sha "$SHA" --arg verdict low --arg ceiling high --arg stage observe \
       '{ts: (now|todate), repo: $repo, pr: $pr, head_sha: $sha, verdict: $verdict, ceiling: $ceiling, stage: $stage, reasons: $ARGS.positional}' \
       --args "実物で動かせなかった（検証環境に入れない）" >> ~/.claude/state/merge-gate/verdicts.jsonl
     ```

   - PR: `advise` と `enforce` では、判定・`$SHA`・実行したコマンドと結果・確かめていないことを PR に書く。`observe` では PR に新しく書き込まない。ただし、プロジェクトの PR テンプレートに検証の欄があり、そこに判定を書く決まりがある時は、その欄に書く。PR に書くのは判定役ではなく、起動したセッション。

## 判定の後

- 判定の後にコミットが増えたら、記録の `head_sha` と PR の head が食い違う。その判定は使わず、手順 1 からやり直す。
- `observe` では、マージの流れを変えない。判定が low でも止めない。記録だけを残す。
- medium と low で差し戻した修正が 3 回続いたら、人に回す。
- high は「人が diff を読まなくてよい」という意味で、マージの許可ではない。段階が変えるのは、人が読むかどうかだけ。誰がマージを実行してよいかは、プロジェクトのマージの決まりに従う。未解決のレビュースレッドと必須 CI も、別に満たす。
- マージ、PR の作成、required check や branch protection の変更は、この skill では行わない。

## 精度を測る

```bash
python3 scripts/followups.py OWNER/REPO --days 60 [--config merge-gate.toml]
```

判定ごとに、件数・後から同じファイルに修正が来た件数・revert の件数を出す。判定は、マージされたコミットに付いたものだけを数える。マージから観測の時間（既定 48 時間）が経っていない PR は「観測中」として別に数え、件数に入れない。`--config` に設定ファイルを渡すと、ルールだけで決まる上限ごとの集計も出る。判定がまだ無いリポジトリでも、設定の良し悪しを過去の PR で測れる。

- 後続の修正は「同じファイルを触った」で数えている。元の PR が原因とは限らないので、high で後続が付いた組は中身を読む。
- 見逃しを決まりに変える条件は、2 つ以上の PR で起き、差分から読み取れること。`[[checks]]` か `sensitive` に足し、効かなくなった決まりは消す。
- 新しい決まりを試す時は、過去の PR を当時の差分だけで判定し直す。後から修正が重なった PR と、同じくらいの大きさで何も起きなかった PR を並べ、重なった側に high が多く付くなら、その決まりは入れない。

## 関連 skill

- verification-before-completion: 書いた側が、完了と言う前に行う検証
- finishing-a-development-branch: 自分のブランチをどう統合するかを選ぶ
- blast-radius: 小さな差分の影響範囲を、実行で確かめる
- test-quality: テストが壊れを見つけられるかの検品
- exploratory-qa / playwright-e2e: 実物で動かして確かめる手段
- harness-engineering: risk-tiered merge の考え方

## 出典

- naobit「HOOTLとは何か：AIに「判断」と「実行」をどこまで任せるか」https://note.com/naobit_/n/ne04255bec534 （Chainguard の公表内容の解説。判定と実行の分離、ルールの信号を主にする、迷ったら低く、SHA への紐付け。2026-11-20 参照）
- Addy Osmani「How the Claude Code team thinks about verification」https://claude.dev/blog/how-the-claude-code-team-thinks-about-verification/ （observe から始める、変更は自分の check を書き換えられない、差分から読める引き金、3 回で人へ、見逃しを決まりに変える）
- nrs「コードを読まずにマージするために必要なこと」https://zenn.dev/nrs/articles/c777388530aa84 （先に合意しておくこと）
- cursor/plugins pstack の shipping playbook（書いた本人の判定は数えない、CI の green と bot の承認は判定ではない。考え方を独自に書き直した）

最終更新 2026-11-20。
