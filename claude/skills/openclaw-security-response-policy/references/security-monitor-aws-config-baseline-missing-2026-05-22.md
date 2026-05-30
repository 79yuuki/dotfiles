# Security monitor AWS config baseline-missing recurrence — 2026-05-22

Context: migrated OpenClaw security monitor cron running from Hermes canonical workspace.

## Observed pattern
- `network-monitor.sh` clean: no suspicious connections; listening ports matched baseline.
- `integrity-check.sh` exited 0 but printed `CHANGED:/Users/angoya-claw/.aws/config` and appended `⚠️ File changes detected`.
- `.aws/config` was present in `integrity-current.txt` but absent from the accepted baseline, so this is a baseline-missing monitored-file appearance, not necessarily a hash drift.

## Metadata-only triage result
Do not read or paste the config contents unless explicitly necessary. The safe metadata observed on 2026-05-22:

- path: `/Users/angoya-claw/.aws/config`
- sha256: `16c0501fe7d3e84a78dc6d4421e3cc56f4f60e0e6acdbd10fea00091c03a6e0a`
- mode: `0600`
- size: `283`
- mtime: `2026-05-19 15:26:21 JST`
- recurrence: same hash observed in repeated integrity logs since 2026-05-19; no fresh additional drift during the 2026-05-22 12:00 run.

## Future handling
- Classify as `要判断` until an operator confirms the AWS config is legitimate and accepts the baseline.
- Do not auto-update `integrity-baseline.txt`, delete the file, or dump file contents in Slack.
- Save a concise triage artifact and send a short anomaly report only because the job’s rule says `⚠️ / 改ざん / 監視失敗 / 要対応` triggers Slack.
