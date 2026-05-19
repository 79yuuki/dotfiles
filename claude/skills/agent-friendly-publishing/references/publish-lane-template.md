# Publish Lane Template

Use this when deciding whether docs, code, demos, prototypes, changelogs, or policy pages should be public, controlled-preview, or private.

## Default stance

Prefer **open by default, close deliberately** for artifacts that benefit from reuse, citation, external review, and agent discoverability. Do not make everything private just because a risk exists; name the specific risk and choose the narrowest lane that mitigates it.

## Lane decision table

| Lane | Use when | Required controls | Typical artifacts |
|---|---|---|---|
| Public | Reuse, citation, recruiting, ecosystem trust, customer onboarding, or agent discoverability is valuable and no secrets/customer data/unresolved vulnerability details are present. | Owner, canonical URL, update cadence, changelog/deprecation path, contact/abuse route, license or usage terms where relevant. | API docs, llms.txt, changelog, pricing, public policy, capability catalog, sanitized examples, reusable open source code. |
| Controlled preview | The surface is useful to customers/partners/reviewers but needs limited audience, early-stage caveats, rate limits, or abuse monitoring. | Auth or invite gate, namespace, data isolation, expiry/retirement date, owner, reviewer list, logging/audit, clear “preview” labeling. | Demo app, review link, internal prototype shared externally, beta docs, staging API, partner sandbox. |
| Private | Exposure would reveal secrets, customer/regulated data, exploitable vulnerability detail, paid/confidential terms, or account/person-level material. | Explicit closure reason, owner, review date, minimal access list, path to sanitize/open later if possible. | Incident exploit details before fix, customer data, secrets, private contracts, unredacted logs, credentialed admin workflows. |

## Minimum output

When applying the template, return:
1. Recommended lane and why.
2. What can be public immediately.
3. What must be redacted, gated, or delayed.
4. Owner and next review date.
5. Agent-readable artifacts to add if public or controlled-preview (`llms.txt`, markdown docs, sitemap/feed, capability card, pricing/policy snippets).

## Reopen check

For every private or controlled-preview decision, set a review trigger:
- vulnerability fixed
- sensitive data removed
- beta ends
- customer/partner permission obtained
- policy or pricing finalized
- prototype retired

If none exists, the lane is likely an indefinite hiding place rather than a deliberate publishing decision.
