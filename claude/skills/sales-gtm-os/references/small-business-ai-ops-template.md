# Small Business AI Ops Package Template

Use this when a project needs a concrete AI-ops offer for small businesses, creator businesses, agencies, or the product/the product-style backoffice-heavy teams.

## Positioning

Turn scattered admin work into an agent-assisted operating layer. Do not sell "AI chat"; sell fewer dropped follow-ups, faster monthly close, cleaner billing, and reusable work records.

## Scope modules

| Module | Jobs to automate/assist | Required integrations | Human approval boundary |
|---|---|---|---|
| Billing / invoice collection | invoice reminders, unpaid list, payment-status summary, customer follow-up draft | accounting/invoice system, payment provider, CRM/sheet | sending payment notices, changing invoice terms, refunds |
| Monthly close prep | collect receipts, reconcile missing items, create close checklist, flag exceptions | accounting system, bank/payment exports, document drive | final accounting judgement, tax/legal conclusions |
| CRM follow-up | stale lead detection, next-action draft, meeting recap, pipeline stage update proposal | CRM, calendar, email/docs | external sends, pricing/contract commitments |
| Sales/ad creation | campaign briefs, landing-page copy drafts, ad variants, objections/FAQ bank | existing site/docs, analytics, ad accounts | public publishing, paid spend changes |
| Workspace docs | turn repeated operations into SOPs, decision logs, onboarding snippets | Google Workspace/Notion/docs | policy promises, HR/legal-sensitive text |
| Business router | route incoming work to the right skill/agent/profile and preserve decision traces | workspace docs, project board, profile routing, routine artifacts | changing ownership, publishing, permission grants |

## Business router skeleton

Use this when packaging a Claude/Hermes-style SMB onboarding offer or internal Muser/the product ops router.

```md
# /smb-onboard Router

## Intake
- business type:
- primary pain loop:
- current source of truth:
- approval-required actions:
- success metric for 30 days:

## Route table
| Request type | First skill/agent | Required context | Output artifact | Approval boundary |
|---|---|---|---|---|
| unpaid invoice / billing | billing ops | invoice list + customer notes | draft reminder + exception list | external send/refund |
| stale lead / CRM | sales-gtm-os | account/contact/opportunity | next-action proposal | external send/pricing |
| monthly close | finance/admin ops | receipts/export/checklist | close-prep checklist | tax/accounting judgement |
| marketing/ad | gtm-content-ops | offer/site/audience | campaign draft | publish/spend |
| workspace SOP | harness-engineering | repeated workflow/logs | SOP + owner + review date | HR/legal-sensitive policy |

## Review ritual
- weekly exception report:
- decision trace location:
- owner:
- what gets escalated to human:
```

Keep the router draft-only until the business has reviewed at least one weekly exception report.

## Discovery questions

1. Which admin loop creates the most missed revenue or founder anxiety today?
2. Where does the source of truth live for customers, invoices, and tasks?
3. Which actions can be drafted by AI but must never be auto-sent?
4. What is the weekly review ritual: who looks at exceptions and when?
5. What evidence proves success: collected invoices, fewer stale leads, close-cycle days, reduced manual hours?

## 1-page offer skeleton

```md
# Small Business AI Ops Package

## Outcome
- [Concrete business result: e.g. unpaid invoices followed up weekly, monthly close checklist ready by day 3]

## Starting workflow
- Billing/invoice:
- Monthly close:
- CRM follow-up:
- Sales/ad creation:
- Workspace docs:

## Agent-assisted deliverables
- Weekly exception report:
- Draft follow-ups:
- SOP/checklist updates:
- Metrics dashboard:

## Human approval boundaries
- AI may draft:
- Human must approve:
- Never automated:

## Integrations
- Accounting/payment:
- CRM:
- Workspace/docs:
- Analytics/ad:

## 30-day pilot success criteria
- Metric 1:
- Metric 2:
- Metric 3:
```

## Safety notes

- Do not grant agent write/send permissions until the draft-only workflow is proven.
- Treat payroll, tax, legal, refunds, and payment disputes as approval-required.
- Keep decision traces for pricing exceptions, refund requests, and escalations.
