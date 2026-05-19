---
name: agent-friendly-publishing
description: >-
  Design and improve publishing surfaces so AI agents and humans can reliably discover, read, cite, and act on them. Use for docs, public sites, README files, llms.txt, API pages, changelogs, and controlled-preview publishing.
---

# Agent Friendly Publishing

## Overview

Public information should be publish-once, reuse-everywhere. Structure pages so humans can skim them and agents can parse them without guessing.

This also applies to **controlled-preview surfaces**: AI-built prototypes, demo apps, review links, and internal tools that start private but often drift toward broader sharing. Treat those as publishing surfaces with stricter guardrails, not as exempt side projects.

For code/docs that benefit from reuse and scrutiny, prefer **open by default, close deliberately**: making everything private adds delivery/policy cost and can reduce external review. Use private/closed lanes for secrets, regulated data, abuse vectors, customer data, or unresolved vulnerability response — not as the default reaction to risk.

Read `references/checklist.md` when you need a concrete artifact checklist or page-by-page template.
Read `references/internal-prototype-publish-lane.md` when you need a gated-preview checklist for AI-built or internal prototypes.
Read `references/publish-lane-template.md` when choosing public / controlled-preview / private lanes for docs, code, demos, or prototype surfaces.
Read `references/tenant-aware-runtime-narrative.md` when a product is being over-described as a payment/API rail and needs a reusable story around tenant state, approval loops, and durable workflow ownership.

## Core Output

Produce an **Agent-Friendly Publishing Pack**:
1. Surface inventory: docs, pricing, policy, changelog, contact, status, trust pages
2. Canonical information hierarchy: what goes where, what links to what
3. Machine-readable layer: `llms.txt`, feeds, structured snippets, stable URLs, markdown/content-negotiation paths
4. AI interface layer: structured HTML landmarks, explicit action/capability entry points, disclosure of what agents may read or do
5. Editorial rules: naming, dates, versioning, update cadence
6. Gap list: what is missing, ambiguous, duplicated, or stale

## Workflow

### 1. Audit the current surface

Check whether a new visitor or agent can answer these fast:
- What is this?
- Who is it for?
- How do I start?
- How much does it cost?
- What are the rules and limits?
- Where is the latest change log?
- Where do I ask for help or report abuse?

If any answer requires hunting across multiple pages, treat it as a publishing bug.

### 2. Normalize the public information architecture

Prefer this order:
- Overview / landing
- Quickstart / getting started
- Reference docs
- Pricing / plans / rate limits
- Policies: privacy, retention, safety, abuse, contact
- Changelog / release notes
- Status / reliability signals

Use stable page names and URLs. Avoid hiding critical facts inside blog posts, tweets, or PDFs.

### 3. Add the agent-readable layer

For important pages, ensure:
- semantic HTML landmarks (`main`, `nav`, `article`, `section`) and stable headings so browser/agent DOM extraction works
- clear headings
- short summary at top
- stable terminology
- explicit dates and versions
- copyable examples
- direct links between overview ↔ quickstart ↔ reference ↔ policy
- agent-discoverable metadata such as sitemaps, `Link` headers, and well-known endpoints where relevant

Where useful, generate:
- `llms.txt`
- RSS/Atom/changelog feed
- machine-readable pricing/plan summary
- policy index page
- FAQ with concise Q/A blocks
- API Catalog / capability index / agent-skills index when the product exposes actionable capabilities
- markdown content negotiation (`Accept: text/markdown`) for docs and high-citation pages
- a reusable narrative block for products whose real value is durable workflow state, tenant isolation, approval routing, or auditability rather than the transport/payment primitive alone

Think in five audit dimensions:
- **Discoverability** — `robots.txt`, `sitemap.xml`, `Link` headers, stable canonical URLs
- **Content** — markdown-first rendering, concise summaries, low-token pages that agents can cite cheaply
- **Bot access control** — explicit crawler policy, training/input/search preferences, auth where needed
- **Capabilities** — API Catalog, OAuth discovery, MCP/agent capability cards, clear start points for tools
- **Agent UI compatibility** — forms, actions, tables, modals, and auth states are understandable from DOM text, not only visual styling or client-only state

If deprecated content must stay online, do not stop at banners or `noindex`. Add enforceable canonical behavior (redirects or equivalent routing) so crawlers and future model training runs are pushed to the current page instead of ingesting stale docs.

### 4. Define maintenance rules

For each artifact, record:
- owner
- source of truth
- update trigger
- review cadence
- deprecation path

If nobody owns a page, assume it will rot.

## Heuristics

- One fact, one canonical home
- Critical facts belong on web pages, not just in social posts
- Add examples before adding prose
- Prefer boring naming over clever naming
- If agents must pay or comply, pricing and policy pages must be first-class
- If the content is worth citing, it needs a stable URL
- If an internal prototype might be shared beyond its maker, give it explicit auth, namespace, owner, and retirement rules before circulating the link
- If old content still ranks or gets crawled, canonical intent must be machine-enforced, not just advisory

## Deliverable Format

When applying this skill, return:
- current gaps
- target page map
- concrete artifacts to create/update
- recommended rollout order
- which pieces should become reusable templates across projects
