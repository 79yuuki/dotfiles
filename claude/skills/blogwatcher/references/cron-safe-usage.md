# Cron-safe blogwatcher usage

Use this when running `blogwatcher-cli` inside scheduled jobs or guarded shells.

## Pitfalls

- `blogwatcher-cli articles` lists unread articles by default. Do not use `--unread` unless the installed `blogwatcher-cli articles --help` shows it.
- Avoid shell pipelines that feed `blogwatcher-cli` output directly into interpreters, e.g. `blogwatcher-cli articles | python3`. Guarded cron environments may block this as HIGH risk.
- Prefer interpreter-owned subprocess calls:

```python
import subprocess
text = subprocess.check_output(['blogwatcher-cli', 'articles'], text=True)
```

## Mark-read order for scanners

1. Scan and identify the new article IDs.
2. Fetch/retrieve enough content to classify the items.
3. Write durable artifacts/reports.
4. Only then run `blogwatcher-cli read <id>`.
5. Verify with a fresh `blogwatcher-cli articles` call that the processed IDs disappeared from the unread list.
