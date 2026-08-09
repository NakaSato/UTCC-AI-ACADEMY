---
id: REL-2026-08-06
type: release
title: Render production deployment boundary
status: planned
owners: ["@release-owner", "@platform-owner", "@tech-lead", "@security-owner"]
created: 2026-08-06
updated: 2026-08-07
version: boundary
risk_tier: C
includes: [SPEC-0022]
depends_on: [ADR-0020, ADR-0021, ADR-0022]
touches:
  - render.yaml
  - config/deploy.yml
  - .github/workflows/release-artifact.yml
  - .github/workflows/render-deploy.yml
  - docs/runbooks/rb-render-deployment.md
enforced_by:
  - test/release/artifact_provenance_test.rb
  - test/release/deployment_configuration_test.rb
  - test/release/release_gate_test.rb
agent_writable: true
deploy_strategy: rolling
rollback: Render rollback to the exact previously known-good image digest, or forward fix/recovery when database compatibility is absent
verify_after_deploy:
  - three /up checks succeed within 30 seconds
  - three synthetic authenticated reads succeed within two minutes
  - HTTP 5xx remains below one percent for the first 15 minutes
  - database, Solid Queue, WebSocket, storage, and recovery signals remain healthy
---

# Render production deployment boundary

## Changes

This is a deployment-boundary record, not an application release. The
production target is the Singapore Render web service at
academy.boring9.dev. Render pulls a prebuilt linux/amd64 image from GHCR.
GitHub Actions builds and scans the image after green CI, signs its digest,
records SBOM and provenance evidence, and the manual production workflow
promotes that digest through the Render deploy hook.

The service runs one web instance with Solid Queue in Puma, an attached
Active Storage disk at /rails/storage, and an external managed PostgreSQL
database supplied through DATABASE_URL. RAILS_MASTER_KEY and DATABASE_URL are
dashboard-owned secrets.

Production email is not enabled by this boundary. Mailpit remains limited to
local or isolated staging verification; real mailbox delivery requires the
separate MAIL-002 and MAIL-003 decision and evidence.

## Migration

- [ ] Expand: add only backward-compatible schema changes.
- [ ] Migrate: run bin/rails db:migrate as Render's pre-deploy command and
      record duration, errors, and compatibility evidence.
- [ ] Contract: remove old schema only in a later release after the previous
      image is no longer active.
- [ ] No destructive migration is approved by this boundary.

## Release-readiness review checklist

**Readiness state:** Not ready for production deployment. This checklist
prepares the human handoff; checking an item requires evidence from the named
owner. The agent must not check approval, credential, provider, rollback, or
production-observation items on a human owner's behalf.

### Artifact and supply chain

- [ ] CI is green for the exact source commit being released.
- [ ] The release manifest names the full GHCR image repository and immutable
      `sha256` digest.
- [ ] The manifest links the SBOM, Critical-vulnerability scan, signature, and
      build provenance for that same digest.
- [ ] Security Owner confirms the vulnerability result and any documented
      exception; no unapproved Critical finding remains.
- [ ] The deployed digest is independently confirmed to match the approved
      manifest; a mutable tag is not used as release or rollback identity.

### Target, secrets, and ownership

- [ ] Platform Owner confirms the Render service, Singapore region, domain/TLS,
      capacity, Active Storage disk, external PostgreSQL, and Solid Queue
      topology with provider evidence.
- [ ] Registry credential `utcc-ai-academy-ghcr` exists in the Render workspace
      and is scoped to the required package only.
- [ ] Required Render dashboard secrets (`RAILS_MASTER_KEY` and
      `DATABASE_URL`) exist, are access-reviewed, and are absent from Git,
      artifacts, logs, and chat.
- [ ] `RENDER_DEPLOY_HOOK_URL` is stored only as the GitHub Actions secret and
      the production environment has required reviewers.
- [ ] Release Owner, Platform Owner, Tech Lead, Security Owner, and On-call
      Owner are named for this release window and escalation path.

### Database, storage, and recovery

- [ ] Tech Lead reviews every migration using expand → migrate → contract and
      confirms compatibility with both the current and rollback images.
- [ ] Migration duration, lock impact, backup freshness, and replication/recovery
      evidence are recorded for the target environment.
- [ ] Active Storage persistence and restore evidence meet ADR-0021; no file
      or database data is assumed recoverable from the image.
- [ ] A witnessed pre-production deployment exercises migration failure,
      health failure, storage, jobs, WebSockets, and the exact rollback or
      forward-fix path.
- [ ] Release Owner records whether rollback is an image reversal, forward fix,
      or recovery procedure when data compatibility is absent.

### Approval and post-deploy evidence

- [ ] Release Owner approves the release window, abort thresholds, and exact
      artifact identity after the preceding evidence is complete.
- [ ] Production promotion is performed manually through the approved workflow
      and environment review; no local command or agent action deploys it.
- [ ] Three `/up` checks succeed within 30 seconds and three synthetic
      authenticated reads succeed within two minutes.
- [ ] HTTP 5xx remains below one percent for the first 15 minutes, with no
      unexpected migration error or failed smoke-path job.
- [ ] Database, Solid Queue, WebSocket, storage, observability, backup, and
      recovery signals remain healthy.
- [ ] The deploy identifier, digest, migration result, health evidence,
      operator, and outcome are recorded without secrets, reset links, learner
      data, or real-mail content.

### Human handoff record

| Owner | Evidence to attach | Status |
| --- | --- | --- |
| Platform Owner | Render target, registry, dashboard, storage, and database evidence | Pending |
| Security Owner | Artifact scan, signature/provenance, secret and access review | Pending |
| Tech Lead | Migration compatibility and application smoke review | Pending |
| Release Owner | Release-window approval and rollback authority | Pending |
| On-call Owner | Recovery, monitoring, escalation, and rollback rehearsal | Pending |

No production deployment, credential configuration, release approval, or
rollback claim is recorded by this checklist.

## Rollback Plan

The Release Owner or On-call Owner may stop promotion after three failed health
checks, an authenticated smoke failure, a migration failure, or more than one
percent HTTP 5xx responses in the first 15 minutes. The operator must confirm
that the target digest remains in GHCR and that the database is compatible.
Render rollback uses the exact known-good digest, never the mutable release
tag. If data compatibility is absent, use a forward fix or RB-0003 instead of
reversing the image.

## Post-release Verification

- Confirm three /up successes within 30 seconds.
- Confirm three synthetic authenticated reads within two minutes.
- Confirm the migration completed without an unexpected error.
- Confirm Solid Queue, WebSocket, storage, database, observability, and
  recovery signals remain healthy.
- Confirm no production check sent real mail or contacted Mailpit.
- Confirm the deployed digest equals the release manifest digest.
- Confirm backup and restore evidence remains within the ADR-0021 recovery
  contract.
- Preserve the Render deploy identifier and evidence; do not record secrets,
  reset links, or learner data.
