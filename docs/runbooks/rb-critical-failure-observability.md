---
id: RB-0002
type: runbook
title: Triage critical failure telemetry
status: draft
owners: ["@platform-owner", "@security-owner", "@tech-lead"]
created: 2026-08-06
updated: 2026-08-06
review_by: 2026-08-13
depends_on: [ADR-0020]
touches:
  - app/services/observability
  - app/jobs/application_job.rb
  - app/controllers/application_controller.rb
  - app/channels/application_cable/connection.rb
  - app/models/audit_event.rb
enforced_by:
  - test/observability/telemetry_contract_test.rb
  - test/observability/alert_ownership_test.rb
agent_writable: true
---

# Triage critical failure telemetry

> This runbook covers the provider-neutral event contract shipped by M9-002.
> It does not select a hosted monitoring product, alert destination, or
> retention period. The Platform Owner must connect the events to an approved
> production collector before treating the signals as live alerts.

## Preconditions

- The operator has access to the approved environment log/metric collector,
  application release metadata, and the current deployment record.
- The operator does not copy cookies, passwords, reset links, request bodies,
  learner answers, direct student IDs, email addresses, or IP addresses into an
  incident channel.
- The event's `owner`, `severity`, `threshold`, `runbook`, `escalation`, and
  `suppression` fields are read from the same release as the application.

## Procedure

1. Search for the event name, release, environment, and correlation/request or
   job ID. Use the event's `fields.error_class`, `fields.operation`, or
   `fields.job_class` only; do not broaden the search to raw request payloads.
2. Confirm whether the symptom is isolated or crosses the event's threshold and
   suppression window.
3. Acknowledge the event within the response window in the contract and assign
   the named owner.
4. Compare the event timestamp with the deployment record and the health check.
   A healthy `/up` response proves boot only; it does not prove mail, jobs,
   database capacity, or WebSocket delivery.
5. Mitigate through the existing deployment/queue/provider procedures. Do not
   retry learner writes or delete durable domain records merely to clear a
   telemetry event.
6. Escalate according to the event's `escalation` field and record the
   redaction-safe timeline in the incident record.

## Signal-specific checks

### HTTP request failure

- Check the affected controller/action, status, release, and request ID.
- Compare 5xx rate with the 5-minute threshold and check whether authentication
  or learner writes are affected.
- If `/up` is green but requests fail, continue with application logs and the
  database/job signal instead of closing the incident.

### Database query failure

- Check the operation and error class, connection capacity, migrations, and
  database provider status.
- Preserve the original application error response; do not replay a write
  without confirming its transaction outcome.
- Escalate immediately when authentication, security records, or learner writes
  are affected.

### Job failure

- Check job class, queue, job ID, release, and retry state.
- Inspect the job's allow-listed failure context without serializing arguments.
- Confirm whether the user-facing request already returned and whether the
  affected operation has a safe idempotent recovery path.

### Mail delivery failure

- Check mailer/action and SMTP/provider health; never inspect or copy the
  message body, recipient, or reset URL into telemetry.
- Keep password-reset responses account-enumeration-safe and direct the user to
  the approved support path if delivery remains unavailable.
- Mailpit is a local/staging verification tool, not a production provider.

### WebSocket connection failure

- Exclude expected authentication denials from paging and check the error class,
  release, and connection rate.
- Compare Action Cable and database health; a destroyed/expired session should
  be rejected without being treated as a platform outage.
- Verify the notification path with a synthetic account only.

### Security audit failure

- Notify the Security Owner and Platform Owner immediately.
- Preserve the learner-facing transaction failure and determine whether the
  domain write rolled back; do not silently continue after an audit write fails.
- Restrict the incident audience to the approved security responders and record
  only action, error class, release, environment, and correlation context.

## Verification

Run the provider-neutral contract and failure tests in an isolated test
environment:

```bash
bin/rails test test/observability
bin/rails test:system test/system/critical_failure_walk_test.rb
```

These tests must not send real email, publish production notifications, use
learner data, or change production/domain records.

## Rollback

Remove or disable the new instrumentation subscribers and event emission while
preserving the existing learner-facing operation and durable domain records.
Do not delete logs or audit rows to hide an incident. Re-run the focused tests
and `bin/verify` after rollback.

## Escalation

- HTTP, database, job, mail, and WebSocket signals: Platform Owner.
- Security audit persistence failures: Security Owner and Platform Owner.
- Application behavior or release regression: Tech Lead.
- Vendor, destination, residency, cost, and retention decisions: Platform,
  Security, Privacy, and Repository Owners before production activation.
