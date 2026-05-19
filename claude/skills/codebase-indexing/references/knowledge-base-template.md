# Project Knowledge Base Template

Use this when a project needs a lightweight second-brain structure that agents and humans can maintain without a heavy wiki migration.

## Folder shape

```text
knowledge/
  raw/       # imported notes, meeting snippets, articles, screenshots OCR, source dumps
  wiki/      # distilled, canonical project knowledge in markdown
  outputs/   # reusable deliverables: briefs, reports, decks, proposal drafts
  CLAUDE.md or AGENTS.md  # short instructions for how to use this knowledge base
```

## Rules

- `raw/` is append-only evidence. Do not polish it; keep source links, dates, author, and retrieval status.
- `wiki/` is the maintained view. Merge duplicates, resolve contradictions, and keep each page focused on one concept.
- `outputs/` stores publishable or reusable artifacts; link back to the `wiki/` pages and `raw/` evidence used.
- Keep the root agent file short. Include only: folder meanings, source-attribution rule, update cadence, and contradiction handling.
- When answering project questions, save high-value Q&A back into `wiki/` if it will be useful again.

## Monthly health check

Run once a month or before major planning:

1. List the newest `raw/` items not cited from `wiki/`.
2. Find stale `wiki/` pages whose source evidence is older than the project’s decision cadence.
3. Search for contradictions: pricing, positioning, API behavior, launch dates, legal/trust claims, owner names.
4. Promote reusable outputs into templates when the same artifact shape appears twice.
5. Archive or mark obsolete pages rather than leaving silent rot.

## Minimal root agent file

```markdown
# Project Knowledge Base

- `knowledge/raw/`: source material. Preserve date, source URL/path, and retrieval status.
- `knowledge/wiki/`: canonical distilled knowledge. Prefer short pages with source links.
- `knowledge/outputs/`: reusable deliverables and drafts.
- Before making a project claim, cite the relevant `wiki/` page or raw source.
- If sources conflict, write the conflict explicitly and ask/route for decision instead of choosing silently.
- After answering a reusable project question, add a short Q&A note to `knowledge/wiki/qa.md`.
```
