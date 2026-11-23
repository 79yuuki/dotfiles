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

### 2026-11-20 second pass: outside sources and trials

- Researched primary sources beyond the 19 given articles (official docs, engineering blogs, papers) in six areas and applied only what a source we opened supports. Each skill lists what it took. Facts written as commands (Playwright CLI names, `context.credentials`, Quint and Apalache defaults, GitHub check runs, SessionStart hook sources) were re-checked on the official pages.
- Corrected stale content in `playwright-e2e`: the context-usage percentages had no traceable source and were removed, the CLI session flag and close commands were updated to the current docs, the config template no longer records video for every test.
- Trials on a real repository fed the skills: a mutation run (109 mutants, 25 survivors, classified by hand) produced the StrykerJS recipe and its gotchas; a retro run of the merge-gate verifier on nine merged pull requests produced the merge-gate gotchas. In that run, none of the four pull requests that later needed a follow-up fix got `high` from evidence alone, and three of the five clean ones did.
- Not applied: items backed only by search snippets or vendor claims (review-independence effect sizes, notification-fatigue numbers, a fixed sample-size threshold for enforcing). The tone of the vendored superpowers skills was left as upstream.

## 2026-11-21 update

- New skill, created locally: `ux-walkthrough`. A human and the agent walk the main happy-path flows together in the human's everyday browser, one action at a time, and a ledger (`scripts/flows.py`, flow list in `.github/main-flows.toml`) keeps which flow a human has seen at which content, so that an unseen main flow shows up before release.
- Sources: primary sources on cognitive walkthroughs, severity ratings, dogfooding limits, form and payment screens, and the Claude in Chrome docs, read as untrusted data and paraphrased. The skill and `references/viewpoints.md` list them. Numbers that were read only through a fetch summary were left out.
- Routing boundaries: `exploratory-qa` hunts defects with abnormal inputs and runs QA sheets with a human; `ux-walkthrough` is the happy path, judged by a human for UI/UX, and required before release. `playwright-e2e` success never counts as "seen".
- Trial on a real repository: a draft list of eight flows; over the last 30 days 57 of 97 merges touched at least one flow, so the check belongs right before a release, not on every merge. Recorded in the skill's Gotchas.
- Entry points: `claude/CLAUDE.md`, `codex/AGENTS.md`, `finishing-a-development-branch` (paste the check result into the PR verification section), `exploratory-qa` (routing line).
- `scripts/install-followthrough.sh` gained `hook` / `unhook`, which register the SessionStart reminder in the two settings files with a backup. An agent session could not edit its own hook settings (blocked by the permission classifier), so the user runs it.
- 2026-11-22: `ux-walkthrough` gained a second way to show a flow. When no human operation is needed, the agent records the flow in an isolated browser (`scripts/recorder.mjs`), writes its observations and concrete proposals against named elements, and builds a review page (`scripts/build-review.mjs`, `assets/review-template.html`): video, per-scene screenshots with numbered boxes, a decision per finding, and a result the human pastes back. The record goes on the commit that was recorded (`--rev`), never on whatever HEAD is by then. Tried on a real static demo flow (11 scenes, 10 findings). An Orca-dispatched Codex review could not start (Codex stopped at its hook review prompt, which is the human's to answer), so the review ran through `codex exec`.

## 2026-11-23 update: superpowers removed

- The owner stopped using superpowers (2026-11-22, "superpowersはもう使わないよ"; 2026-11-23, the vendored skills too). Deleted the twelve vendored skills listed in the old `THIRD_PARTY_NOTICES.md` section, the plugin entry in `claude/settings.base.json` and `claude/plugins/manifest.json`, and the license section. The live plugin was disabled with `claude plugin disable superpowers@claude-plugins-official -s user`.
- Rules that other files pointed at were moved, not dropped: the evidence rule and the PR body rules (verification section bound to the head commit, risky-area flag) now live in `claude/CLAUDE.md` and `codex/AGENTS.md`; the review-loop bounds and the reviewer output rules (pre-existing vs introduced, flag the class, cap nits) live in the `codex` skill's gate conditions; single-bug debugging steps and the flaky rule live in `evidence-driven-investigation/references/debug.md`. `manual-review-digest` moved from `requesting-code-review/` to `codex/`.
- Pointers in other skills were rewritten or removed. History files (`reports/`, `docs/superpowers/`, older entries above) keep the old names.
- Fixed while there: `evidence-driven-investigation` had an unquoted description containing `: `, which is invalid YAML; it is now quoted.
