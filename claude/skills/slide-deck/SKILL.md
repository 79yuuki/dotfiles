---
name: slide-deck
description: >-
  Plan, write, and review slide decks, proposals, business explainers, technical presentations, and pitch materials. Use when creating slides or turning strategy/research into a presentation structure.
---

# スライド・資料作成スキル（70点メソッド）

## コンセプト

**完璧を目指して手が止まるより、構造を先に固める。**

1. 目的設定（Why）
2. ストーリーライン（70点）
3. ドラフト作成（型に当てはめる）
4. ブラッシュアップ（磨く）

---

## STEP 1: 目的設定（5分）

資料を作る前に必ず答える3つの質問：

```
1. 誰に見せる？        → 対象読者・意思決定者
2. 何を決めてほしい？  → 期待するアクション
3. 相手の現状は？      → 前提知識・懸念点
```

**典型パターン：**

| 資料種別     | 対象         | 期待アクション           |
|------------|-------------|------------------------|
| 提案書       | クライアント CxO | 発注承認・予算確保       |
| 見積もり     | 担当者・経理   | 金額承認・PO発行         |
| 事業説明     | 投資家・パートナー | 関心獲得・次回MTG設定   |
| 技術説明     | エンジニア・CTO | 採用判断・実装合意       |

---

## STEP 2: ストーリーライン（70点）

### 黄金構造（SCQA）

```
S: Situation  → 現状・背景（読者が共感できる事実）
C: Complication → 問題・課題（だから行動が必要）
Q: Question   → 問い（どうすればいいか？）
A: Answer     → 解決策（私たちの提案）
```

### ストーリーライン作成テンプレート

```markdown
## ストーリーライン（70点ドラフト）

**S（現状）:** _______________
**C（課題）:** _______________
**Q（問い）:** _______________
**A（答え）:** _______________

## スライド構成案
1. 表紙
2. エグゼクティブサマリー
3. 現状・課題
4. ソリューション概要
5. 詳細・実績
6. 費用・スケジュール
7. 次のステップ
```

**ポイント：** 上記を埋めたら「70点完成」。Claudeに渡して叩き台を作らせる。

---

## STEP 3: スライドの型

### 各スライドの型

#### 🎯 表紙
```
タイトル（一言で何の資料か）
サブタイトル（補足）
日付 | 会社名 | 担当者名
```

#### 📋 エグゼクティブサマリー
```
[結論を3行で]
・ポイント1（数字入り）
・ポイント2（数字入り）
・ポイント3（次のアクション）
```

#### 🔴 課題提示
```
[現状の問題]
事実A → だから問題Xが起きている
事実B → だから機会Yを逃している
→ 解決しないと損失Z
```

#### ✅ ソリューション
```
[提案するアプローチ]
BEFORE: 現在の状態
AFTER:  提案後の状態
HOW:    どうやって実現するか（3ステップ以内）
```

#### 📊 実績・根拠
```
[なぜ我々が適任か]
実績1: [具体的数字]
実績2: [具体的事例]
実績3: [推薦・認定]
```

#### 💰 費用・スケジュール
```
[投資対効果]
フェーズ1: [期間] [金額]
フェーズ2: [期間] [金額]
合計: [金額]
ROI予測: [数字]
```

#### 🚀 次のステップ
```
[読者に何をしてほしいか]
→ Action 1（期日: YYYY/MM/DD）
→ Action 2（期日: YYYY/MM/DD）
お問い合わせ: [連絡先]
```

---

## STEP 4: テンプレート選択

用途に応じてreferences/のテンプレートを使う：

| 用途     | テンプレート                              | Marpアセット              |
|---------|----------------------------------------|------------------------|
| 提案書   | `references/proposal-template.md`     | `assets/marp-proposal.md` |
| 見積もり | `references/estimate-template.md`     | `assets/marp-estimate.md` |
| 事業説明 | `references/business-template.md`     | `assets/marp-business.md` |
| 技術説明 | `references/tech-template.md`         | `assets/marp-tech.md`     |

---

## STEP 4.5: ブランドトークン設計（AI品質安定化）

> 💡 SmartBank @yuki930 の「AIスライド生成を仕組みから解決」を参考に設計。
> ブランド準拠のスライドをAIで安定的に生成するための構造。

### ブランド定数管理

色やフォントをHEXコードや直値で散在させず、**名前付き定数**で管理する。
AIは `color="brand-primary"` のように名前で指定すれば正しい色が適用される。

```markdown
## ブランドカラー（プロジェクトごとに定義）
- brand-primary: #XXXXXX   ← メインカラー
- brand-accent: #XXXXXX    ← アクセント
- brand-bg: #XXXXXX        ← 背景
- brand-text: #XXXXXX      ← テキスト
- brand-muted: #XXXXXX     ← 控えめテキスト

## フォント
- heading: [フォント名] / [ウェイト]
- body: [フォント名] / [ウェイト]
- code: [フォント名]

## テキストスタイルプリセット
- heading: 28pt, Bold, brand-text
- subheading: 22pt, SemiBold, brand-text
- body: 16pt, Regular, brand-text
- caption: 12pt, Regular, brand-muted
- kpi-number: 48pt, Bold, brand-accent
```

