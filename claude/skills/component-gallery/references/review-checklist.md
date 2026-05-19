# UI構成レビューチェックリスト

既存UIをComponent Gallery視点でレビューし、改善提案を出すためのチェックリスト。

## 1. コンポーネント識別

- [ ] 現在のページで使われているコンポーネントを全て列挙
- [ ] 各コンポーネントの正式名称（Component Gallery名）を特定
- [ ] 名称不一致を検出（例: 「お知らせバー」→ Alert / Banner）

## 2. 構造分析

- [ ] ページの情報階層は適切か（Header→Hero→Content→CTA→Footer）
- [ ] コンポーネントの並び順は認知負荷の低い順か
- [ ] ネスト構造に不整合はないか（例: Card内にCardがある等）
- [ ] 同じ情報が複数コンポーネントで重複していないか

## 3. 欠落コンポーネント

- [ ] **Empty State** — データなし時の表示はあるか
- [ ] **Skeleton** — ローディング中のプレースホルダーはあるか
- [ ] **Breadcrumb** — 深い階層でパンくずは必要か
- [ ] **Toast/Alert** — アクションのフィードバックはあるか
- [ ] **Skip Link** — キーボードナビゲーション対応
- [ ] **Visually Hidden** — スクリーンリーダー用テキスト

## 4. コンポーネント選択の妥当性

| よくある誤用 | 正しい選択 |
|---|---|
| カスタムドロップダウン | Select or Combobox |
| 手動アコーディオン | HTML `<details>` / Accordion |
| テキストリンクのクリック | Button（アクション）vs Link（ナビゲーション） |
| Tabs で大量コンテンツ | Accordion（モバイルでは特に） |
| Modal の多用 | Drawer（サイド表示）の検討 |
| カスタムトグル | Toggle（アクセシビリティ対応） |

## 5. レスポンシブ対応

- [ ] Card Grid → モバイルで1カラムに適切にフォールバック
- [ ] Tabs → モバイルでAccordionまたはSelectに変化
- [ ] Sidebar → モバイルでDrawerに変化
- [ ] Table → モバイルでCard Listに変化
- [ ] Navigation → モバイルでハンバーガーメニュー

## 6. アクセシビリティ

- [ ] 全インタラクティブ要素にキーボード操作可能
- [ ] Focus管理（Modal表示時のフォーカストラップ等）
- [ ] ARIA属性の適切な使用（aria-expanded, aria-label等）
- [ ] 色だけに依存しない情報伝達（Badge + テキスト）
- [ ] Visually Hidden テキストの存在

## 7. パフォーマンス

- [ ] Skeleton使用でCLS（レイアウトシフト）防止
- [ ] 画像のlazy loading
- [ ] Carouselの自動再生を避ける（アクセシビリティ）
- [ ] Heavy Animation は `prefers-reduced-motion` 対応

## レビュー出力フォーマット

```markdown
## UI構成レビュー: [ページ名]

### 現在の構成
Header → Hero → [Feature Cards] → CTA → Footer

### 検出された問題
1. 🔴 Empty Stateが未実装（検索結果0件時に真っ白）
2. 🟡 TabsがモバイルでAccordionにフォールバックしない
3. 🟡 Skeleton Loaderなし（データ取得中にCLS発生）

### 改善提案
1. Empty State追加: イラスト + 「条件を変えて再検索」ボタン
2. Tabs → モバイルではAccordionに切替（768px breakpoint）
3. Card GridにSkeleton(3枚)を追加

### 推奨構成（改善後）
Header(fixed) → Hero(compact) → Search + Badge(filter-chips)
→ Card Grid(3col, Skeleton) + Empty State → Pagination → Footer
```
