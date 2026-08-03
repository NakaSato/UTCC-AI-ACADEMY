---
id: SPEC-0021
type: spec
title: Backup, restore, and recovery verification
status: draft
owners: ["@platform-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0021, ADR-0020]
implemented_by: []
touches:
  - config/database.yml
  - config/storage.yml
  - config/deploy.yml
  - db
  - docs/runbooks
  - docs/releases
  - lib
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-003, SKILL-BLD-003, SKILL-BLD-004, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-BLD-003, SKILL-BLD-004]
---

# Backup, restore, and recovery verification

> **Review state:** Draft and blocked on RPO/RTO, provider, retention,
> credential, privacy, storage, and restore-drill policy. No production backup
> or restore is claimed by this document.

> [Executable Specifications](README.md) ·
> [M9 recovery decision](../decisions/adr-0021-backup-restore-verification.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Problem

The production database is external to the application deployment, while local
Active Storage uses a persistent volume. The repository does not define how
these surfaces are backed up together, how quickly they must be recovered, how
the restore is isolated, or what evidence proves the restored application is
usable.

## Scope

### Included after policy approval

- Inventory database, blob/storage, configuration, key, and provider state
  required for application recovery.
- Define backup schedule, RPO, RTO, retention, encryption, immutability,
  residency, access, and deletion rules.
- Define a provider-supported backup and isolated restore target.
- Create an executable recovery runbook and release/migration compatibility
  checks.
- Verify database/blob referential integrity, schema compatibility, safe boot,
  disabled outbound side effects, and approved smoke paths.
- Record backup freshness, integrity, restore duration, validation results, gaps,
  and accountable sign-off.

### Excluded

- Selecting a managed database, object-storage, backup, or encryption provider
  without a Platform Owner decision.
- Restoring over production or using production credentials in a test target.
- Treating a Docker volume, Git checkout, image rollback, or `/up` response as a
  complete backup.
- Copying raw learner data into development, fixtures, logs, or public artifacts.
- Claiming recovery readiness without a witnessed restore drill and evidence.

## Invariants

1. Every authoritative data class has an approved backup owner, schedule,
   retention, encryption, access, and recovery target.
2. Database rows and referenced Active Storage blobs are recovered together or
   the missing dependency is detected before the restore is declared valid.
3. Restore verification runs in an isolated environment with outbound mail,
   notifications, WebSockets, and production writes disabled or safely routed.
4. Backup and restore credentials, keys, reset links, and learner data do not
   appear in Git, logs, alerts, runbooks, or test output.
5. The restore process is repeatable, observable, time-bounded by the approved
   RTO, and safe to retry without overwriting the source.
6. Current application code and migrations are tested against the restored
   schema/data before recovery readiness is claimed.
7. A failed backup, stale backup, corrupt archive, missing blob, incompatible
   schema, or failed smoke check produces an explicit failure signal and owner.
8. Restore evidence records what was tested, when, with which version, target,
   sanitized dataset, duration, checks, and unresolved gaps.

## Acceptance Criteria

- [ ] The Platform Owner, Tech Lead, Security Owner, and Privacy Owner approve
      the data inventory, RPO, RTO, schedule, retention, encryption, provider,
      restore target, credential boundary, and drill cadence
      (`docs/decisions/adr-0021-backup-restore-verification.md`).
- [ ] An executable recovery runbook names preconditions, isolation controls,
      backup/restore commands or provider actions, validation, rollback, and
      escalation (`docs/runbooks/rb-backup-restore-verification.md`).
- [ ] A backup check verifies freshness, scope, integrity, encryption, and
      retention without exposing secrets (`test/operations/backup_contract_test.rb`).
- [ ] An isolated drill restores database and storage state, runs migrations or
      compatibility checks, and records duration against the approved RTO
      (`test/operations/restore_drill_test.rb`).
- [ ] Referenced blobs, foreign keys, row counts/checksums, and safe application
      smoke paths are validated (`test/operations/recovery_integrity_test.rb`).
- [ ] Restored environments cannot send real mail, publish notifications, open
      production WebSockets, or write to production (`test/operations/restore_isolation_test.rb`).
- [ ] Backup/restore failures are observable through the approved M9 monitoring
      contract (`test/observability/recovery_signal_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- A database snapshot exists but is stale, incomplete, corrupt, or inaccessible.
- Database rows restore successfully while an Active Storage blob is missing or
  belongs to a different snapshot point.
- The restored schema is older/newer than the deployed application or a pending
  migration cannot run safely.
- A restore target has real SMTP, notification, Action Cable, credentials, or
  network access that could cause production side effects.
- The provider reports backup success but the archive cannot be downloaded or
  decrypted by the recovery owner.
- RPO or RTO is missed, a drill fails midway, or a second operator must take
  over without hidden credentials.
- A restore includes personal or academic data that must be sanitized, deleted,
  or access-reviewed after validation.
- A provider outage prevents both backup creation and monitoring delivery.

## Human Recovery Handoff

Implementation and operational use are held until the accountable owners
complete this table.

| Review point | Decision required |
| --- | --- |
| Data inventory | Database, blobs, secrets, provider state, and dependencies. |
| Recovery targets | RPO, RTO, availability window, and acceptable data loss. |
| Backup policy | Schedule, retention, encryption, immutability, residency, deletion. |
| Restore target | Isolation, capacity, network, credentials, sanitization, access. |
| Compatibility | Release/migration order and schema/blob validation. |
| Operations | Runbook owner, drill cadence, evidence, escalation, and cost. |
| Monitoring | Freshness, failure, restore duration, integrity, and alert thresholds. |

## Rollback and observability

- If a drill fails, preserve the source and backup evidence, stop the unsafe
  procedure, document the gap, and return the isolated target to its approved
  state; never “repair” production as part of a drill.
- Rollback of recovery tooling must not remove backups, keys, or evidence needed
  for the next attempt.
- Monitor backup age, failed jobs, archive integrity, restore duration, missing
  blobs, schema incompatibility, and validation failures without logging raw
  learner content.

## Verification

```bash
bin/docs
bin/rails test test/operations/backup_contract_test.rb test/operations/restore_drill_test.rb
bin/rails test test/operations/recovery_integrity_test.rb test/operations/restore_isolation_test.rb test/observability/recovery_signal_test.rb
bin/verify
```
