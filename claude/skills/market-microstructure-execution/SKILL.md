---
name: market-microstructure-execution
description: トレードbotの注文執行、板情報、スプレッド、スリッページ、約定可能性、CEX/DEXアービトラージ、マーケットメイク、funding rate、オーダーフロー、レイテンシを設計・検証する時に使う。
---

# Market Microstructure Execution

裁定や短期戦略は「価格差を取って引き算する」だけでは動かない。実運用で重要なのは、見えている価格で約定できるか、どの順序で注文するか、失敗時にどう逃げるか。

## まず分類する

- **Directional**: シグナルに従って片側売買する
- **Arbitrage**: 複数市場/商品間の価格差を取る
- **Market making**: maker 注文と在庫管理で収益化する
- **Funding/carry**: funding、金利、貸借、先物ベーシスを取る
- **DEX/MEV-sensitive**: ガス、ブロック、RPC、MEV の影響が大きい

分類により、必要なデータ粒度と失敗時のヘッジが変わる。

## 執行設計

1. **市場データの鮮度を測る**
   - 取引所ごとの受信時刻、イベント時刻、ローカル時刻を分ける
   - 板と約定履歴の遅延、欠落、順序入れ替わりを検知する
   - アービトラージでは比較対象の時刻差を明示する

2. **約定可能価格で評価する**
   - mid price ではなく bid/ask、板厚、想定発注量で損益を計算する
   - スプレッド、手数料、funding、借入、ガス代、送金コストを入れる
   - 部分約定と片側約定の損失を見積もる

3. **注文方式を戦略ごとに選ぶ**
   - maker/taker、指値/成行、post-only、IOC/FOK、トレーリングを使い分ける
   - マーケットメイクでは在庫、逆選択、ティックサイズ、板の透明性を監視する
   - DEX ではMEV、サンドイッチ、ガス、ブロック確定、RPC遅延を別リスクにする

4. **失敗時の状態遷移を設計する**
   - 片側だけ約定した時のヘッジ
   - 注文キャンセル失敗時の再照会
   - WebSocket断、REST制限、取引所メンテ時の縮退
   - ポジションと注文の再同期

5. **本番監視に接続する**
   - latency、spread、fill ratio、cancel reject、order age をメトリクス化する
   - 閾値超過時はサイズ縮小または取引停止する
   - `trading-ai-agent-ops` の監視ログに渡せる形式にする

## バックテストに入れるもの

- bid/ask スプレッド
- 板厚に応じた価格インパクト
- taker/maker 手数料とリベート
- 注文遅延、キャンセル遅延、約定失敗
- funding rate と清算コスト
- ガス代、ブリッジ、送金待ちが必要な戦略ならその時間リスク

## 出力テンプレート

```markdown
## Execution Model
- Strategy class:
- Data freshness threshold:
- Price used for PnL:
- Order types:
- Expected costs:
- Failure states:

## Runtime Metrics
| Metric | Threshold | Action |
|---|---|---|
| market_data_lag_ms | | |
| spread_bps | | |
| fill_ratio | | |
| order_age_ms | | |
| position_mismatch | | |
```

## 実装レビューの質問

- PnL は mid ではなく実際に取れる価格で計算しているか
- データ時刻差が閾値を超えたら取引を止めるか
- 最小利益幅はコストと片側約定リスクを超えているか
- 約定しなかった注文が残り続けないか
- API障害後に、ローカル状態と取引所状態を照合しているか
- paper と live で注文状態遷移が同じコードを通るか
