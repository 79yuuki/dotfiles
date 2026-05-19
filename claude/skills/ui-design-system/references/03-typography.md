# Stage 3: Typography — タイポグラフィスケール

## 目的

読みやすさ・情報ヒエラルキー・ブランドトーンをフォント設計で実現する。
スケールを明示することで「なんとなく大きい文字」ではなく意図的な設計になる。

## プロンプトテンプレート

```
# Stage 3: Typography System

Stage 2のカラーシステムと組み合わせて、タイポグラフィシステムを設計してください。

## 基本情報
- UIタイプ: [WebApp / LP / Dashboard / MobileUI]
- トーン: [プロフェッショナル / フレンドリー / テック / モダン]
- 日本語テキストあり: [Yes / No]

## 要求

1. **フォントファミリー選定**:
   - Sans-serif (UI用): [Inter / Geist / Plus Jakarta Sans など]
   - Mono (コード用): [JetBrains Mono / Fira Code など]
   - Display (見出し用, optional): [...]
   - 日本語: [Noto Sans JP / BIZ UDGothic など]

2. **タイポグラフィスケール** (Tailwind `fontSize` ベース):
   - display: 3rem / line-height 1.1 / tracking -0.03em
   - h1〜h4: サイズ・行高・字間を定義
   - body / body-sm: 本文用
   - caption / overline: ラベル用

3. **Fluid Typography** (optional): clamp() でvpサイズに応じて変化

4. **実装コード**: Tailwind config + globals.css として出力

出力: tailwind.config.ts の `theme.extend.fontSize` + globals.css
```

## タイポグラフィスケール 標準定義

```typescript
// tailwind.config.ts
theme: {
  extend: {
    fontFamily: {
      sans: ['Inter', 'system-ui', 'sans-serif'],
      mono: ['JetBrains Mono', 'monospace'],
      // 日本語
      ja: ['BIZ UDGothic', 'Noto Sans JP', 'sans-serif'],
    },
    fontSize: {
      // Display
      'display-xl': ['4.5rem',  { lineHeight: '1.05', letterSpacing: '-0.04em', fontWeight: '700' }],
      'display-lg': ['3.75rem', { lineHeight: '1.08', letterSpacing: '-0.03em', fontWeight: '700' }],
      'display':    ['3rem',    { lineHeight: '1.1',  letterSpacing: '-0.02em', fontWeight: '700' }],

      // Headings
      'h1': ['2.25rem',  { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],
      'h2': ['1.875rem', { lineHeight: '1.25', letterSpacing: '-0.015em', fontWeight: '600' }],
      'h3': ['1.5rem',   { lineHeight: '1.3', letterSpacing: '-0.01em', fontWeight: '600' }],
      'h4': ['1.25rem',  { lineHeight: '1.4', letterSpacing: '-0.005em', fontWeight: '600' }],
      'h5': ['1.125rem', { lineHeight: '1.4', letterSpacing: '0', fontWeight: '600' }],
      'h6': ['1rem',     { lineHeight: '1.5', letterSpacing: '0', fontWeight: '600' }],

      // Body
      'body-lg': ['1.125rem', { lineHeight: '1.7', letterSpacing: '0' }],
      'body':    ['1rem',     { lineHeight: '1.6', letterSpacing: '0' }],
      'body-sm': ['0.875rem', { lineHeight: '1.5', letterSpacing: '0' }],

      // Utility
      'caption':  ['0.75rem',  { lineHeight: '1.4', letterSpacing: '0.01em' }],
      'overline': ['0.6875rem',{ lineHeight: '1.4', letterSpacing: '0.08em', fontWeight: '600' }],
      'code':     ['0.875rem', { lineHeight: '1.6', letterSpacing: '0' }],
    },
  }
}
```

## 日本語フォント注意点

- `font-feature-settings: "palt"` で日本語の字間を自然に
- `text-autospace` (Chrome 123+) で英数字と日本語の間に自動スペース
- 見出しの `letter-spacing` は日本語フォントに効きすぎるので `-0.01em` 程度に抑える
- フォールバック: `'BIZ UDGothic', 'Hiragino Sans', 'Meiryo', sans-serif`

## TypographyのAppleレベルディテール

1. **字間（tracking）を必ず設定**: デフォルト0だと大きい見出しはバラバラに見える
2. **行高は本文1.6、見出し1.15付近**: ピタリ決めると別格になる
3. **fluid typography**: `clamp(2rem, 5vw, 4.5rem)` でスケールさせると洗練度が増す
4. **モノスペースフォントの等幅数字**: `font-variant-numeric: tabular-nums` でテーブルの数字が揃う

## チェックポイント

- [ ] 最小フォントサイズ: モバイル本文 16px以上（14pxはSafari自動ズームが発生）
- [ ] 見出しの字間（tracking）が設定されているか
- [ ] 日本語フォントのフォールバックが指定されているか
- [ ] コードブロックにmonoフォントが使われているか
- [ ] 行長（measure）: 1行65〜75文字が読みやすさのベスト

## 次のステージへ

Stage 3承認後 → Stage 4 (Spacing)
