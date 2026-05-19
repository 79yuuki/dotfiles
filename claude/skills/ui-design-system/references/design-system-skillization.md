# Design System Skillization Checklist

Use this when turning a one-off `DESIGN.md`, UI audit, or visual direction into a reusable design skill / template for future agents.

## Output shape

Create three artifacts instead of one huge prompt:

1. **Token CSS** — `tokens.css` / `globals.css` with semantic variables only.
2. **Prohibitions** — `prohibitions.md` with explicit “do not do” rules that preserve the design language.
3. **Human polish checklist** — `human-checklist.md` for final judgment that should not be delegated blindly.

## 1. Token CSS split

Keep tokens machine-usable and small enough for agents to reuse without rereading the whole design doc.

Minimum sections:
- color: background, foreground, surface, border, brand, semantic states
- typography: font families, scale, line-height, tracking
- spacing: 4px or 8px grid, container widths, section rhythm
- radius / shadow / elevation
- motion: duration, easing, reduced-motion fallback

Rules:
- Use semantic names (`--surface-raised`, `--text-muted`) rather than visual adjectives only (`--nice-gray`).
- Keep brand tokens separate from component tokens when possible.
- If using Tailwind/shadcn, update both CSS variables and `tailwind.config` mappings.
- Add acceptance checks for contrast, responsive breakpoints, and focus states.

## 2. Prohibitions file

`prohibitions.md` should prevent regression into generic AI UI.

Include:
- banned visual motifs: overused gradients, random glassmorphism, noisy shadows, mismatched icon styles
- spacing mistakes: cramped cards, inconsistent section rhythm, off-grid values
- typography mistakes: too many weights/sizes, unreadable Japanese fallback, low line-height
- interaction mistakes: invisible focus, motion without `prefers-reduced-motion`, hover-only affordances
- brand mistakes: colors not in token set, unsupported illustration style, inconsistent tone

Template:

```md
# Design Prohibitions

## Never use
- [...]

## Avoid unless explicitly justified
- [...]

## If tempted, use this instead
| Temptation | Replacement |
|---|---|
| generic blue gradient | brand primary + neutral surface |
```

## 3. Human polish checklist

Use this for the final pass before shipping or handing to a client.

Checklist:
- [ ] Can a human name the design language in one sentence?
- [ ] Does the UI still work in grayscale / dark mode / mobile?
- [ ] Are primary actions obvious without relying on color alone?
- [ ] Are Japanese and English text both visually balanced?
- [ ] Does every repeated component use the same token + variant path?
- [ ] Did a human inspect at least one real page/screenshot, not just code?
- [ ] Are any intentional deviations documented in `DESIGN.md`?

## When to create a reusable skill

Promote to a project skill/template when at least two are true:
- the same visual language will be reused across multiple pages/products
- multiple agents will implement UI from the same design direction
- generic AI UI regressions have already appeared once
- brand consistency matters for trust, sales, hiring, or investor-facing material

Do not create a new skill when a single `DESIGN.md` is enough. Prefer a reference file inside `ui-design-system` until the pattern repeats.
