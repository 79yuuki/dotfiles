# Measurement + Worktree Isolation

`WORKSPACE_ROOT` は現在のランタイムが使う共有workspace root（agent runtime workspace / Hermes workspace / 任意の共有workspace）に読み替える。

harness改善を「なんか良さそう」で広げず、**衝突防止** と **軽い計測** を最低限セットで回すための実務メモ。

## 1. workspace-local worktree を標準にする
同じrepoで複数タスク/レビューを並列に走らせる時は、checkoutを使い回さない。

### 基本レイアウト
```bash
$WORKSPACE_ROOT/projects/<repo>/                  # base repo
$WORKSPACE_ROOT/projects/_worktrees/<repo>/<task> # task/review専用worktree
```

### ルール
- **1 task / 1 review / 1 agent = 1 worktree**
- PRレビュー用と実装用の worktree は分ける
- `/tmp` / `mktemp -d` / workspace直下 は使わない
- 依存インストールや生成物は、その worktree の中だけで完結させる
- handoff が必要なら branch名・worktree path・未完了メモを残してから離脱する

### 例: PRレビュー
```bash
BASE=$WORKSPACE_ROOT/projects/example-repo
WT=$WORKSPACE_ROOT/projects/_worktrees/example-repo/pr-130-review
mkdir -p "$(dirname "$WT")"
git -C "$BASE" fetch origin
git -C "$BASE" worktree add "$WT" origin/pr/130
bash pty:true workdir:"$WT" command:"codex review --base origin/main"
```

### 例: 並列 issue 修正
```bash
BASE=$WORKSPACE_ROOT/projects/example-repo
WT_ROOT=$WORKSPACE_ROOT/projects/_worktrees/example-repo
mkdir -p "$WT_ROOT"
git -C "$BASE" fetch origin

git -C "$BASE" worktree add -b fix/issue-78 "$WT_ROOT/issue-78" origin/main
git -C "$BASE" worktree add -b fix/issue-99 "$WT_ROOT/issue-99" origin/main

bash pty:true workdir:"$WT_ROOT/issue-78" background:true command:"pnpm install && codex exec --full-auto 'Fix issue #78: <desc>'"
bash pty:true workdir:"$WT_ROOT/issue-99" background:true command:"pnpm install && codex exec --full-auto 'Fix issue #99: <desc>'"
```

### cleanup
```bash
git -C "$BASE" worktree remove "$WT_ROOT/issue-78"
git -C "$BASE" worktree remove "$WT_ROOT/issue-99"
```

## 2. 計測は lightweight でいい
毎タスクで重い計測は不要。**新しいハーネス変更** や **並列運用のやり方を変えた時** だけ、最低限これを残す。

### 残すと良い指標
- `time_to_first_green` — 最初にテスト/ビルド/実行が通るまでの時間
- `review_loops` — Codex review gate の往復回数
- `isolation_wins` — worktree 分離で防げた衝突や混線
- `failure_mode` — まだ解決できてない失敗モード
- `handoff_artifact` — 次回再開に使うファイル/branch/path

### 最小テンプレ
```markdown
## Harness measurement
- repo: <repo>
- task: <task>
- agent: codex / claude / opencode / pi
- worktree: $WORKSPACE_ROOT/projects/_worktrees/<repo>/<task>
- time_to_first_green: 18m / not reached
- review_loops: 2
- isolation_wins: branch衝突なし、node_modules汚染なし
- failure_mode: initial seed scriptが手動前提
- handoff_artifact: docs/tasks/<task>.md
```

## 3. 昇格の考え方
- `coding-agent` に入れるのは **現場で毎回効く実務ルール**
- `agent-runtime-self-improvement` に残すのは **複数runを見てから昇格させる判断ルール**
- まだ測れていない改善は `hot.md` / `routines.md` に即昇格させない

要するに、**作業中の安全策は coding-agent、常設ルール化の判定は self-improvement 側** で持つ。
