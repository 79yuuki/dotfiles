---
name: component-gallery
description: >-
  Choose and specify UI component patterns using a gallery of proven design-system structures. Use when asking an agent to build or improve concrete UI sections, components, dashboards, cards, forms, tables, or navigation.
---

# Component Gallery — UI構造パターンによるコンポーネント設計

Component Gallery（https://component.gallery/）の60コンポーネント×95デザインシステムの知識を使って、UIの設計・改善・レビューを行う。

## いつ使うか

- ✅ 新規ページのUI構成を設計する時
- ✅ 既存UIの改善提案をする時
- ✅ 「このページにどんなコンポーネントが必要？」という質問
- ✅ AIコーディングエージェントへの構造指示を組み立てる時
- ❌ ビジュアルデザイン（色・フォント）の決定（それはブランドガイドラインの仕事）

## クイックスタート

1. ユーザーの要件を聞く（何のページ？誰向け？目的は？）
2. `references/components.md` を読んでパターンを選定
3. `references/page-recipes.md` を読んでページタイプ別の推奨構成を確認
4. 構成案をコンポーネント名で提示（例: "Hero + Card Grid + Tabs + Accordion"）
5. 実装指示に落とし込む

## コンポーネント名で指示する理由

AIコーディングエージェント（Claude Code等）に「App Bar + Drawer + Card Grid + Tabs構成で」と構造名で指示すると、各パターンの標準的な実装を一発で出力できる。曖昧な自然言語より再現性が高い。

詳細は `references/` 配下を参照。
