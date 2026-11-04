---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- When Codex step review is part of the workflow (a Codex reviewer is available: tmux pane, or `codex exec` if there is no tmux; see the `codex` skill), after each task/commit before proceeding
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or: git merge-base origin/main HEAD
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Codex cross-check (required when Codex step review is part of the workflow; otherwise optional):**

After reviewer subagent approval, use the `codex` skill to send the same commit range plus reviewer verdict to the Codex reviewer (tmux pane, or `codex exec` if there is no tmux). Ask whether the next step can proceed. Codex is an external reviewer and can catch issues the in-session subagent missed.

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Leave Pre-existing issues out of this change (separate PR if worth it)
- Push back if reviewer is wrong (with reasoning)

## Avoiding review loops

The fix→re-review cycle can run away — an agent author and an agent reviewer
keep each other busy (one real case at Anthropic hit 50+ rounds overnight),
and most repeat flags are old code, not new bugs (~59% pre-existing in their
data). Bound it — this is the one place these rules live; the Codex
`✅ APPROVED` loop (`codex` skill, CLAUDE.md, orchestrate-with-advisory §7)
points here:

- **Round cap.** After 3 fix→review rounds on the same change, stop and
  reconsider the approach with your human partner instead of patching further.
  Three rounds that don't converge signal a design problem, not a fixable nit.
- **Diff-only re-review after the first pass.** The first review reads the
  change against the whole repo and intent; later rounds review only the new
  diff since the last round. Re-reading the whole range each time re-surfaces
  pre-existing issues as if they were new.
- **No repeats.** Don't re-raise a finding already posted and answered. If it
  keeps surfacing, it's resolved or it's pre-existing — not a new round.
- **Pre-existing is out of scope.** Fixing old bugs the diff didn't introduce
  belongs in a separate change, not this loop.

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll just review the diff myself instead of dispatching a reviewer" | You're the coordinator — reviewing the diff inline burns the context window you need to keep driving the work. Dispatch a reviewer subagent: the diff and the evaluation live in its context, and only the findings come back to you. |
| "The reviewer needs my whole session history to understand the change" | Hand it precisely crafted context, never your session's history. That keeps the reviewer on the work product, not your thought process. |

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
