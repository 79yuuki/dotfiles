---
name: ui-accessibility-design
description: >-
  Review and improve UI/UX information architecture and accessibility. Use for WCAG-oriented audits, forms, navigation, error messages, keyboard flows, screen-reader considerations, and inclusive product design.
---

# UI Accessibility Design

Cloudflare Turnstileのリデザイン（日7.6Bチャレンジ処理）から学んだ原則に基づくUIデザイン・アクセシビリティスキル。

## コア原則（即アクセス）

1. **One IA to rule them all**: Widget・ページ全体で同じ構造パターン・視覚ヒエラルキーを使う
2. **WCAG AAA準拠**: 全ユーザー対応（年齢・能力・文化・技術リテラシー不問）
3. **Don't Make Me Think**: 認知負荷を最小化する（Steve Krug）
4. **一貫性**: エラー状態・ヘルプリンク・アクションの配置を統一する
5. **コピーライティング**: 技術的/曖昧なメッセージを排除。選択肢は明確に
6. **制約はデザインの友**: 選択肢を絞ることで本質的なディテールに集中できる

## デザイン業務ワークフロー

### 新規UI設計

1. **IAを先に固める** → コンポーネント種別を問わず同じ構造パターンを定義
2. **コピーライティングレビュー** → 技術用語・曖昧表現を排除
3. **アクセシビリティチェック** → `references/accessibility-checklist.md` を参照
4. **一貫性確認** → エラー状態・空状態・ローディングで同じパターンを使っているか

### UIレビュー依頼時

```
1. 既存IAパターンを把握（何が統一されているか）
2. 逸脱箇所を特定
3. コントラスト・フォントサイズ・タッチターゲットを確認
4. コピーの明確さを確認
5. 改善案を提示（理由付き）
```

### ユーザーリサーチ設計（簡潔版）

- **被験者**: 8名程度、多様性を意識（年齢・文化・技術リテラシー）
- **方法**: ABテスト + タスクベース観察
- **重要**: 「修正不要な部分」の発見も成果。全部変えなくていい
- **記録**: 定量（完了率・時間）＋定性（言語化できない困惑も観察）

## x402プロダクト適用例

| プロダクト | IAのコア | 優先アクセシビリティ |
|---|---|---|
| LP | Hero → Value → CTA の3ブロック構造 | コントラスト比・CTA明確さ |
| Directory | 検索 → 一覧 → 詳細 の一貫したナビ | キーボード操作・スクリーンリーダー |
| Hub | タスク起点のナビゲーション | フォームのエラーメッセージ明確化 |

**共通ルール**: 全プロダクトでエラー状態・空状態・成功状態のパターンを統一する。

## 参照リソース

詳細が必要な場合は以下を読む:
- `references/design-principles.md` — 各原則の詳細解説・適用例
- `references/accessibility-checklist.md` — WCAG AAA準拠チェックリスト
- `references/ui-audit-process.md` — UIデザイン監査プロセス（ステップ付き）

## クイックチェック（毎回確認）

- [ ] コントラスト比: テキスト 7:1以上（AAA）、大テキスト 4.5:1以上
- [ ] タッチターゲット: 44×44px以上
- [ ] エラーメッセージ: 何が問題で、どうすれば解決できるかを明示
- [ ] フォーカス表示: キーボードで操作可能か
- [ ] コピー: 専門用語なし、一読で意味が取れるか
