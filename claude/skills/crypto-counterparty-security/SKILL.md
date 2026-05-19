---
name: crypto-counterparty-security
description: >-
  Assess crypto, wallet, exchange, market-making, DeFi, vendor, and AI-agent collaboration workflows for counterparty, social-engineering, key-management, and operational-security risk. Use before trusting external parties or changing sensitive crypto operations.
---

# Crypto Counterparty Security

## Overview

Turn vague "気をつけよう" warnings into an operational checklist for human-layer attack surfaces around crypto and agent work.

This also covers **package / skill / CI runner intake** where the weak point is provenance, hidden execution, maintainer trust, or runner isolation — not just whether the README looks legitimate.

This also covers **DeFi / vault / bridge / MM DD where the weak point is operational trust, dependency concentration, or human process**, not just smart-contract bugs.

This also covers **trading bot / market-making / prediction-market go-live risk** when the weak point is autonomy, sizing, adverse selection, toxic flow, kill switches, or venue dependency rather than the strategy code alone.

This also covers **crypto value-capture / distribution-layer risk**: a technically strong protocol, DEX, aggregator, or bot may create value while wallets, frontends, chains, custody rails, or other user-relationship owners capture pricing power and fees.

Read `references/checklist.md` when you need the concrete checklist and risk-rating table. Read `references/prediction-market-arbitrage-screening.md` when evaluating cross-platform prediction-market arbitrage spreads or PMbot go-live candidates.

## Core Output

Produce a **Counterparty Security Brief** with:
1. exposure map
2. red / yellow / green actions
3. isolation rules
4. verification steps before trust
5. escalation / refusal rules
6. dependency / control map when DeFi DD is involved
7. liquidity / redemption model when RWA or tokenized securities are involved

## Workflow

### 1. Map the contact surface

Identify:
- who introduced the counterparty
- where contact started
- what artifacts they want you to open, install, connect, or sign
- what assets are at risk: codebase, wallet, credentials, device, reputation, customer data

### 2. Classify requested actions by blast radius

Typical high-risk requests:
- clone this repo
- install this wallet / extension / desktop app
- join this TestFlight / beta
- run this script
- add this package / skill / action / MCP tool quickly before review
- attach this new self-hosted runner to CI or give it repo secrets
- open this document with macros or plugins
- connect this account or sign this message

If the request mixes trust-building and execution urgency, treat it as elevated risk.

For package / skill / CI intake, explicitly check:
- provenance: official source, maintainer continuity, recent ownership or publisher changes
- hidden execution: `postinstall` / lifecycle scripts, setup commands, curl-pipe-shell, remote fetch at runtime
- namespace risk: typosquat / dependency confusion / lookalike package or skill names
- privilege path: what secrets, repo write paths, CI tokens, or runner access it would gain
- rollback path: how to disable, remove, rotate secrets, and recover if the component is compromised

### 2.5 Map DeFi operational trust surfaces when relevant

For DeFi / vault / bridge / MM DD, explicitly map:
- signer / deployer / operator / upgrade-admin separation
- key custody and secret storage assumptions
- bridge / oracle / RPC / relayer / DVN dependencies
- single dependency vs redundancy / failover path
- pause / revoke / incident response authority and runbook
- whether "audited" is being used as a substitute for operational controls

For RWA / tokenized securities / stock tokens, also classify the liquidity design before treating the asset like normal DeFi liquidity:
- **AMM-only**: who absorbs price impact, how oracle/market price divergence is corrected, and what happens in thin liquidity
- **RFQ / issuer-inventory**: who quotes, what inventory or hedging source backs quotes, and whether issuer pricing creates counterparty concentration
- **Redemption / custody path**: who holds the underlying asset, redemption eligibility, settlement timing, jurisdiction, and halt/freeze authority
- **Market-structure mismatch**: on-chain 24/7 transfer vs underlying market hours, corporate actions, dividends, and off-chain trading halts
- **Exit risk**: maximum expected spread/discount under stress, not just normal quoted depth

### 2.6 Map trading bot / MM go-live risk when relevant

For LP bots, prediction-market MM, DEX market-making, arbitrage, or AI-assisted trading, explicitly separate **research edge** from **execution risk**:

- profitability evidence: proven / plausible / unknown / weak
- signal sanity: sample size, autocorrelation/regime split, slippage, fee break-even, delay sensitivity
- market-making edge vs information edge: spread capture, liquidity gaps, skilled-trader following, toxic flow, resolution ambiguity
- venue microstructure: order-flow transparency, adverse selection, MEV/front-running, maker/taker incentives, API/rate-limit failure
- go-live gates: paper duration, max position, max daily loss, kill switch, rollback owner, and human approval for each stage
- monitoring: stale quotes, unexpected exposure, fill failures, venue/API errors, and adverse selection alerts

Default: AI may research and code backtests, but must not be final authority for live execution, allocation size, or production go-live.

### 2.7 Map value-capture control when relevant

For DEX, x402, wallet, payment, LP/MM, prediction-market, or chain ecosystem strategy, separate **value creation** from **value capture** before recommending where to build or partner:

- who owns the user relationship: wallet, frontend, exchange, merchant, agent, chain, app, or API provider
- who controls distribution: default placement, routing, embedded checkout, aggregator ranking, integrations, KOL/channel access, or compliance gate
- who can charge or extract: spread, fees, rebates, subscription, order-flow, listing/access, infra margin, custody/redemption margin
- who is replaceable: commodity liquidity/protocol layer vs differentiated interface/trust/compliance layer
- dependency leverage: whether a protocol or bot depends on a frontend, RPC, oracle, wallet, chain grant, exchange, or partner that can reprice access
- defensibility: switching cost, trust surface, custody/regulatory moat, exclusive inventory, data advantage, or community/brand gravity

Default output line: `Value created by the technical layer is not automatically captured there; identify the distribution/user-relationship owner before treating protocol edge as business edge.`

### 3. Define safe handling rules

At minimum decide:
- what can be opened on the daily-use machine
- what requires isolated VM / throwaway account / separate device
- what requires second-person review
- what is rejected outright
- what cannot touch CI, self-hosted runners, or production secrets until provenance and rollback are documented

### 4. Preserve evidence and rationale

Capture:
- source link or handle
- date / channel
- requested action
- risk judgement
- allowed environment
- final decision

### 5. Convert lessons into policy

Do not stop at one-off advice. Turn repeated patterns into default operating rules for the team.

## Principles

- "Met in person" is not proof of safety
- Contact age is not proof of safety
- Never let partner urgency choose your execution environment
- Untrusted repos and beta apps belong in isolation first
- New packages, skills, and CI runners do not get trust before provenance and hidden-execution review
- Wallet and signing flows deserve stricter rules than normal SaaS onboarding
- "Audited" is not proof of operational safety
- Single dependency is often hidden leverage; map it before trusting yield
- Tokenized real-world assets are not interchangeable with normal AMM tokens; check issuer inventory/RFQ, custody, redemption, and market-hour mismatch before trusting quoted liquidity
- Refusal is cheaper than incident response

## Deliverable Format

Return:
- attack surface summary
- concrete do / don't rules
- environment separation guidance
- verification questions to ask the counterparty
- reusable policy lines for team rollout
- DeFi dependency / control checklist when relevant
