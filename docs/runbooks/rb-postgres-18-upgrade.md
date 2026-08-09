---
id: RB-0005
type: runbook
title: Upgrade the production PostgreSQL database from 17 to 18
status: draft
owners: ["@platform-owner", "@tech-lead"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-16
depends_on: [RB-0003, RB-0004]
touches:
  - compose.yml
  - config/database.yml
  - docs/runbooks
enforced_by:
  - test/operations/database_version_test.rb
agent_writable: true
---

# Upgrade the production PostgreSQL database from 17 to 18

> Development and test already run PostgreSQL 18 (`postgres:18-alpine` in
> `compose.yml`), and the full test suite passes against 18.4. This runbook
> covers the remaining surface: the external managed PostgreSQL that production
> reaches through `DATABASE_URL`. The provider dashboard owns the instance and
> its version; no credential or provider identity is committed here.

## Why this app's exposure is small

- The schema uses no feature affected by the 18 compatibility notes: no
  full-text or `pg_trgm` indexes to reindex, no partitioned or unlogged
  tables, no table inheritance, and no deferred triggers.
- The app authenticates with a URL-supplied password over
  `sslmode=require`; SCRAM is the provider default, so the MD5 deprecation
  does not apply.
- The `pg` gem ships its own precompiled libpq, so no host client library
  needs upgrading alongside the server.

## Preconditions

- [ ] RB-0003 backup evidence is fresh: a provider-generated backup of the
      production database exists and its restore path has been verified.
- [ ] The provider offers an in-place major-version upgrade to 18, or a new
      18 instance plus a migration window has been approved.
- [ ] A maintenance window is agreed with the Release Owner; Solid Queue,
      Solid Cache, and Solid Cable all live in this database, so the app is
      fully down while the database is.

## Procedure

1. Announce the window per the Slack policy (`academy-alerts`, P2).
2. Suspend the Render service (or scale to zero) so no writes occur during
   the upgrade. Solid Queue runs inside Puma, so stopping the web service
   stops all workers.
3. Take a final provider backup and record its identifier in the release
   record for this change.
4. Run the provider's upgrade path:
   - **In-place upgrade:** trigger it from the provider dashboard and wait
     for the instance to report healthy on 18.
   - **New instance:** create the 18 instance, restore or `pg_dump | pg_restore`
     the final backup into it, then update `DATABASE_URL` in the Render
     dashboard. The URL is the whole connection; nothing in the repo changes.
5. Resume the service and verify:
   - `SELECT version();` reports PostgreSQL 18.x.
   - The health check and recovery signals in RB-0004's verification list are
     green (database, Solid Queue, WebSocket, storage).
   - A queued job executes and a page that reads course data renders.
6. Run `VACUUM (ANALYZE)` (or the provider's post-upgrade analyze) if the
   provider's path does not preserve optimizer statistics.
7. Close the window in Slack and record the outcome in a `release-*.md`
   entry, including the backup identifier and the old instance's retention
   date.

## Verification

- `SELECT version();` on the production `DATABASE_URL` reports PostgreSQL 18.x.
- `test/operations/database_version_test.rb` passes: the compose file pins
  `postgres:18-alpine` and the connected server reports `server_version_num`
  at or above 180000.
- The full suite (`bin/verify`) is green against an 18 server.
- RB-0004's post-deploy verification list is green after the service resumes:
  /up checks, synthetic authenticated reads, Solid Queue smoke job, WebSocket
  and storage reads, and 5xx below one percent for 15 minutes.
- The release record names the final pre-upgrade backup identifier and the
  old instance's retention date.

## Rollback

- **In-place upgrade failed:** restore the final pre-upgrade backup to a new
  17 instance per RB-0003 and point `DATABASE_URL` at it.
- **New-instance cutover failed:** point `DATABASE_URL` back at the untouched
  17 instance; it received no writes during the window.
- Keep the old instance or final backup until the acceptance checklist in the
  release record is complete.
