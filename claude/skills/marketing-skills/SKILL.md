---
name: marketing-skills
description: >-
  Use a compact library of marketing playbooks for CRO, SEO, positioning, copywriting, analytics, experiments, pricing, launches, ads, and social content. Use when creating or auditing marketing strategy and deliverables.
---

# Marketing Skills

## Summary

One installed skill containing 23 marketing modules. Pick the relevant module under `references/` to get practical checklists, frameworks, and copy/paste deliverables.

This skill vendors the full content from `coreyhaines31/marketingskills` under `references/` and provides a simple router to load the right module.

## How to use

1) Identify the module that matches the request.
2) Read the corresponding `references/<module>/SKILL.md` file.
3) Apply the framework and deliver practical outputs (drafts + checklists).

## Included modules (what each one does)

Each module lives at `references/<module>/SKILL.md`.

- `ab-test-setup`: plan and implement A/B tests
- `analytics-tracking`: set up tracking and measurement (GA4/GTM/events)
- `competitor-alternatives`: competitor comparison + alternatives / “vs” pages
- `copy-editing`: edit and polish existing copy
- `copywriting`: write or improve marketing copy (headlines, CTAs, page copy)
- `email-sequence`: build email sequences and drip campaigns
- `form-cro`: optimize lead capture and contact forms
- `free-tool-strategy`: plan engineering-as-marketing free tools (calculators, generators)
- `launch-strategy`: product launches and announcements
- `marketing-ideas`: idea bank for growth + marketing tactics
- `marketing-psychology`: mental models / cognitive biases for better persuasion
- `onboarding-cro`: improve activation and onboarding
- `page-cro`: conversion optimization for any marketing page
- `paid-ads`: create and optimize paid ad campaigns
- `paywall-upgrade-cro`: optimize in-app paywalls and upgrade screens
- `popup-cro`: create/optimize popups and modals
- `pricing-strategy`: pricing, packaging, and monetization
- `programmatic-seo`: build SEO pages at scale (templates + data)
- `referral-program`: design referral and affiliate programs
- `schema-markup`: add structured data and rich snippets
- `seo-audit`: audit technical and on-page SEO
- `signup-flow-cro`: optimize signup and registration flows
- `social-content`: create and schedule social media content

## Module router

Pick one of these modules and read the matching file:

- `references/page-cro/PLAYBOOK.md`
- `references/signup-flow-cro/PLAYBOOK.md`
- `references/onboarding-cro/PLAYBOOK.md`
- `references/form-cro/PLAYBOOK.md`
- `references/popup-cro/PLAYBOOK.md`
- `references/paywall-upgrade-cro/PLAYBOOK.md`
- `references/copywriting/PLAYBOOK.md`
- `references/copy-editing/PLAYBOOK.md`
- `references/email-sequence/PLAYBOOK.md`
- `references/social-content/PLAYBOOK.md`
- `references/analytics-tracking/PLAYBOOK.md`
- `references/ab-test-setup/PLAYBOOK.md`
- `references/seo-audit/PLAYBOOK.md`
- `references/programmatic-seo/PLAYBOOK.md`
- `references/schema-markup/PLAYBOOK.md`
- `references/competitor-alternatives/PLAYBOOK.md`
- `references/pricing-strategy/PLAYBOOK.md`
- `references/launch-strategy/PLAYBOOK.md`
- `references/paid-ads/PLAYBOOK.md`
- `references/referral-program/PLAYBOOK.md`
- `references/free-tool-strategy/PLAYBOOK.md`
- `references/marketing-ideas/PLAYBOOK.md`
- `references/marketing-psychology/PLAYBOOK.md`

## Output rules

- Prefer 80/20: biggest levers first.
- Never invent metrics or keyword volumes. If missing, label assumptions.
- When possible: include copy/paste drafts and an implementation checklist.

## Muser GTM engineer loop

When a request involves one-person marketing teams, GTM engineers, sales automation, CRM context layers, LinkedIn/X launch loops, or AI-assisted campaign operations, do not produce isolated copy only. Design the loop:

1. shared context: ICP, pains, objections, competitor position, proof, and current conversations
2. distribution queue: derive X / LinkedIn / note / newsletter / PR / ads from one hypothesis
3. semantic layer: define account, creator, campaign, artifact, buyer intent, and next action fields
4. experiment log: record impressions, CTR, CVR, replies, meetings, sales, CAC, complaints, and risk signals
5. learning reflection: feed winning copy, objections, FAQs, and proof back into skills/templates/pitches

For the product and x402, reusable template first; project-specific injection second.

## Muser AI-era brand and persuasion gates

Use these as quick overlays before shipping AI-assisted LPs, proposals, SNS, ads, or launch narratives.

### Anti-average brand gate

AI-generated marketing often looks polished while drifting toward a generic average. Before editing for polish, compare two variants:

- `average-safe`: the obvious, broadly positive, easy-to-approve version
- `distinctive-bitter`: the version that preserves a sharper point of view, even if it is less immediately comfortable

Check:
- Is the tone excessively cheerful, frictionless, or consensus-seeking?
- Could a competitor, unrelated SaaS, or generic AI template say the same thing?
- What did we deliberately choose not to say or not to optimize for?
- Does the piece contain a taste/point-of-view marker that selects the right audience instead of explaining everything to everyone?
- If the distinctive version is rejected, is the reason recorded as a brand decision rather than silently reverting to average?

### Future-loss copy pattern

For CRO and sales pages, do not stop at “here is your ideal future.” Use an ethical loss-framing sequence:

1. Make the desired future vivid with numbers, scene, action, and felt experience.
2. Show, with evidence or clear constraints, why the current path causes that future to be missed.
3. Position the offer as the recovery path for the missed future, not merely a new benefit.
4. Give two concrete choices so the reader retains autonomy.

Do not use this pattern when evidence is weak. Avoid fear-only copy; the exit path must be concrete and proportionate.
