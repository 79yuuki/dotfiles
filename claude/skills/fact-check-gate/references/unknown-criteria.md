# 「不明」判定基準

以下のいずれかに該当する場合、その情報は `unknown` として人間に質問する。**推測で埋めてはならない。**

## 判定フロー

```
事実情報が必要
  ├─ facts.jsonにキーが存在する？
  │   ├─ YES → statusがverified/code_verified？
  │   │   ├─ YES → expires_at超過してない？
  │   │   │   ├─ YES（未超過）→ ✅ 使用OK
  │   │   │   └─ NO（超過）→ ❓ staleとして再確認質問
  │   │   └─ NO（assumed等）→ ❓ 確認質問
  │   └─ NO → ❓ unknownsに追加して質問
  └─ カテゴリがno_guess_categories？
      ├─ YES → ❌ 絶対に推測禁止。質問必須
      └─ NO → ⚠️ 推定可だが、レビューで確認
```

## 具体的な判定基準

### 1. キーが存在しない
facts.jsonに該当する事実IDがない → `unknowns` に追加

### 2. ステータスが未確認
`status` が `verified` でも `code_verified` でもない → 質問

### 3. 高リスクカテゴリで一次ソースなし
domain, url, price, date, person で `source.kind` が空 or `source.evidence` が空 → 質問

### 4. ソース間の不一致
複数のソース（コード・ドキュメント・人間）で値が矛盾 → 質問
例: package.jsonに `homepage: "x402relay.com"` だがREADMEに `x402-relay.com`

### 5. 相対表現で解釈が複数
「来月リリース」「約1000人」→ 具体的な値を質問

### 6. TTL切れ
`expires_at` が現在日時を超過 → 再確認質問
例: 価格情報が3ヶ月前に確認されたもの

### 7. 「たぶん」「おそらく」で始まる推定
エージェント自身が確信を持てない情報 → 正直に `unknown` とする

## 質問のフォーマット

```
⚠️ ファクトチェック: 以下の情報を確認させてください

1. [domain] x402-relayの公開ドメインは何ですか？
   → 現在の候補: なし（推測不可）
   
2. [price] APIのper-call料金は？
   → コードに $0.001 の記述がありますが、公開価格として正しいですか？

blocking項目が含まれるため、回答いただくまで生成を保留します。
```
