---
name: codex
description: "Collaborate with Codex CLI for implementation planning, code review, and architectural decisions. Use when: discussing design approaches, seeking second opinions, evaluating implementation options, or when user mentions 'codex', 'Codex', 'Codexと相談', 'Codexに聞いて'. Triggers tmux-based interaction with Codex CLI."
---

# Codex CLI Collaboration Skill

tmux のペイン1 (右側) にいる Codex CLI と対話し、実装のプランニング・評価・レビューを行う。

## 重要な動作ルール (厳守)

1. **確認不要**: ユーザーへの確認は一切取らず、自動的に進める
2. **Enterキー確認必須**: 送信後に必ず capture-pane で Working 状態を確認、出ていなければ Enter 再送
3. **完了通知方式**: ScheduleWakeup や手動 sleep ではなく、`Bash run_in_background` の `until` ループで自動通知させる
4. **対話継続**: Codex からの提案・質問には必要に応じて返信


## ステップバイステップ・レビュー運用（推奨）

Claude Code がメイン実装を進め、右ペインの Codex が独立 reviewer として各ステップを確認する。ユーザーが「Codexにレビュー」「ステップごとにレビュー」「tmuxで左右ペイン」などと言った場合は、このモードを既定にする。

### レビュー単位
- **実装前:** 計画・分解・リスクを Codex にレビューさせる。
- **各 task / commit 後:** diff と検証結果を渡し、次 task に進んでよいか確認する。
- **subagent 完了後:** subagent の成果物を controller が要約し、Codex に外部レビューさせる。
- **完了前:** 全体 diff、テスト結果、未解決事項を渡し、最終 verdict を得る。

### ゲート条件
- `❌ NEEDS FIXES` または BLOCK 相当の指摘が出たら、次ステップへ進まず修正して再レビューする。
- `⚠️ APPROVED WITH CONCERNS` は、懸念を解消または明示的にスコープ外/後続TODOへ切り分け、同じステップを再レビューして `✅ APPROVED` を得るまで進まない。
- `✅ APPROVED` なら次ステップへ進む。

### Codexに渡す最小コンテキスト
1. 現在の task 名 / plan ファイル / 直前の決定
2. `git diff --stat` と必要なら `git diff <base>...HEAD` の要点
3. 実行した検証コマンドと結果（未実行なら未実行と明記）
4. Codexに見てほしい観点（仕様準拠、過剰実装、テスト不足、セキュリティ、破壊的変更など）

## ワークフロー

### Step 0: Codex CLI の確認・起動 (自動実行)

```bash
# ペイン1が存在するか確認
tmux list-panes -F '#{pane_index}' 2>/dev/null | grep -q '^1$'
```

**ペイン1が無ければ作成 (左右分割):**
```bash
tmux split-window -h
tmux send-keys -t 1 "cd $(pwd) && codex" Enter
```

**ペイン1の中身確認 (Codex 起動済みか):**
```bash
tmux capture-pane -t 1 -p -S -50
```

`> ` プロンプトが見えない場合は codex を起動して数秒待つ。

### Step 1: 質問送信 (paste → Enter → Working 確認)

**以下の Bash 呼び出しを **順番** に実行 (`&&` でチェーンしない):**

```bash
# 1. 質問を一時ファイルへ
cat > /tmp/codex_prompt.txt << 'PROMPT_EOF'
<質問内容>
PROMPT_EOF
```

```bash
# 2. tmux バッファ経由で paste (Codex 入力欄に投入)
tmux load-buffer /tmp/codex_prompt.txt && tmux paste-buffer -t 1 && rm -f /tmp/codex_prompt.txt
```

```bash
# 3. paste 完了を確認 (1 秒待ってから capture)
sleep 1 && tmux capture-pane -t 1 -p | tail -5
```
→ 投入した質問の末尾の数行が見えれば paste 成功。`Pasted Content N chars` のような placeholder のみが見える場合は paste 自体は完了している。`Explain this codebase` 等の placeholder のみが見える場合は paste 失敗 → 手順 2 をやり直す。

```bash
# 4. Enter キー送信
tmux send-keys -t 1 Enter
```

```bash
# 5. **送信確認** (paste-buffer のクセで Enter が消える事故が多い、必ず確認):
sleep 4 && tmux capture-pane -t 1 -p | tail -5
```
→ `• Working (Xs • esc to interrupt)` が見えれば確定送信成功。
→ `Explain this codebase` プレースホルダのみ / `> ` プロンプトのみ → **Enter が確定していない**ので再送:
```bash
tmux send-keys -t 1 Enter && sleep 4 && tmux capture-pane -t 1 -p | tail -5
```

