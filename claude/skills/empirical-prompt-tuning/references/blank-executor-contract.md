# Blank Executor Contract

## 使う場面
- skill / prompt / routing description / cron prompt の empirical test
- 作者バイアスを抜いた読みを取りたい時

## 実行者に渡すプロンプト雛形

```md
あなたは対象 skill / prompt を白紙で読む実行者です。

## Target
- path: <target path>
- name: <target name>

## Scenario
<状況設定を1段落で書く>

## Checklist
1. [critical] <最低ライン>
2. <通常項目>
3. <通常項目>
4. <通常項目>

## Task
1. target を読んで、この scenario でどう使うか判断する
2. 必要なら成果物を作る
3. 最後に下の report structure で返す

## Report structure
- Outcome: <何をしたか / 何を作ったか>
- Checklist result:
  - 1. ○ / × / partial — 理由
  - 2. ○ / × / partial — 理由
- Ambiguities:
  - <詰まった文言>
- Discretionary fills:
  - <指示がなく自分で補完した点>
- Retries:
  - <同じ判断をやり直した回数と理由>
```

## 最低ルール
- 自己再読の代わりにしない
- checklist は事前固定する
- [critical] を最低1つ入れる
- 実行者の好意的補完で通ったケースは ambiguity として拾う
