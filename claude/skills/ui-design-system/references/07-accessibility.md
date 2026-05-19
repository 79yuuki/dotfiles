# Stage 7: Accessibility — WCAG AAA監査

## 目的

`ui-accessibility-design` スキルのWCAG AAA原則をコードレベルで監査・修正する。
「後でやる」は存在しない。Stage 7で必ず通す。

## プロンプトテンプレート

```
# Stage 7: Accessibility Audit (WCAG AAA)

以下のUIをWCAG AAAレベルでアクセシビリティ監査してください。

## 現状コード
[コードを貼る]

## 要求

1. **コントラスト比チェック**:
   - 全テキストのコントラスト比を算出
   - 7:1未満の箇所を特定し修正案を提示

2. **キーボード操作**:
   - Tab順序が論理的か
   - フォーカスリングが全要素で可視か
   - Escape / Enter / Space / Arrow キーが正しく機能するか

3. **スクリーンリーダー対応**:
   - 全インタラクティブ要素にaria-labelまたはテキストがあるか
   - 画像にalt属性があるか（装飾画像は alt=""）
   - aria-live で動的コンテンツ変化を通知しているか
   - フォームのlabel + aria-describedby が設定されているか

4. **モーション**:
   - prefers-reduced-motion 対応コードの確認

5. **フォームアクセシビリティ**:
   - エラーメッセージが「何が問題か」+「どう直すか」を明示しているか
   - autocomplete 属性が適切か

出力: 問題リスト（重要度付き）+ 修正済みコード
```

## WCAG AAA チェックリスト（全項目）

### 1. 視覚・コントラスト

- [ ] **1.4.6 コントラスト (AAA)**: 通常テキスト 7:1以上、大テキスト 4.5:1以上
- [ ] **1.4.3 コントラスト (AA)**: プレースホルダー 4.5:1以上（AAAはさらに厳格）
- [ ] **1.4.11 非テキストのコントラスト**: UI部品・グラフィック 3:1以上
- [ ] **1.4.4 テキストのリサイズ**: 200%ズームでもコンテンツが欠けない
- [ ] **1.4.10 リフロー**: 320px幅で水平スクロールなし
- [ ] フォーカスリングが背景から区別できる

### 2. キーボードアクセシビリティ

- [ ] **2.1.1 キーボード**: 全機能がキーボードのみで操作可能
- [ ] **2.1.3 キーボード(例外なし) (AAA)**: キーボード操作の例外ゼロ
- [ ] **2.4.7 フォーカスの可視化**: フォーカスリング常時表示
- [ ] **2.4.3 フォーカス順序**: Tab順がDOMの論理順序に従う
- [ ] **2.4.11 フォーカスの見た目 (WCAG 2.2)**: フォーカスエリア3px以上
- [ ] Modalを開いたらフォーカスがModal内に移動する (focus trap)
- [ ] Modalを閉じたらフォーカスが開いたボタンに戻る

### 3. スクリーンリーダー対応

- [ ] **1.1.1 非テキストコンテンツ**: 全画像に alt 属性
- [ ] **4.1.2 名前・役割・値**: 全インタラクティブ要素に name + role
- [ ] **aria-live="polite"**: 動的に更新される領域（Toast、結果数など）
- [ ] **aria-label** または `<label>`: 全フォームフィールド
- [ ] **aria-expanded**: Accordion / Dropdown / Sidebar の開閉状態
- [ ] **aria-current="page"**: 現在アクティブなナビアイテム
- [ ] **aria-disabled="true"**: disabled 状態のボタン（role="button"の場合）
- [ ] **role="status"**: 軽微なフィードバック
- [ ] **role="alert"**: 重要なエラーメッセージ

### 4. フォームアクセシビリティ

- [ ] **3.3.1 エラーの特定**: エラー箇所をテキストで明示
- [ ] **3.3.2 ラベルまたは説明**: 全フィールドにvisible label
- [ ] **3.3.3 エラー提案 (AA)**: 「どう直すか」を提示
- [ ] **3.3.4 エラー回避 (AAA)**: 重要な操作は確認ダイアログ
- [ ] `autocomplete` 属性設定（email, tel, name, etc.）
- [ ] `required` 属性 + aria-required
- [ ] エラー時: `aria-invalid="true"` + `aria-describedby` でエラーテキストと紐付け

### 5. モーション・時間

- [ ] **2.3.3 アニメーション (AAA)**: prefers-reduced-motion 対応
- [ ] **2.2.1 タイミング調整可能**: タイムアウトがあれば延長手段を提供

### 6. タッチ・ポインタ

- [ ] **2.5.5 ターゲットのサイズ (AAA)**: 44×44px以上
- [ ] **2.5.3 ラベルを名前に**: ボタンのaria-labelとvisibleテキストを一致させる

## よくあるバグと修正

### アイコンボタンにラベルなし
```html
<!-- ❌ -->
<button><svg>...</svg></button>

<!-- ✅ -->
<button aria-label="メニューを開く"><svg aria-hidden="true">...</svg></button>
```

### フォームのラベルなし
```html
<!-- ❌ -->
<input type="email" placeholder="メールアドレス">

<!-- ✅ -->
<label for="email">メールアドレス</label>
<input id="email" type="email" autocomplete="email" aria-describedby="email-error">
<p id="email-error" role="alert" class="text-destructive">
  有効なメールアドレスを入力してください（例: name@example.com）
</p>
```

### フォーカスリングの消去
```css
/* ❌ 絶対禁止 */
:focus { outline: none; }

/* ✅ マウス操作時だけ非表示に（キーボードでは表示） */
:focus:not(:focus-visible) { outline: none; }
:focus-visible { outline: 2px solid var(--color-primary); outline-offset: 2px; }
```

### 色だけでステータスを表現
```html
<!-- ❌ 赤いだけでエラーと分からない -->
<input class="border-red-500">

<!-- ✅ アイコン + テキスト + 色 -->
<input class="border-destructive" aria-invalid="true" aria-describedby="err">
<p id="err" class="text-destructive flex gap-1">
  <AlertCircle aria-hidden="true" /> パスワードは8文字以上にしてください
</p>
```

## 次のステージへ

Stage 7承認後 → Stage 8 (Responsive)
