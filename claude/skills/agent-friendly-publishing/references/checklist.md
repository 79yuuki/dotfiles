# Agent-Friendly Publishing Checklist

See also: `references/internal-prototype-publish-lane.md` for auth-gated demos, internal tools, and AI-built prototypes that need a safe share path before they become public surfaces.

## Minimum viable public pack
- Overview page
- Quickstart page
- Reference/API page
- Pricing + limits page
- Privacy / retention / safety / abuse page set
- Changelog page or feed
- Contact / support route
- `llms.txt` or equivalent crawler guidance when relevant
- `robots.txt` + `sitemap.xml`
- Canonical tags on current pages and redirect policy for deprecated pages when stale docs remain public

## Agent-readiness audit lens
- **Discoverability:** `robots.txt`, `sitemap.xml`, `Link` headers, stable canonical URLs
- **Content:** top summary, markdown output, explicit version/date, low-token readable structure
- **Bot access control:** crawler policy, AI training/input/search preferences, auth guidance
- **Capabilities:** API Catalog / agent-skills / OAuth discovery / MCP card when the product exposes tools

## Page templates

### Workflow-value narrative block
Use when the product is being framed too narrowly as a rail / protocol / API wrapper.
- workflow problem first
- tenant-scoped state
- approval / review checkpoints
- operator control surfaces
- audit trail / ownership boundaries
- primitive (payments / protocol / transport) as enabling layer, not headline

### Overview
- one-sentence what it is
- target user
- first action
- key links

### Quickstart
- prerequisites
- first successful action
- common failure cases

### Pricing / limits
- plans
- rate limits
- quota / usage model
- billing contact

### Policy set
- data collected
- retention period
- third-party sharing
- abuse / takedown route
- security contact

### Changelog
- date
- version
- what changed
- breaking changes
- migration notes

## Common smells
- pricing only in deck or sales memo
- policy only in legal PDF
- docs with no last-updated date
- quickstart missing copy-paste example
- status and changelog mixed together
- multiple contradictory explanations for the same feature
- deprecated pages rely on banners / `noindex` / canonical tags only, with no enforceable redirect path for crawlers
