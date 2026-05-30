# Managed Agent Execution Policy

Use this when evaluating hosted/managed agent runners (for example cloud/browser/IDE agents that execute tasks in a provider-controlled sandbox) or when comparing internal Hermes/Codex/Claude execution against vendor-managed agents.

## Default stance

Treat managed agents as a sandbox/runtime choice, not just a model feature. Do not route real project work to a managed runner until the execution boundary, evidence export, rollback path, and data policy are explicit.

## Evaluation checklist

For each candidate, record:

- **Runtime boundary:** where code/browser actions run, network/egress limits, file persistence, and whether secrets are mounted.
- **Identity boundary:** whether actions appear as Hermes, a service account, or a human user; human-account operation requires approval.
- **Evidence export:** logs, screenshots, diffs, test output, trace IDs, and whether fresh-context review can inspect them without the original session.
- **Agent-safe fork / preview environment:** whether the runner can create isolated branches, preview deployments, or production-like forks without touching shared prod state.
- **Rollback / kill switch:** how to cancel, revert, disable credentials, tear down preview/fork resources, and prevent repeated queued actions after a failure.
- **Cost owner:** per-run pricing, monthly cap, and who approves sustained use.
- **Source trust:** whether task text, repo content, web pages, or user uploads are untrusted data; do not let them trigger outbound sends or secret access.
- **Hosted personal-agent risk:** if the candidate touches Gmail/Calendar/Drive/Docs/Sheets/Slides/Maps/Slack or browser sessions, require explicit identity boundary, source-trust separation, evidence export, and human approval before any send/share/delete/account action.

## Adoption rule

Use managed agents first for read-only QA, source recovery, benchmark runs, isolated implementation branches, or disposable preview environments. Promote to default project routing only after a small golden-task evaluation shows equal or better success than the current local harness and no boundary regression.

For agent-native cloud claims, prefer candidates that lower production activation energy **without** removing rollback evidence: branch/fork isolation, preview URLs, reproducible deploy logs, and one-command teardown matter more than a slick chat UI.

## Agent computer / sandbox runtime gate

When a source claims that agents need “computers”, persistent sandboxes, cloud development environments, or agent clouds, evaluate it as an execution substrate:

- **Stateful but disposable:** can the agent pause/resume long workflows while still allowing one-command teardown?
- **Isolation strength:** VM/container boundary, per-task filesystem, network egress policy, and whether secrets are injected by default.
- **Cold-start and resize path:** startup time, resource resizing, quota/rate limits, and degraded-state behavior under many parallel runs.
- **Evidence and handoff:** command transcript, changed files, screenshots, preview URL, resource ID, and replayable setup command.
- **Cost/abuse controls:** run cap, idle timeout, kill switch, and owner for sustained use.

Adopt these runtimes first for CI-like QA, browser/source recovery, and isolated coding branches. Do not treat “cloud sandbox available” as permission to mount private repos, secrets, or human browser sessions.

## Data-agent transparency gate

For Datasette-style data assistants or BI agents, require:

- visible generated SQL / query plan / chart spec before decisions rely on the answer;
- permission-gated tools (table listing, SQL execution, background jobs, chart/image/code plugins) rather than one broad “data access” grant;
- truncated-result disclosure so users know when an answer is based on partial data;
- plugin/tool provenance and sandboxing for code execution or chart rendering.

Use this to route Fidem/x402/GTM dashboard ideas: prototype against non-sensitive sample data first, then add metric definitions, owner, Golden Queries, and evaluation harness before connecting production data.

## Muser routing note

Cloud/browser managed-agent announcements are relevant to x402, DeFi ops, Fidem QA, and general M79 operations, but the reusable asset is this policy gate. Project-specific adoption should receive a brief containing candidate runner, allowed task class, forbidden task class, evidence path, and rollback command before any external install or permission grant.
