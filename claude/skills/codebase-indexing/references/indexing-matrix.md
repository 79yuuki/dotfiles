# Codebase Indexing Matrix

## Tier 0 — Cleanup only
Use when repo is small or short-lived.
- normalize file naming
- add missing READMEs for entry areas
- document main commands

## Tier 1 — Repo map
Use when onboarding or code review is slow.
- repo map
- domain map
- entrypoints
- config/env paths

## Tier 2 — Symbol index
Use when functions/classes are hard to trace.
- ctags / tree-sitter / language-server output
- symbol-to-file lookup
- script to refresh index

## Tier 3 — Semantic retrieval
Use when repo is huge or multi-repo.
- embeddings / vector search / semantic chunking
- namespace per project / customer / major language before building a global corpus
- metadata filters / boosts (`project`, `tenant`, `repo`, `language`, `area`, `doc_type`, `freshness`)
- explicit query ladder: local namespace → adjacent namespace → global
- strong freshness rules
- clear fallback to grep and deterministic search

## Anti-patterns
- giant hand-written architecture bibles
- one giant cross-project index with no tenant boundaries
- semantic search with no metadata filters or deterministic fallback
- indexes with no owner
- hidden generated artifacts nobody refreshes
