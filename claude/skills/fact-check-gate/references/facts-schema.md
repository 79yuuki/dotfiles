# facts.json スキーマ定義

## 構造

```json
{
  "schema_version": "1.0.0",
  "context": {
    "project": "プロジェクト名",
    "artifact_type": "video | lp | email | sns | press | docs",
    "locale": "ja-JP",
    "timezone": "Asia/Tokyo"
  },
  "facts": [
    {
      "id": "cta.primary_domain",
      "category": "domain",
      "value": "x402-relay.com",
      "status": "verified",
      "risk": "high",
      "source": {
        "kind": "human_confirmed | code_verified | doc_reference",
        "uri": "参照元URL（あれば）",
        "evidence": "確認の根拠"
      },
      "verified_at": "2026-03-01",
      "expires_at": null,
      "must_match": "正規表現パターン（オプション）"
    }
  ],
  "unknowns": [
    {
      "id": "pricing.monthly",
      "category": "price",
      "question": "月額料金はいくらですか？",
      "blocking": true,
      "status": "open | answered | not_needed"
    }
  ],
  "policies": {
    "no_guess_categories": ["domain", "url", "price", "person", "date", "product"],
    "fail_on_missing": true,
    "strict_match_categories": ["domain", "url", "price", "date"]
  },
  "signoff": {
    "prepared_by": "agent",
    "approved_by": "未承認の場合null",
    "approved_at": null
  }
}
```

## カテゴリ一覧

| カテゴリ | 例 | リスク | 推測可否 |
|---|---|---|---|
| `domain` | x402-relay.com | 🔴 高 | ❌ 絶対禁止 |
| `url` | https://docs.x402-relay.com/setup | 🔴 高 | ❌ 絶対禁止 |
| `price` | $0.001/call, ¥980/月 | 🔴 高 | ❌ 絶対禁止 |
| `date` | 2026年3月15日リリース | 🔴 高 | ❌ 絶対禁止 |
| `person` | 紫竹佑騎, CTO | 🟡 中 | ❌ 禁止 |
| `product` | x402-relay, VWBL | 🟡 中 | ❌ 禁止 |
| `org` | 合同会社the company | 🟡 中 | ❌ 禁止 |
| `stat` | 「99.9% uptime」 | 🟡 中 | ❌ 禁止 |
| `feature` | 「EIP-3009対応」 | 🟢 低 | ⚠️ コードで検証可 |
| `description` | 製品説明文 | 🟢 低 | ✅ 要レビュー |

## status の意味

| status | 意味 |
|---|---|
| `verified` | 人間が確認済み or コードから検証済み |
| `code_verified` | リポジトリ・設定ファイルから自動検証 |
| `assumed` | エージェントが推定（要確認フラグ） |
| `stale` | 期限切れ（再確認必要） |

## source.kind の意味

| kind | 意味 |
|---|---|
| `human_confirmed` | 人間（user等）が直接回答 |
| `code_verified` | ソースコード・設定ファイルから抽出 |
| `doc_reference` | ドキュメント・README等から引用 |
| `web_verified` | 公式サイト等で確認 |
