---
name: ui-design-system
description: >-
  Design, critique, and refine high-quality UI systems for web apps, landing pages, dashboards, and mobile interfaces. Use for layout, visual hierarchy, color, typography, components, interaction states, responsive behavior, and accessibility.
---

# UI Design System — 9段階プロンプトチェーン

Claudeに「9回に分けて段階的に磨く」ことで、1発プロンプトでは得られないAppleレベルのUIクオリティを実現する。

## このスキルの立ち位置

| スキル | 役割 | このスキルとの関係 |
|---|---|---|
| `component-gallery` | どのコンポーネントを使うか選定 | **Stage 1** のインプットとして活用 |
| `vibe-coding` | コンポーネント構造名でAIに指示 | **Stage 5** の実装指示フォーマット |
| `ui-accessibility-design` | WCAG AAA準拠レビュー | **Stage 7** で専門チェックリストを参照 |
| **`ui-design-system`** | 9段階で全体を磨き上げる **司令塔** | 上記3スキルを統合・オーケストレーション |

---

## 9段階プロンプトチェーン 概要

```
Stage 1: Layout       — IA・構造・グリッド
Stage 2: Color        — カラーパレット・コントラスト・ダークモード
Stage 3: Typography   — フォント・スケール・ラインハイト
Stage 4: Spacing      — 余白・リズム・密度
Stage 5: Components   — 個別コンポーネントの品質
Stage 6: Interaction  — ホバー・トランジション・フィードバック
Stage 7: Accessibility— WCAG AAA監査・キーボード・スクリーンリーダー
Stage 8: Responsive   — モバイル・タブレット・デスクトップ
Stage 9: Polish       — 最終仕上げ・マイクロディテール
```

各段階の前のステージの出力がインプットになる。「なんか物足りない」と感じたら、該当ステージから再開するだけ。

---

## クイックスタート

### 0. 既存UIや参考サイトがあるなら、先に `DESIGN.md` を作る

新規にゼロから考えるより、まず観測結果を artifact に分離した方が速い。
`references/design-handoff.md` を使って、既存サイト / スクショ / 実装コードから **observed design language** を抽出する。

空の叩き台から始めたい時は `references/design-md-starter.md` を repo-level の `DESIGN.md` にコピーして使う。
この starter は **`observed / proposed / keep / rethink / discard / accessibility assertions / acceptance checks`** を最初から持っている。

**原則:**
- scan と improve を混ぜない
- `observed` と `proposed` を分ける
- `keep / rethink / discard` を明示する
- `a11y assertions` と `acceptance checks` を artifact に残す
- 最後は人間が polish する前提で渡す

### 0.5. 再利用するなら design skill 化する

同じデザイン言語を複数ページ・複数agent・複数プロジェクトで再利用するなら、`DESIGN.md` だけで終わらせない。
`references/design-system-skillization.md` を使い、次の3点を分割して残す:

1. **Token CSS** — semantic CSS variables / Tailwind mapping / shadcn variables
2. **Prohibitions** — generic AI UIへ戻らないための禁止事項
3. **Human polish checklist** — 最後に人間が見るべき判断項目

新規skill化は、同じ視覚言語を2回以上使う・agent間で実装差が出た・trust/sales/hiringに効くUIである、のいずれかがある時だけ検討する。単発ならこのskillのreferenceとして残す。

### 1. UIタイプを宣言

```
タイプ: [WebApp / LP / Dashboard / MobileUI]
スタック: [Next.js + Tailwind + shadcn/ui / その他]
対象ユーザー: [...]
参照デザイン: [Vercel / Linear / Stripe / Apple / など]
DESIGN.md: [ある / まだない]
```

### 2. Stage 1から順番にプロンプトを送る

各ステージのプロンプトテンプレートは `references/0N-*.md` を参照。
既存UI起点なら Stage 1 の前に `references/design-handoff.md` を1回通す。

### 3. 各ステージで「承認 or 修正」してから次へ

承認したら次のステージへ。修正が出たら同じステージを再実行。

### 4. Rapid LP prototype route（AI時代の初速出し）

Claude Design / 画像生成系を使って **半日で叩き台を出したい** 時は、9段階を省略せずに「前段をAIで圧縮」する。

**推奨フロー:**
1. 画像生成 or 参考LPスクショで方向性を出す
2. Claude Design などで HTML / PPTX / PDF の叩き台を出す
3. その出力から `DESIGN.md` を作る
4. `ui-design-system` の Stage 1〜9 で構造化して磨く
5. 最後は人間が価値訴求・ブランド整合・CTA を polish する

**UX5 → Design → Code → Codex Review:** LP / signup / recruiting / product UI の初動は、`references/ux5-design-code-review-template.md` を使い、UX5で意図を切ってから Design artifact → Claude Code実装 → Codex/fresh review に渡す。

**注意:**
- いきなり最終成果物扱いしない
- `observed` と `proposed` を混ぜない
- 速く作れたことより、**再利用できる design language を抽出できたか** を重視する

---

## ページタイプ別 推奨スターターコンポーネント

`component-gallery` スキルの知識から引用。Stage 1で使うインプット。

