# CLI Reference — Codex / Claude Code / Pi / OpenCode

## Codex CLI

**Model:** `gpt-5.2-codex` (default in ~/.codex/config.toml)

### Flags

| Flag            | Effect                                             |
| --------------- | -------------------------------------------------- |
| `exec "prompt"` | One-shot execution, exits when done                |
| `--full-auto`   | Sandboxed but auto-approves in workspace           |
| `--yolo`        | NO sandbox, NO approvals (fastest, most dangerous) |

### Building/Creating

```bash
# Quick one-shot
bash pty:true workdir:~/project command:"codex exec --full-auto 'Build a dark mode toggle'"

# Background for longer work
bash pty:true workdir:~/project background:true command:"codex --yolo 'Refactor the auth module'"
```

### Reviewing PRs

**⚠️ Never review PRs in the live agent repo itself!**

```bash
# Clone into workspace for safe review
BASE=$WORKSPACE_ROOT/projects/example-repo
mkdir -p $WORKSPACE_ROOT/projects
git clone https://github.com/user/repo.git "$BASE"
cd "$BASE" && gh pr checkout 130
bash pty:true workdir:"$BASE" command:"codex review --base origin/main"

# Or use a workspace-local git worktree
BASE=$WORKSPACE_ROOT/projects/example-repo
WT=$WORKSPACE_ROOT/projects/_worktrees/example-repo/pr-130-review
mkdir -p "$(dirname "$WT")"
git -C "$BASE" fetch origin
git -C "$BASE" worktree add "$WT" origin/pr/130
bash pty:true workdir:"$WT" command:"codex review --base origin/main"
```

### Batch PR Reviews

```bash
git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'
bash pty:true workdir:~/project background:true command:"codex exec 'Review PR #86. git diff origin/main...origin/pr/86'"
bash pty:true workdir:~/project background:true command:"codex exec 'Review PR #87. git diff origin/main...origin/pr/87'"
process action:list
```

## Claude Code

```bash
bash pty:true workdir:~/project command:"claude 'Your task'"
bash pty:true workdir:~/project background:true command:"claude 'Your task'"
```

## OpenCode

```bash
bash pty:true workdir:~/project command:"opencode run 'Your task'"
```

## Pi Coding Agent

```bash
bash pty:true workdir:~/project command:"pi 'Your task'"
bash pty:true command:"pi -p 'Summarize src/'"
bash pty:true command:"pi --provider openai --model gpt-4o-mini -p 'Your task'"
```

## Parallel Issue Fixing with git worktrees

```bash
BASE=$WORKSPACE_ROOT/projects/example-repo
WT_ROOT=$WORKSPACE_ROOT/projects/_worktrees/example-repo
mkdir -p "$WT_ROOT"
git -C "$BASE" fetch origin

# 1. Create worktrees
git -C "$BASE" worktree add -b fix/issue-78 "$WT_ROOT/issue-78" origin/main
git -C "$BASE" worktree add -b fix/issue-99 "$WT_ROOT/issue-99" origin/main

# 2. Launch agents in parallel
bash pty:true workdir:"$WT_ROOT/issue-78" background:true command:"pnpm install && codex exec --full-auto 'Fix issue #78: <desc>'"
bash pty:true workdir:"$WT_ROOT/issue-99" background:true command:"pnpm install && codex exec --full-auto 'Fix issue #99: <desc>'"

# 3. Create PRs after fixes
cd "$WT_ROOT/issue-78" && git push -u origin fix/issue-78
gh pr create --repo user/repo --head fix/issue-78 --title "fix: ..." --body "..."

# 4. Cleanup
git -C "$BASE" worktree remove "$WT_ROOT/issue-78"
```
