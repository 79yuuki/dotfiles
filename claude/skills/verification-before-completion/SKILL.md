---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| Behavior changed (UI, API, CLI) | Drove the real app on the surface that changed and saw the new behavior | Unit tests pass, build green, "it compiles" |
| PR can merge without a human reading it | Verdict from an agent that did not write it, bound to the head commit (`merge-gate`) | Green CI, approving bot review, your own confidence |

## What Counts as Evidence

Check the real thing. A proxy is not evidence: file timestamps, a self-report, cached output, a green build, or a run on a different surface from the one that changed.

- **Inconclusive is not a pass.** If you could not run the check (missing key, external service down, wrong environment), say "not verified" and why.
- **Do not hand the human a check you could run yourself.** Run it, then report.
- **Say what each check does not tell you.** A run shows the result for the inputs you gave. A test shows the inputs it tries. A type check shows the kinds of values. A proof shows the property as written. Report what you verified and what you did not.
- **When a check passes too easily, suspect the check first.** A regression test that never failed proves nothing.
- **Your own closing summary is not evidence, and neither is another model's opinion of it.** A confident final message says nothing about the final state. Re-run the command and read its exit code; check each claim in your report (tests pass, file created, endpoint returns X) against the real thing before you send it.
- **If you changed a test, an expected value or a fixture to get to green, say so first.** Put that diff at the top of the report. When the spec and a test disagree, do not edit one to match the other: stop and ask.
- **After three failed fix rounds on the same check, stop and bring in a human.**

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## When To Apply

**Where to go for more than a command:** `test-quality` when you doubt the tests would catch a break, `exploratory-qa` or `playwright-e2e` to drive a running app, `formal-methods` for ordering and state-space properties, `merge-gate` for the merge verdict.

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness
