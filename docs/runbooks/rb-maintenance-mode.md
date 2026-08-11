---
id: RB-0006
type: runbook
title: Put the academy into maintenance mode and take it out again
status: draft
owners: ["@platform-owner", "@release-owner", "@on-call-owner"]
created: 2026-08-11
updated: 2026-08-11
review_by: 2026-08-25
depends_on: [ADR-0045, SPEC-0045, ADR-0022, SPEC-0022]
touches:
  - render.yaml
  - docs/maintenance.html
  - lib/error_pages.rb
  - lib/templates/error_page.html.erb
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

- [ ] The maintenance page is live. Open
      <https://nakasato.github.io/UTCC-AI-ACADEMY/maintenance.html> and confirm
      it returns 200 and renders in Thai and English.
      **As of 2026-08-11 it does not**: the documentation site has never
      published, because every GitHub Actions run is refused with *"the job was
      not started because your account is locked due to a billing issue"*.
      Until that is cleared, turning maintenance on shows **Render's default
      page**, not the academy's — the wiring is correct and inert.
- [ ] `bin/rails error_pages:check` passes, so the published page matches the
      copy in `config/locales`.
- [ ] The downtime is announced to whoever is teaching that day.
- [ ] You hold Render dashboard access for the `utcc-ai-academy` service.

## Procedure

1. Confirm the page one more time — a maintenance page that 404s is worse than
   Render's default, because nobody will look again until the next outage:

   ```
   curl -sI https://nakasato.github.io/UTCC-AI-ACADEMY/maintenance.html | head -1
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
- `test/release/deployment_configuration_test.rb` keeps `enabled: false` in the
  repository and the `uri` pointing at the generated page.

## Escalation

- Page renders but is not the academy's → the `uri` is unreachable; check the
  documentation site deployed, then Platform Owner.
- Maintenance mode absent from the dashboard → it is a paid-plan feature; the
  service is on `starter`, so escalate to whoever owns the Render account.
- 502 or 504 instead of 503 → not maintenance mode; the service is genuinely
  failing. RB-0002.
