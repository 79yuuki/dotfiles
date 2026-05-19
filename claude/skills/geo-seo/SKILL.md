---
name: geo-seo
description: >-
  Optimize content and sites for AI search and generative engine visibility across ChatGPT, Perplexity, Claude, Gemini, Google AI Overviews, and traditional SEO. Use for citation-worthiness, entity clarity, robots/llms.txt, and answer-engine content.
---

# GEO-SEO: AI検索最適化スキル

AI検索がトラフィックの主戦場になりつつある。従来SEOの土台を維持しつつ、AI検索エンジンに**引用される**コンテンツを作る。

## 背景データ

- AI経由トラフィック: 前年比 **+527%**
- AI経由CVR: オーガニックの **4.4倍**
- 2028年までに検索トラフィック **-50%** (Gartner予測)
- AIでの引用にはバックリンクよりブランド言及が **3倍** 重要
- GEO投資してるマーケターはまだ **23%**（＝先行者利益）

## コマンド一覧

| コマンド | 内容 |
|---------|------|
| `geo audit <url>` | フルGEO+SEO監査 |
| `geo quick <url>` | 60秒スナップショット |
| `geo citability <url>` | AI引用レディネスチェック |
| `geo crawlers <url>` | AIクローラーアクセス分析 |
| `geo llmstxt <url>` | llms.txt分析/生成 |
| `geo brands <url>` | ブランド言及スキャン |
| `geo schema <url>` | 構造化データ分析・生成 |
| `geo content <url>` | コンテンツ品質・E-E-A-T評価 |
| `geo report <url>` | クライアント向けレポート生成 |

## 実行フロー

### 0. 外部SEO skill / MCP導入判断

SEO Sprint / Ahrefs MCP など外部skill・MCPを見つけた時は、いきなりinstallしない。まず既存の `geo audit` / `geo citability` / `geo llmstxt` で再現できる範囲を確認し、足りない差分（例: 実装まで走るプレイブック、Ahrefs連携、技術スタック非依存の修正提案）だけを導入候補にする。導入する場合は `skill-creator` の provenance確認 → staging install → security scan → 承認の順を通す。

### 1. `geo audit <url>` — フル監査

```
Step 1: Discovery
  - web_fetch でトップページ取得
  - ビジネスタイプ検出
  - サイトマップ探索

Step 2: 並列分析（5領域同時）
  [A] AI Visibility — citability + crawlers + llms.txt + brand mentions
  [B] Platform Analysis — ChatGPT/Perplexity/Google AIO対応度
  [C] Technical SEO — SSR/セキュリティ/モバイル
  [D] Content Quality — E-E-A-T/可読性/鮮度
  [E] Schema Markup — 検出/検証/生成

Step 3: GEOスコア算出（0-100）
  AI Citability & Visibility: 25%
  Brand Authority: 20%
  Content Quality & E-E-A-T: 20%
  Technical Foundations: 15%
  Structured Data: 10%
  Platform Optimization: 10%

Step 4: 優先アクションプラン出力（クイックウィン付き）
```

### 2. `geo quick <url>` — 60秒診断

最低限の3項目だけチェック：
1. **robots.txt** — AIクローラー14種のアクセス状況
2. **メタ構造** — title/description/h1の引用適性
3. **llms.txt** — 存在チェック

### 3. `geo citability <url>` — 引用レディネス

コンテンツブロックごとにAI引用適性をスコアリング：

**最適な引用パッセージの条件:**
- 134-167語で自己完結
- 事実ベース（数値・データ含む）
- 質問に直接回答する構造
- 専門用語の定義を含む

**チェック項目:**
- [ ] 各セクションに自己完結型の要約段落があるか
- [ ] 数値・統計データが含まれているか
- [ ] FAQ形式のQ&Aがあるか
- [ ] 定義・比較・手順が明確に構造化されているか

### 4. `geo crawlers <url>` — AIクローラー分析

`robots.txt` で以下14+クローラーのアクセス状況をチェック：

```
GPTBot (OpenAI), ChatGPT-User (ChatGPT),
ClaudeBot (Anthropic), anthropic-ai,
PerplexityBot, Bytespider (ByteDance),
Google-Extended (Gemini), GoogleOther,
CCBot (Common Crawl), cohere-ai,
Applebot-Extended, FacebookBot,
Amazonbot, Meta-ExternalAgent
```

**推奨設定例:**
```
# robots.txt — AI検索に見つけてもらう設定
User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Google-Extended
Allow: /

# ブロックする場合（コンテンツ保護）
User-agent: CCBot
Disallow: /
```

### 5. `geo llmstxt <url>` — llms.txt

新興標準。AIクローラーにサイト構造を理解させるファイル。

**生成テンプレート:**
```markdown
# [サイト名]

> [1行の説明]

## About
[会社/プロダクトの概要。2-3文]

## Key Pages
- [ページ名](URL): [1行説明]
- [ページ名](URL): [1行説明]

## Documentation
- [ドキュメント名](URL): [1行説明]

## API
- [API名](URL): [1行説明]

## Contact
- [連絡先情報]
```

