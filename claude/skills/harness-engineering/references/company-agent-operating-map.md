# Company Brain / Orchestrator / Worker / Routine Template

Use this to describe a lightweight agent-operated company or project OS without duplicating whole prompts across agents.

```md
# [Company / Project] Agent Operating Map

## 1. Company Brain
- Source of truth: [repo/docs/memory/project board]
- Stable context: [mission, user profile, product facts, security rules]
- Update rule: [who/what may edit; how changes are reviewed]
- Do not duplicate into workers: [list]

## 2. Orchestrator
- Responsibilities: triage, routing, prioritization, synthesis, exception handling
- Inputs: [inbox, project board, cron artifacts, team chat mentions]
- Outputs: [task brief, artifact, project update, approval request]
- Decision gates: [external send, spending, permissions, irreversible action]

## 3. Workers
| Worker/profile | Owns | Receives | Must return |
|---|---|---|---|
| default/general | triage / bookmark / routing | raw signals | artifact + target profile |
| project ops | scoped implementation | issue/doc/brief | diff/test/artifact |
| evaluator | review / QA | outputs + evidence only | pass/fail + fixes |

## 4. Routines
| Routine | Cadence | Checks | Writes | Escalates when |
|---|---|---|---|---|
| heartbeat | 2-4/day | mail/calendar/mentions/weather | daily log | anomaly / deadline |
| bookmark insight | daily | new Raindrop items | self-improvement artifacts | landed/blocked changes |
| project monitor | per project | status/blockers | tasks/project board | stale/high-risk |

## 5. Feedback loops
- Failure log → skill/template/hook update target: [...]
- Bookmark insight → reusable asset target: [...]
- QA finding → deterministic check or reviewer prompt: [...]
- Customer/user signal → GTM/product decision trace: [...]

## 6. Permission boundaries
- Read-only by default: [...]
- Draft-only: [...]
- Human approval required: [...]
- Never automated: [...]
```

Design principle: Company Brain is shared context, Orchestrator is judgment/routing, Workers are scoped execution, Routines are scheduled sensing. If a rule appears in all four layers, extract it into a skill/reference instead of copying it.
