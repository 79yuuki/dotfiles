# Tenant-Aware Runtime Narrative Block

Use this when a product is being explained too narrowly as a payment rail, API pipe, or thin protocol wrapper, but the durable value is actually in how work is routed, approved, and persisted per tenant.

## When to use
- LP / overview copy keeps leading with the transport primitive (`payments`, `API relay`, `MCP server`, etc.)
- Buyers really care about approval loops, auditability, state isolation, multi-tenant controls, or operator trust
- The same product story needs to work across x402-relay, GTM tooling, internal agent ops, and future workflow products

## Reframe
Instead of:
- "X is a payment rail for agents"
- "Y lets AI call tools with money attached"

Prefer:
- "X gives each customer a tenant-aware runtime for agent actions, approvals, and settlement"
- "Y turns one-off agent calls into governed workflows with state, review points, and reusable operator controls"

## Narrative structure

### 1. Start with the durable job
Name the workflow problem first.
- approvals get lost in chat
- tenant context is mixed together
- operators cannot see who approved what
- one-off automations break because state and ownership are unclear

### 2. Explain the runtime, not just the rail
Describe the persistent system behavior.
- tenant-scoped state and history
- approval checkpoints / human-in-the-loop gates
- actor separation and permissions
- audit trail and replayable decisions
- handoff between agent, operator, and customer

### 3. Demote the primitive to enabling infrastructure
Payment rails, protocols, or transport layers matter, but they are not the headline.
- mention them as enablers of trust, settlement, or interoperability
- avoid making the buyer infer workflow value from protocol jargon alone

### 4. Show the control surfaces
Call out what an operator can actually configure.
- who can trigger actions
- what needs approval
- what state is stored per tenant
- where logs / status / exceptions live
- how escalation and retry paths work

### 5. End with the business effect
Tie the narrative to outcomes.
- less operator confusion
- safer delegation
- clearer customer boundaries
- faster onboarding of repeatable workflows
- easier expansion from one workflow to many

## Reusable copy blocks

### One-liner
`[Product] gives each customer a tenant-aware runtime for agent work: state, approvals, and control surfaces stay organized even as automations scale.`

### Short paragraph
`[Product] should not be presented as just a rail or protocol wrapper. The real value is that it turns agent actions into governed workflows with tenant-scoped state, approval checkpoints, and operator-visible control surfaces. Payments / transport / protocol support are enabling layers, but the product story should lead with durable workflow ownership and trust.`

### FAQ prompt
- What state is persisted per tenant?
- Where do approvals happen?
- What can an operator review or override?
- How does the system prevent one tenant's workflow from leaking into another?
- What does the buyer gain beyond the underlying payment/protocol primitive?

## Placement guidance
Use this block in:
- overview / hero support copy
- FAQ / objections
- architecture page for non-technical buyers
- sales one-pagers and partner decks
- internal messaging docs before writing launch copy

## Anti-patterns
- leading with protocol jargon before workflow value
- implying that money flow alone creates trust
- describing tenant isolation only in security/legal pages, not in product value copy
- talking about agent autonomy without showing approval boundaries
