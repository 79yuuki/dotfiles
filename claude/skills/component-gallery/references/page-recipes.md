# ページタイプ別レシピ集

ページの種類ごとに推奨コンポーネント構成を定義。AIコーディングエージェントに「○○構成で」と指示する時のテンプレート。

## 使い方

1. ページタイプを特定
2. 必須コンポーネントを確認
3. オプションから必要なものを選択
4. 「Header + Hero + Card Grid(3col) + Accordion + CTA + Footer 構成で」と指示

---

## 🏠 Landing Page / Homepage

**目的:** 初見ユーザーの理解→アクション

### 必須
```
Header → Hero → Features(Card Grid) → CTA → Footer
```

### フル構成
```
Header
  → Navigation + Button(CTA) + Badge("Beta")
AlgorithmicBackground / 3D Animation
  → Canvas or CSS animation (差別化要素)
Hero
  → Badge + Heading + Subtitle + Button Group(Primary+Ghost) + Terminal/Code Demo
AudienceSelector
  → Card(2col): ペルソナ別の導線分岐
Quickstart
  → Progress Indicator(Steps) + Code Block
Problem
  → Card Grid: 課題の可視化
HowItWorks
  → Progress Indicator(Stepper) + Card + Code Block
Features
  → Card Grid(2-3col) + Badge(status) + Icon
UseCases
  → Tabs or Card Grid: ユースケース別
DeveloperExperience
  → Code Block + Tabs(言語切替)
Roadmap
  → Progress Indicator(Timeline) + Badge(status)
FAQ
  → Accordion
CTA Section
  → Heading + Text Input(email) + Button
Footer
  → Navigation + Link + Icon(social)
```

### Component Gallery指示例
```
"Header(fixed, backdrop-blur) + Hero(full-height, gradient-bg, terminal-demo)
+ Card(2col, persona-selector) + Stepper(3-step quickstart)
+ Card Grid(3col, icon+title+description) + Accordion(FAQ, 10 items)
+ CTA(email-capture) + Footer(3-column)"
```

---

## 📁 Directory / Marketplace / Catalog

**目的:** 大量のアイテムから探索・発見

### 必須
```
Header → Search → Card Grid → Pagination → Footer
```

### フル構成
```
Header
  → Navigation + Search(global, ⌘K shortcut) + Avatar + Badge(notification)
Breadcrumb
  → 現在位置表示
Sidebar(Drawer)
  → Navigation(category) + Checkbox(filter) + Slider(price range)
Filter Bar
  → Badge/Chip(toggleable filter tags) + Select(sort) + Segmented Control(view)
Card Grid
  → Card(image+title+description+Badge+Rating) + Skeleton(loading)
  → 各CardにBadge(Verified/Beta/New) + Rating(stars)
Empty State
  → 検索結果なし時の代替アクション
Pagination
  → ページナビゲーション
Toast
  → アクション完了通知（「Added to favorites」等）
Footer
```

### Component Gallery指示例
```
"Header(search-bar, avatar) + Breadcrumb + Sidebar(category-nav, checkbox-filters)
+ Badge(filter-chips, toggleable) + Card Grid(3col, image+rating+badge)
+ Skeleton(loading-placeholder) + Empty State + Pagination + Toast"
```

---

## 💰 Pricing Page

**目的:** プラン比較→購入決定

```
Header
Hero(compact)
  → Heading + Subtitle + Segmented Control(Monthly/Annual toggle)
Card Grid(3-4col, pricing tiers)
  → Card(plan-name + price + feature-list + Button + Badge("Popular"))
Table(feature comparison)
  → Checkbox/Icon(included features per plan)
Accordion(FAQ)
CTA Section
Footer
```

---

## 📊 Dashboard / Admin

**目的:** データの一覧・管理・操作

```
Header(compact)
Sidebar(Drawer, persistent)
  → Navigation(vertical) + Avatar + Badge(notification count)
Breadcrumb
Card Grid(stats overview)
  → Card(metric + Progress Bar + Sparkline)
Table(data)
  → Search + Select(filter) + Checkbox(bulk select) + Pagination
  → Dropdown Menu(row actions)
Modal(create/edit forms)
  → Form + Fieldset + Text Input + Select + Button Group
Toast(action feedback)
```

---

## 📝 Blog / Article

**目的:** コンテンツ消費

```
Header
Hero(article, image + heading + Badge(category) + Avatar(author))
Article Body
  → Heading(h2-h4) + Image + Quote + List + Table + Code Block
Navigation(TOC sidebar, sticky)
  → Link(anchor) + Progress Bar(reading progress)
Card Grid(related articles)
CTA(newsletter subscribe)
Footer
```

---

## 📋 Form / Multi-Step Wizard

**目的:** 情報入力

```
Header(minimal)
Progress Indicator(Steps)
Form
  → Fieldset + Label + Text Input + Select + Radio + Checkbox
  → Date Picker + File Input + Combobox
  → Alert(validation errors)
Button Group(Back + Next/Submit)
Modal(confirmation)
Toast(success feedback)
```

---

## 👤 Settings / Profile

**目的:** 設定管理

```
Header
Sidebar or Tabs(settings categories)
Form(settings groups)
  → Fieldset + Toggle + Select + Text Input
  → Avatar(profile photo upload) + File Input
Alert(save confirmation)
Modal(dangerous actions: delete account)
Button(Save)
```

---

## 🔍 Search Results

**目的:** 検索結果の閲覧

```
Header + Search(persistent)
Badge(result count + filter chips)
Card(result items) or List(compact results)
  → Heading + Badge(relevance/category) + Link
Pagination or Infinite Scroll
Empty State(no results)
```

---

## 構成指示のベストプラクティス

### 1. 構造名で指示する
❌ 「上の方にメニューを置いて、その下に大きい画像があって...」
✅ 「Header(fixed) + Hero(full-height, image-bg) + Card Grid(3col)」

### 2. 修飾子で詳細化
- `(fixed)` — 固定配置
- `(2col)`, `(3col)` — カラム数
- `(compact)` — 省スペース版
- `(sticky)` — スクロール追従
- `(toggleable)` — 切り替え可能

### 3. 関係性を明示
- `→` でネスト（親子関係）
- `+` で並列
- `|` で排他（AまたはB）

### 4. データの流れを含める
```
Search → Filter(Badge chips) → Card Grid → Pagination
                                    ↓
                              Empty State(no results)
```

### 5. インタラクションを指定
```
Card(clickable → Modal(detail))
Toggle(→ API call → Toast(success))
Button(→ Form submit → Alert(validation) | Toast(success))
```
