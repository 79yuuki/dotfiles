# UX5 → Design → Code → Codex Review Startup Template

Use this for LP, signup pages, product UI, recruiting pages, or quick service prototypes where speed matters but quality must remain reviewable.

## 1. UX5 decomposition
Write one short paragraph or bullet list for each layer before creating pixels or code:
1. Strategy: business goal, audience, primary conversion, non-goals
2. Scope: must-have user tasks and content sections
3. Structure: page flow, IA, hierarchy, decision points
4. Skeleton: wireframe-level section layout and component inventory
5. Surface: visual direction, tone, motion, brand constraints

## 2. Design artifact
Create or update `DESIGN.md` with:
- observed/proposed design language
- keep / rethink / discard
- tokens and key components
- a11y assertions and acceptance checks
- human polish questions

## 3. Code implementation
Give Claude Code / coding agent only the approved UX5 + DESIGN.md artifact, not a vague aesthetic request. Implement one vertical slice first: hero + primary CTA + one proof/benefit section + responsive baseline.

## 4. Codex review
Ask Codex/fresh reviewer to check:
- intent alignment: does the UI serve the primary conversion?
- component structure: reusable names, no over-specific one-off clutter
- accessibility: focus, contrast, target size, reduced motion
- performance: unnecessary JS/images/animation
- polish gaps: what a human should adjust before shipping

## Done criteria
- UX5 notes exist
- DESIGN.md exists and separates design facts from proposals
- first code slice is small and revertible
- fresh review produced concrete fixes or an explicit pass
