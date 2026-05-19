# Stage 8: Responsive — モバイル・タブレット・デスクトップ

## 目的

ブレークポイントを明示し、全デバイスで成立するレイアウトに仕上げる。
Mobile Firstで設計し、デスクトップに向けて拡張する。

## プロンプトテンプレート

```
# Stage 8: Responsive Design

以下のUIをモバイルファーストでレスポンシブに改善してください。

## 現状コード
[コードを貼る]

## ターゲットデバイス
- Mobile: 375px (iPhone 14), 390px (iPhone 14 Pro)
- Tablet: 768px (iPad), 1024px (iPad Pro横)
- Desktop: 1280px / 1440px / 1920px (large)

## 要求

1. **Mobile First リファクタリング**:
   - デフォルト（無プレフィックス）= モバイル
   - sm: / md: / lg: / xl: で拡張

2. **レイアウト変換**:
   - サイドバー: モバイル=Drawer(bottom/left) / デスクトップ=persistent
   - ナビ: モバイル=Bottom Tab Bar / デスクトップ=App Bar
   - Card Grid: モバイル=1col / タブレット=2col / デスクトップ=3col
   - テーブル: モバイル=スクロール or Card形式に変換

3. **タイポグラフィのfluid化**:
   - 見出しを `clamp()` でスケール

4. **タッチ操作最適化**:
   - リンクのタッチターゲット 44px確保
   - スワイプジェスチャー対応（Drawer等）

出力: モバイル → デスクトップの段階的変化が明確なコード
```

## Tailwind ブレークポイント（デフォルト）

```
sm:  640px  — 大きめモバイル / 縦向きタブレット
md:  768px  — タブレット
lg:  1024px — 横向きタブレット / 小デスクトップ
xl:  1280px — デスクトップ標準
2xl: 1536px — ワイドモニター
```

## レイアウト変換パターン

### Sidebar → Drawer
```html
<!-- Mobile: Hidden drawer, toggle button -->
<!-- Desktop: Always visible sidebar -->
<aside class="
  fixed inset-y-0 left-0 z-50 w-72
  transform transition-transform duration-300
  -translate-x-full       /* モバイル: 非表示 */
  lg:translate-x-0        /* デスクトップ: 常時表示 */
  lg:relative lg:z-auto
">
```

### Navigation
```html
<!-- Mobile: Bottom Tab Bar -->
<nav class="fixed bottom-0 inset-x-0 lg:hidden bg-background border-t">
  <!-- 4-5 items max -->
</nav>

<!-- Desktop: App Bar (top) -->
<header class="hidden lg:flex sticky top-0 ...">
```

### Card Grid
```html
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 lg:gap-6">
```

### Table → Card List (モバイル)
```html
<!-- デスクトップ: table -->
<table class="hidden md:table">...</table>

<!-- モバイル: card list -->
<ul class="md:hidden space-y-2">
  <li class="bg-card rounded-lg p-4 shadow-sm">
    <div class="flex justify-between">
      <span class="font-medium">名前</span>
      <Badge>ステータス</Badge>
    </div>
    <p class="text-muted-foreground text-sm">詳細情報...</p>
  </li>
</ul>
```

### Typography Fluid
```css
/* clamp(min, preferred, max) */
h1 { font-size: clamp(1.75rem, 5vw, 3rem); }
h2 { font-size: clamp(1.5rem, 4vw, 2.25rem); }
.display { font-size: clamp(2.5rem, 8vw, 5rem); }
```

## モバイル最適化チェックリスト

### レイアウト
- [ ] 横スクロールが発生していないか (`overflow-x-hidden` で確認)
- [ ] コンテナの横余白: モバイル最低 `px-4` (16px)
- [ ] フォームがモバイルで1カラムになっているか
- [ ] Modalがモバイルでは bottom sheet になっているか（UX）

### インタラクション
- [ ] タッチターゲット 44×44px以上（特にナビアイコン）
- [ ] スクロール可能な領域が視覚的に分かるか
- [ ] Drawer はスワイプで閉じられるか
- [ ] ズームを無効にしていないか（`user-scalable=no` は使わない）

### パフォーマンス
- [ ] 画像に `sizes` 属性を設定しているか（responsive images）
- [ ] `next/image` の `fill` / `width` / `height` が適切か
- [ ] フォントの `font-display: swap` 設定

### Viewport / Meta
```html
<meta name="viewport" content="width=device-width, initial-scale=1">
<!-- ✅ user-scalable=no は絶対に設定しない -->
```

## 主要デバイス確認リスト

| デバイス | 解像度 | 確認ポイント |
|---|---|---|
| iPhone SE (3rd) | 375×667 | 最小モバイル。一番厳しい |
| iPhone 14 Pro | 393×852 | Dynamic Island考慮 |
| iPad (10th) | 820×1180 | 両方向で確認 |
| MacBook Air 13" | 1280×800 | デスクトップ最小 |
| 1920×1080 | FHD | コンテナ幅制限確認 |

## 次のステージへ

Stage 8承認後 → Stage 9 (Polish)
