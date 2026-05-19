---
name: gtm-content-ops
description: >-
  Design and run small-team content operations: source monitoring, social posts, articles, newsletters, press releases, repurposing loops, editorial calendars, and distribution systems. Use when building repeatable GTM content workflows.
---

# GTM Content Ops — 一人法人コンテンツ量産オペレーション

## コンセプト

**GTMエンジニア（Go-To-Market Engineer）のコンテンツ実行エンジン。**

GTMエンジニアは1人がAI活用でICP設計→リード獲得→CRM→営業オペ→分析改善を統合的に回す役割。
このスキルはその中の「リード獲得 × コンテンツ量産」を担う。

「バラバラに頑張る」のではなく、**1つのインプットから複数アウトプットを自動展開**するループ構造を作る。

```
[インプット]
  ↓
ニュース / 日報 / ノウハウ / 開発ログ
  ↓
[コンテンツループ]
  ↓  ↓  ↓  ↓  ↓
 SNS  記事  NL  PR  ネタ化
  ↑_________________________↓
      改善 → 仕組み → コンテンツ
```

## ワークフロー

### Phase 1: ループ設計

ユーザーの事業・リソースをヒアリングし、コンテンツループを設計する。

1. **インプット源の特定**: 何が日常的にインプットになるか（ニュース、日報、開発ログ、顧客声）
2. **アウトプット先の選定**: どのプラットフォームに出すか
3. **ループ構造の設計**: インプット→アウトプットの変換ルールを定義
4. **運用リズムの決定**: 朝/夜/週次のルーティン設計

→ 詳細: [references/content-loop.md](references/content-loop.md)

### Phase 2: マルチプラットフォームSNS運用

1トピック × Nプラットフォームの同時投稿体制を構築する。

- プラットフォーム別のテキスト整形ルール
- 投稿スケジュールとバッチ処理
- エンゲージメント計測の仕組み

→ 詳細: [references/multi-platform-sns.md](references/multi-platform-sns.md)

### Phase 3: 記事量産パイプライン

新規記事 + 既存記事リライトの二本柱で月100本級を回す。

- 新規記事: SNS投稿 → 深掘り記事化
- リライト: 情報の陳腐化検出 → 自動更新
- 双方向展開: 記事 → SNS / SNS → 記事

→ 詳細: [references/article-pipeline.md](references/article-pipeline.md)

### Phase 4: プレスリリース運用

「やったのにプレスにしてなかった」を撲滅する。

- PR TIMES等の配信サービス活用
- プレスリリースネタの棚卸し
- 月額プランでのコスト最適化

→ 詳細: [references/press-release.md](references/press-release.md)

### Phase 5: ニュースレター自動化

既存コンテンツからニュースレターを自動生成する。

- Beehiiv等のプラットフォーム活用
- 週次/月次の配信リズム
- コンテンツキュレーション自動化

→ 詳細: [references/newsletter.md](references/newsletter.md)

### Phase 6: 分析と最適化

量を出した後の質の最適化フェーズ。

- 何が伸びるかの分析
- プラットフォーム別のパフォーマンス計測
- コンテンツの「自分らしさ」の担保

→ 詳細: [references/analytics-optimization.md](references/analytics-optimization.md)

## 運用の鉄則

1. **仕組みの開発自体がコンテンツになる** — メタ的に回す
2. **量が先、質は後** — まず出せる体制を作り、最適化は別フェーズ
3. **双方向展開** — SNS→記事も記事→SNSも。一方通行にしない
4. **棚卸しを忘れない** — 過去にやったことのプレス化、古い記事の更新
5. **1日30分〜1時間** — 仕組み構築に時間をかけ、運用は軽くする
6. **低制作コストのバズ型を先に選ぶ** — 金額開示 / 準備密着 / 無言レビュー / 視聴者回答 / ストリートスナップを、事業テーマに転用してから台本化する
7. **AI駆動GTMはTripodで作る** — GTMエンジニア / データ担当 / 業務トップパフォーマーの3者でベストプラクティスを文書化し、human-in-the-loop QA後に自律化する
8. **既存スタックの“間”を縫う** — CRM/team chat/メール/商談ログを全部置き換えず、まずteam chatをフロントドアにしてエージェントがコンテキストを集約する
9. **Semantic layerを先に置く** — ARR/CVR/リード品質/商談段階などの定義が揺れるとGTMエージェントは壊れる。コンテンツ/営業自動化前に共通KPIとGolden Queriesを固定する
