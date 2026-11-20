# Claude/Codex skill routing audit

Date: 2026-05-19 (updated 2026-07-07, 2026-10-07)

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

Copied from a private agent-runtime skill library into `claude/skills/` and normalized for generic dotfiles reuse:

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

These were left out because they are too personal, product-specific, account-specific, adult-platform-specific, runtime-specific, or incomplete:

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

## 2026-07-07 re-audit

- The runtime-prefixed security response skill was renamed to `security-response-policy` and rewritten as a generic pre-flight guard (untrusted input, Rule of Two, impersonation, scoped outbound approval). Its account-specific operational references (dated incident logs, channel IDs, runtime cron notes) were deleted; that content belongs in the private runtime, not in reusable dotfiles.
- Remaining personal/org codenames (runtime nicknames, org abbreviations, personal domains, machine-local absolute paths) in `harness-engineering`, `coding-agent`, `skill-creator`, `blogwatcher`, `sales-gtm-os`, `fact-check-gate`, `README.md`, and `codex/AGENTS.md` were generalized.
- Broken relative links fixed: `harness-engineering` → `references/org-operating-patterns.md`, `coding-agent` → `references/coding-hygiene.md`.
- Routing pointers to skills that do not exist in this repo (`dual-agent-dev`, `agent-teams-dev`, `lessons-gate`, `sessions_spawn`, `agent-runtime-self-improvement`) were remapped to existing skills (`codex`, `parallel-orchestrator`, `subagent-driven-development`, `skill-portfolio-evolution`, `verification-before-completion`).
- `blogwatcher` runtime-split notes (installed-copy vs active-copy patching) were removed as runtime-specific; CLI examples normalized to the `blogwatcher-cli` binary name.
- Known validator false positives (not defects): example links inside fenced code blocks in `skill-creator` and `prompt-design`; `[名前](URL)` template placeholders in `geo-seo`; placeholder emails like `name@example.com` in playbooks and tests.

## 2026-10-07 update

- Source: `https://zenn.dev/mizchi/articles/ai-coding-loop-formal` (treated as untrusted data; tips paraphrased, not copied).
- New skill: `formal-methods`, created locally. The `formal-methods-reconciler` skill in mizchi/skills was used as a reference only and was not imported.
- Updated `harness-engineering`: a goal-loop reference (loop drivers, perspective sweep into an umbrella issue, quantified metrics), SKILL.md additions (delegation triage, risk-tiered merge), and `sources.md`.
- Updated `prompt-design`, `codebase-indexing`, `finishing-a-development-branch`, and `orchestrate-with-advisory`.
- Codex parity: `codex/AGENTS.md` now carries short versions of formal-methods, onboarding, loop metrics, risk-tiered merge, and global instruction rules.
- Superpowers vendored skills merged with upstream v6.4.2 (plugin stays at 6.4.1, the latest on the official marketplace; obra marketplace offers 6.3.0); license notice in `THIRD_PARTY_NOTICES.md`.
- `explainer@explainer` installed as a trial plugin (v0.5.2, pinned `578defba7249`, security-scanned).
- `skill-portfolio-evolution` now applies improvements directly to the working tree instead of staging under `claude/_proposed`.
- `codex` skill gained a `codex exec` fallback for non-tmux sessions.
- `codex/config.base.toml` model updated to `gpt-6.1-sol`.
- Goal clarification gate added (harness-engineering goal-loop reference, prompt-design Pattern 11, `codex/AGENTS.md`).

## 2026-11-20 update

- Sources: 19 articles and talks on QA, E2E, formal verification, test quality and human-out-of-the-loop merging, read as untrusted data and paraphrased. Each skill lists its own sources.
- New skills, created locally: `exploratory-qa`, `test-quality`, `merge-gate`.
- Updated: `formal-methods` (project verify skill lifecycle, proof acceptance checks, CI rule), `playwright-e2e` (step convention, failure handling, three-valued results, browser rule), `verification-before-completion` (what counts as evidence), `finishing-a-development-branch` (head SHA in the PR, hand-off to merge-gate).
- Imported from cursor/plugins pstack (MIT): the two formal-verification skills, summarized into `formal-methods/references/project-verify-skill.md`. Notice in `THIRD_PARTY_NOTICES.md`.
- Not imported: the pstack plugin as a whole, per-phase QA skills (test-plan, test-design, test-run, ...), a stronger adversarial-review skill, a decision-record CLI, mizchi's `mutation-test-loop` skill, shokai's `dependency-update` plugin. Their ideas are reflected where they fit.
- Routing boundaries: `test-quality` audits tests after they exist, `test-driven-development` writes the first failing test. `exploratory-qa` explores without a script, `playwright-e2e` writes and repairs specs. `merge-gate` is the verdict by an agent that did not write the change, `verification-before-completion` is the author's own check, `finishing-a-development-branch` picks how to integrate.
- Codex parity: `codex/AGENTS.md` carries short versions of the three new skills and the evidence rule. `claude/CLAUDE.md` gained a four-line entry section.
- `skill-creator` Step 6 names `scripts/skill-security-scan.sh`, which is not in this repository. The new skills were checked with `quick_validate.py` and a manual pattern scan instead.
- Follow-through for staged plans: `scripts/followthrough.py` (daily check, no model), `scripts/install-followthrough.sh` (launchd), `claude/hooks/followthrough-remind.sh` (SessionStart reminder). The hook is not registered in `claude/settings.base.json` yet; registration and the launchd install wait for the owner's approval.
