# Stage 2: Color — カラーパレット・テーマ・コントラスト

## 目的

ブランドカラーをベースに、WCAG AAA対応の完全なカラーシステムを定義する。
ダークモード対応・感情的トーン・コントラスト比を同時に解決する。

## プロンプトテンプレート

```
# Stage 2: Color System

Stage 1のレイアウト構造に対してカラーシステムを設計してください。

## ブランド情報
- プライマリカラー: [#XXXXXX または「ブルー系」など]
- 雰囲気: [プロフェッショナル / フレンドリー / ミニマル / ダーク など]
- 参照: [Vercel / Linear / Stripe / Apple など]

## 要求

1. **カラーパレット** を以下の変数で定義してください（Light / Dark 両方）:
   - primary / primary-hover / primary-foreground
   - secondary / secondary-hover
   - surface / surface-raised / surface-overlay
   - text / text-muted / text-disabled
   - border / border-focus
   - destructive / warning / success / info
   - (+ 各foreground)

2. **Tailwind CSS変数** として `globals.css` の `:root` と `.dark` に出力

3. **コントラスト比チェック**:
   - text on surface: 7:1以上 (WCAG AAA)
   - muted text on surface: 4.5:1以上
   - primary button text on primary bg: 4.5:1以上

4. **カラーの意図**: 各カラーを選んだ理由を1行で

出力: CSS変数 + 使用例コード
```

## WCAG AAA コントラスト基準

| ペア | 最低比率 |
|---|---|
| 通常テキスト on 背景 | **7:1** (AAA) |
| 大テキスト(18px+) on 背景 | **4.5:1** (AAA) |
| ボタンテキスト on ボタン背景 | 4.5:1 |
| アイコン on 背景 | 3:1 |
| フォーカスリング on 背景 | 3:1 |

検証ツール: https://webaim.org/resources/contrastchecker/

## カラーパレット設計原則

### 彩度コントロール
- **プロ感を出すには彩度を落とす**: `hsl(220, 80%, 50%)` より `hsl(220, 60%, 45%)` の方が洗練される
- ライトモードのサーフェス: 純白(`#FFF`)より `hsl(220, 9%, 98%)` 程度に微妙にトーンを加える
- ダークモードのサーフェス: `#000` ではなく `hsl(220, 9%, 10%)` 程度

### セマンティックカラー
```css
:root {
  /* Semantic */
  --success: hsl(142, 71%, 45%);
  --warning: hsl(38, 92%, 50%);
  --destructive: hsl(0, 84%, 60%);
  --info: hsl(199, 89%, 48%);
}
```

### グレースケール設計（8段階）
```
50   → 背景（最も薄い）
100  → サーフェスの微細差
200  → ボーダー（subtle）
300  → ボーダー（visible）
400  → アイコン・disabled
500  → muted text
600  → secondary text
700  → primary text（light mode）
800  → heading（light mode）
900  → 最も濃いテキスト
```

## チェックポイント

- [ ] primary on surface のコントラスト比 ≥ 7:1
- [ ] テキスト on サーフェスのコントラスト比 ≥ 7:1
- [ ] ダークモードで全カラーが機能するか
- [ ] セマンティックカラー（success/warning/error）が色覚多様性に配慮されているか（色だけでなくアイコン・テキストも使う）
- [ ] フォーカスリングがすべての背景で視認できるか

## 次のステージへ

Stage 2承認後、確定した変数を Stage 3 (Typography) に渡す:
```
CSS変数定義済み: globals.css (:root + .dark)
primaryカラー: #XXXXXX
サーフェスカラー: #XXXXXX
```
