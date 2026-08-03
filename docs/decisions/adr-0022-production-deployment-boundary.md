---
id: ADR-0022
type: adr
title: Define the production deployment, artifact, and rollback boundary
status: draft
owners: ["@platform-owner", "@tech-lead", "@security-owner", "@release-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0020, ADR-0021]
implemented_by: []
touches:
  - config/deploy.yml
  - Dockerfile
  - .github/workflows/ci.yml
  - bin/kamal
  - config/database.yml
  - config/environments/production.rb
  - docs/build-release.md
  - docs/releases
  - docs/runbooks
  - db
  - lib
enforced_by: []
agent_writable: true
requires_skills: [SKILL-ARCH-001, SKILL-ARCH-002, SKILL-BLD-002, SKILL-BLD-003, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-BLD-002, SKILL-BLD-003]
---

# Define the production deployment, artifact, and rollback boundary

> **Decision state:** Agent-prepared draft. The Platform Owner, Tech Lead,
> Security Owner, and Release Owner must select the real target and accept the
> artifact, migration, rollback, and post-deploy controls before placeholder
> deployment settings are replaced.

> [Decision Records](README.md) ·
> [M9 deployment specification](../specs/spec-m9-production-deployment.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Context

`config/deploy.yml` still names a private placeholder host, a localhost image
registry, and commented example TLS/registry settings. The repository's build
policy requires one immutable image, provenance, SBOM, signing, manual release
approval, rollback evidence, and post-deploy checks, but those controls are not
connected to a real production target. The database is external through
`DATABASE_URL`, Active Storage uses a persistent volume, and Solid Queue may run
inside the web process until the deployment shape is approved.

A deployment is therefore more than filling in a host name. It determines where
learner data, secrets, logs, images, storage, database connections, jobs,
WebSockets, and recovery controls live, and whether a code rollback is safe
against the current database schema.

## Problem frame

- **Affected user:** Learners and staff relying on a reachable, correctly
  configured academy; the platform/release owner responsible for safe changes.
- **Current behavior:** Local CI and image build paths exist, but the production
  host, domain/TLS, registry, secret store, process split, release approval,
  migration procedure, rollback command, and post-deploy checks are placeholders
  or policy text only.
- **Failure risk:** Deploying to the wrong target, exposing secrets, running
  incompatible migrations, losing background/WebSocket work, rebuilding an
  unverified image, or discovering failure without a tested rollback.
- **Success signal:** A named release can promote the tested artifact to a real
  target, run a compatible migration sequence, verify user-visible health, and
  return to the last known-good state using an exercised procedure.

## Decision

The production deployment contract must define:

1. The authoritative hosting target, region/data residency, domain, TLS
   termination, network boundary, database provider, Active Storage provider or
   volume, registry, and job/WebSocket process topology.
2. A build-to-release identity: commit/specification, immutable image digest,
   SBOM, vulnerability result, signature/provenance, environment, and approver.
3. Secret injection and rotation without repository, image, log, or release-note
   exposure; production credentials must be scoped to the required service.
4. Expand → migrate → contract rules for database changes, including how the
   previous image behaves during a rolling deployment and which migrations cannot
   be rolled back.
5. A Release Owner and On-call Owner, manual approval, deploy window, abort
   criteria, exact rollback action, migration/data compatibility rule, and
   numeric post-deploy checks.
6. Separate runbooks for deployment, rollback, failed migration, job recovery,
   and dependency/health verification, linked to the observability and recovery
   contracts in ADR-0020 and ADR-0021.

The hosting provider, registry, domain, region, and process topology remain
human-owned decisions and are not selected by this draft.

## Alternatives

### Complete the Kamal target

Use the repository's existing container/deploy path with a real host, registry,
secrets, TLS, volumes, and external services. This keeps the operational model
close to the repository, but leaves the team responsible for host, capacity,
patching, registry, and rollback operations.

### Use a managed application platform

Delegate host and rolling-deploy mechanics to a managed platform while keeping
the image and release contract. This may reduce operations work, but introduces
provider-specific networking, storage, logs, and deployment semantics.

### Keep production deployment deferred

Retain local/CI verification and do not claim production readiness. This avoids
unsafe infrastructure commitments, but delays real learner access and production
recovery learning.

### Deploy directly from mutable source or rebuild per environment

This may be convenient, but makes the tested artifact differ from the deployed
artifact and prevents reliable provenance or rollback. It is rejected.

No target or provider is selected by this draft.

## Consequences

- Production readiness becomes a coordinated platform, security, release,
  database, and recovery decision rather than a config-only change.
- An immutable artifact and manual approval add release steps, but make the
  deployed version and rollback target inspectable.
- Rolling deployment and schema changes require compatibility planning and may
  split a feature across multiple releases.
- Real infrastructure introduces recurring cost, access review, patching,
  capacity, and incident-response obligations.

## Supply-chain and rollback boundary

- The registry, builder, base image, dependencies, SBOM, signature, provenance,
  and deployment identity are part of the release trust boundary.
- A Git revert or previous image is not sufficient rollback when a migration or
  data transformation is not backward-compatible; the release record must name
  the safe data action or explicitly block rollback.
- Release logs and notifications must contain artifact identifiers and links,
  never credentials, raw learner data, reset links, or database URLs.

## Fitness Functions

- A production release cannot proceed without a real target, named owners,
  approved artifact identity, migration plan, rollback action, and post-deploy
  checks.
- The deployed digest matches the independently verified artifact digest and
  its recorded source/provenance.
- A controlled staging deployment demonstrates health, database compatibility,
  job processing, mail safety, WebSocket behavior, storage access, and rollback.
- A release fails closed when required secrets, TLS, backup/recovery evidence,
  or observability ownership is absent.
