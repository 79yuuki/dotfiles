# Stage 1: Layout — IA・構造・グリッド

## 目的

ページ全体の情報アーキテクチャ（IA）とレイアウト構造を確定する。
「何をどこに置くか」が決まれば後のステージが全て楽になる。

## プロンプトテンプレート

```
# Stage 1: Layout Review

以下のUIのレイアウト構造を設計・改善してください。

## 基本情報
- タイプ: [WebApp / LP / Dashboard / MobileUI]
- スタック: [Next.js + Tailwind + shadcn/ui など]
- 目的: [ユーザーが達成したいこと]
- 参照デザイン: [Vercel / Linear / Stripe / Apple など]
- DESIGN.md: [要約を貼る / まだない]
- keep / rethink / discard: [残す要素 / 作り直す要素 / 捨てる要素]

## 現状のHTML/コード（あれば貼る）
[コードまたは「まだない」]

## 要求

1. **IA構造**: ページの情報ヒエラルキーを箇条書きで定義してください
2. **コンポーネント構成**: vibe-codingフォーマットで記述してください
   例: `App Bar(fixed) + Sidebar(persistent, 240px) + Main Content`
3. **グリッドシステム**: 12カラム / 4カラム / どのグリッドか
4. **コンテナ幅**: max-w-screen-xl / max-w-4xl など
5. **改善点**: IAの問題点と修正案（あれば）

出力はコードではなく構造仕様として記述してください。
```

## チェックポイント

- [ ] ユーザーの主要タスクがファーストビューに来ているか
- [ ] 一貫したナビゲーションパターン（全ページで同じ）
- [ ] 空状態・ローディング状態のレイアウトも考慮されているか
- [ ] モバイルでも成立するIA（hamburger menu？bottom nav？）

## ページタイプ別 標準IA

### LP (ランディングページ)
```
1. Hero — 価値提案 + プライマリCTA
2. Social Proof — 実績・ロゴ・数字
3. Features — 3〜6つの特徴
4. How it works — ステップ説明
5. Pricing — プランカード
6. FAQ — よくある疑問
7. Final CTA — 最後の申し込み促進
8. Footer
```

### Dashboard
```
1. App Bar — グローバルナビ・ユーザー情報
2. Sidebar — セクション別ナビゲーション
3. Breadcrumb — 現在地表示
4. Page Header — タイトル + アクションボタン
5. Stat Cards — KPI一覧
6. メインコンテンツ — テーブル / チャート / カード
7. Toast — 操作フィードバック
```

### Web App (タスク系)
```
1. App Bar — ロゴ + グローバル検索 + ユーザーメニュー
2. Sidebar / Drawer — 機能ナビ
3. Main — ページコンテンツ
4. Context Panel (optional) — 詳細・設定
5. Command Palette (⌘K) — パワーユーザー向け
```

### Mobile UI
```
1. Status Bar (system)
2. Navigation Bar — 画面タイトル + アクション
3. Scroll Area — メインコンテンツ
4. Bottom Tab Bar — プライマリナビ (4〜5項目)
5. FAB — プライマリアクション (optional)
```

## 次のステージへ

Stage 1承認後、以下を確定して Stage 2 (Color) へ:
- コンポーネント構成（vibe-coding形式）
- グリッド・コンテナ幅
- 画面遷移フロー（あれば）
