# Migrated OpenClaw deep security audit cron

Use for migrated cron jobs that run `openclaw security audit --deep --json` and report only on actionable security audit findings.

## Procedure
1. Confirm Hermes owns migrated cron execution via the handover ledger before acting on OpenClaw-adjacent state.
2. Run the audit exactly as requested and capture stdout/stderr plus exit status to timestamped artifacts under `/Users/angoya-claw/.hermes/harness-workspace/reports/security/`.
   - In unattended cron, prefer Python/subprocess capture or `write_file` for artifact text rather than shell-embedded prose, especially when Japanese text would trigger the terminal confusable-text guard. Keep raw JSON/stderr/meta as separate files.
3. Parse the JSON. Treat these as reportable: command non-zero, JSON parse failure, `summary.critical > 0`, `summary.warn > 0`, `secretDiagnostics` with actionable entries, or any audit failure field.
4. If `gateway.probe_failed` says `connect ECONNREFUSED 127.0.0.1:18789`, run `openclaw status --all` read-only before deciding severity. After handover, an unreachable OpenClaw gateway can be an expected state when OpenClaw Slack/cron are disabled and Hermes is primary. Evidence such as `Gateway service ... not loaded` and a clean shutdown log supports classifying it as handover-state warning rather than compromise.
5. Do not auto-start OpenClaw gateway, change `gateway.trustedProxies`, or pin/update plugins unless the prompt explicitly authorizes that scope. These affect handover, exposure, or supply-chain policy.
6. When warnings remain, write a short triage artifact with: conclusion, observed facts, safe checks run, prevention/next action, and residual risk. Then follow the cron's report rule; do not silently suppress warnings merely because they are recurring or expected.

## Known finding classes
- `gateway.trusted_proxies_missing`: if gateway bind is loopback, actionable mainly when Control UI is reverse-proxy exposed. Do not set automatically.
- `security.trust_model.multi_user_heuristic`: review sandbox / workspaceOnly / credential separation if mutually untrusted users share one runtime.
- `plugins.installs_unpinned_npm_specs`: supply-chain stability issue; pin only through the OpenClaw plugin/update policy.
- `gateway.probe_failed`: verify with `openclaw status --all`; in post-handover state it may simply confirm OpenClaw gateway is stopped.

## Delivery
- If the audit is fully clean, return the job's exact suppression token (`NO_REPLY` when specified).
- If critical/warn/failure/actionable items exist, send one concise Japanese Slack alert to the scoped target if the wrapper authorizes it, then return the requested sent sentinel such as `[SENT]`.
- Keep raw JSON/logs in local artifacts; Slack should summarize conclusion → repair/safe check → prevention/next action → residual risk in 2–6 lines.
