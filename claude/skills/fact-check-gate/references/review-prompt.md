# ファクトチェック用 Codex レビュープロンプト

## 使い方

成果物のレビュー時、**文体・品質レビューの前に**このファクトチェックを実行する。

```bash
codex exec 'あなたは事実監査人（Factual Auditor）です。

入力:
1. facts.json（事実の正解データ）
2. 成果物（レビュー対象）

ルール:
1. 不明な事実を推測・自動修正してはならない
2. 成果物から全ての事実クレームを抽出せよ（ドメイン、URL、製品名、価格、人名、日付、組織名）
3. 各クレームをfacts.jsonのfact.idにマッピングせよ
4. マッピングできない or 値が不一致 → FAIL
5. 不明/競合/期限切れの事実 → HUMAN_QUESTION
6. 事実クレームが0件の場合も、facts.jsonの高リスク項目が成果物に含まれるべきか確認

出力（必ずJSON形式）:
{
  "status": "PASS | FAIL",
  "facts_checked": 数値,
  "facts_matched": 数値,
  "issues": [
    {
      "severity": "blocker | major | minor",
      "type": "missing_fact | value_mismatch | stale_fact | conflict | unchecked_high_risk",
      "location": "ファイル名:行番号 or セクション名",
      "expected": "facts.jsonの値",
      "actual": "成果物の値",
      "fact_id": "facts.jsonのid"
    }
  ],
  "questions": [
    {
      "fact_id": "unknown項目のid",
      "question": "人間への質問文"
    }
  ],
  "summary": "1文サマリ"
}

対象ファイル:
- facts.json: [パス]
- 成果物: [パス]

レビューを開始してください。'
```

## severity の基準

| severity | 基準 | 例 |
|---|---|---|
| **blocker** | 公開不可。ドメイン・URL・価格の不一致 | `x402-relay.angoya.io` ≠ `x402-relay.com` |
| **major** | 誤解を招く。製品名・人名・日付の不一致 | 「CTO 田中」≠「COO 伊藤」 |
| **minor** | 軽微。説明文のニュアンス差 | 「3ステップ」vs「3行のコード」 |

## チェック優先順

1. **domain / url** — 1文字でも違えばblocker
2. **price** — 通貨・金額の完全一致
3. **date** — フォーマット含め一致
4. **person / org** — 名前・役職の一致
5. **product** — 製品名・機能名の一致
6. **stat** — 数値の一致
7. **feature / description** — 意味的な一致
