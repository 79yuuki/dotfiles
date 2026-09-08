# Goal Loop Evidence-Convergence Contract

Use this for autonomous or long-running work that starts from a broad goal and must converge without treating activity as completion.

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
