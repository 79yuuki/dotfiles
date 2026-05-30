# Model Routing Experiment Policy

Use this before adopting cost/quality routers, new models, IDE agent releases, or agent-system benchmarks such as OpenRouter Pareto Code, Gemini/Claude/Codex upgrades, Cursor/Composer-style agent releases, or `min_coding_score` rules for Codex/Claude delegation.

## Experiment first, default later

Do not change the standing model/router config only because a benchmark looks good. Run a bounded experiment with a small task corpus and hold-out cases.

For frontier “long-reasoning breakthrough” claims (for example low-cost theorem proving, research-agent discoveries, or very long autonomous runs), treat the source as a market signal rather than an adoption trigger. Convert the claim into one reproducible golden task, record cost/wall-clock/evidence artifacts, and keep routing manual until the result is independently repeatable on Muser-relevant work.

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
- system boundary being compared: model-only, IDE-agent, managed runtime, or full agent harness
- success / needs-human-repair / failed
- tool errors and retries
- wall-clock latency
- total cost if available
- test/lint/typecheck evidence
- reviewer verdict
- whether context/security boundaries were respected
- claim reproducibility: source evidence, independent reproduction attempt, and whether the task maps to a real Muser workflow rather than a publicity benchmark

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
