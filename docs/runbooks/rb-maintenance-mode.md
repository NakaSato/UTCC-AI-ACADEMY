---
id: RB-0006
type: runbook
title: Put the academy into maintenance mode and take it out again
status: draft
owners: ["@platform-owner", "@release-owner", "@on-call-owner"]
created: 2026-08-11
updated: 2026-08-12
review_by: 2026-08-26
depends_on: [ADR-0045, SPEC-0045, ADR-0022, SPEC-0022]
touches:
  - render.yaml
  - docs/maintenance.html
  - lib/error_pages.rb
  - lib/tasks/error_pages.rake
  - lib/templates/error_page.html.erb
  - vercel.json
enforced_by:
  - test/release/deployment_configuration_test.rb
  - test/lib/error_pages_test.rb
agent_writable: true
---

# Put the Academy Into Maintenance Mode and Take It Out Again

> [Runbooks](README.md) ·
> [Render deployment runbook](rb-render-deployment.md) ·
> [Error pages specification](../specs/spec-error-pages.md) ·
> [Rendered error pages decision](../decisions/adr-0045-rendered-error-pages.md)

> This runbook covers **planned** downtime only. An unplanned outage is
> RB-0002; nothing here brings a service back.

## What this can and cannot do

Render answers a maintained service with **503** and a page of our choosing.
That page is `docs/maintenance.html`, generated from the same locale copy as
`public/503.html` and published by the documentation site — it cannot live on
the academy's own domain, because the academy is what is unavailable.

**502 and 504 cannot be customised.** They are what Render's proxy emits when
the service is unreachable or too slow, and its blueprint exposes no hook for
them; a visitor meeting one sees Render's page, not the academy's.
`public/502.html` and `public/504.html` exist for a proxy that can be told
otherwise, and are not reachable through Render today. Do not promise a branded
502 to anyone.

## Preconditions

- [ ] The maintenance page is live and current:

      ```
      bin/rails error_pages:published
      ```

      It fetches the `uri` in `render.yaml` and fails unless the answer is a 200
      whose body is the page this repository generates — so a redirect, a 404, or
      a stale deploy each fail with the reason. It appears one deploy after the
      page is generated and merged: the documentation site builds on push to
      `main`, from this repository, on Vercel.
      The GitHub Pages workflow in `.github/workflows/pages.yml` is a second,
      currently failing publisher: its runs are refused for an account billing
      lock. It is **not** what serves this page, and the `github.io` address
      does not resolve. Do not point the `uri` at it.
- [ ] `bin/rails error_pages:check` passes, so the published page matches the
      copy in `config/locales`.
- [ ] The downtime is announced to whoever is teaching that day.
- [ ] You hold Render dashboard access for the `utcc-ai-academy` service.

> The URL has no `.html`. `vercel.json` sets `cleanUrls: true`, so the page is
> served at `/maintenance` and `/maintenance.html` answers 308. Checking it with
> a bare `curl -sI` reads that 308 as a live page and tells you nothing — which
> is how the `uri` sat pointing at a 404 for three days.

## Procedure

1. Confirm the page one more time — a maintenance page that 404s is worse than
   Render's default, because nobody will look again until the next outage:

   ```
   bin/rails error_pages:published
   ```

2. Turn maintenance **on** in the Render dashboard: *utcc-ai-academy →
   Settings → Maintenance Mode → Enabled*. It takes effect without a deploy.

   Do **not** flip `maintenanceMode.enabled` in `render.yaml` and deploy. That
   couples the switch to a release, ships a commit whose only content is an
   operational state, and leaves the repository claiming maintenance long after
   it ended. `render.yaml` carries the `uri` so the page is wired; the state
   belongs to the dashboard. `test/release/deployment_configuration_test.rb`
   fails if `enabled` is committed as `true`.

3. Verify from outside the network:

   ```
   curl -sI https://academy.boring9.dev/ | head -1     # expect 503
   ```

4. Do the work.

5. Turn maintenance **off** in the same place, and verify:

   ```
   curl -sI https://academy.boring9.dev/up | head -1   # expect 200
   ```

## Rollback

Maintenance mode has no rollback of its own — it is a toggle, and turning it
off is the whole of the reversal. If the service is still unhealthy once it is
off, the visitor now meets Render's 502 rather than the academy's 503, and this
is no longer planned downtime: follow RB-0002 and, if a release caused it,
RB-0004.

If the maintenance page itself is wrong — stale copy, broken layout — fix it in
`config/locales/*.yml`, run `bin/rails error_pages:build`, and merge to `main`;
the documentation site republishes on push. The page a visitor sees updates
without touching the service.

## Verification

- `curl -sI https://academy.boring9.dev/` returns 503 while on, 200 while off.
- The 503 body is the academy's page, in Thai and English, not Render's default.
- `bin/rails error_pages:check` passes on `main`.
- `bin/rails error_pages:published` passes, so the `uri` resolves to the current
  page rather than a redirect, a 404, or an older deploy.
- `test/release/deployment_configuration_test.rb` keeps `enabled: false` in the
  repository and the `uri` pointing at the path the documentation host serves
  the generated page at, `cleanUrls` included.

## Escalation

- **The page is challenged rather than served** (403, "Vercel Security
  Checkpoint") → the documentation host has bot protection or attack-challenge
  mode on, and it applies to every path including the dashboard itself. This
  began on 2026-08-12. A human browser may pass the interstitial; automation
  never will, and a visitor meeting a challenge during downtime is not being
  told the academy is down. Turn the protection off for this host, or move the
  page to one that does not challenge readers, before relying on maintenance
  mode. Platform Owner owns that call.
- Page renders but is not the academy's → the `uri` is unreachable; run
  `bin/rails error_pages:published`, which names the reason. If the page 404s,
  check that the last Vercel deploy of the documentation site succeeded: its
  build runs `bin/docs` and `script/validate-rendered-doc-links`, so a bad link
  anywhere in the documentation aborts it — and the previous deploy stays online
  looking current, which is how it went unnoticed for three days in August 2026.
  Then Platform Owner.
- Maintenance mode absent from the dashboard → it is a paid-plan feature; the
  service is on `starter`, so escalate to whoever owns the Render account.
- 502 or 504 instead of 503 → not maintenance mode; the service is genuinely
  failing. RB-0002.
