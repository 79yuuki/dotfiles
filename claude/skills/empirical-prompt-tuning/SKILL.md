---
name: empirical-prompt-tuning
description: >-
  Empirically improve agent-facing instructions such as skills, AGENTS.md, CLAUDE.md, slash commands, task prompts, routing descriptions, and cron prompts by testing fixed scenarios with a blank executor. Use when creating or heavily revising high-frequency or routing-sensitive instructions.
---

# Empirical Prompt Tuning

プロンプトや skill の品質は、作者の主観だけでは分からない。
**白紙実行者に実際に動いてもらい、固定シナリオ + fixed checklist + hold-out で改善を回す**。
高頻度 skill / routing-sensitive skill は、運用へ昇格する前にこの検証を通す。

## Quick route

- **新規 skill / 大改訂 skill / routing更新** → まず Iteration 0、次に白紙実行者テスト
- **高頻度 skill** → 白紙実行者テスト **必須**
- **単発プロンプト** → この skill は使わない
- **dispatch 不可** → 自己再読で代替しない。`empirical evaluation skipped: dispatch unavailable` と明示して止める

## 高頻度 skill の定義

以下のいずれかを満たしたら高頻度扱い。
- 週次以上で繰り返し使う
- 他 skill の routing / quality gate に効く
- cron / automation / review loop の中核に入る
- company-wide / cross-project に再利用する
- `hot.md` に上げたい、または standing rule 化したい

## ワークフロー

### Step 0: Iteration 0 — description と body の整合チェック

まず静的に見る。
- frontmatter `description` の trigger / NOT for / 想定用途を確認する
- body が description の約束を本当にカバーしているか確認する
- 乖離があれば、白紙実行者テストの前に直す

これは **false positive 防止**。
description だけ強くて body が弱い状態でテストすると、読者が好意的に補完して通ってしまう。

### Step 1: ベースラインを作る

最低これを固定する。
- **シナリオ 2-3本**: 中央値 1、本番で困りやすい edge 1-2
- **要件チェックリスト 3-7項目**
- **[critical] 項目を最低1つ**
- **hold-out 1本**: 収束判定まで温存する境界ケース

先に固定し、評価の途中で都合よく変えない。

詳しい起動契約は [references/blank-executor-contract.md](references/blank-executor-contract.md)、
レポート雛形は [references/report-template.md](references/report-template.md) を使う。
Latest local gate summaries may be mirrored in [references/latest.md](references/latest.md) / [references/latest.json](references/latest.json) when the environment is updating this skill package directly.



### Step 2: 白紙実行者を dispatch する

自己再読ではなく、**別セッション / 別 subagent** に読ませる。
実行者には以下だけ渡す。
- 対象プロンプト or skill のパス
- シナリオ
- fixed checklist
- レポート構造

実行者には、成果物に加えて次を自己申告させる。
- 不明瞭点
- 裁量補完
- 再試行回数

### Step 3: 両面評価を取る

最低限これを見る。
- **success**: `[critical]` が全部通ったか
- **accuracy**: checklist 達成率
- **efficiency**: 無駄な探索・往復・過読が減ったか
- **executor feedback**: 不明瞭点 / 裁量補完 / retries

`tool_uses` / `duration_ms` が session metadata から取れるなら記録する。
取れない環境では、**success / accuracy / executor feedback を優先**して続行する。
時間短縮だけを最適化しない。

### Step 4: 1 iteration 1 theme で直す

1回で全部盛りしない。
- 関連する微修正はまとめてよい
- 無関係な修正は次の iteration に回す
- 「この修正が checklist のどれを改善するか」を先に言語化してから直す

### Step 5: 再実行する

毎回 **新しい白紙実行者** で回す。
同じ実行者を再利用しない。
前回の改善を学習しているから。

### Step 6: 収束判定をする

停止目安:
- 連続2回で新規不明瞭点 0
- accuracy の改善が小さい
- efficiency の変動が小さい
- hold-out で大崩れしない

3回以上回しても不明瞭点が減らないなら、修正パッチではなく構造自体を見直す。

## 高頻度 skill gate

高頻度 skill は、**以下を満たすまで standing rule 扱いしない**。
1. Iteration 0 を通す
2. 白紙実行者テストを最低1 iteration 実施する
3. 結果を `reports/empirical-prompt-tuning/` に残す
4. hold-out を含む改善方針を次アクションに書く

「良さそう」だけで `hot.md` / routing / org-wide rule に昇格しない。

## レポート保存先

毎回、以下を残す。
- Markdown: `reports/empirical-prompt-tuning/YYYY-MM-DD-<target>-iterN.md`
- Latest summary: `reports/empirical-prompt-tuning/latest.md`
- Machine-readable summary: `reports/empirical-prompt-tuning/latest.json`
- `references/latest.md` / `references/latest.json` may mirror the latest in-package gate note when skill packaging is the active task; do not treat that mirror as a substitute for `reports/empirical-prompt-tuning/` in normal runs.
- When `reports/` writes are not available from the active skill-management tool, save a concise skipped-gate note in `references/YYYY-MM-DD-<target>.md` and link it from the “Recent skipped examples” list; label it clearly as a fallback, not a full empirical report.

最低限の記録項目:
- target
- scenario list
- checklist
- success / accuracy / efficiency notes
- executor-reported ambiguity / discretionary fills / retries
- change made this iteration
- next action
- status (`doing` / `converged` / `skipped` / `rewrite-needed`)

## Red flags

- **自己再読で代替する** → ダメ
- **1シナリオだけで満足する** → 過適合しやすい
- **不明瞭点ゼロ1回で終える** → 早すぎる
- **MUST / ALWAYS を足すだけで改善した気になる** → 最後の手段
- **metricだけ見て質的フィードバックを捨てる** → 危ない
- **同じ白紙実行者を使い回す** → ダメ

## 実務ルール

- 高頻度 skill の更新では、まずこの skill を読み、検証計画を立てる
- `skill-creator` から辿ってきた時は、`../skill-creator/SKILL.md` の high-frequency gate と合わせて扱う
- dispatch 不能ならスキップを明記し、実証済みみたいな顔をしない
- 実測で効いたものだけを routing / hot / org-wide rule に昇格する
