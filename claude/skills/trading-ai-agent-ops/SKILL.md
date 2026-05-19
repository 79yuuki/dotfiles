---
name: trading-ai-agent-ops
description: Claude Code やLLMエージェントでトレードbot、マーケット分析、戦略生成、運用監視、AIOpsを行う時に使う。AIに投資判断を丸投げせず、ログ、可視化、レビュー、監視、権限境界を設計する。
---

# Trading AI Agent Ops

AI エージェントは戦略探索と運用補助を速くするが、投資判断と資金移動を無制限に任せない。人間が検証できる中間成果物、権限境界、監査ログを必ず残す。

## 原則

- AIは提案者、検証者、監視者として使う
- live 注文、増額、停止解除は人間承認を要求する
- すべての提案はデータ、コード、ログ、チケットのいずれかに紐づける
- 監視は「異常を説明する」だけでなく「止める/縮小する」制御に接続する

## 役割分離

- **Research agent**: 仮説、特徴量、文献、関連銘柄を調べる
- **Backtest agent**: 検証コード、データ分割、結果表を作る
- **Risk reviewer**: 損失制限、レバレッジ、停止条件を確認する
- **Execution monitor**: 注文、約定、残高、ログ、異常を監視する
- **Human approver**: 本番投入、増額、戦略変更を承認する

## AIに任せてよいこと

- 市場メモ、銘柄スクリーニング、論文要約
- 特徴量候補の整理と実験計画
- バックテストコードの作成とレビュー
- ログ監視、異常検知、日次レポート
- 戦略仕様書とリスクチェックリストの更新

## AIに丸投げしないこと

- 実弾注文の最終承認
- APIキー、出金、権限管理
- 検証なしのパラメータ変更
- バックテスト結果だけを根拠にした増額
- 損失停止条件の解除

## 可視化と説明

戦略を実装する時は、AIと人間が同じ絵を見られるようにする。

- エントリー理由、エグジット理由、無取引理由
- シグナル、閾値、ポジション、PnL、DD、手数料
- 市場レジーム、ボラティリティ、出来高、OI、funding
- バックテストと本番の差分
- 異常時のログと復帰判断

## 運用監視

- 本番と同じ画面、同じログ、同じDBを監視対象にする
- 残高、建玉、未約定注文、想定PnL、実現PnLを照合する
- 異常は「通知」だけでなく、取引停止やサイズ縮小に接続する
- 日次で、AIの提案、実行された変更、却下理由を残す

## 権限設計

| Capability | Default |
|---|---|
| Read market data | allow |
| Read logs and positions | allow |
| Write research notes | allow |
| Change strategy code | human review |
| Change risk limits | human approval |
| Place live orders | deny unless explicitly approved |
| Withdraw/transfer funds | deny |

## 運用成果物

```markdown
## Daily Bot Ops Note
- Market regime:
- Strategies active:
- PnL vs expected:
- Risk limit usage:
- Execution anomalies:
- Code/config changes:
- AI suggestions accepted/rejected:
- Human actions required:
```

## 公式金融 skill との使い分け

- 株式のアイデア、決算、カタリスト、セクター分析は `equity-research` の skill を優先する
- セクター/テーマから投資候補を広く洗う時は `market-researcher` を優先する
- DCF、comps、3-statement、スプレッドシート監査は `financial-analysis` の skill を優先する
- bot の検証、執行、リスク、運用監視はこの trading 系 skill 群を優先する

## 他 skill への受け渡し

- 戦略仮説の調査: `quant-research-workflow`
- 本番投入前の合否判定: `strategy-validation-gate`
- サイズ、停止条件、破産回避: `trading-risk-controls`
- 注文、板、約定、レイテンシ: `market-microstructure-execution`

## Generative AI investment guardrails

- 生成AIは投資知識を説明できても、運用責任を持つ投資主体ではない。銘柄選定、売買タイミング、ポジションサイズ、停止解除の最終判断をそのまま任せない。
- AIの有効な使い方は、仮説生成、反対意見、資料/ログ要約、検証コード作成、異常説明、チェックリスト更新に限定する。
- AIが市場データ/API/RAGに接続していても、「データに接続している」ことと「重要度・織り込み・価格影響を正しく判断できる」ことは別物として扱う。
- AI提案は必ず artifact 化する: source data、assumption、code diff、test/backtest result、risk review、human decision を残す。
- live注文、サイズ増額、停止解除、API key/出金/権限変更は human approval がない限り deny にする。
