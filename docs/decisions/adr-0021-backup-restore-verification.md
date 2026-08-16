---
id: ADR-0021
type: adr
title: Define backup, restore, and recovery verification
status: accepted
owners: ["@platform-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-06
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: [ADR-0020]
implemented_by: []
touches:
  - config/database.yml
  - config/storage.yml
  - config/deploy.yml
  - db
  - docs/runbooks
  - docs/releases
  - lib
  - app/services/recovery
enforced_by:
  - test/operations/backup_contract_test.rb
  - test/operations/restore_drill_test.rb
  - test/operations/recovery_integrity_test.rb
  - test/operations/restore_isolation_test.rb
  - test/observability/recovery_signal_test.rb
agent_writable: true
requires_skills: [SKILL-ARCH-001, SKILL-ARCH-002, SKILL-BLD-003, SKILL-BLD-004, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-003, SKILL-BLD-003, SKILL-BLD-004]
---

# Define backup, restore, and recovery verification

> **Decision state:** Accepted by the user on 2026-08-06 for a provider-neutral
> recovery baseline. PostgreSQL and Active Storage are recovered together under
> a one-hour RPO, four-hour RTO, isolated target, integrity checks, and quarterly
> drill cadence. Provider, retention, and production credential activation
> remain human-owned.

> [Decision Records](README.md) ·
> [M9 recovery specification](../specs/spec-m9-backup-restore-verification.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Context

Production is configured to use an external managed PostgreSQL database through
`DATABASE_URL`. Kamal does not run or back up that database. Active Storage is
configured to use a local persistent volume, and academic-post images or other
blobs therefore have a separate recovery surface from database rows. The
repository has no provider-specific backup contract, restore runbook, recovery
targets, or exercised restore evidence.

The database contains account, learning, assessment, academic, audit, session,
queue, cable, and notification data. A database-only restore could lose attached
files; a volume-only restore could leave database references inconsistent. A
snapshot that exists but has never been restored is not recovery evidence.

## Problem frame

- **Affected user:** Learners and staff who depend on progress, academic posts,
  course records, and operational history surviving provider failure or data
  corruption; the on-call/platform owner responsible for recovery.
- **Current behavior:** The app can boot against a configured database and local
  storage volume, but backup cadence, retention, encryption, restore isolation,
  recovery targets, and validation are not recorded or tested.
- **Failure risk:** Data loss beyond an unknown tolerance, unrecoverable file
  references, a restore that cannot run the current code, leaked personal data
  in a test environment, or a recovery action that overwrites the source.
- **Success signal:** A named owner can restore an isolated, representative
  copy within the approved RTO, demonstrate an approved RPO, validate the
  application and data invariants, and document the result without exposing
  production secrets or learner data.

## Decision

The accepted recovery baseline covers the complete authoritative data set rather
than only the primary database:

1. Inventory PostgreSQL data, Active Storage blobs, deployment/configuration
   metadata, encryption keys, and any external provider state required to boot
   and serve the application.
2. Use an RPO of at most one hour and an RTO of at most four hours. Verify
   backup freshness at least hourly and exercise the recovery contract at least
   quarterly and after provider, schema, migration, storage, or credential
   boundary changes. Retention duration remains deferred.
3. Require a provider-supported backup method for managed PostgreSQL and a
   corresponding Active Storage backup at a compatible point, with a separate
   or isolated restore target. No restore drill may overwrite production.
4. Produce an executable runbook covering backup verification, isolated restore,
   schema/migration compatibility, blob/database consistency, secrets handling,
   smoke tests, escalation, and rollback to the source environment.
5. Exercise the runbook on the approved quarterly cadence with sanitized or
   synthetic data where possible, recording duration, recovered version,
   validation results, gaps, and owner sign-off. The repository baseline uses
   synthetic manifests and does not claim a witnessed production restore.
6. Connect failed backup, stale backup, restore, and capacity signals to the
   observability contract in ADR-0020.

The backup provider, exact production targets, retention values, and restore
credentials remain human-owned decisions and are not selected by this baseline.

## Alternatives

### Rely on managed-provider backups only

This minimizes application complexity and may provide PITR and snapshots, but
the academy still needs provider evidence, access ownership, a blob strategy,
and an independent restore drill.

### Scheduled logical database dumps plus storage archives

This can be portable and easy to inspect, but may be slower at scale, requires
secure key management, and needs careful ordering for database/blob consistency.

### Provider backups plus independent recovery copies

This reduces provider lock-in and correlated failure risk, but increases cost,
retention, encryption, access review, and operational complexity.

### Treat deployment rollback as recovery

Reverting an image can restore code, not deleted or corrupted learner data. It
is not a backup or restore strategy.

### Approved policy direction

Provider-supported managed PostgreSQL recovery plus a corresponding Active
Storage backup is selected as the policy shape. The repository implements the
provider-neutral manifest, isolation, integrity, RPO/RTO, telemetry, and drill
contract; provider commands and credentials require a later operational record.

## Consequences

- Recovery becomes a recurring operational responsibility with a named owner,
  review cadence, cost, and drill evidence.
- Database schema changes and Active Storage changes must be considered together
  when defining restore compatibility and release order.
- Restored data may contain sensitive learner and institutional information;
  isolation, sanitization, access, and deletion are part of the procedure.
- A restore drill can reveal provider, migration, capacity, or application gaps
  that must create bounded backlog work rather than being hidden as a pass.
- The baseline intentionally does not add a backup service, credentials, or
  production provider dependency to the application.

## Recovery boundary

- Backup credentials and encryption keys are not stored in Git, logs, runbooks,
  or test fixtures.
- A restore target is isolated from production network writes, outbound mail,
  active WebSocket clients, and real notification channels.
- Verification uses counts, checksums, referential integrity, selected safe
  smoke paths, and synthetic identities; it does not require reading raw learner
  answers or publishing restored content.
- The runbook distinguishes backup existence, backup freshness, restore success,
  application compatibility, and business-data validation; one check cannot
  stand in for all five.

## Fitness Functions

- A backup is not marked successful unless its completion, age, integrity, scope,
  encryption, and retention evidence meet the approved policy.
- A restore drill reconstructs database rows and attached blobs sufficiently to
  pass the approved integrity and application smoke checks in isolation.
- The restored application cannot send real mail, mutate production, or expose
  restored learner data to an unapproved actor.
- A migration or release that cannot read the approved restored state is blocked
  from release until the compatibility gap has an accepted plan.
- A synthetic contract test is not a witnessed provider restore; operational
  readiness remains gated on human-owned provider evidence and sign-off.
