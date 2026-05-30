# OpenClaw deep security audit exemplar — 2026-05-22

Context: migrated Hermes cron running `openclaw security audit --deep --json` with local delivery, Slack only on critical/warn/failure/actionable findings.

## Observed result
- Audit command: exit `0`, JSON parse OK.
- Summary: `critical=0`, `warn=4`, `info=1`.
- `secretDiagnostics=[]`.
- Warn findings:
  - `gateway.trusted_proxies_missing`: loopback bind with empty `gateway.trustedProxies`; relevant if Control UI is reverse-proxy exposed.
  - `security.trust_model.multi_user_heuristic`: Slack group allowlist + default unsandboxed runtime/fs exposure means OpenClaw is not hostile multi-tenant safe.
  - `plugins.installs_unpinned_npm_specs`: plugin index includes unpinned npm specs (`@openclaw/acpx`, `brave-plugin`, `codex`, `discord`, `slack`).
  - `gateway.probe_failed`: `connect ECONNREFUSED 127.0.0.1:18789`.

## Safe follow-up check
Run read-only status before deciding severity:

```bash
openclaw status --all > reports/security/openclaw-status-all-<ts>.txt 2> reports/security/openclaw-status-all-<ts>.stderr.txt
```

In this exemplar status showed:
- Gateway `unreachable (connect ECONNREFUSED 127.0.0.1:18789)`.
- Gateway service `LaunchAgent installed · not loaded`.
- Last gateway log line: clean shutdown.
- Handover ledger said Hermes owns cron/front and OpenClaw gateway was closed after migration.

Conclusion: the probe warning is likely handover-state, not compromise, but it remains an audit warn so do **not** return `NO_REPLY`.

## Safe repair boundary
Do **not** auto-start OpenClaw gateway or modify these from this cron:
- `gateway.trustedProxies`
- sandbox / workspaceOnly / runtime/fs exposure policy
- plugin npm pinning / OpenClaw plugin index

Reason: each affects handover, exposure, or supply-chain policy and needs explicit operator approval.

## Artifact pattern
Save:
- raw audit JSON
- audit stderr
- audit exit status
- `openclaw status --all` output
- a short triage artifact with conclusion, observed facts, root-cause hypothesis, safe checks, prevention/next action, residual risk

## Slack wording pattern
When warn findings remain, send one concise Japanese top-level post to the scoped target:

```text
OpenClaw deep security audit: critical 0 / warn 4（trustedProxies未設定、multi-user警告、unpinned npm specs、gateway probe失敗）。
修復は未実施：gateway起動・設定変更・pinningはhandover/供給網ポリシーに関わるため要判断。追加確認ではOpenClaw gatewayはnot loaded・clean shutdownで、移管後停止状態の可能性が高いです。
再発防止: triage artifact保存済み `<artifact-path>`
```

Return `[SENT]` only after `send_message` succeeds. If no reportable findings exist, return the job's exact suppression token such as `NO_REPLY`.
