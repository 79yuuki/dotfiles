# Human-attention review contract

Use when an agent creates a change that a person must approve, merge, publish, or act on. Do not treat a large diff or fluent summary as proof.

## Contract

Give the reviewer one compact decision packet:

1. **Decision:** State the decision the reviewer must make and the acceptance criterion it resolves.
2. **Change map:** List the changed behavior, intentional non-changes, assumptions, and possible side effects.
3. **Verification objects:** Attach the smallest falsifiable evidence for each material claim: test result, before/after state, replay, screenshot, query result, or reproducible command.
4. **Exceptions:** Separate failed, unverified, and out-of-scope cases from successful evidence.
5. **Reviewer action:** Name the shortest check that can disprove the claim, plus the owner and escalation path when it cannot be checked.

## Operating rules

- Design agent output around the reviewer’s decision, not an exhaustive narration of the agent’s process.
- Use diffs as change evidence, not as the only quality proof. Prefer behavior-level evidence whenever it exists.
- Keep the packet small enough to inspect; split broad fan-out work into independently reviewable slices.
- Require a fresh-context evaluator for high-impact changes. The evaluator receives the packet and artifacts, not the maker’s conversational rationale.
- Keep the packet in the handoff artifact or review system that the next owner actually reads.

### First-reader rebuild for revised handoffs

When a plan, decision packet, or implementation brief has accumulated several revisions and will be read by a new person or agent:

1. Rebuild the final artifact as if its current design had been chosen from the start.
2. Keep only context needed to evaluate the decision: goal, scope, selected approach, material assumptions, and evidence.
3. Remove conversational residue such as amendment history, obsolete alternatives, and negative rationale that no longer changes the decision. Retain an intentional non-change only when it bounds behavior or verification.
4. If the approach is genuinely unsettled, run a separate alternatives pass before rebuilding; do not make the handoff carry the full exploration history.
5. Verify that a first reader can name the decision, changed behavior, evidence, and next owner action without the originating chat.

## Minimal template

```markdown
## Review packet
- Decision / acceptance criterion:
- Changed behavior:
- Intentional non-changes and assumptions:
- Verification objects:
- Unverified or failed cases:
- Reviewer check / owner / escalation:
```
