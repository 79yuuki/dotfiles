---
name: sales-gtm-os
description: >-
  Build and operate a reusable sales and go-to-market system: lead intake, qualification, outreach, follow-up, proposal flow, CRM tagging, pipeline review, reusable assets, and decision gates.
---

# Sales GTM OS

## Overview

Turn ad hoc founder-led selling into a reusable operating system. Optimize for visibility, follow-through, and reusability across multiple projects.

Read `references/os-template.md` when you need the object model and pipeline template.
Read `references/decision-trace-template.md` when the user needs rationale / override / outcome logging around proposals, follow-ups, or account decisions.
Read `references/small-business-ai-ops-template.md` when packaging agent-assisted billing, monthly close, CRM follow-up, sales/ad creation, or workspace-doc operations for small businesses, creator businesses, agencies, the product, or the product.

When strategy depends on a technical edge, add the **distribution / user-relationship gate** before proposal or prioritization: verify who owns the audience, channel, default surface, trust relationship, and charging point.

When the work is AI-native / agent-native, add the **AI-native company design gate** before GTM or sales-org recommendations: do not stop at "AI feature" or "AI product". Check which workflows move to agents, where human review stays, how FDE / field decision drivers carry last-mile adoption, what data / permission / audit layer becomes the moat, whether usage-based inference costs preserve gross margin, and whether docs / pricing / trust signals are machine-readable enough for agent-led discovery.

## Core Output

Produce a **Sales / GTM OS Pack**:
1. canonical object model
2. stage definitions
3. follow-up rules
4. reusable asset inventory
5. weekly review format
6. decision-trace schema for important commercial decisions

## Workflow

### 1. Normalize the object model

At minimum define:
- account / company
- contact
- opportunity
- project / offer
- proposal / deck
- engagement mode / role expectation
- blocker
- next action

Add a lightweight **semantic layer** before dashboarding: define each object and metric in business language, keep one canonical meaning across projects, and map raw fields to terms humans use (e.g. `waiting investor`, `decision owner`, `stale opportunity`, `proposal role`). This prevents CRM / Sheets / team chat / docs from drifting into incompatible definitions.

`engagement mode / role expectation` は最低でも明示する。
例:
- execution partner（手足役）
- specialist advisor（専門家役）
- momentum driver（推進剤役）
- system designer（設計役）
- field decision driver（現場で判断を前に進める役）

提案が刺さらない時は、価格や資料の前に「相手が何役を買おうとしているか」がズレていることが多い。
FDE/現場密着型の役割を扱う時は、「顧客に近い人」ではなく「現場で意思決定を前に進め、停滞をほどく人」として定義する。

If these objects blur together, pipeline visibility collapses.

### 2. Define stages with exit criteria

Example stages:
- inbound / sourced
- qualified
- discovery
- proposal in progress
- proposal sent
- negotiation / waiting
- won / lost / dormant

Each stage must have:
- owner
- required facts
- next action rule
- stale limit

### 3. Build reusable operating rules

Before GTM prioritization, proposal framing, or partnership recommendations for a technically strong product, run a **distribution / user-relationship gate**:
- Who already owns the buyer/user relationship?
- Which channel or default surface makes adoption happen: wallet, frontend, store, community, KOL, partner, marketplace, search, compliance gate, or workflow embedding?
- Where can the business actually charge: subscription, take-rate, margin, implementation, managed service, listing/access, referral, data, or financing?
- What is the replaceable technical layer, and what relationship/trust asset is hard to replace?
- What proof shows capture potential: repeat contact, opt-in list, signed LOI, default integration, exclusive inventory, regulatory/custody trust, or retention?

If value creation and value capture are split, make the GTM plan target the capture point, not only the technical layer.

Include:
- intake format
- qualification checklist
- proposal assembly checklist
- follow-up cadence
- inbox / email triage rule
- dormant deal revival rule
- transfer rule when opportunity moves projects

`inbox / email triage rule` では次を決める:
- どのメールを human-only に残すか
- どの定型返信 / 催促 / 資料送付を agent-assisted にするか
- 返信本文だけでなく、decision trace / CRM / 次アクション更新をどこまで同時に行うか
- 「誰にとっての inbox か」（founder / investor / customer / partner）を分けるか

### 4. Standardize reusable assets

Track reusable materials:
- one-pagers
- case studies
- pricing/menu
- proposal templates
- FAQ / objection bank
- meeting note template

### 5. Add a decision-trace layer when judgement quality matters

For proposals, exceptions, pricing changes, founder overrides, and postmortems, define a small log that captures:
- context
- proposed action
- chosen action
- override reason
- expected outcome
- actual outcome
- lesson / rule update

If a team keeps repeating the same discussions, the missing system is often not CRM data but decision history.

## Principles

- Every opportunity needs one owner and one next action
- “Waiting” is not a next action
- Reuse assets across projects unless differentiation matters
- Multi-project visibility matters more than local tracker perfection
- Follow-up rules are default, not improvised
- 役割期待（execution / advisor / momentum / design）を proposal 前に固定する
- 採用・評価・合宿では「勢いを作った証拠」（停滞解消、次アクション生成、意思決定前進、関係者の再同期）をログに残す
- Email は単なる通知ではなく、agent touchpoint として設計する
- Important commercial decisions must leave rationale, not mere status updates

## Deliverable Format

Return:
- pipeline design
- stage definitions
- required templates/assets
- decision-trace schema if judgement logging matters
- immediate cleanup tasks
- how the OS can generalize across x402, the company, the product, Avenir, and future work
