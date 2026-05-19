# Stage 6: Interaction — ホバー・トランジション・フィードバック

## 目的

静的なUIに「生きている感」を加える。ただし過剰なアニメーションは逆効果。
Apple UIの原則: 「動きは情報を伝えるためにある」

## プロンプトテンプレート

```
# Stage 6: Interaction & Animation

以下のUIにインタラクションとアニメーションを追加してください。

## 現状コード
[コードを貼る]

## 要求

1. **Hover / Focus states**:
   - ボタン: hover時の色変化（わずかに暗く / 明るく）
   - カード: hover時の elevation変化（shadow増 + 微小上移動）
   - リンク: underline on hover または色変化

2. **Transitions**:
   - 全インタラクティブ要素: `transition-colors duration-150`
   - transform系: `transition-transform duration-200`
   - 複合: `transition-all duration-200 ease-out`

3. **Feedback animations**:
   - フォーム送信: ボタンのloading spinner
   - 成功時: Toast の slide-in
   - エラー時: Input の shake animation
   - コピー時: アイコン変化 (copy → check)

4. **Page transitions** (Next.js の場合):
   - route変更時のloading indicator

5. **prefers-reduced-motion 対応**:
   ```css
   @media (prefers-reduced-motion: reduce) {
     *, *::before, *::after {
       animation-duration: 0.01ms !important;
       transition-duration: 0.01ms !important;
     }
   }
   ```

出力: Tailwind + CSS でのアニメーション実装コード
```

## Tailwind アニメーションプリセット

```typescript
// tailwind.config.ts
theme: {
  extend: {
    keyframes: {
      // Slide in from bottom (Toast)
      'slide-in-bottom': {
        '0%':   { transform: 'translateY(100%)', opacity: '0' },
        '100%': { transform: 'translateY(0)',    opacity: '1' },
      },
      // Fade in
      'fade-in': {
        '0%':   { opacity: '0' },
        '100%': { opacity: '1' },
      },
      // Scale in (Modal)
      'scale-in': {
        '0%':   { transform: 'scale(0.95)', opacity: '0' },
        '100%': { transform: 'scale(1)',    opacity: '1' },
      },
      // Shake (validation error)
      'shake': {
        '0%, 100%':       { transform: 'translateX(0)' },
        '10%, 30%, 50%, 70%, 90%': { transform: 'translateX(-4px)' },
        '20%, 40%, 60%, 80%':      { transform: 'translateX(4px)' },
      },
      // Ping (notification badge)
      'ping-slow': {
        '75%, 100%': { transform: 'scale(2)', opacity: '0' },
      },
      // Skeleton loading
      'shimmer': {
        '0%':   { backgroundPosition: '-200% 0' },
        '100%': { backgroundPosition: '200% 0' },
      },
    },
    animation: {
      'slide-in-bottom': 'slide-in-bottom 0.3s ease-out',
      'fade-in':         'fade-in 0.2s ease-out',
      'scale-in':        'scale-in 0.2s ease-out',
      'shake':           'shake 0.5s ease-in-out',
      'ping-slow':       'ping-slow 2s cubic-bezier(0, 0, 0.2, 1) infinite',
      'shimmer':         'shimmer 2s linear infinite',
    },
  }
}
```

## インタラクション設計パターン

### ボタン押下フィードバック
```css
/* 押した感（微小スケール） */
.btn:active { transform: scale(0.98); }

/* 同 Tailwind */
<button class="active:scale-[0.98] transition-transform duration-100">
```

### カードのHover elevation
```html
<div class="
  shadow
  hover:shadow-lg
  hover:-translate-y-1
  transition-all duration-200 ease-out
  cursor-pointer
">
```

### Skeleton Loading
```html
<div class="
  bg-muted
  rounded
  animate-pulse
  /* または shimmer */
  bg-gradient-to-r from-muted via-muted/60 to-muted
  bg-[length:200%_100%]
  animate-shimmer
">
```

### Toast の出現
```html
<!-- Radix UI Toast / shadcn Toast を使う場合 -->
<!-- 自動で slide-in + auto-dismiss を処理 -->
<Toast className="animate-slide-in-bottom" duration={3000}>
  <ToastTitle>保存しました</ToastTitle>
</Toast>
```

### Modal / Dialog の開閉
```html
<!-- 開く: scale-in + fade-in -->
<!-- 閉じる: scale-out + fade-out (Radix/shadcn が自動処理) -->
<DialogContent className="data-[state=open]:animate-scale-in data-[state=closed]:animate-scale-out">
```

## チェックポイント

- [ ] `prefers-reduced-motion` で全アニメーションが停止するか
- [ ] transition duration: 150〜300ms（遅すぎると待たされる感）
- [ ] hover state が全インタラクティブ要素にあるか
- [ ] フォーカス時もhover相当のフィードバックがあるか（キーボードユーザー向け）
- [ ] loading状態でボタンが無効化されているか（二重送信防止）
- [ ] アニメーションがコンテンツをジャンプさせないか（CLS = 0）

## 避けるべきアニメーション

- ❌ 1秒超えるトランジション（ユーザーを待たせる）
- ❌ スクロール追従のパララックス（酔いやすい）
- ❌ 自動ループするアニメーション（注意散漫）
- ❌ スプラッシュスクリーン / ローディング画面（最初のコンテンツを遅らせる）

## 次のステージへ

Stage 6承認後 → Stage 7 (Accessibility)