**ポイント:** ブランドガイドがあるプロジェクトは `references/brand-tokens/` にファイルを作る。
なければ用途に応じたデフォルトパレットを使う。

### パターンカタログ方式

AIに「いい感じに」と言わず、**型（パターン）から選ばせる**。

```
カテゴリ別パターン例:
├── 汎用: タイトル, セクション区切り, KPI行, 比較表, タイムライン
├── ビジネス: 表紙, サマリー, 課題/解決, BEFORE/AFTER, 費用/ROI
├── テック: アーキテクチャ図, フロー, コードスニペット, API仕様
├── マーケ: ファネル, チャネル比較, A/Bテスト結果, ペルソナカード
└── 職種別: エンジニア向け, PM向け, 経営陣向け, 投資家向け
```

使い方: AIがスライドを生成する際、各ページにどのパターンを使うかを決めてから内容を埋める。
パターン一覧は `references/pattern-catalog.md`（なければ汎用パターンで進行）。

### バリデーションチェックリスト

生成結果の品質を自動チェック:

**エラー（修正必須）:**
- ❌ ブランドパレット外の色が使われている
- ❌ 指定外フォントが使われている
- ❌ 1スライド300文字超（テキスト過多）
- ❌ 1スライド25要素超（要素過多）

**警告（確認推奨）:**
- ⚠️ フォントサイズ 9pt未満 or 60pt超
- ⚠️ 表紙タイトル 14文字超（1行に収まらない）
- ⚠️ コンテンツが表示領域外にはみ出し

### 設計思想（3層分離）

```
1. スキル定義層（SKILL.md）    → AIへの指示書（ワークフロー）
2. パターンカタログ層           → デザインの引き出し（型の選択肢）
3. 出力層（Marp / PPTX / PDF） → 実際の生成エンジン
```

この分離により、各層を独立して改善できる。
- 新パターン追加 → カタログ層だけ更新
- ブランド変更 → トークン定義だけ差し替え
- 出力形式変更 → 出力層だけ切り替え

---

## STEP 5: 出力形式を選ぶ（Marp / HTML Artifact）

### HTML Artifactを優先する場面

Markdown/Marpだけでなく、**1枚HTMLのプレゼン/説明資料**も標準候補にする。次の条件ならHTMLを優先する。

- 動的グラフ、SVG図解、タブ、クリック展開、スライダー等のインタラクションが効く
- 社内外にURLで共有して「読まれる」確率を上げたい
- 100行超のMarkdownでは読者が追いづらい
- AI/Codex/Claude Codeがローカルファイル・MCP・git履歴を読んで、文脈込みの資料を作る

### HTML Artifactの作り方

1. 先にSTEP 1〜3で **台本/アウトライン/スライドごとの伝達意図** を固める
2. 「単一HTMLファイル、CSS/JSインライン、外部依存なし」を指定して生成する
3. 反復は2段階に分ける
   - 構造変更: チャット/計画段階でまとめて直す
   - 細部修正: Claude Code / Codex でHTMLファイルを直接編集する
4. 共有する場合は、`index.html` をGitHub Pages等に置く。ただし公開範囲・外部送信は事前承認を取る

**最低プロンプト:**
```text
このアウトラインを、1つのHTMLプレゼンとして作ってください。
CSSとJavaScriptはインライン、外部依存なし。
各スライドはテキスト3行以内、数字・図・SVG・簡単なアニメーションを優先。
矢印キーでページ移動できるようにしてください。
```

## STEP 5.5: Marp出力

MarpはMarkdownをスライドPDFに変換するツール。静的PDFや編集しやすいMarkdownが重要な時に使う。

### インストール確認
```bash
which marp || npm install -g @marp-team/marp-cli
```

### PDF生成コマンド
```bash
# PDF出力
marp --pdf slides.md

# HTML出力（プレゼン用）
marp --html slides.md

# テーマ指定
marp --theme theme.css --pdf slides.md
```

### Marpスライドの基本構文
```markdown
---
marp: true
theme: default
paginate: true
---

# タイトル

---

## スライド2

内容

---
```

---

## 使い方フロー

```
ユーザー:「提案書作りたい」

Claude:
1. 目的設定ヒアリング（3Q）
2. SCQAフレームワークで構成案提示
3. references/のテンプレートを使ってドラフト生成
4. 必要に応じてassets/のMarpファイルに転記してPDF化
```

---

## the companyでよく使うパターン

### product社対応
- 技術説明 or 提案書テンプレートを使用
- Web3/ブロックチェーン用語を一般的な言葉に翻訳するスライドを追加

### コンサル見積もり
- 見積もりテンプレートをベース
- 工数・単価・成果物を明確に

### クライアント提案
- 提案書テンプレートをベース
- SCQA構造で課題から入る

---

## 参照ファイル一覧

- `references/proposal-template.md` — 提案書テンプレート（詳細）
- `references/estimate-template.md` — 見積もりテンプレート（詳細）
- `references/business-template.md` — 事業説明テンプレート（詳細）
- `references/tech-template.md` — 技術説明テンプレート（詳細）
- `assets/marp-proposal.md` — 提案書Marpスライド
- `assets/marp-estimate.md` — 見積もりMarpスライド
- `assets/marp-business.md` — 事業説明Marpスライド
- `assets/marp-tech.md` — 技術説明Marpスライド
