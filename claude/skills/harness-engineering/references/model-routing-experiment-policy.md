# Model Routing Experiment Policy

Use this before adopting cost/quality routers such as OpenRouter Pareto Code or `min_coding_score` rules for Codex/Claude delegation.

## Experiment first, default later

Do not change the standing model/router config only because a benchmark looks good. Run a bounded experiment with a small task corpus and hold-out cases.

## Minimal evaluation set

Include 5-10 real Muser tasks:
- simple edit / mechanical refactor
- medium feature with tests
- debugging from logs
- UI/LP quality pass
- security-sensitive review
- long-context artifact synthesis
- one hold-out task that should **not** go to the cheap router

## Metrics

Record:
- success / needs-human-repair / failed
- tool errors and retries
- wall-clock latency
- total cost if available
- test/lint/typecheck evidence
- reviewer verdict
- whether context/security boundaries were respected

## Routing rule template

```md
# Model router experiment

- candidate router/model:
- baseline:
- min_coding_score or equivalent threshold:
- task classes allowed:
- task classes excluded:
- evaluation corpus path:
- success threshold:
- rollback condition:
- decision date:
```

Promote only if it is a Pareto improvement for the intended task class: same or better success with lower cost/latency, or materially better success with acceptable cost. If quality falls on hold-out/security cases, keep it as manual opt-in.
