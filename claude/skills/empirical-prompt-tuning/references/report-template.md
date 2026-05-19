# Empirical Prompt Tuning Report Template

```md
# Empirical Prompt Tuning — <target>

- date: YYYY-MM-DD
- target: <skill/prompt>
- iteration: N
- status: doing | converged | skipped | rewrite-needed

## Scenario set
- S1: <median case>
- S2: <edge case>
- Hold-out: <withheld boundary case>

## Checklist
1. [critical] <item>
2. <item>
3. <item>
4. <item>

## Change in this iteration
- <what changed>

## Results
| Scenario | success | accuracy | efficiency note | retries |
|---|---|---|---|---|
| S1 | ○ | 100% | <note> | 0 |
| S2 | × | 50% | <note> | 1 |

## New ambiguities
- <scenario>: <ambiguity>

## Discretionary fills
- <scenario>: <fill>

## Metrics
- tool_uses: <count or unavailable>
- duration_ms: <value or unavailable>

## Decision
- <keep iterating / converged / rewrite structure>

## Next action
- <smallest next change>
```

## latest.json suggested shape

```json
{
  "target": "skill-creator",
  "date": "YYYY-MM-DD",
  "iteration": 1,
  "status": "doing",
  "scenarios": ["median case", "edge case"],
  "holdOut": "boundary case",
  "success": {"S1": true, "S2": false},
  "accuracy": {"S1": 1.0, "S2": 0.5},
  "toolUses": "unavailable",
  "durationMs": "unavailable",
  "newAmbiguities": ["..."],
  "discretionaryFills": ["..."],
  "nextAction": "..."
}
```
