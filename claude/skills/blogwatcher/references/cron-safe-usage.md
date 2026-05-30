# Cron-safe blogwatcher usage

Use this when running `blogwatcher` inside scheduled jobs or guarded shells.

## Pitfalls

- `blogwatcher articles` lists unread articles by default. Do not use `--unread` unless the installed `blogwatcher articles --help` shows it.
- Avoid shell pipelines that feed `blogwatcher` output directly into interpreters, e.g. `blogwatcher articles | python3`. Guarded cron environments may block this as HIGH risk.
- Prefer interpreter-owned subprocess calls:

```python
import subprocess
text = subprocess.check_output(['blogwatcher', 'articles'], text=True)
```

## Mark-read order for scanners

1. Scan and identify the new article IDs.
2. Fetch/retrieve enough content to classify the items.
3. Write durable artifacts/reports.
4. Only then run `blogwatcher read <id>`.
5. Verify with a fresh `blogwatcher articles` call that the processed IDs disappeared from the unread list.
