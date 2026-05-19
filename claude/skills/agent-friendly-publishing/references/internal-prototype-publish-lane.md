# Internal Prototype Safe Publish Lane

Use this when an AI-built app, internal tool, review link, or demo environment is about to be shared beyond the person who made it.

## Why this exists
A prototype becomes a publishing surface the moment someone else can open it.
Do not treat AI-built or "just internal" apps as exempt from auth, naming, data isolation, or ownership rules.

## Core rule
Separate:
- **owner logic** — who requested it, who operates it, who can approve wider sharing
- **platform guardrails** — auth, namespace, storage, deploy lane, logging, retirement path

The app idea can be experimental.
The guardrails should be boring.

## Use this checklist before sharing a link

### 1. Owner / audience / expiry
- Name one owner who is responsible for the prototype.
- State the allowed audience: just maker, internal team, selected partner, or public preview.
- Set an expiry or review date so "temporary" does not become permanent by accident.
- Decide whether recipients may forward the link, screenshot it, or demo it onward.

### 2. Auth and access
- Default to authenticated access for anything non-public.
- Separate viewer access from admin/operator access.
- Do not share common admin credentials in chat, docs, or prompt history.
- Remove or rotate temporary access after the review window closes.

### 3. URL, naming, and discoverability
- Put prototypes on a clearly non-canonical hostname/path so they cannot be mistaken for production.
- Label the surface as prototype / internal / review where relevant.
- Avoid production-like naming that implies official support or permanence.
- If the surface is not meant to be publicly indexed, keep it behind auth and add non-index guidance as defense in depth, not as the primary boundary.

### 4. Data and storage isolation
- Prefer synthetic, scrubbed, or minimum-necessary data.
- Keep prototype databases, buckets, queues, and logs separate from production by default.
- Do not reuse production secrets just because it is faster.
- Decide retention/deletion behavior for uploaded files, logs, and generated outputs.

### 5. Runtime and deploy lane
- Use a distinct environment/project/account where possible.
- Record who can redeploy, who can change config, and how to shut it down.
- Have at least a minimal rollback or kill-switch path.
- Log enough to debug misuse or breakage without over-collecting sensitive data.

### 6. Surface clarity for humans and agents
- State what the prototype does in one sentence.
- State what is stable vs experimental.
- Link to the owner or feedback route.
- If an agent or reviewer needs instructions, provide a short start page instead of burying context in chat.

### 7. Graduation or retirement
- Define the next state explicitly: archive, keep internal, convert to product, or publish publicly.
- If graduating to a public surface, hand off into the normal agent-friendly publishing checklist.
- If retiring, remove access and document where the final artifact or decision lives.

## Common failure modes
- "Internal" app shared from a production-looking domain with no owner label
- Demo uses live customer data because it was convenient
- Temporary review link becomes the de facto canonical URL
- AI-built prototype gets circulated without auth because the team assumes obscurity is enough
- No retirement date, so stale prototypes accumulate and confuse humans/crawlers

## Handoff artifact
When you use this checklist, leave a short artifact with:
- owner
- audience
- URL / namespace
- auth mode
- data source classification
- expiry/review date
- graduation or retirement decision