### 🌐 Web App
```
App Bar(fixed) + Sidebar(persistent) + Main Content Area
→ Breadcrumb + Page Header + Content + Toast
```

### 🏠 ランディングページ (LP)
```
App Bar(fixed, transparent→solid) + Hero(full-height)
→ Features(Card Grid 3col) + Social Proof + Pricing + FAQ(Accordion) + Footer
```

### 📊 ダッシュボード
```
App Bar(compact) + Sidebar(240px) + Main:
→ Breadcrumb + Stat Cards(4col) + Chart Area + Table(sortable)
```

### 📱 モバイル UI
```
Status Bar + Navigation Bar(bottom) + Scroll View
→ Card List / Grid + FAB + Sheet(bottom drawer)
```

---

## デザイントークン基本定義

Stage 2・3で使う設計変数の雛形。Tailwindのconfig/CSS変数として出力させる。

```css
/* カラー */
--color-primary: ...;       /* ブランドカラー */
--color-primary-hover: ...; /* 10% darker */
--color-surface: ...;       /* 背景 */
--color-surface-raised: ...; /* カード背景 */
--color-text: ...;          /* 本文 */
--color-text-muted: ...;    /* 補助テキスト */
--color-border: ...;        /* ボーダー */
--color-destructive: ...;   /* 警告・削除 */

/* タイポグラフィ */
--font-sans: 'Inter', system-ui;
--font-mono: 'JetBrains Mono', monospace;
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-4xl: 2.25rem;   /* 36px */

/* スペーシング (4px基準) */
--space-1: 0.25rem;  /* 4px */
--space-2: 0.5rem;   /* 8px */
--space-3: 0.75rem;  /* 12px */
--space-4: 1rem;     /* 16px */
--space-6: 1.5rem;   /* 24px */
--space-8: 2rem;     /* 32px */
--space-12: 3rem;    /* 48px */
--space-16: 4rem;    /* 64px */
```

---

## デザインシステム連携

### Tailwind CSS
- `tailwind.config.ts` にデザイントークンを反映
- Stage 2: `colors` → Stage 3: `fontFamily/fontSize` → Stage 4: `spacing`

### shadcn/ui
- `globals.css` の CSS変数に上書き
- コンポーネントは `npx shadcn@latest add [component]` で追加
- バリアントは `class-variance-authority (cva)` で定義

### Radix UI (headless)
- `ui-accessibility-design` スキルのアクセシビリティ原則と最も相性が良い
- Stage 7のアクセシビリティ監査でRadix組み込み機能を活用

---

## アクセシビリティ 最低ライン（全ステージ共通）

`ui-accessibility-design` スキルのWCAG AAA基準から抜粋。全ステージで常に守る。

| 項目 | 基準 |
|---|---|
| テキストコントラスト | **7:1以上** (AAA) |
| 大テキスト（18px+/14px+ bold） | 4.5:1以上 |
| タッチ/クリックターゲット | **44×44px以上** |
| フォーカスリング | 常に表示（outline省略禁止） |
| エラーメッセージ | 「何が問題か」+「どう直すか」を明示 |
| アニメーション | `prefers-reduced-motion` 対応必須 |

詳細チェックリストは `references/07-accessibility.md` を参照。

---

## よくある失敗パターン

| 症状 | 該当ステージ | 対処 |
|---|---|---|
| 「なんか安っぽい」 | Stage 9 | Polishプロンプトを実行 |
| 「余白が窮屈/スカスカ」 | Stage 4 | Spacingを再実行 |
| 「色がパキパキしすぎ」 | Stage 2 | Colorを再実行（彩度下げ・HSL調整） |
| 「スマホで崩れる」 | Stage 8 | Responsiveを再実行 |
| 「障害者対応が不安」 | Stage 7 | Accessibility監査を実行 |
| 「動きが固い」 | Stage 6 | Interactionを再実行 |

---

## 参照リソース

各ステージの詳細プロンプトと実行手順:

- `references/01-layout.md` — IA・構造・グリッドレイアウト
- `references/02-color.md` — カラーパレット・テーマ・コントラスト
- `references/03-typography.md` — タイポグラフィスケール
- `references/04-spacing.md` — 余白・リズム・密度
- `references/05-components.md` — コンポーネント品質チェック
- `references/06-interaction.md` — インタラクション・アニメーション
- `references/07-accessibility.md` — WCAG AAA監査チェックリスト
- `references/08-responsive.md` — レスポンシブ設計
- `references/09-polish.md` — 最終仕上げ・マイクロディテール
- `references/design-handoff.md` — 既存UI / 参考サイト / スクショから `DESIGN.md` を作る手順
- `references/ux5-design-code-review-template.md` — UX5 → Design artifact → Claude Code実装 → Codex/fresh review のLP/UI初動テンプレ
- `references/design-md-starter.md` — `observed / proposed / keep / rethink / discard / a11y assertions / acceptance checks` 付きの `DESIGN.md` 叩き台
- `references/design-tokens.md` — デザイントークン完全定義
- `references/design-system-skillization.md` — DESIGN.mdを再利用可能な token CSS / prohibitions / human checklist に分割する手順
- `references/stack-guide.md` — スタック別実装ガイド（Tailwind/shadcn/Radix）
