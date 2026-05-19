# Browser-Native Agent Evaluation Policy

Use this before adopting or routing work into a browser-native coding/QA agent such as a Codex Chrome integration.

## Default stance

Treat browser-native agents as **evaluation candidates**, not trusted replacements for the existing terminal/browser/Playwright workflow, until safety and usefulness are verified.

Do not install extensions, grant permissions, or connect accounts during an autonomous run without explicit approval.

## Pre-install checklist

```markdown
# Browser-native agent safety check

## Scope
- Tool / extension name:
- Source / vendor:
- Intended use: QA / research / browser automation / coding / other
- Accounts or browser profiles touched:

## Permission review
- Requested browser permissions:
- Can it read page contents?
- Can it act on authenticated sites?
- Can it access cookies, localStorage, downloads, clipboard, files, or native messaging?
- Can permissions be limited to specific sites/profiles?

## Data flow
- What data may leave the browser?
- Does it send screenshots, DOM text, prompts, code, cookies, or account context?
- Is retention/training configurable?
- Are there logs/artifacts for review?

## user impersonation / account risk
- Could actions appear as the user or an account owned by user?
- Could it post, reply, react, edit, delete, buy, approve, or submit forms?
- Is read-only mode possible for first evaluation?

## Sandbox / isolation
- Use a non-personal browser profile when possible.
- Start with test sites / local apps / disposable accounts.
- Keep existing Playwright/browser QA as baseline until comparison is complete.

## Decision
- Approve for read-only trial / limited trial / reject / needs user approval
- Reason:
```

## Evaluation workflow

1. **Do not replace baseline.** Run the same task with the existing browser or Playwright flow.
2. **Use one narrow scenario first.** Example: inspect a local UI and produce an accessibility/QA note.
3. **Record artifacts.** Capture what it could read, what it changed, logs/screenshots, and time-to-useful-result.
4. **Check side effects.** Confirm no posts, reactions, purchases, form submissions, account changes, or persistent browser changes happened.
5. **Compare.** Adopt only if it improves speed, coverage, or reliability without widening permissions beyond the value gained.

## Routing rule

- Use `browser-operation` / Playwright for current production QA and authenticated browsing.
- Use browser-native agents only after a documented safety check and small evaluation artifact.
- If the tool needs broad authenticated browser access, external extension install, third-party account linking, paid plan, or any action that may appear as user, mark blocked and ask for scoped approval.

## Artifact template

```markdown
# Browser-Native Agent Evaluation — [tool] — [date]

## Verdict
- Status: read-only trial approved / limited trial approved / blocked / rejected
- Why:

## Scenario
- Target site/app:
- Baseline workflow:
- Browser-native workflow:

## Observed value
- Speed:
- Coverage:
- Reliability:
- Parallel/background benefit:

## Safety findings
- Permissions:
- Data leaving browser:
- Authenticated account exposure:
- Side effects observed:

## Next action
- ___
```
