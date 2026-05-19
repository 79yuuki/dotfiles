# DESIGN.md Starter

Copy this into a repo-level `DESIGN.md` when you want a reusable design artifact before implementation.

## Why this version exists

Use this starter when the goal is not just "capture vibes" but to leave an artifact that:
- separates **observed** from **proposed**
- makes **keep / rethink / discard** explicit
- carries **a11y assertions** forward into implementation and QA
- defines **acceptance checks** so the next agent knows what done looks like

---

```md
# DESIGN.md

## 1. Source
- source type: [existing product / reference site / screenshot / codebase]
- source links: [...]
- screens reviewed: [...]
- why this source matters: [...]
- target audience: [...]

## 2. Product intent
- job to be done: [...]
- primary user action: [...]
- primary CTA: [...]
- emotional tone: [...]
- constraints: [brand / legal / device / accessibility / engineering]

## 3. Observed design language

### Layout
- information hierarchy: [...]
- section order: [...]
- grid / container logic: [...]
- navigation pattern: [...]

### Visual system
- color roles: [...]
- surface layering: [...]
- contrast character: [...]
- typography feel: [...]
- spacing / density: [...]

### Components
- repeated patterns: [...]
- hero / header pattern: [...]
- card / table / form pattern: [...]
- CTA treatment: [...]
- trust / proof elements: [...]

### Interaction
- hover / active / focus behavior: [...]
- motion / transitions: [...]
- error / success feedback: [...]
- empty / loading / disabled states: [...]

## 4. Keep / Rethink / Discard

### Keep
- [...]

### Rethink
- [...]

### Discard
- [...]

## 5. Proposed direction
- translation rule: [what to borrow vs what to change]
- design principles for this project: [...]
- token direction: [color / type / radius / shadow / spacing]
- component priorities: [...]
- content priorities: [...]

## 6. Accessibility assertions
- text contrast target: [AAA 7:1 by default, or justified exception]
- focus visibility: [what must always stay visible]
- target sizes: [44x44 minimum for touch / click]
- keyboard flow: [critical paths that must be keyboard-complete]
- screen reader expectations: [landmarks / labels / error messages]
- motion policy: [reduced motion fallback]
- form clarity: [required fields / validation / recovery]

## 7. Acceptance checks
- [ ] Primary CTA is visible without hunting
- [ ] Heading hierarchy matches information hierarchy
- [ ] Key screens preserve agreed keep-items from section 4
- [ ] Rethink items are resolved, not silently copied over
- [ ] All interactive elements have visible focus states
- [ ] Contrast on body text and CTA text meets target
- [ ] Error / loading / empty states are designed, not omitted
- [ ] Mobile and desktop layouts preserve the same intent
- [ ] Implementation can map tokens/components back to this artifact

## 8. Open questions
- [...]

## 9. Human review points
- what still needs taste judgment: [...]
- what should be user-tested: [...]
- what engineering should challenge early: [...]
```

---

## How to use it

1. Fill **Source / Product intent / Observed** first
2. Do **not** fill `Proposed direction` until the observations feel stable
3. Use `Keep / Rethink / Discard` before asking an agent to redesign
4. Carry `Accessibility assertions` into implementation and QA
5. Treat `Acceptance checks` as the minimum bar for review or dogfooding

## Good default prompt

```md
Read this DESIGN.md starter and fill it from the provided screens/code.

Rules:
- keep observed vs proposed separate
- do not redesign during the observation pass
- make keep / rethink / discard explicit
- add accessibility assertions that can be checked later
- write acceptance checks that an implementer or reviewer can verify
```
