---
name: public-site-stack-decision
description: >-
  Choose a stack for public-facing sites such as landing pages, docs, blogs, corporate sites, campaign pages, and help centers. Use to decide between static, CMS, docs frameworks, app routes, and publishing workflows.
---

# Public Site Stack Decision

## Overview

Do not pick WordPress, headless, or static by habit. Pick the stack that matches the publishing model, team reality, and maintenance burden.

Read `references/decision-matrix.md` when you need the scoring criteria.

## Core Output

Produce a **Public Site Stack Decision Pack**:
1. site type classification
2. requirements and constraints
3. stack option scorecard
4. governance / maintenance model
5. migration recommendation

## Workflow

### 1. Classify the site

Typical classes:
- landing page
- docs / developer portal
- corporate site
- campaign site
- blog / newsroom
- help center / knowledge base

One stack does not need to serve every class.

### 2. Score the real constraints

Evaluate:
- editor autonomy needed
- developer involvement needed
- localization needs
- performance / SEO needs
- content structure complexity
- design flexibility
- deployment reliability
- plugin/security burden
- preview/review workflow
- long-term maintenance cost

### 3. Compare candidate stacks

Examples:
- WordPress
- static site generator
- headless CMS + frontend
- docs-focused platform
- custom app surface

Prefer the simplest stack that satisfies the actual editing and governance needs.

### 4. Define the operating model

The stack choice is incomplete without:
- ownership
- publishing workflow
- preview / approval path
- rollback path
- analytics / monitoring
- security update responsibility

## Principles

- Publishing model first, technology second
- Lower maintenance beats theoretical flexibility
- Do not force docs, corporate, and campaign pages into the same tool if their needs differ
- Plugins are operational liabilities unless clearly justified

## Deliverable Format

Return:
- site classification
- weighted criteria
- option comparison
- recommended stack per surface
- migration/no-migration decision and rationale
