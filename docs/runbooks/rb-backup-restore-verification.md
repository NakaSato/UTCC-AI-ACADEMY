---
id: RB-0003
type: runbook
title: Verify backup freshness and isolated restore evidence
status: draft
owners: ["@platform-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-06
updated: 2026-08-06
review_by: 2026-08-13
depends_on: [ADR-0020, ADR-0021]
touches:
  - config/database.yml
  - config/storage.yml
  - config/deploy.yml
  - app/services/recovery
  - docs/runbooks
enforced_by:
  - test/operations/backup_contract_test.rb
  - test/operations/restore_drill_test.rb
  - test/operations/recovery_integrity_test.rb
  - test/operations/restore_isolation_test.rb
agent_writable: true
---

# Verify backup freshness and isolated restore evidence

> This runbook defines the provider-neutral recovery contract. It does not
> contain provider credentials or select a managed database, object-storage,
> backup, or encryption provider. A real production drill requires the named
> owners to add provider-specific actions in an approved operational record.

## Preconditions

- The recovery owner has an approved, provider-generated backup manifest for
  PostgreSQL and the corresponding Active Storage data.
- The backup point is encrypted and the recovery owner can access the separate
  credential/key boundary without copying secrets into this repository.
- The restore target is isolated from production writes, outbound SMTP, real
  notifications, production WebSockets, and unapproved network access.
- The source backup is immutable for the duration of the drill and the target
  has enough capacity for database rows and attached blobs.
- Use synthetic or approved sanitized data whenever the provider supports it.

## Trigger and Symptoms

Run on the approved backup freshness cadence, at least quarterly, and after a
provider, schema, migration, storage, or credential-boundary change. Trigger an
incident when the newest backup is older than the one-hour RPO, a backup
manifest is invalid, a restore target is unsafe, an integrity check fails, or a
drill exceeds the four-hour RTO.

## Procedure

1. Record the release/artifact identity, drill ID, operator, source backup age,
   and target environment. Do not record credentials, raw learner data, reset
   links, or blob contents.
2. Validate that the manifest includes PostgreSQL rows, Active Storage blobs,
   encryption evidence, and integrity evidence. A database-only manifest is not
   complete.
3. Confirm the target isolation controls: production writes, outbound mail,
   notifications, and production WebSockets are disabled; credentials are
   non-production; the source is immutable.
4. Restore the database and storage surfaces using the approved provider action
   or isolated test adapter. Never restore over production.
5. Run schema/migration compatibility checks against the recovered database.
6. Validate foreign keys, safe row counts/checksums, Active Storage blob
   references, and blob checksums. Do not inspect learner answers or publish
   recovered content.
7. Boot the application in the isolated target and run safe smoke paths such as
   `/up`, sign-in with a synthetic identity, and a read-only learner screen.
8. Record backup age, restore duration, recovered release, integrity checks,
   smoke results, gaps, and owner sign-off. Emit the approved recovery signal
   for every failed check.

## Backup Failure

An invalid manifest or failed backup emits `recovery.backup.failure`. Preserve
the last valid backup, page the Platform Owner, and escalate to the Tech Lead
before the one-hour RPO is missed. Do not mark a provider's “success” response
as valid until scope, encryption, integrity, and storage coverage are checked.

## Stale Backup

A backup older than one hour emits `recovery.backup.stale`. Open one incident
per data class, identify the cause without exposing provider credentials, and
record whether the next successful backup restores the approved RPO.

## Restore Failure

An unsafe target, failed restore, or four-hour RTO breach emits
`recovery.restore.failure`. Stop the drill, preserve the source and evidence,
and do not repair production as part of the drill.

## Integrity Failure

Missing blobs, invalid foreign keys, incompatible schema, failed row counts, or
checksum mismatch emits `recovery.integrity.failure`. The restore is not valid;
keep the target isolated and escalate to the Platform and Security Owners.

## Rollback

Stop and destroy or quarantine only the isolated restore target according to the
provider's approved procedure. Never delete the source backup, encryption keys,
or evidence needed for a second attempt. Re-run the contract and focused tests
after changing recovery tooling.

## Verification

The repository validates the provider-neutral contract with synthetic data:

```bash
bin/rails test test/operations test/observability/recovery_signal_test.rb
```

This is not a witnessed production restore. Production readiness requires the
named owners to record provider evidence, target isolation, duration, checks,
gaps, and sign-off in a separate recovery record.

## Escalation

- Backup freshness, provider access, restore duration, or capacity: Platform Owner.
- Schema/migration compatibility or application smoke failure: Tech Lead.
- Encryption, credentials, isolation, missing data, or privacy exposure:
  Security Owner and Privacy Owner.
- RPO/RTO, retention, provider, cost, and drill-cadence changes: accountable
  human owners before implementation or production activation.
