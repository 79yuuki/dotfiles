# Security monitor exemplar: `.aws/config` baseline gap (2026-05-23 12:00 JST)

## Situation
A migrated Hermes security-monitor cron ran the Hermes-canonical scripts:

```bash
zsh /Users/angoya-claw/.hermes/harness-workspace/security/network-monitor.sh
zsh /Users/angoya-claw/.hermes/harness-workspace/security/integrity-check.sh
```

`network-monitor` was clean, but `integrity-check` exited 0 while printing:

```text
CHANGED:/Users/angoya-claw/.aws/config
```

Latest same-day integrity log block showed:

```text
⚠️ File changes detected: /Users/angoya-claw/.aws/config
> /Users/angoya-claw/.aws/config:16c0501fe7d3e84a78dc6d4421e3cc56f4f60e0e6acdbd10fea00091c03a6e0a
```

## Safe triage pattern
- Treat `.aws/config` as secret-adjacent: do **not** read or paste contents during cron triage.
- Collect metadata only:
  - `shasum -a 256 /Users/angoya-claw/.aws/config`
  - `stat -f "%Sp %z %Sm" -t "%Y-%m-%d %H:%M:%S %Z" /Users/angoya-claw/.aws/config`
  - `grep -F '/Users/angoya-claw/.aws/config' /Users/angoya-claw/.hermes/harness-workspace/security/logs/integrity-baseline.txt`
- Known observed metadata: hash `16c0501f...c03a6e0a`, mode `0600`, size `283`, mtime `2026-05-19 15:26 JST`, absent from the active Hermes-canonical baseline.
- Write a dated triage artifact under `/Users/angoya-claw/.hermes/harness-workspace/security/logs/triage-YYYY-MM-DD-HHMM.md` before alerting.

## Reporting rule
This is still reportable under anomaly-only cron rules because it is `⚠️` / `要判断`, even if recurring and even if the script exits 0. Use one concise Japanese fixed-channel Slack alert when scoped by the cron prompt. Phrase it as an unaccepted baseline gap, not confirmed compromise.

## Do not auto-repair
Do not update `integrity-baseline.txt` automatically for this file. Operator must confirm the AWS config legitimacy before accepting the baseline.
