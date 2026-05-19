# Shared Browser / WebBridge Policy

Use this before adopting a shared-browser, WebBridge, or agent-visible browser state across Claude, Codex, Hermes, agent runtime, or project agents.

## Default stance

Shared browser state is useful for source recovery, UI QA, and DOM extraction, but dangerous for identity, permissions, and outbound actions. Treat it as a **read-only observation harness** until explicitly approved otherwise.

## Allowed by default

- Open public or already-approved internal pages for inspection.
- Extract page title, URL, visible text, accessibility tree, screenshots, and DOM snippets.
- Use browser state to reproduce UI bugs or verify flows without submitting external forms.
- Save local artifacts: screenshots, QA notes, DOM excerpts.

## Approval-required

- Posting, replying, reacting, editing, deleting, following, liking, voting, or sending messages.
- Submitting forms that change external state.
- Using a browser profile that appears as the user or another human account.
- Granting OAuth permissions, installing extensions, or changing browser security settings.
- Reading sensitive authenticated pages unless the task explicitly requires it and Rule-of-Two is satisfied.

## Profile separation

Keep separate profiles when possible:

| Profile | Purpose | Write/send allowed? |
|---|---|---|
| `read-public` | Public source recovery / DOM extraction | no |
| `qa-sandbox` | Local/dev UI testing | only local/dev state |
| `project-auth-readonly` | Approved project dashboards | no external sends |
| `human-account` | user or human-owned sessions | Hermes does not operate |

## Reporting requirement

When browser extraction is used, record:
- URL and retrieval route (`browser_dom`, `chromium_dom`, screenshot, etc.)
- whether authenticated state was used
- whether any write/send capability was present
- what was not attempted because it would require approval

This lets bookmark/source recovery benefit from shared browser context without collapsing identity and permission boundaries.
