# Anthropic official skill/plugin sources checked (2026-05-12)

- `anthropics/skills` @ `f458cee31a75`
  - Contains Agent Skills spec/template and example skills including `skill-creator`, `webapp-testing`, `claude-api`, document/design skills.
  - Claude Code install route: `/plugin marketplace add anthropics/skills`, then `/plugin install example-skills@anthropic-agent-skills` or `document-skills@anthropic-agent-skills`.
- `anthropics/financial-services` @ `853f755a61f7`
  - Contains financial-services plugins and managed-agent cookbooks. Existing dotfiles manifest already records financial-analysis/equity-research/market-researcher.
- `anthropics/claude-plugins-official` @ `45896c8f2fe6`
  - Contains official Claude Code plugin marketplace entries such as Superpowers/frontend-design.

Portable introduction in this repo is via `claude/plugins/manifest.json` rather than committing local plugin caches.