**重要事項**:
- `send-keys Enter` は paste-buffer と **必ず別の Bash 呼び出し**で実行 (`&&` チェーンすると Enter が落ちる)
- paste 直後の `Create a plan?` ヒント表示は **Enter が確定していない**サイン。再送が必要
- `Explain this codebase` placeholder は Codex の入力欄が空になっている (= paste 反映後ではない)

### Step 2: 完了を待つ (bg 通知方式、推奨)

`ScheduleWakeup` で「N 分後にチェック」する従来方式は、cache TTL を浪費しやすく、レスポンスが遅くなる。代わりに `Bash run_in_background: true` で **`Working` 表示が消えるのを待つ** until ループを起動し、完了で自動通知させる:

```bash
# bg ループ: Codex の "Working (Xs • esc to interrupt)" 表示が消えるまで待つ
until ! tmux capture-pane -t 1 -p -S -10 | grep -q "Working ([0-9]"; do
  sleep 8
done
echo "CODEX_DONE_AT_$(date +%H:%M:%S)"
```
→ `run_in_background: true` で起動。Codex 完了時に自動 system 通知が届く。手動で polling する必要なし。

### Step 3: 結果取得

bg 通知が来たら capture して verdict を読む:

```bash
tmux capture-pane -t 1 -p -S -800 | tail -200
```

レビュー verdict (✅ APPROVED / ⚠️ APPROVED WITH CONCERNS / ❌ NEEDS FIXES) と各観点の評価が見える。

### Step 4: 対話継続

- 修正必要 → コード修正して再 commit、Step 1 から再投入
- 別意見/補足ある → 返信を Step 1 で投入
- ✅ APPROVED → 次のステップへ進める

### Step 5: 結論まとめ

合意した実装方針をユーザーに報告。

## 質問テンプレート

```
【背景】
<現在の状況・解決したい問題>

【現在のアプローチ】
<検討中の実装方針があれば記載>

【質問】
<具体的に聞きたいこと>
```

レビュー依頼の場合:

```
## 対象ステップ
<例: Task 2 / subagent: parser implementation / commit: abc1234>

## 対象 commit

```
<commit hash> <commit message>
```

## 実装内容まとめ

<変更概要>

## 検証

- pnpm test: <count>/<count> PASS
- pnpm typecheck: PASS

## レビュー観点

### 1. 次ステップに進んでよいか
仕様漏れ・テスト不足・破壊的変更・過剰実装があれば止めてください。

### 2. <観点>
<詳細>

### 3. <観点>
...

## 出力フォーマット

各観点を ✅ PASS / ⚠️ CONCERN / ❌ BLOCK で評価。
最後に総合判定: ✅ APPROVED / ⚠️ APPROVED WITH CONCERNS / ❌ NEEDS FIXES。
日本語で簡潔に。
```

## Claude Code の役割

- **コンテキスト提供**: リポジトリ構造、既存コード、命名規則を把握
- **設計レビュー**: アーキテクチャ準拠、レイヤー分離の観点で評価
- **品質チェック**: パフォーマンス、テスタビリティ、保守性の観点で検討
- **統合**: Codex の提案とリポジトリ文脈を統合して最適解を導出

## エラー対処 / よくあるトラブル

| 症状 | 原因 | 対処 |
|------|------|------|
| `Working` が出ない、`Explain this codebase` のまま | Enter が送信されていない (paste-buffer のタイミング問題) | `tmux send-keys -t 1 Enter` を再実行 |
| `Create a plan?` ヒントが見える | paste 後の Enter 未確定状態 | `tmux send-keys -t 1 Enter` で確定 |
| `no buffer` | 一時ファイル書き込み失敗 | `/tmp` の権限確認 |
| `can't find pane` | tmux 構成不正 | Step 0 を再実行 |
| paste 直後に `tab to queue message` 表示 | 入力欄に paste 済み、Enter 待ち | `tmux send-keys -t 1 Enter` |
| Codex セッション期限切れ | Codex CLI が exit | Step 0 で再起動 |

## 改善履歴

- **2026-05-09**: Enter 押し忘れ事故対策と bg 通知方式を追加
  - paste-buffer と send-keys Enter を必ず別 Bash 呼び出しに分離
  - paste 後 + Enter 後の各タイミングで capture-pane 確認を必須化
  - `ScheduleWakeup` polling 方式から `Bash run_in_background` の until ループ方式へ移行 (cache TTL 節約 + 完了即通知)

## 引数

$ARGUMENTS - Codex に送る質問や議題。会話の文脈を踏まえて質問を構築すること。
