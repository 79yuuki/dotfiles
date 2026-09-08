# State and Data Contracts for Agent Workflows

Use when an agent must resume work, report progress, or make analysis from operational data.

## Core rule

Keep mutable work state outside chat in a declared SSOT. Every nonterminal item needs `state`, `owner`, `next_action`, `blocker`, and `last_verified_evidence`. A resume path may use only fields it actually reads; do not assume a completion comment, chat summary, or archived issue body will be injected.

State changes need a receipt: `item_id / from_state / to_state / evidence / actor / time / next_action`. Prefer a typed transition tool or a bounded hook. If a transition cannot be recorded, leave the item nonterminal and record the update failure; never infer completion from narrative alone.

## Resume and transition gate

1. At start or after compaction, load open/blocked state plus durable decisions from the SSOT.
2. During work, record a state delta at a real boundary: validation finished, work blocked, review requested, or verified completion.
3. Before a terminal state, run the declared verification and attach its evidence to the receipt.
4. On the next resume, reconcile active state with the previous receipt. Escalate a missing, contradictory, or stale receipt instead of guessing.

## Data contract for analysis agents

Keep shared KPI definitions separate from exploratory analysis. For every decision-relevant analysis, record the metric/semantic scope, source and time range, filters, and evidence or query reference.

- Treat ad-hoc cross-domain/raw-data results as provisional; do not silently substitute them for a governed metric.
- Promote a repeated query, derived dataset, or business definition into a reviewed asset with an owner, definition, freshness expectation, access rule, and test/golden query.
- Use golden queries and spot checks before a decision. Preserve competing definitions rather than collapsing them into one unlabeled number.
- Compare local agent speed with organization-wide data debt, processing cost, and maintenance before standardizing a shortcut.

## Design checklist

- Name the state SSOT and the exact fields injected on resume.
- Define legal transitions, terminal-state evidence, and an explicit update-failure state.
- Keep durable decisions in a resume-readable record, not only in a closed-task note.
- State the data scope and provenance for every decision-relevant output.
- Require review before promoting exploratory data or a repeated query into a shared asset.
