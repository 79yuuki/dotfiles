---
name: codebase-indexing
description: >-
  Improve repository discoverability for AI coding agents and humans by adding code maps, repo manifests, indexes, and retrieval workflows. Use when repo exploration is slow, onboarding is hard, or agents repeatedly miss important files. Use ALSO when the human mental model and the agent's explanation of an existing codebase may diverge (explain-back check); build indexing artifacts only if that check exposes discoverability problems.
---

# Codebase Indexing

## Overview

Treat repository discoverability as infrastructure. The goal is to make “where does this live?” cheap for both humans and agents.

Read `references/indexing-matrix.md` when choosing the right indexing tier. Read `references/knowledge-base-template.md` when the repo/project needs a lightweight raw/wiki/outputs knowledge base rather than a code-only index.

## Core Output

When discoverability problems exist (or the explain-back check in step 0 exposes them), produce a **Codebase Indexing Pack**:
1. current search pain points
2. indexing tier choice
3. generated or maintained repo map artifacts
4. retrieval workflow for humans and agents
5. maintenance rules

## Workflow

### 0. Explain-back check (existing repo onboarding)

When an agent enters an existing repository, have it read the current structure and explain it back before anything is indexed or changed:
- entrypoints, major domains, data flow, and the test/verification commands
- compare the explanation with the human's understanding of the repo
- write only the mismatches, plus constraints and preferences that cannot be read from the code, into `AGENTS.md` / `CLAUDE.md`; do not record what the code already shows
- instead of reading all the code, build a behavior map from E2E test names, test code, and public function signatures
- if a human needs a conceptual explanation, ask for an ELI5 or a diagram
- if the explain-back matches and nothing was hard to find, stop here; continue to the steps below only when it exposes discoverability problems
- source of this approach: https://zenn.dev/mizchi/articles/ai-coding-loop-formal

### 1. Audit current discoverability

Check how quickly you can answer:
- entrypoints
- major domains / bounded contexts
- background jobs / workers
- API surfaces
- env/config locations
- tests for each area
- migration / deploy paths

If the answer depends on tribal knowledge, indexing is missing.

### 2. Pick an indexing tier

Use the lightest tier that solves the problem:
- Tier 0: file conventions + grep + README cleanup
- Tier 1: repo map / domain manifest / key-path index
- Tier 2: symbol index / ctags / tree-sitter outputs
- Tier 3: embeddings or semantic retrieval for large repos

Prefer deterministic indexes before fancy retrieval.

When Tier 3 is needed across multiple projects, customers, or languages, make retrieval tenant-aware by default:
- namespace per project / customer / major language unless a shared corpus is clearly intended
- attach metadata like `project`, `tenant`, `repo`, `language`, `area`, `doc_type`, `freshness`
- filter or boost by namespace + metadata before semantic ranking
- widen to cross-namespace search explicitly as a second pass, not the default

### 3. Create retrieval-friendly artifacts

Common artifacts:
- `docs/repo-map.md`
- `docs/domains/<name>.md`
- `docs/entrypoints.md`
- `knowledge/raw/`, `knowledge/wiki/`, `knowledge/outputs/` for project second-brain material that is not code-only
- generated symbol index
- retrieval manifest for namespace + metadata schema
- query ladder doc for local → adjacent → global search
- “where to start” guide for agents
- script wrappers for index refresh

Keep facts close to code. Do not create fluffy architecture prose that will rot.

### 4. Define usage patterns

Document how humans and agents should use the index:
- first search path
- fallback search path
- default query ladder: local namespace → adjacent namespaces → global
- when cross-namespace search is allowed
- refresh cadence
- ownership
- metadata fields that ingest / refresh scripts must preserve
- what must be updated in PRs

## Principles

- Deterministic > magical
- Generated artifacts are better than hand-maintained catalogs when possible
- Local context first; global semantic search only when justified
- A small accurate map beats a giant stale architecture document
- Indexes should speed up review, debugging, onboarding, and agent work simultaneously

## Deliverable Format

If step 0 ended the work, return only the explain-back result and any mismatches recorded in `AGENTS.md` / `CLAUDE.md`. Otherwise return:
- pain points found
- chosen tier and why
- artifacts/scripts to add
- PR/update rules
- rollout order across repositories

For project-wide knowledge bases, also return the proposed `raw/wiki/outputs` folder shape, the root agent-file snippet, and the monthly health-check owner/cadence.