### 6. `geo brands <url>` — ブランド言及スキャン

AI引用とブランド言及の相関はバックリンクの3倍。以下でプレゼンス確認：

- YouTube（動画タイトル・説明文）
- Reddit（サブレディット・コメント）
- Wikipedia（ページ・言及）
- LinkedIn（企業ページ・記事）
- GitHub（リポジトリ・スター）
- Stack Overflow
- Product Hunt
- Hacker News

**方法:** `web_search` でブランド名 + 各プラットフォーム名で検索

### 7. `geo schema <url>` — 構造化データ

AI検索に特に効くスキーマ：

| タイプ | 用途 |
|--------|------|
| Organization + sameAs | ブランドエンティティ認識 |
| Article + Person (author) | E-E-A-T、著者権威 |
| FAQPage | 直接回答の引用元 |
| HowTo | 手順系クエリの引用元 |
| Product + Offers | AI ショッピング推薦 |
| SoftwareApplication | SaaS/ツール認識 |
| WebSite + SearchAction | サイト内検索対応 |

**チェック:** `web_fetch` でページ取得 → JSON-LD/microdata を検出・検証

### 8. `geo content <url>` — コンテンツ品質

E-E-A-T（Experience, Expertise, Authoritativeness, Trustworthiness）の観点：

- [ ] **Experience:** 実体験・一次情報が含まれているか
- [ ] **Expertise:** 著者プロフィール・資格が明示されているか
- [ ] **Authoritativeness:** 外部引用・業界認知があるか
- [ ] **Trustworthiness:** HTTPS、プライバシーポリシー、連絡先明示

**AI引用されやすいコンテンツ特性:**
- 独自データ・調査結果
- 明確な数値（「約」ではなく具体的数字）
- 比較表・対照表
- ステップバイステップの手順
- 定義から始まる段落

## プラットフォーム別最適化

### ChatGPT
- `GPTBot` + `ChatGPT-User` を Allow
- FAQ構造化データ必須
- 端的な定義パラグラフが引用されやすい

### Perplexity
- `PerplexityBot` を Allow
- ソース明示（引用元リンク付き）を好む
- 最新情報（日付入り）を優先

### Google AI Overviews
- `Google-Extended` を Allow
- E-E-A-Tシグナルが強く影響
- 構造化データとの相関が高い

### Claude (Anthropic)
- `ClaudeBot` + `anthropic-ai` を Allow
- 長文の文脈理解が得意 → 詳細な解説記事が有利

## 実装手順（Muser環境）

### ツール
- `web_fetch` — ページ取得・分析
- `web_search` — ブランド言及・競合調査
- `browser` — 動的コンテンツの確認
- `exec` — robots.txt確認 (`curl -s <url>/robots.txt`)

### 典型的なワークフロー

```bash
# 1. robots.txt チェック
web_fetch url:"https://example.com/robots.txt"

# 2. トップページ分析
web_fetch url:"https://example.com" maxChars:15000

# 3. llms.txt チェック
web_fetch url:"https://example.com/llms.txt"

# 4. ブランド言及検索
web_search query:"example.com" count:10
web_search query:"\"Example Corp\" site:reddit.com" count:5
web_search query:"\"Example Corp\" site:youtube.com" count:5

# 5. 構造化データ確認（ページソースからJSON-LD抽出）
web_fetch url:"https://example.com" → JSON-LD検出

# 6. レポート生成
```

## レポートテンプレート

```markdown
# GEO監査レポート: [サイト名]
日付: YYYY-MM-DD

## GEOスコア: XX/100

### サマリー
[3行で現状と最大の改善ポイント]

### スコア内訳
| カテゴリ | スコア | ウェイト | 加重スコア |
|---------|--------|---------|-----------|
| AI Citability | XX/100 | 25% | XX |
| Brand Authority | XX/100 | 20% | XX |
| Content Quality | XX/100 | 20% | XX |
| Technical | XX/100 | 15% | XX |
| Structured Data | XX/100 | 10% | XX |
| Platform Opt. | XX/100 | 10% | XX |

### 🚀 クイックウィン（今すぐできる改善）
1. [アクション1]
2. [アクション2]
3. [アクション3]

### 📋 詳細分析
[各カテゴリの詳細]

### 📅 優先アクションプラン
| 優先度 | アクション | 期待効果 | 工数 |
|--------|-----------|---------|------|
| 🔴 | ... | ... | ... |
| 🟡 | ... | ... | ... |
| 🟢 | ... | ... | ... |
```

## 参考
- [geo-seo-claude](https://github.com/zubair-trabzada/geo-seo-claude) — OSS GEO最適化ツール
- [llms.txt standard](https://llmstxt.org/) — AI向けサイト構造ファイル
- AI検索市場: $850M → $7.3B (2031年予測)
