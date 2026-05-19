# 事実クレーム抽出ルール

成果物（テキスト、コード、動画台本等）から事実クレームを抽出する際のルール。

## 抽出対象パターン

### domain
- `xxx.com`, `xxx.io`, `xxx.dev` 等のドメイン形式
- `https://` 付きURL内のホスト部分
- コード内の文字列リテラル: `"x402-relay.com"`, `BASE_URL=...`

### url
- `https://` or `http://` で始まる文字列
- `href="..."`, `src="..."` 内のURL
- Markdown リンク: `[text](url)`
- コード内: API エンドポイント、リダイレクト先

### price
- 通貨記号 + 数値: `$0.001`, `¥980`, `0.001 USDC`
- 「月額」「年額」「per-call」等の価格表現
- 「無料」「フリープラン」も価格情報

### date
- `YYYY-MM-DD`, `YYYY年M月D日`
- 「2026年3月リリース」等の時期表現
- 「来月」「今週」等の相対日付（→ unknown扱い）

### person
- 人名（漢字、アルファベット）
- 役職 + 名前: 「CTO 紫竹佑騎」
- SNSハンドル: `@example_account`

### product
- 製品名: `x402-relay`, `VWBL`, `Choja`
- 機能名: 「Payment Gateway」「Agent Marketplace」
- SDK名: `@x402relay/sdk`

### org
- 会社名: 「合同会社the company」
- ブランド名: 「x402」

### stat
- 数値 + 単位: 「99.9% uptime」「1000+ users」
- 比較表現: 「3倍速い」「業界No.1」

## 抽出しないもの（事実ではない表現）

- 主観的形容: 「美しい」「使いやすい」
- 一般的知識: 「HTTP 402はPayment Required」
- 仮定: 「もし〜だったら」
- 比喩: 「ロケットのように速い」
