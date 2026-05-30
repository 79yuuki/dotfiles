# Migrated OpenClaw security monitor cron

Use for cron prompts that run OpenClaw security scripts from Hermes.

## Procedure
1. Confirm Hermes owns migrated cron execution via the handover ledger before running OpenClaw workspace scripts.
2. Run both scripts exactly as requested, capturing exit status. For Hermes-migrated security jobs, prefer the Hermes-canonical root when present:
   - `zsh /Users/angoya-claw/.hermes/harness-workspace/security/network-monitor.sh`
   - `zsh /Users/angoya-claw/.hermes/harness-workspace/security/integrity-check.sh`
   Use `/Users/angoya-claw/.openclaw/workspace/security/...` only as a fallback when the Hermes-canonical scripts are absent or the live prompt explicitly targets OpenClaw.
3. Inspect the latest files under the matching `security/logs/` directory, especially same-day `network-YYYY-MM-DD.log` and `integrity-YYYY-MM-DD.log`. Same-day logs append multiple runs; identify the newest `=== ... ===` block after running the scripts and base the alert on that block, while using earlier blocks only to classify recurrence.
3. Inspect the latest files under the matching `security/logs/` directory, especially same-day `network-YYYY-MM-DD.log` and `integrity-YYYY-MM-DD.log`. Same-day logs append multiple runs; identify the newest `=== ... ===` block after running the scripts and base the alert on that block, while using earlier blocks only to classify recurrence.
4. Do not rely on exit code alone. The integrity script can exit 0 while printing `CHANGED:` and writing `⚠️ File changes detected`; network logs can contain `⚠️ Unknown external connections` or baseline port diffs despite successful execution. For secret-bearing files such as `.aws/config`, do metadata-only triage (`stat`, `shasum`, baseline `grep`) and do not read contents unless there is a separate scoped need and it is safe.
5. If prior-day or same-day triage artifacts show the same condition, call it recurring/continuing when useful, but still report when the job’s rules say `⚠️ / 改ざん / 監視失敗 / 要対応` should trigger. For file-hash drift or new monitored-file appearances, check `stat` mtime and current `shasum -a 256` so the alert distinguishes an old baseline gap from a fresh modification. Do not auto-accept/update baselines without operator confirmation. When the signal is a continuing recurrence, read the newest prior triage artifact first, compare the PIDs/hashes/mtimes at a metadata level, then write a fresh dated artifact for the current run rather than reusing the old one.
6. For network warning PIDs, run `ps -p <pids> -o pid,ppid,comm,args` before summarizing so expected Hermes/OpenClaw/desktop processes are classified instead of reported as unexplained compromise.
7. Keep outbound content concise: outcome, affected file/process class, evidence log paths, and minimal next action. Do not paste raw logs unless necessary.

## Clean suppression
Only return the job’s suppression token (`NO_REPLY` or wrapper-specific silent token) when both scripts ran successfully and latest logs contain no warning/change/action-needed signals. If the migrated instruction explicitly says clean runs should end with `NO_REPLY`, use exactly `NO_REPLY` rather than the generic cron wrapper’s `[SILENT]`.

## Delivery and final sentinel
- When the active wrapper authorizes `send_message` / legacy `message` only on anomalies, run local checks first, send exactly one concise Slack alert only if warning/change/action-needed signals are present, then return the wrapper’s requested sent sentinel such as `[SENT]` if the send succeeds. In Hermes, call the bridge with the explicit send action when the schema supports it: `send_message(action='send', target='slack:<channel>', message='<concise alert>')`.
- For fixed-channel Slack IDs from migrated OpenClaw prompts, prefer the raw top-level target form `slack:<channel_id>` (for example `slack:C0AM8ET8MPG`) rather than any stale topic/thread target shown by discovery. If uncertain whether the messaging bridge is available, `send_message(action='list')` is a safe availability/target check; it does not require reading Slack content.
- If `send_message` succeeds, final response should be only the requested sent sentinel (commonly `[SENT]`), not a duplicate local summary. If no warning/change/action-needed signals are present and the job says clean runs end with `NO_REPLY`, return exactly `NO_REPLY` and do not post.
- If the active Hermes cron wrapper says final response is auto-delivered and explicitly says not to use `send_message`, that wrapper takes precedence over older migrated OpenClaw text that says to post to Slack. Put the Slack-ready alert in the final response.
- If the prompt asks for `message`/`send_message` but Hermes runtime exposes no such tool, put the concise alert in the final response; do not fake Slack delivery.

## Known recurring signal: OpenClaw config hash after handover
A repeated integrity warning for `/Users/angoya-claw/.openclaw/openclaw.json` may be a legitimate post-handover config change rather than a fresh compromise. In the May 10–17, 2026 cron runs, the file mtime was `May 1 22:41:00 2026`, while the stale baseline was from Apr 1 and logs showed the same hash drift (`73b2da...` baseline vs `895de0...` current). Still report it as `要確認` until the baseline is consciously accepted/updated; do not suppress solely because the script exits 0 or the warning is recurring.

## Known recurring signal: post-handover ports and user-app connections
Network monitor can flag expected post-handover/runtime processes even when the script exits 0. Recurring post-handover examples include:
- Hermes gateway: `python -m hermes_cli.main gateway run --replace` listening on `*:8644` and making HTTPS connections.
- OpenClaw local/admin gateway: `openclaw-gateway` listening on loopback admin ports such as `127.0.0.1:18789`, `[::1]:18789`, and `127.0.0.1:18791`.
- OpenClaw controlled browser: Chromium launched with `--remote-debugging-port=18800 --user-data-dir=/Users/angoya-claw/.openclaw/browser/openclaw/user-data`, listening on `127.0.0.1:18800` and making normal browser HTTPS/Google connections.
- User desktop apps such as Whimsical, Chromium, Brave, and Tailscale with outbound connections or loopback listeners.

When warnings appear, use a process listing for the PIDs from the warning lines (for example `ps -p ... -o pid,ppid,comm,args`) to classify the processes before summarizing. Still report `⚠️` according to the cron rule, but phrase these as likely expected/recurring when process args match the handover runtime; recommend baseline review rather than implying compromise without evidence.
