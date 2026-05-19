# Muser Harness Operating Patterns

`memory/topics/harness.md` と `memory/topics/dev-workflow.md` から、
Muser環境で繰り返し使うハーネス運用パターンだけを抽出したもの。

## 1. Default loop = Plan → Execute → Evaluate → Learn
- **Plan:** ゴール・制約・合格条件を固定
- **Execute:** 役割に合う skill / agent / tool を選ぶ
- **Evaluate:** 自己評価で終わらせず、決定論的チェック or 別視点レビューを通す
- **Learn:** lessons / hook / skill / policy へ昇格する

## 2. artifact-first, not chat-first
- progress / decision / task / next step をファイルに残す
- 長タスクは compaction だけに頼らず、context reset + handoff を前提にする
- 継続性は会話ではなくアーティファクトに持たせる

## 3. verifier-first
- LLM自己評価より、決定論的 verifier を優先する
- 完全自動判定できない領域でも generator と evaluator を分離する
- red flag（長すぎる応答、フォーマット崩れ、期待件数ズレ）が出たら retry / reject を先に考える

## 4. specialized tools は boundary の所だけ
typed tool に昇格するのは、以下のように境界管理が必要な操作だけ:
- 外部送信
- 破壊的変更
- 承認が必要な操作
- 構造化ログが欲しい高リスク操作

単なるデータ加工や段取りまで専用ツール化しない。
まず bash / file / browser / memory の組み合わせで足りるか確認する。

## 5. prune-first harness review
新しいハーネスを足す時は、同時に「何を削れるか」を点検する。
- 古い補助ロジック
- 毎回の冗長な手順
- 使われていない context 注入
- 役割が重複した tool / skill

## 6. cache-friendly context design
- 静的なものを先、動的なものを後
- system prompt を頻繁にいじるより、messages / reminder / skill 読み出しで更新
- 長タスクほど model / tool set の頻繁な切替を避ける

## 7. zero-key / supervisor-first
- credential は agent に直接渡さない
- host/runtime/egress 側で権限・ログ・課金・制限を握る
- agent には scoped tool / allowed host / mounted filesystem だけを見せる

## 8. DESIGN.md と CLAUDE.md を分ける
- `CLAUDE.md` = 作業手順
- `DESIGN.md` = UI / 設計原則
- 人間向け説明より、検証器が読める schema / registry / test を正本に寄せる

## 9. 昇格ルール
- 同じ痛みが2回以上出たら、skill / hook / policy 化を検討
- 3回出たら、できるだけ自動化 or 強制ゲート化する

## 10. lifecycle gate routing
外部skill packやslash command体系を見つけたら、導入前に `define/spec → plan → build → verify/test → review/simplify/security → ship/learn` のどこを強くするものかに分類する。

- 既存skillで受けられるgateは、個別プロジェクトにquality gateを複製せず共通skillへ寄せる
- command名はUI都合、gateは運用品質のSSOTとして扱う
- install / plugin導入は provenance・staging・security scan が済むまでしない
- 足りないのが「入口」だけなら、まずrouting表・template・checklistで済ませる
