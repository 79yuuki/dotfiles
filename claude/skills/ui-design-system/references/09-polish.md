# Stage 9: Polish — 最終仕上げ・マイクロディテール

## 目的

「いい感じ」から「Appleレベル」に引き上げる最終仕上げ。
ディテールの積み重ねが全体の品質感を決める。

## プロンプトテンプレート

```
# Stage 9: Final Polish

UI全体の品質を「Appleレベル」に引き上げるための最終仕上げをしてください。

## 現状コード
[コードを貼る]

## 要求

1. **マイクロインタラクション**:
   - ボタン押下の micro bounce
   - Checkbox / Toggle のチェックアニメーション
   - コピー成功時のアイコン変化

2. **視覚的精度**:
   - pixel-perfectなアライメント確認
   - アイコンサイズの統一（16/20/24px）
   - テキストとアイコンのベースライン揃え

3. **空状態の品質**:
   - EmptyStateのイラスト or アイコン + テキスト + CTA
   - LoadingスケルトンがActualコンテンツと同サイズ

4. **コピー（文言）最終確認**:
   - ボタンラベルが動詞で始まっているか（「保存する」「追加する」）
   - エラーメッセージが人間的な言葉か（「エラーが発生しました」はNG）
   - 空状態のメッセージが前向きか（「データがありません」→「まだデータがありません。最初のXXXを追加しましょう」）

5. **ダークモード最終確認**:
   - 全コンポーネントでダークモードが正しく機能するか
   - 画像・アイコンがダークで見えにくくなっていないか

出力: 修正箇所リスト（Before/After）+ 修正済みコード
```

## Appleレベルのディテール集

### 1. Shadow の繊細さ
```css
/* ❌ 単調な box-shadow */
box-shadow: 0 4px 6px rgba(0,0,0,0.1);

/* ✅ 複数レイヤーで自然な影 */
box-shadow:
  0 1px 2px rgb(0 0 0 / 0.04),
  0 4px 8px rgb(0 0 0 / 0.06),
  0 12px 24px rgb(0 0 0 / 0.08);
```

### 2. Gradient の使い方
```css
/* ❌ ベタ塗りだけ */
background: #6366f1;

/* ✅ 微細なグラジエントで奥行き */
background: linear-gradient(135deg, hsl(239, 84%, 67%) 0%, hsl(262, 83%, 58%) 100%);

/* Hero背景のノイズテクスチャ */
background-image:
  url("data:image/svg+xml,..."), /* noise */
  linear-gradient(135deg, ...);
```

### 3. Typography の最終調整
```css
/* 見出しの字間を微調整 */
h1 { letter-spacing: -0.04em; font-feature-settings: "kern" 1; }

/* 等幅数字（テーブル・メトリクス） */
.number { font-variant-numeric: tabular-nums; }

/* スモールキャップスのラベル */
.overline { font-variant: small-caps; letter-spacing: 0.1em; }
```

### 4. Border の繊細さ
```css
/* ❌ 太いボーダー */
border: 1px solid #e5e7eb;

/* ✅ 透明度で環境適応 */
border: 1px solid rgb(0 0 0 / 0.08);  /* Light mode */
border: 1px solid rgb(255 255 255 / 0.08);  /* Dark mode */
```

### 5. Backdrop Blur（Glassmorphism）
```css
/* App Bar / Floating Panel */
backdrop-filter: blur(12px) saturate(180%);
background: rgb(255 255 255 / 0.8);  /* light */
/* または */
background: rgb(0 0 0 / 0.8);  /* dark */
```

### 6. 空状態の作り方
```html
<div class="flex flex-col items-center justify-center py-16 text-center">
  <!-- アイコン（大きめ、muted色） -->
  <div class="rounded-full bg-muted p-4 mb-4">
    <InboxIcon class="size-8 text-muted-foreground" />
  </div>
  <!-- タイトル：前向きな表現 -->
  <h3 class="text-h5 font-semibold mb-2">まだデータがありません</h3>
  <!-- 説明：次のアクションを示す -->
  <p class="text-muted-foreground text-body-sm mb-6 max-w-xs">
    最初のプロジェクトを作成して、チームと共有しましょう。
  </p>
  <!-- CTA -->
  <Button>
    <PlusIcon /> プロジェクトを作成
  </Button>
</div>
```

## コピーライティング最終チェック

`ui-accessibility-design` スキルのコピー原則から:

| ❌ NG | ✅ OK |
|---|---|
| エラーが発生しました | メールアドレスが見つかりません。別のアドレスをお試しください |
| データがありません | まだ[X]がありません。最初の[X]を追加しましょう |
| 保存 | 変更を保存する |
| 削除 | アカウントを完全に削除する |
| OK | 了解しました |
| キャンセル | やめる |
| エラー: 422 | 入力内容に問題があります |

## パフォーマンス最終確認

```bash
# Core Web Vitals チェック
- LCP (最大コンテンツの描画): < 2.5秒
- FID / INP (インタラクション): < 200ms
- CLS (レイアウトシフト): < 0.1

# チェックツール
- Chrome DevTools > Lighthouse
- https://pagespeed.web.dev/
- https://web.dev/measure/
```

## 最終 QA チェックリスト

### 見た目
- [ ] 全フォントが正しくロードされているか（FOIT/FOUT なし）
- [ ] アイコンサイズが統一されているか（16/20/24px）
- [ ] ボーダーラジアスが全コンポーネントで一貫しているか
- [ ] ダークモードで全コンポーネントが正しく表示されるか

### インタラクション
- [ ] ホバー → フォーカス → アクティブ の状態遷移が自然か
- [ ] ローディング中にボタンが二重押しできないか
- [ ] エラー後に状態がリセットされるか

### コンテンツ
- [ ] 全ボタンが動詞から始まっているか
- [ ] エラーメッセージが具体的で前向きか
- [ ] 空状態に必ずCTAがあるか
- [ ] Toastメッセージの表示時間が十分か（3-5秒）

## 完成！

Stage 9完了 = プロダクションリリース可能な品質。
次の改善サイクルは Stage 1 から再スタートするか、修正が必要なステージに直接飛ぶ。
