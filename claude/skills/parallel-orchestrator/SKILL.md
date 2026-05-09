---
name: parallel-orchestrator
description: "Automatically estimates task complexity and orchestrates parallel subagent execution with Codex review. Triggers on: complex implementation requests, multi-file changes, feature additions. Auto-activates when 3+ independent subtasks detected."
---

# Parallel Orchestrator Skill

タスク量を自動見積もりしCodexにレビューしてもらい、並列実行可能な作業を計画してCodexレビューしてからsubagentに振り分け実行前にCodexレビューしたものを実行して再度Codexレビューしてもらい、Codexレビューを経て統合する汎用オーケストレーター。

## 設計原則（ベストプラクティス）

### Single-Responsibility Design
各 subagent は以下を明確に持つ:
- **目標**: 1つの明確なゴール
- **入力**: 必要なコンテキスト・ファイル
- **出力**: 成果物（変更ファイル、テスト結果）
- **ハンドオフルール**: 完了条件と次のステップ

### Safe Parallelization (Disjoint Slugs)
並列実行は **異なるモジュール/ファイル** の場合のみ安全:
- ✅ `src/domain/` と `src/ui/` を別 subagent で並列
- ✅ `backend/` と `frontend/` を並列
- ❌ 同じファイルを複数 subagent が編集

### Human-in-the-Loop (HITL) Pattern
明確なハンドオフポイントで人間の承認を得る:
1. **計画承認**: Wave 構成の確認
2. **統合前**: 全ストリーム完了後の最終確認

### Serialize High-Risk, Parallelize Safe
- **直列化**: 型定義、共通基盤、破壊的変更
- **並列化**: 独立コンポーネント、Read-only 調査、テスト

## 自動トリガー条件

以下の条件を満たす場合、このスキルを自動適用する:

1. **複数ファイル変更**: 3つ以上のファイルに変更が必要
2. **独立タスク**: 依存関係のない独立した作業が3つ以上
3. **機能追加**: 新機能実装で複数コンポーネントが必要
4. **リファクタリング**: 広範囲のコード変更

**適用しない場合:**
- 単一ファイルの小さな修正
- バグ修正1件
- 質問への回答のみ

## フェーズ1: タスク分析（自動実行）

ユーザーのプロンプトを受信したら、以下を自動で分析:

```
1. 要求の解析
   - 何を実現したいか
   - どのファイル/コンポーネントが関係するか
   - 既存コードへの影響範囲

2. 作業量見積もり
   - 変更対象ファイル数
   - 新規作成ファイル数
   - 変更行数の概算

3. 依存関係分析
   - 直列で実行すべき作業（型定義、共通モジュール等）
   - 並列実行可能な作業（独立したコンポーネント）

4. Disjoint Slugs 検証
   - 各ストリームの担当ファイルをリスト化
   - 重複がないことを確認
   - 重複がある場合は分割を再検討
```

### 調査フェーズの並列化（Read-only）

実装前の調査は積極的に並列化する:

```typescript
// 同時に複数の Explore subagent を起動
Task({
  subagent_type: "Explore",
  description: "調査: 既存の認証パターン",
  prompt: "src/infrastructure/ 配下の認証関連コードを調査"
})
Task({
  subagent_type: "Explore",
  description: "調査: API設計パターン",
  prompt: "services/collector/src/routes/ のルート定義パターンを分析"
})
```

Read-only 操作は安全に並列化でき、メインコンテキストの節約にもなる。

## フェーズ2: 並列化判定

**並列化の必須条件:**
- 独立タスクが3つ以上
- 各タスクが **disjoint slugs**（異なるファイル/モジュール）
- 依存関係が明確で、Wave 1 で解消可能

**並列化を避けるケース:**
- 同一ファイルへの複数変更
- 密結合したコンポーネント
- 実行順序に依存する処理

**判定結果をユーザーに報告（HITL Gate 1）:**

```
【タスク分析結果】

■ 作業量見積もり
- 変更対象: X ファイル
- 新規作成: Y ファイル
- 独立タスク: Z 件

■ 並列化判定: [適用/不適用]
理由: <判定理由>

■ Disjoint Slugs 検証
- Stream A: src/domain/*, src/infrastructure/foo_client.ts
- Stream B: src/ui/*, public/index.html
- Stream C: test/*
→ 重複なし ✅

■ 実行計画
Wave 1 (直列・基盤):
  - タスク1: <内容>
Wave 2 (並列):
  - Stream A: <内容> [担当: src/domain/*, src/infrastructure/foo_*]
  - Stream B: <内容> [担当: src/ui/*, public/*]
  - Stream C: <内容> [担当: test/*]

この計画で進めてよいですか？
```

## フェーズ3: Wave実行

### Wave 1: 基盤作業（直列）

全ストリームの前提となる作業を先に完了:
- 型定義 (types.ts)
- 共通ユーティリティ
- 設定ファイル
- インターフェース定義

**完了条件:** typecheck 通過

### Wave 2: 並列実行

Task ツールで subagent を並列起動:

```typescript
// 同時に複数の Task を実行
Task({
  subagent_type: "general-purpose",
  description: "Stream A: <タスク概要>",
  prompt: `<詳細な指示>`
})
// 他のストリームも同時実行
```

**各 subagent への指示に含める内容:**

1. **コンテキスト**: 関連する既存コード、型定義
2. **タスク詳細**: 何を実装するか、どのファイルを変更するか
3. **制約**: 命名規則、コーディング規約
4. **完了条件**: typecheck 通過必須
5. **スコープ制限**: 他のストリームの担当範囲には手を出さない

## フェーズ4: Codexレビュー

各ストリーム完了後、tmux経由でCodexにレビュー依頼:

```bash
# Step 1: レビュー内容を一時ファイルに保存
cat > /tmp/codex_prompt.txt << 'PROMPT_EOF'
【レビュー依頼】

■ 対象: Stream A - <タスク名>
■ 変更ファイル:
<git diff --name-only の結果>

■ 実装内容:
<実装の要約>

■ 確認観点:
1. 型の整合性
2. 既存コードとの一貫性
3. エッジケースの考慮
4. パフォーマンス

問題があれば指摘してください。
PROMPT_EOF

# Step 2-4: 送信
tmux load-buffer /tmp/codex_prompt.txt && tmux paste-buffer -t 1
tmux send-keys -t 1 Enter
rm -f /tmp/codex_prompt.txt
```

**レビュー結果が NG の場合:**
- 指摘事項を修正
- 再度レビュー依頼

## フェーズ5: 統合検証

全ストリーム完了後:

```bash
# 1. 型チェック
npm run typecheck

# 2. テスト
npm test

# 3. ビルド
npm run build
```

**Codex統合レビュー:**

```
【統合レビュー依頼】

全ストリームの実装が完了しました。

■ 変更概要:
<全体の変更内容>

■ 各ストリームの実装:
- Stream A: <内容>
- Stream B: <内容>
- Stream C: <内容>

■ 確認観点:
1. ストリーム間の整合性
2. 全体的なアーキテクチャ
3. 見落としているエッジケース

統合レビューをお願いします。
```
