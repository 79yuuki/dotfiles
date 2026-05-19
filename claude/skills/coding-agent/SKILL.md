---
name: coding-agent
description: >-
  Run short coding tasks, one-off scripts, small utilities, and focused code changes with a lightweight agent workflow plus review and verification gates. Use when work is too small for a full multi-agent plan but still needs tests and review.
metadata:
  {
    "agent-runtime": { "emoji": "🧩", "requires": { "anyBins": ["claude", "codex", "opencode", "pi"] } },
  }
---

# Coding Agent (bash-first)

Use **bash** (with optional background mode) for all coding agent work.

> Muser運用の追加ルール: [references/muser-coding-hygiene.md](references/muser-coding-hygiene.md)

## ⚠️ PTY Mode Required!

Coding agents are interactive terminal apps. **Always use `pty:true`.**

```bash
# ✅ Correct
bash pty:true command:"codex exec 'Your prompt'"
# ❌ Wrong
bash command:"codex exec 'Your prompt'"
```

### Bash Tool Parameters

| Parameter    | Description                                      |
| ------------ | ------------------------------------------------ |
| `command`    | Shell command to run                             |
| `pty`        | Allocates pseudo-terminal (required for agents)  |
| `workdir`    | Working directory (agent's context scope)        |
| `background` | Returns sessionId for monitoring                 |
| `timeout`    | Timeout in seconds                               |

### Process Tool Actions (for background sessions)

| Action      | Description                                          |
| ----------- | ---------------------------------------------------- |
| `list`      | List all running/recent sessions                     |
| `poll`      | Check if session is still running                    |
| `log`       | Get session output (with optional offset/limit)      |
| `write`     | Send raw data to stdin                               |
| `submit`    | Send data + newline (like typing + Enter)            |
| `send-keys` | Send key tokens or hex bytes                         |
| `kill`      | Terminate the session                                |

---

## 📚 Lessons Gate 連携（必須）

コーディングタスク開始前に `memory/topics/lessons.md` を読む。
詳細は `skills/lessons-gate/SKILL.md` を参照。

---

## 📂 作業ディレクトリ（必須）

共有ワークスペース root 配下の `projects/` にプロジェクトディレクトリを作ってコーディングすること。
ここでいう `WORKSPACE_ROOT` は、現在のランタイムが使う作業用 root（agent runtime workspace / Hermes workspace / 任意の共有workspace）に読み替える。
`mktemp -d` や `/tmp` での作業は禁止。

```bash
# ✅ ワークスペース内にリポジトリ作成
WORKSPACE_ROOT="<workspace-root>"
mkdir -p "$WORKSPACE_ROOT/projects/<project-name>"
cd "$WORKSPACE_ROOT/projects/<project-name>"
git init

# ❌ tmpで作業しない
# SCRATCH=$(mktemp -d) && cd $SCRATCH && git init
```

### 🌿 task / review ごとに worktree を分離する

同じrepoで複数タスクやPRレビューを並列で走らせる時は、**1 task / 1 review / 1 agent = 1 worktree** を基本にする。
base repo は `projects/<repo>`、専用 worktree は `projects/_worktrees/<repo>/<task>` に置く。

```bash
WORKSPACE_ROOT="<workspace-root>"
BASE="$WORKSPACE_ROOT/projects/<repo>"
WT="$WORKSPACE_ROOT/projects/_worktrees/<repo>/<task>"
mkdir -p "$(dirname "$WT")"
git -C "$BASE" worktree add "$WT" -b <branch-name> origin/main
```

- `/tmp` worktree は使わない
- レビュー用 worktree と実装用 worktree を混ぜない
- handoff 時は branch / path / 未完了メモを artifact に残す

→ 詳細: [references/measurement-and-isolation.md](references/measurement-and-isolation.md)

## 🔧 Harness初期化 + コーディング規約（必須）

作業開始時に以下を実行:

1. `CLAUDE.md` / `AGENTS.md` がなければ `/init` で生成
2. 生成されたファイルにコーディング規約を追記

```bash
cd <project-dir>
[ ! -f CLAUDE.md ] && [ ! -f AGENTS.md ] && claude /init
```

→ 規約テンプレート: `skills/dual-agent-dev/references/coding-standards.md` を参照

## 📏 Harness計測（軽量）

新しいハーネス改善や並列運用のやり方を試した時は、**良かった気がする** で終わらせず最低限の計測を残す。

最低でもどれかを artifact に残す:
- `time_to_first_green` — 最初にビルド/テスト/実行が通るまでの時間
- `review_loops` — Codex Review Gate の往復回数
- `isolation_wins` — worktree分離で防げた衝突
- `failure_mode` — まだ残っている失敗モード
- `handoff_artifact` — 次回再開に使うファイル/branch/path

**まだ測れていない改善は、すぐ常設ルール扱いしない。**
作業中の安全策は `coding-agent` に入れ、昇格判断は `agent-runtime-self-improvement` 側でやる。

→ 詳細: [references/measurement-and-isolation.md](references/measurement-and-isolation.md)
→ benchmark候補: [references/benchmark-corpus-shortlist.md](references/benchmark-corpus-shortlist.md)
→ ブラウザ常駐/Chrome拡張型エージェントの導入検証: [references/browser-native-agent-evaluation.md](references/browser-native-agent-evaluation.md)

### 🧪 Benchmark corpus starter
新しい harness / prompt / review flow を比べる時は、**単発 repo 成功談だけで判断しない**。

- まず `references/benchmark-corpus-shortlist.md` から **scenario / hold-out / onboarding** を1本ずつ選ぶ
- artifact に `Benchmark bundle` を残す
- 3本とも見ずに standing rule 化しない
- まず 3 asset で1回回し、足りない時だけ shortlist を広げる

---

## Quick Start

```bash
# ワークスペース内でプロジェクト作成
WORKSPACE_ROOT="<workspace-root>"
mkdir -p "$WORKSPACE_ROOT/projects/my-script" && cd "$WORKSPACE_ROOT/projects/my-script"
git init
[ ! -f CLAUDE.md ] && claude /init

# ワンショット実行
bash pty:true workdir:"$WORKSPACE_ROOT/projects/my-script" command:"codex exec --full-auto 'Your prompt'"
```

---

## CLI Reference

→ 詳細: [references/cli-reference.md](references/cli-reference.md)
Codex, Claude Code, OpenCode, Pi の使い方・フラグ・PR レビュー・並列issue修正パターン。

---

## 🔒 Codex Review Gate（必須）

→ 詳細: [references/review-gate.md](references/review-gate.md)

コーディング完了後、必ずCodexで最終レビュー。LGTM出るまで最大3ループ。

**概要:**
1. 作業完了 → `git diff` 取得
2. 別ディレクトリでCodexレビュー
3. 指摘あり → 修正 → 再レビュー（最大3回）
4. LGTM → 完了

---

## 📖 Codex ベストプラクティス

→ 詳細: [references/codex-best-practices.md](references/codex-best-practices.md)
→ Muser-specific 開発衛生: [references/muser-coding-hygiene.md](references/muser-coding-hygiene.md)

### プロンプト4要素（毎回必須）
1. **Goal** — 何を変更/構築するか
2. **Context** — 関連ファイル、エラー、ドキュメント
3. **Constraints** — 規約、安全要件、制約
4. **Done when** — テスト通過、リンターエラー0、etc.

### Muser追加ルール
- 実装前に **contract（Goal / Non-goals / Done when / Boundaries）** を固定する
- 用語がぶれる / ドメイン理解が薄い / 仕様説明が長くなる時は、先に `CONTEXT.md` や ADR で **shared language** を作ってから実装する
- UI / LP / 管理画面の変更で Figma・口頭仕様・雑なメモしかない時は、**いきなり本実装しない**。先に Storybook / プロトタイプ / 受け入れシナリオへ落として **spec-hole review** を回し、Empty / Loading / Error / 長文 / i18n / 権限差分まで露出させてから実装する
- 変更が大きい時は、いきなり一発実装せず **vertical slice** に切って1スライスずつ進める
- JS/TS は vibe / agent coding 後に `knip` ベースの dead code 掃除を検討する
- ワンショットの守備範囲を超えたら、`dual-agent-dev` / `agent-teams-dev` / `harness-engineering` へ昇格する

---

## 🏗️ Harness Engineering

→ 詳細: [references/harness-engineering.md](references/harness-engineering.md)

### MVH（Minimum Viable Harness）
1. **AGENTS.md** — 50行以下、ポインタのみ
2. **プリコミットフック** — Lefthookでリンター強制
3. **Claude Code Hooks** — PostToolUse: 自動リント / PreToolUse: 設定ファイル保護 / Stop: テスト通過

### Skill配布ルール（運用）
- 作業中のノウハウが **そのrepo限り** ならローカルの `AGENTS.md` / `CLAUDE.md` に留める
- **他repoでも再利用** しそうなら skill 化を検討する
- 配布先が **自分だけ** なら local folder で十分
- **他人に単発送付** するなら `.skill` / ClawHub
- **複数人・継続運用・依存込み再現** が必要なら APM を第一候補にする
- 口頭セットアップが必要な時点で、ただのメモ運用じゃなく APM / packaged skill に寄せる

---

## ⚠️ Rules

1. **Always use pty:true** — coding agents need a terminal
2. **Respect tool choice** — user指定のエージェントを使う。自分で代行しない
3. **Be patient** — 「遅い」で kill しない
4. **--full-auto for building** / vanilla for reviewing
5. **NEVER start in workspace root 直下** — top-level docs を誤読して混乱しやすい。必ず `projects/` サブディレクトリ内で作業
6. **NEVER checkout branches in ~/Projects/agent-runtime/** — LIVE instance

---

## Progress Updates

- 開始時: 1メッセージ（何を・どこで実行中か）
- 変化時のみ更新: マイルストーン完了、質問待ち、エラー、完了
- kill時は即報告+理由

---

## Auto-Notify on Completion

長時間タスクにはwake triggerを付与:
```
... your task here.
When completely finished, emit a runtime-native completion notification if available (example in agent runtime: `agent-runtime system event --text "Done: [summary]" --mode now`). If no event hook exists, report completion directly in chat.
```

---

## 振り返り
- 2026-03-16: Progressive Disclosure適用。本体416→130行。Review Gate・CLI Reference・ベストプラクティスをreferences/に分離
