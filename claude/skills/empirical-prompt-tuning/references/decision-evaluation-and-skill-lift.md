# Decision evaluation and skill-lift comparison

Use this when a skill, prompt, model, or context change is being considered for an operational workflow.

## Decision-oriented evaluation card

Before measuring a candidate, write:

1. The user/product decision that the evaluation must support.
2. One primary outcome that represents the intended benefit.
3. Safety constraints that must remain inside a predefined range.
4. Operational guardrails: latency, cost, reliability, and integration/review burden as applicable.
5. A repeatable baseline: prompt/instruction version, model version, fixture/dataset version, system configuration, and run ID.

Change one major variable at a time. Re-run the same evaluation after material changes to the prompt, model, context construction, or surrounding logic. Preserve a rollback-capable prior configuration.

## Skill-lift experiment

For a high-frequency skill candidate, do not infer usefulness from a structural or security scan. Keep safety scanning mandatory, then compare a fixed no-secret fixture under identical conditions:

- control: no target skill (or the prior skill version)
- candidate: the target skill/reference available
- fixed checklist including at least one critical requirement
- predefined success, accuracy, efficiency, ambiguity, discretionary-fill, and retry observations
- one hold-out that remains untouched until the candidate looks promising

A positive result supports the fixture-specific decision; it does not establish a universal performance claim. A skipped blank-executor evaluation remains skipped rather than being replaced by author self-review.
