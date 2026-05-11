---
name: trading-risk-controls
description: トレードbotの資金管理、ポジションサイズ、損切り、ATR、Kelly基準、ドローダウン制限、レバレッジ制限、日次停止、破産確率、リスク監査を設計・レビューする時に使う。
---

# Trading Risk Controls

予測精度より資金管理が支配的になる。bot の設計では、利益ロジックと同じ重さで損失制御を実装する。

## 最初に固定する入力

- 口座サイズ、許容最大DD、最大日次損失
- 対象市場、レバレッジ、清算ルール
- 1回あたりの想定保有時間
- 注文方式と約定失敗時の挙動
- backtest/paper/live のどの段階か

## 先に決める制約

- 1トレード最大損失
- 1日/1週/月次の最大損失
- 最大建玉、最大レバレッジ、最大銘柄集中度
- 連敗時の減額ルール
- 流動性低下時、API不安定時、異常ボラ時の停止条件
- 手動停止と再開条件

## ポジションサイズ

1. 期待値、勝率、平均利益、平均損失、損益分布を確認する
2. Kelly は上限ではなく参考値として使い、実運用では fractional Kelly か固定リスクに落とす
3. ボラティリティターゲットを使う場合は、急変時にサイズが遅れて大きくならないよう上限を置く
4. ペア/デルタニュートラルでも、相関崩壊、借入、funding、清算、片側約定を別リスクとして扱う

## 損切りとエグジット

- 固定幅、ATR連動、トレーリング、時間切れ、シグナル反転を戦略ごとに分ける
- ATR や実現ボラでストップを調整する時は、近すぎる損切りと遠すぎる損切りを両方検証する
- 利確だけを最適化せず、損切り後の再エントリー抑制も設計する
- 取引所の注文機能を使う場合でも、bot 側に監視と非常停止を持つ

## 実装チェックリスト

- すべての注文前に `pre_trade_risk_check` が走る
- 注文数量は残高、証拠金、最小注文単位、最大建玉をすべて満たす
- 約定後に残高、建玉、未実現PnL、証拠金率を更新する
- 日次損失、連敗、ドローダウンで自動停止する
- 例外時にポジションが放置されない
- backtest、paper、live で同じリスク計算を使う
- リスク違反はログだけでなく通知される
- 再起動時に取引所状態とローカル状態を照合してから取引再開する

## レビュー観点

| Area | Question |
|---|---|
| Sizing | 1回の外れ値で口座が壊れないか |
| Leverage | 清算価格と証拠金余力を常時見ているか |
| Correlation | 複数戦略が同じリスクに賭けていないか |
| Liquidity | 逃げたい時に約定できるサイズか |
| Operations | bot停止中もリスクが増えないか |

## 出力テンプレート

```markdown
## Risk Plan
- Account/risk budget:
- Position sizing:
- Stop loss / exit:
- Daily and weekly circuit breakers:
- Leverage and liquidation controls:
- Recovery procedure:

## Required Code Checks
| Check | Location | Status |
|---|---|---|
| pre_trade_risk_check | | |
| post_fill_reconcile | | |
| circuit_breaker | | |
| restart_reconciliation | | |
```

## 危険な兆候

- 勝率や予測精度だけでサイズを増やす
- Kelly をそのままフルサイズで使う
- paper では止まるが live では止まらない別実装
- デルタニュートラルを無リスク扱いする
- 損失停止後の再開条件が曖昧
