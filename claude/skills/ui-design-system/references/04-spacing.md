# Stage 4: Spacing — 余白・リズム・密度

## 目的

4px基準のスペーシングスケールを定義し、ページ全体に視覚的リズムをもたらす。
「なんか詰まってる」「スカスカ」の解消はほぼSpacingの問題。

## プロンプトテンプレート

```
# Stage 4: Spacing & Rhythm

以下のUIのスペーシングシステムを設計・適用してください。

## 現状コード
[コードを貼る]

## 要求

1. **スペーシングスケール**: 4px基準で全体を統一
   - コンポーネント内部の padding
   - コンポーネント間の gap / margin
   - セクション間の py (vertical rhythm)

2. **密度バリアント** を定義:
   - compact (dense): テーブル行・サイドバーアイテム
   - default: 標準UIパーツ
   - comfortable (spacious): LP・Hero・カード

3. **適用**: 現状コードのスペーシングを上記スケールで修正

4. **コンテナとセクション**:
   - px (コンテナ水平余白): モバイル16px / タブレット32px / デスクトップ48px
   - py (セクション縦余白): 64px〜128px (LPのセクション間)
   - gap (グリッドギャップ): Card Grid は 24px 推奨

出力: 修正済みコード + スペーシング決定の理由
```

## 4px グリッドスケール（Tailwindデフォルト）

```
1  →  4px  (0.25rem) — 最小の余白、アイコンとテキストの間
2  →  8px  (0.5rem)  — インライン要素間
3  →  12px (0.75rem) — compact padding
4  →  16px (1rem)    — default padding (ボタン、インプット)
5  →  20px (1.25rem) — medium padding
6  →  24px (1.5rem)  — カード内padding、grid gap
8  →  32px (2rem)    — セクション内 margin
10 →  40px (2.5rem)  — サイドバー内 padding
12 →  48px (3rem)    — ページ横padding (tablet)
16 →  64px (4rem)    — セクション間 gap (small)
20 →  80px (5rem)    — セクション間 gap (medium)
24 →  96px (6rem)    — LP セクション間
32 → 128px (8rem)    — LP Hero padding
```

## 密度定義テーブル

| 密度 | padding-x | padding-y | 用途 |
|---|---|---|---|
| compact | 8px | 4px | テーブル行、サイドバーアイテム、Badge |
| default | 16px | 8-12px | ボタン、インプット、Card小 |
| comfortable | 24px | 16-20px | カード、Panel |
| spacious | 32-48px | 24-32px | LP Feature Card、Hero |

## Visual Rhythm の原則

### 垂直リズム（Vertical Rhythm）
```css
/* h2 → p → h3 の流れの余白 */
h2 { margin-bottom: 1.5rem; }
p  { margin-bottom: 1rem; }
h3 { margin-top: 2rem; margin-bottom: 1rem; }

/* セクション間 */
.section { padding-block: 5rem; }  /* 80px 上下 */

/* LP セクション（大きい） */
.section-lp { padding-block: clamp(4rem, 10vw, 8rem); }
```

### コンポーネント内部の余白原則
- **アイコン + テキスト**: `gap-2` (8px)
- **ボタン**: `px-4 py-2` (16px x 8px) → comfortable: `px-6 py-3`
- **Card**: `p-6` (24px) → spacious: `p-8` (32px)
- **Form field gap**: `space-y-4` (16px)
- **Form section gap**: `space-y-8` (32px)

## Breathing Room の法則

要素の重要度が高いほど、周囲の余白を大きくする。

```
Apple.com の法則:
- Hero テキスト: 余白が「大きすぎる」くらいが正解
- ナビゲーション: コンパクト（情報密度を上げる）
- CTA ボタン: 上下に十分な余白（視線を誘導）
```

## チェックポイント

- [ ] 4pxグリッドに乗っているか（ピクセルパーフェクト）
- [ ] コンテナの横余白がモバイルで十分あるか（最低16px）
- [ ] セクション間に十分な呼吸があるか（LP: 最低64px）
- [ ] カード内のpadding が一貫しているか
- [ ] フォームのフィールド間隔が適切か（16〜24px）

## 次のステージへ

Stage 4承認後 → Stage 5 (Components)
