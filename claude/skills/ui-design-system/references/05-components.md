# Stage 5: Components — コンポーネント品質チェック

## 目的

個別コンポーネントの品質を `vibe-coding` スキルのコンポーネント構造名を使いながら磨く。
状態管理（empty/loading/error/success）と一貫性が焦点。

## プロンプトテンプレート

```
# Stage 5: Component Quality Review

以下のコンポーネントを全状態に対してレビュー・改善してください。

## 対象コンポーネント
[コンポーネント名と現状コード]

## 要求

1. **全状態の実装**:
   - default (通常)
   - hover / focus / active
   - loading (Skeleton / Spinner)
   - empty (データなし)
   - error (エラー状態)
   - disabled

2. **コンポーネントバリアント**: cva (class-variance-authority) で定義
   - size: sm / md / lg
   - variant: default / outline / ghost / destructive

3. **shadcn/ui との統合**:
   - 既存コンポーネントがあれば `npx shadcn@latest add [name]` で取得
   - テーマのCSS変数に準拠しているか

4. **一貫性チェック**:
   - ボーダーラジアス: 全コンポーネントで統一されているか
   - Shadow: 同じスケールを使っているか

出力: 修正済みコンポーネントコード（全状態・全バリアント込み）
```

## コンポーネント品質チェックリスト

### Button
- [ ] `size`: sm(h-8) / md(h-10) / lg(h-11)
- [ ] `variant`: default / outline / ghost / destructive / link
- [ ] `disabled` 状態: `opacity-50 cursor-not-allowed pointer-events-none`
- [ ] `loading` 状態: Spinner + テキスト非表示 or "Loading..."
- [ ] アイコンのみバリアント: 正方形、aria-label必須
- [ ] フォーカスリング: `focus-visible:ring-2 focus-visible:ring-offset-2`

### Form Input
- [ ] `placeholder`: 薄すぎないコントラスト（4.5:1以上）
- [ ] `error` 状態: 赤ボーダー + エラーメッセージ（何が問題か + 修正方法）
- [ ] `success` 状態: 緑チェックアイコン（任意）
- [ ] `disabled`: `opacity-50 bg-muted`
- [ ] `autocomplete` 属性の設定
- [ ] aria-describedby でヘルプテキスト / エラーメッセージを紐付け

### Card
- [ ] Hover: subtle shadow増 + わずかな上移動 (`hover:-translate-y-1`)
- [ ] クリッカブルカード: `cursor-pointer` + `role="button"` or `<a>`
- [ ] 画像: aspect-ratio固定 + `object-cover`
- [ ] 空状態: スケルトンと同じ寸法を保つ

### Table
- [ ] ヘッダー: sort矢印 + ariasort属性
- [ ] 行 hover: `hover:bg-muted/50`
- [ ] Empty State: テーブルの中に「データがありません」+ アクションボタン
- [ ] 一括選択: `<th>` にCheckbox + `aria-label="全行を選択"`
- [ ] Pagination: 現在ページ・総ページ数・前後ボタン

### Navigation (Sidebar / Bottom Tab)
- [ ] アクティブ状態: 背景色 + テキスト色変更
- [ ] Hover状態: subtle背景
- [ ] アイコン + テキストの組み合わせ
- [ ] collapsed (アイコンのみ) 状態対応
- [ ] `aria-current="page"` で現在ページを示す

## vibe-coding コンポーネント名リファレンス

`component-gallery` / `vibe-coding` スキルの構造名から主要なもの:

```
# ナビゲーション
App Bar / Navigation Bar / Breadcrumb / Tabs / Pagination

# コンテンツ表示
Card / Card Grid / Table / List / Accordion / Modal / Drawer / Sheet

# フォーム
Form / Text Input / Select / Checkbox / Radio / Toggle / Date Picker / File Input / Slider

# フィードバック
Toast / Alert / Badge / Progress Bar / Skeleton / Spinner / Empty State

# レイアウト
Sidebar / Drawer / Container / Grid / Divider / Spacer

# アクション
Button / Button Group / FAB / Dropdown Menu / Context Menu / Command Palette
```

## Shadow スケール（統一）

```css
--shadow-sm:  0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow:     0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
--shadow-md:  0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
--shadow-lg:  0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
--shadow-xl:  0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);

/* カード: shadow */
/* Dropdown/Modal: shadow-lg */
/* Elevated Card: shadow-md + hover:shadow-xl */
```

## ボーダーラジアス統一

```
radius-sm:   4px  — Badge, Tag, input
radius:      8px  — Button, Card, Input (default)
radius-md:   12px — Card (comfortable)
radius-lg:   16px — Sheet, Panel
radius-xl:   24px — Modal, Bottom Sheet
radius-full: 9999px — Avatar, Pill Badge, Toggle
```

## 次のステージへ

Stage 5承認後 → Stage 6 (Interaction)
