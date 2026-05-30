# Slack threaded reporting correction — Fidem ranking monitor

## Session signal

The user corrected a Fidem ranking monitor report that said the detailed text was saved to `reports/fidem-ranking-monitor/latest/summary.md` because “thread unsupported.” The correction was explicit: local files are not readable from Slack, so the detailed report must be posted as a reply to Hermes' own report.

## Reusable rule

For long Slack reports and recurring monitor outputs:

1. Send a 2–3 line parent summary only.
2. Reply to Hermes' own parent with the detailed report body.
3. Do not use another person's existing thread for the detail.
4. Do not replace the thread with a local file path; local artifacts are only backups/source material.
5. If the Slack tool cannot thread, send the full details as the closest visible fallback immediately after the parent and say threading failed/fallback was used.

## Fidem-specific application

For `fidem-ranking-monitor-daily`:

- Parent: `👀` summary with what was updated, the top reason to look today, and “詳細はスレッド”.
- Thread reply: start with `🧵全文`, then paste `latest/summary.md` or the equivalent readable detail.
- Failure: one `⚠️` parent post with 1–2 lines; no long detail unless useful.

## Verification hint

After changing cron/report prompts, verify the cron job still has:

- `deliver: local`
- Slack tool access when manual `send_message` is required
- explicit instruction to use the returned parent message id / thread id for the detail reply
