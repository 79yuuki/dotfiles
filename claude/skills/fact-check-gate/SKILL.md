---
name: fact-check-gate
description: >-
  Verify factual claims before publishing or sending outputs: URLs, domains, dates, prices, product names, people, legal/compliance statements, and external references. Use for public-facing content, decks, proposals, posts, and reports.
---

# Fact Check Gate — ハルシネーション防止スキル

事実に基づく情報を含む成果物（PR動画、LP、メール、SNS投稿等）を生成する前に、事実情報を`facts.json`として明示的に定義・検証するゲートフロー。

## いつ使うか

- ✅ ドメイン名・URL・価格・人名・日付を含む成果物を生成する時
- ✅ 外部公開物（LP、SNS、プレスリリース、動画）の作成時
- ✅ 「この情報、本当に合ってる？」と不安になった時
- ❌ 内部メモ・調査ノート（リスクが低い）

## フロー（3ステップ）

### Step 1: facts.json 作成（生成前）
1. 成果物に含まれる事実情報を洗い出す
2. `references/facts-schema.md` に従い `facts.json` を作成
3. 不明な項目は `unknowns` に入れて**人間に質問**
4. `blocking: true` の unknown が残っている間は**生成禁止**

### Step 2: 生成
- 事実値は **facts.json からのみ引用**。自由入力・推測禁止
- `no_guess_categories`: domain, url, price, person, date, product

### Step 3: 検証（生成後）
- 成果物から事実クレームを抽出し facts.json と突合
- 差分があれば FAIL → 修正
- `references/review-prompt.md` のプロンプトでCodexレビュー

## 詳細

- `references/facts-schema.md` — facts.json スキーマ定義
- `references/unknown-criteria.md` — 「不明」判定基準
- `references/review-prompt.md` — Codexレビュー用プロンプト
- `references/extraction-rules.md` — 事実クレーム抽出ルール
- `references/agents-policy.md` — AGENTS.md反映用ポリシー
- `assets/templates/facts.json` — テンプレート
