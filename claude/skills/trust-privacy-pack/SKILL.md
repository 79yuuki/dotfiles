---
name: trust-privacy-pack
description: >-
  Create and review trust, privacy, safety, retention, compliance, and customer-assurance artifacts for products and internal operations. Use for privacy pages, DPAs, security FAQs, data-retention policies, and launch readiness.
---

# Trust Privacy Pack

## Overview

Turn vague trust concerns into a concrete public artifact set. The goal is not legal perfection in one pass; the goal is to stop shipping products with trust-critical blanks.

Read `references/pack-template.md` when you need the actual sections to draft.

## Core Output

Produce a **Trust / Privacy Pack** with:
1. data flow summary
2. public trust artifact map
3. retention matrix
4. external contact routes
5. known gaps / decisions needing legal or founder sign-off

## Workflow

### 1. Define the exposure surface

Identify:
- who the user is
- what data enters the system
- where data is stored
- who can access it
- what external processors are involved
- what harms matter most: privacy, abuse, fraud, model misuse, takedown, data loss

### 2. Make the minimum artifact set explicit

At minimum, decide whether the product needs:
- privacy notice
- retention / deletion policy
- safety / acceptable use notice
- abuse or takedown contact
- security overview / trust page
- subprocessors or third-party dependency note
- incident / disclosure contact

If the answer is “later”, capture the risk and owner instead of silently skipping it.

### 2.5. Convert specs into an audit checklist before drafting

For AI-assisted product QA, trust pages, policies, onboarding flows, or review screens, turn the spec into checkable scenarios before writing prose:
- requirement / promise being made
- user harm if it is wrong or missing
- observable pass/fail check
- evidence source (screen, policy text, log, data-flow note)
- owner for legal/founder sign-off when judgement is required

Use this for the product / the product review flows and trust/privacy artifacts before launch. It is not a substitute for counsel; it is a way to surface missing decisions early.

### 2.6. Apply the legal-output review gate

When drafting legal-adjacent outputs (terms, privacy policy inputs, DD notes, compliance summaries, retention promises, trust-center claims), keep AI in the assistant lane:

- cite source material for each substantive claim, including file/path/URL and retrieval date when available
- state jurisdiction and governing-law assumptions explicitly; do not silently generalize across countries or regulated domains
- separate **draftable structure/plain-language text** from **attorney/founder sign-off required** clauses
- flag missing documents, unclear authority, and contradictions instead of resolving them by model confidence
- do not install or run external legal-agent/plugin bundles without the standard skill/security approval flow

Use the gate before sharing legal-adjacent artifacts externally. The safe default is a marked-up draft + open questions, not a final legal opinion.

### 3. Build the retention matrix

For each data category, define:
- data type
- why it exists
- default retention
- delete / archive trigger
- who can override
- user-visible explanation

### 4. Separate draftable vs approval-required work

Draft now:
- structure
- section headings
- first-pass plain-language text
- unanswered questions

Escalate for review:
- legal promises
- jurisdiction-specific claims
- security guarantees
- DPAs / contractual language

## Principles

- Trust artifacts are product features, not legal afterthoughts
- If you collect it, explain it
- If you keep it, time-box it
- If abuse is possible, publish a route for reporting it
- Prefer plain-language summaries before legal detail
- Missing decisions should be visible, not hidden

## Deliverable Format

Return:
- risk summary
- trust artifact list
- retention matrix
- draft sections ready to publish
- open questions needing sign-off
- which templates should be standardized across all projects
