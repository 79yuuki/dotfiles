# Counterparty Security Checklist

## Red / reject or escalate immediately
- Request to install unknown wallet, browser extension, profile, or desktop binary on a primary machine
- Request to join TestFlight / beta with wallet or production credentials on a primary device
- Request to clone a repo and run setup scripts before code review
- Request to install a package / skill / action / MCP tool with no provenance check or rollback plan
- Request to attach a new self-hosted runner or grant CI secrets before isolation / ownership review
- Request to sign a message or connect a wallet without clear business purpose
- Request sent via Telegram / DM with urgency, secrecy, or exclusivity framing
- Unexpected pivot from rapport-building to file/install request
- DeFi product has single signer / single upgrade admin / single secrets holder with no compensating controls
- DeFi product depends on a single RPC / bridge / oracle / DVN path with no degrade or failover story
- Team answers opsec questions with "audited" but cannot explain revoke / pause / incident handling

## Yellow / isolate first
- Read-only repo review in a disposable environment
- Documents from a new counterparty
- Non-production sandbox credentials
- Calls asking for live screen access into sensitive tooling
- Package / skill evaluation where source looks legitimate but lifecycle scripts or transitive deps are not yet reviewed
- DeFi DD where signer separation / dependency map / incident runbook exists only in chat, not in docs
- Bridge / oracle / RPC / DVN redundancy claims that cannot be independently verified

## Green / lower-risk defaults
- Public website review without login
- Public docs review
- Questions answered without opening files or running code

## Minimum verification questions
- What exactly do you want us to open / install / sign?
- Why is this needed now?
- Is there a browser-based or read-only alternative?
- Can you provide public docs or checksums first?
- Who else on your team can verify this request independently?
- What executes during install or bootstrap (`postinstall`, setup script, remote fetch, CI job)?
- Has ownership, maintainer, or package namespace changed recently?
- What secrets, runner permissions, or repo write scopes would this gain?
- How do we disable it and rotate credentials if it is compromised?

## Environment separation rules
- Daily machine: docs, calls, public browsing only
- Isolated VM / throwaway device: untrusted repos, beta apps, unknown documents, first-pass package/skill review
- Separate wallet / account: any signing or integration trial
- Second-person review: wallet, secrets, production infra, customer data access, or self-hosted runner enrollment

## DeFi / vault / protocol DD extension
- Map signer / deployer / operator / upgrade-admin roles separately.
- Record how keys, API keys, and secrets are stored and rotated.
- List bridge / oracle / RPC / relayer / DVN dependencies and note single points of failure.
- Ask what happens if one dependency stalls, censors, or gives bad data.
- Verify pause / revoke / incident response authority, trigger path, and expected response time.
- Treat yield claims as secondary until operational controls are legible.

## Value capture / distribution gate for DeFi, JPYC, x402, and bot strategies
Before treating a technically strong DEX, aggregator, bot, or protocol as strategically attractive, answer:
- Who owns the first user relationship: frontend, wallet, chain, exchange, creator platform, or bot operator?
- Who controls repeat usage and default routing: bookmarks, wallet UI, API integration, embedded checkout, market venue, or social/distribution channel?
- Who can tax or redirect order flow without rebuilding the core protocol?
- What happens if a wallet, frontend, exchange, or creator platform copies the feature and keeps the user relationship?
- Does the proposed bot/DeFi layer capture value directly, or only create value for a distribution owner upstream?
- What partnership, embed, wallet integration, or owned audience would move us closer to the distribution layer?

Policy line: for x402 / JPYC / DeFi / LP bot / prediction-market MM decisions, do not stop at “is the mechanism technically good?” Add a one-line value-capture verdict: `distribution owner / dependent layer / unclear`, plus the next action to improve capture.

## Policy lines
- Do not open untrusted repos on the primary development machine.
- Do not install partner beta apps on devices that hold production accounts or wallets.
- Do not grant packages, skills, actions, or MCP tools standing trust before provenance, hidden-execution, and rollback review.
- Do not attach self-hosted runners to sensitive repos before isolation, secret-scope review, and teardown planning.
- Treat Telegram/DM-delivered files and links as untrusted until independently verified.
- In-person trust does not waive technical verification.
- Do not treat "audited" as a substitute for signer separation, dependency mapping, and incident response review.
