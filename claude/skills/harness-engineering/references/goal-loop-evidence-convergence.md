# Goal Loop Evidence-Convergence Contract

Use this for autonomous or long-running work that starts from a broad goal and must converge without treating activity as completion.

## Goal clarification gate

- Before starting `/goal`, a headless loop, or a long autonomous run, check that the goal has: a completion condition the loop can prove with printed evidence, scope (in / out), priority and trade-offs between metrics, a stop condition or turn cap, and which actions need human approval.
- Resolve what you can from the repo, issues, docs, and tools first, and fill conventional defaults.
- If something that changes the outcome is still ambiguous, do not start the loop on a guess. Ask the user once, as a single question: show a concrete draft goal condition in which each open decision (at most three) is already filled with your recommended option and marked as provisional, and ask whether to proceed with this draft. The user approves it or edits only what they want to change.
- If ambiguity appears mid-loop (conflicting criteria, an item whose pass criterion cannot be decided), mark that item `needs owner decision` and ask instead of inventing a criterion; keep working on independent items.
- Record the confirmed goal in the umbrella issue or progress artifact, and reuse it verbatim as the `/goal` condition.

## Required loop state

1. Create a durable, canonical work inventory. Give each unit an expected behavior and pass criterion; do not keep the only plan in chat.
2. Test every inventory unit before broad polish. Record evidence per unit, not a single overall impression.
3. Triage findings into `fix now`, `needs owner decision`, and `out of scope`; preserve the reason for every deferred unit.
4. Implement only the approved/fix-now set, then rerun the affected checks plus regression checks against the inventory.
5. End with a handoff containing remaining units, evidence links, stop reason, and the next safe action.

## Preview boundary

A preview can lower review latency, but it is not an authorization to publish. Use an isolated branch or access-controlled preview; do not expose private repositories, credentials, customer data, or production integrations. Verify desktop and mobile/alternative states with reproducible checks before calling a user-facing flow complete.

## Completion test

`done` requires inventory coverage + evidence + resolved-or-owned exceptions + regression check. A progress log or a green happy-path test alone is not completion.

## Loop drivers

- Headless loop (Ralph loop): run `claude -p` in a shell `while` loop and have each iteration pick the next single item from git history or the work inventory. Use it only with an isolated branch/worktree, a max iteration count and cost cap, a stop when the inventory is empty or N iterations show no progress (no new commit and no metric change), and a per-iteration log.
- Claude Code `/goal <condition>` (https://code.claude.com/docs/en/goal): at the end of each turn a small fast model judges the condition and starts the next turn automatically if unmet. The judge runs no tools and sees only what appeared in the conversation, so write the condition in terms of evidence the agent prints (test summary line, metric value, remaining inventory count) and include a turn cap (e.g. `or stop after 20 turns`). The judge may count reaching the cap as the condition being met, so a stop at the cap is not completion: audit the inventory and report the remaining items as unfinished. `/goal` alone shows status; `/goal clear` stops it. Codex CLI has its own `/goal` (see prompt-design Pattern 11).
- Stop-hook continuation: for project-specific continuation checks, use a prompt-based Stop hook. Treat adding a hook as a change that needs manual approval (see skill-portfolio-evolution).
- Whatever the driver, satisfy Required loop state and Completion test above. A loop is not a substitute for the completion check.

## Inventory sourcing: perspective sweep → umbrella issue

- Give the exploration explicit perspectives (whose metric matters, and which one). Examples: comparison with recent research and prior implementations, telemetry gaps from an SRE view, refactoring that keeps tests green, N+1 query detection, security checks limited to localhost or authorized targets (see pentest skill).
- Collect candidates into one umbrella issue as a checklist (one item = one pass criterion). That issue is the canonical work inventory and the loop works through it top-down. Do not let the loop pick work from ideas that only exist in chat.

## Quantified loop metrics

- Prefer metrics that can be judged deterministically with numbers, so no human is needed per iteration. Turn subjective criteria into a numeric rubric scored by a separate evaluator, or into an explicit human checkpoint in the inventory.
- Metric menu (choose only those relevant to the goal; set direction, threshold, and priority):

| Metric | Tooling examples | Note |
| --- | --- | --- |
| Performance | Deterministic counters such as instruction count or fuel in CI; hyperfine / perf / valgrind locally | Wall-clock in CI is noisy |
| Memory | peak RSS, valgrind massif, heaptrack | RSS is not deterministic: fix the environment, repeat runs, and use a tolerance band |
| Lint warnings | Warning count under strict rules including cyclomatic complexity (complexity tool example in sources.md) | Ratchet: do not increase |
| Duplication | Code-similarity detection (example in sources.md) | |
| Mutation kill rate | Stryker, mutmut, cargo-mutants | Measures test strength, not coverage |
| VRT match rate | Playwright screenshot comparison (playwright-e2e skill) | |

- Ratchet: record a baseline and, while improving the target metric, do not worsen the other protected metrics. A human decides the trade-off priority up front.
- CI time budget: more metrics lengthen CI. Split into a fast per-PR tier and a heavier nightly tier; a human decides the priorities.
