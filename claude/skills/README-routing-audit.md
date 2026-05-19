# Claude/Codex skill routing audit

Date: 2026-05-19

## Sources checked

- Claude Code skills docs: `https://docs.anthropic.com/en/docs/claude-code/skills.md`
- Claude Code settings/memory docs for skill visibility and AGENTS/CLAUDE.md behavior
- OpenAI Codex docs for AGENTS.md/customization and the open Agent Skills direction
- Agent Skills open standard: `https://agentskills.io/specification.md`

## Routing rules applied

1. Put reusable Claude Code workflows under `claude/skills/<skill>/SKILL.md`; `install.sh` symlinks this directory to `~/.claude/skills`.
2. Keep frontmatter `description` short and trigger-rich. Claude Code always lists descriptions; `description + when_to_use` is truncated around 1536 characters.
3. Use `disable-model-invocation: true` only for side-effectful manual workflows. Skills intended to fire naturally should not set it.
4. Keep `SKILL.md` concise; move long references, examples, and scripts into supporting files and reference them from the body.
5. Codex CLI does not automatically apply Claude Code skills, so durable cross-agent rules are summarized in `codex/AGENTS.md` instead of copying full skill bodies there.
6. Project/account-specific or sensitive operational skills were excluded or generalized before copying.

## Copied / upgraded skills

Copied from the Hermes/OpenClaw-trained skill library into `claude/skills/` and normalized for generic dotfiles reuse:

- `agent-friendly-publishing`
- `clarity-gate`
- `codebase-indexing`
- `coding-agent`
- `component-gallery`
- `crypto-counterparty-security`
- `empirical-prompt-tuning`
- `fact-check-gate`
- `geo-seo`
- `gtm-content-ops`
- `harness-engineering`
- `marketing-skills`
- `pentest`
- `playwright-e2e`
- `project-account-architecture`
- `prompt-design`
- `public-site-stack-decision`
- `sales-gtm-os`
- `skill-creator`
- `slide-deck`
- `smart-contract-audit`
- `trust-privacy-pack`
- `ui-accessibility-design`
- `ui-design-system`
- `unit-economics-gate`
- `winning-proposal`

## Intentionally not copied as-is

These were left out because they are too personal, product-specific, account-specific, adult-platform-specific, OpenClaw-runtime-specific, or incomplete:

- account-specific social posting skills
- bookmark-to-task personal interpretation skills
- personal prioritization/advisor skills
- logged-in browser operation skills
- internal batch-ops skills
- incomplete template skills
- adult-platform/ranking monitor skills
- product-specific marketing harness and pitch skills
- runtime-specific self-improvement/monitoring skills

If any excluded skill becomes needed in dotfiles, first rewrite it as a generic public/private-safe skill and remove account names, channel IDs, product strategy, and operational logs.

## Dotfiles-side changes

- `README.md` now documents Claude skill auto-discovery, frontmatter constraints, and the full skill inventory.
- `codex/AGENTS.md` now mirrors the important routing/gate behavior for Codex CLI: prompt design, empirical prompt tuning, harness engineering, Playwright verification, codebase indexing, fact-checking, clarity, UI/slides/security, and GTM decision gates.
- Copied skill descriptions were normalized to be concise and natural-invocation friendly.
- Obvious local/private identifiers in copied skills were scrubbed or generalized.
