# Coding-Agent Source Ingestion Pattern

Use this when public articles/news about coding agents, agent harnesses, IDE agents, browser agents, Claude Code/Codex, or evaluation tooling should become reusable Muser operating knowledge.

## Why this exists

Raindrop bookmarks show user's explicit interest, but the coding-agent field moves fast. Hermes should also watch public sources and convert useful patterns into small, reversible skill updates instead of waiting for manual bookmarking.

## Source classes

1. **User intent sources** — user Raindrop bookmarks. Highest priority; interpret as direction of interest.
2. **Public coding-agent sources** — `blogwatcher` feeds prefixed `CA-` and bounded web search. Use for market/source discovery.
3. **Implementation evidence** — local traces, failed runs, test/lint/security results. Required before making strong standing rules.

## Triage ladder

For each source item:

1. **Read enough content** — RSS summary is acceptable for low-risk routing; use article/body fetch for landed rules.
2. **Classify the pattern**:
   - harness primitive: context, tools, evaluator, runner, state, permissions;
   - workflow primitive: plan/build/verify/review/ship/learn;
   - safety primitive: sandbox, approval, rollback, source provenance;
   - skill primitive: routing, checklist, reference, template, pitfall.
3. **Choose the smallest durable asset**:
   - one bullet in an existing skill;
   - compact reference under `references/`;
   - checklist/template;
   - cron/reporting rule;
   - new skill only when no existing skill fits.
4. **Land rough if safe** — if the change is internal, reversible, and security-scannable, prefer a small landed update over leaving everything queued.
5. **Escalate to eval** — if the item proposes changing core harness behavior, model routing, or agent autonomy, convert it into scenario/hold-out/evaluation first.

## Rough landed update standard

A rough update is acceptable when it has:

- source title/URL/date in the artifact or reference;
- a narrow target path;
- no external install or permission grant;
- rollback path via git diff/commit or simple file revert;
- `skill-security-scan` CRITICAL/HIGH 0 when skills changed.

It does **not** need a full benchmark if it only adds a routing/checklist/pitfall note. It **does** need evidence/eval before changing default autonomy, permissions, model routing, or external tool installation.

## Report shape

In Bookmark → Skill Evolution reports, public coding-agent discoveries belong in:

`🌐 Public coding-agent source watch`

Include only:

- 1–3 useful items;
- why it matters to Muser;
- landed/queued/blocked status;
- target skill/reference path if landed.

Do not flood the daily report with every feed item.
