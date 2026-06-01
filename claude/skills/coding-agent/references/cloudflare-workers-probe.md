# Cloudflare Workers probe slice

Use this when adding a small Cloudflare Workers deploy target to an existing TS/Node repo, especially to test whether a globally hosted Worker can reach an upstream API.

## Minimal implementation pattern

- Add a dedicated Worker entrypoint under `src/workers/<probe>.ts` instead of mixing the probe into the main Node runtime.
- Keep the Worker dependency-light: use platform `fetch`, `Request`, `Response`, and env vars only.
- Provide two endpoints:
  - `GET /health` — no upstream calls; verifies Worker routing/bundle is alive.
  - `GET /probe` — calls the upstream(s), returns JSON with `ok`, elapsed timings, HTTP status, content-type, small response sample, and Cloudflare `request.cf` metadata such as colo/country when available.
- Keep probe samples capped (for example 600 chars) so logs and Slack reports do not become noisy.
- Return non-2xx (usually 502) when any required upstream probe fails, while still including per-target diagnostics.

## Wrangler setup

Add `wrangler.toml` with:

```toml
name = "<worker-name>"
main = "src/workers/<probe>.ts"
compatibility_date = "YYYY-MM-DD"
workers_dev = true

[vars]
UPSTREAM_API_URL = "https://example.com"
PROBE_TIMEOUT_MS = "8000"
```

Add scripts:

```json
{
  "worker:dev": "wrangler dev",
  "worker:deploy": "wrangler deploy",
  "worker:tail": "wrangler tail <worker-name>"
}
```

Install Wrangler as a dev dependency when the repo does not already pin it:

```bash
npm install --save-dev wrangler@^4
```

## Verification sequence

1. Format/check only the files you changed first, especially in repos with existing lint debt:
   `npx biome check --write src/workers/<probe>.ts src/workers/<probe>.test.ts`
2. Run typecheck and targeted tests:
   `npm run typecheck && npm run test:run -- src/workers/<probe>.test.ts`
3. Run a deploy dry-run before real deploy:
   `npx wrangler deploy --dry-run`
4. Real deploy requires Cloudflare auth in non-interactive runs:
   `CLOUDFLARE_API_TOKEN=... npm run worker:deploy`
5. After deploy, hit:
   `https://<worker-name>.<account-subdomain>.workers.dev/probe`
   and verify `ok: true` plus Cloudflare `cf` metadata is present.

## Pitfalls

- Do not turn a missing `CLOUDFLARE_API_TOKEN` into a general claim that Wrangler/deploy is broken. It is a setup step: set `CLOUDFLARE_API_TOKEN` or run authenticated Wrangler interactively.
- If full repo lint fails with unrelated pre-existing errors, explicitly report that the changed files were formatted/checked and list full-lint as blocked by existing debt. Do not auto-format unrelated dirty files unless the task is lint cleanup.
- Prefer `wrangler deploy --dry-run` before touching remote state; it verifies bundling and bindings without requiring a successful production deploy.
