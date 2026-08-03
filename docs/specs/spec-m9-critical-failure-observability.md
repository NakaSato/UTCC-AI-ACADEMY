---
id: SPEC-0020
type: spec
title: Critical-failure observability and alert ownership
status: draft
owners: ["@tech-lead", "@platform-owner", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0020]
implemented_by: []
touches:
  - app/jobs
  - app/controllers
  - app/channels
  - app/mailers
  - config/environments/production.rb
  - config/ci.rb
  - config/recurring.yml
  - lib
  - docs/runbooks
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-OPS-001, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-OPS-001, SKILL-TEST-001]
---

# Critical-failure observability and alert ownership

> **Review state:** Draft and blocked on SLOs, alert ownership, telemetry
> destination, privacy/retention, and incident-response policy. No monitoring
> provider or production alert is implied by this document.

> [Executable Specifications](README.md) ·
> [M9 observability decision](../decisions/adr-0020-critical-failure-observability.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Problem

The repository can report that Rails boots at `/up`, but does not yet define
how the team detects or responds to failed application requests, Solid Queue
jobs, password-reset mail, Action Cable notifications, database capacity, or
security events. Logs and durable records exist, but critical failure evidence
is not consistently correlated, redacted, owned, or connected to a runbook.

## Scope

### Included after policy approval

- Define critical user-facing symptoms, baseline/target windows, thresholds,
  severity, owners, and runbooks.
- Define minimum metrics/logs/traces for HTTP, database, jobs, mail, WebSockets,
  authentication, session security, and academic-integrity events.
- Define correlation fields, release/environment dimensions, redaction,
  sampling, access, retention, and destination boundaries.
- Define controlled failure tests and operational review evidence.
- Clarify the boundary between durable domain records and transient telemetry.

### Excluded

- Selecting a monitoring vendor, paid plan, alert destination, or cloud provider
  without the Platform/Security/Privacy decision.
- Logging request bodies, learner answers, passwords, cookies, reset links, or
  raw student identifiers for convenience.
- Treating `/up` as a full dependency health check without an accepted contract.
- Building a dashboard without an owner, threshold, response action, and runbook.
- Automatic production remediation or destructive incident actions.

## Invariants

1. Every actionable alert has an owner, severity, symptom, threshold, response
   window, runbook, escalation route, and suppression policy.
2. Telemetry fields are allow-listed and redacted before emission; prohibited
   secrets, learner work, and unnecessary direct identifiers never enter the
   monitoring boundary.
3. Correlation context is stable across the relevant HTTP, job, mail, WebSocket,
   and security-event path without making learner identity the default key.
4. Durable domain evidence remains queryable independently of transient metrics,
   logs, traces, or alert delivery.
5. A failed dependency, queue, mail delivery, WebSocket path, or security event
   produces an observable outcome within the approved detection window, or the
   gap is explicitly documented.
6. Controlled failure tests do not send real learner data, real reset links, or
   production notifications.
7. Monitoring failure does not make the learner-facing request silently succeed
   or erase the underlying domain failure.
8. Alert thresholds and retention are versioned with an accountable owner and
   review date.

## Acceptance Criteria

- [ ] The Tech Lead, Platform Owner, Security Owner, and Privacy Owner approve
      the critical symptom matrix, SLOs/thresholds, owners, runbooks,
      destination, redaction, access, retention, and escalation policy
      (`docs/decisions/adr-0020-critical-failure-observability.md`).
- [ ] The repository records a provider-neutral event/metric contract for HTTP,
      database, jobs, mail, WebSockets, and security events
      (`test/observability/telemetry_contract_test.rb`).
- [ ] Prohibited fields are rejected or redacted, including credentials, cookies,
      reset links, request bodies, learner answers, and direct student IDs
      (`test/observability/redaction_test.rb`).
- [ ] Controlled failures produce the approved signals and correlation context
      without changing learner/domain data (`test/observability/failure_signals_test.rb`).
- [ ] Each actionable signal links to an executable runbook and an owner
      (`docs/runbooks/`, `test/observability/alert_ownership_test.rb`).
- [ ] Security and academic-integrity events have the approved access and
      retention boundary (`test/observability/security_event_boundary_test.rb`).
- [ ] Thai/English user-facing behavior remains truthful when a background or
      real-time dependency is unavailable (`test/system/critical_failure_walk_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- `/up` is healthy while the database, queue, mail provider, or WebSocket path
  is degraded.
- A job fails after its user-facing request already returned success, or a mail
  provider accepts a request but delivery later fails.
- The same failure repeats and would create alert storms or duplicate pages.
- A trace/log field contains a nested exception with a password, cookie, answer,
  or direct identifier.
- The telemetry destination is unavailable, delayed, sampled, or over quota.
- A release changes event fields or thresholds while an incident is active.
- An authentication, session, or proctoring event is sensitive enough to require
  a separate audience or retention rule.
- A controlled failure accidentally reaches a real external mail, alert, or
  learner-facing channel.

## Human Observability Handoff

Implementation is held until the accountable owners complete this table.

| Review point | Decision required |
| --- | --- |
| Critical symptoms | User-visible failures and detection windows. |
| Targets | SLOs, thresholds, severity, and alert-noise budget. |
| Ownership | On-call role, escalation, runbook, and response window per alert. |
| Signal contract | Metrics, logs, traces, correlation, sampling, and versioning. |
| Privacy | Redaction, access, retention, deletion, and student-data limits. |
| Security | Auth/session/proctoring event audience and escalation. |
| Provider | Destination, residency, cost, availability, and integration owner. |
| Verification | Controlled failure plan, review cadence, and rollback. |

## Rollback and observability

- Rollback removes new instrumentation or alert rules without changing the
  learner-facing domain operation; preserve the existing logs and durable event
  records according to their current policies.
- A monitoring destination outage must be visible to the Platform Owner but must
  not block ordinary learning writes unless the accepted safety policy requires
  a fail-closed path.
- Review alert volume, false positives, missed failures, response time, and
  redaction failures after controlled tests and real incidents.

## Verification

```bash
bin/docs
bin/rails test test/observability/telemetry_contract_test.rb test/observability/redaction_test.rb
bin/rails test test/observability/failure_signals_test.rb test/observability/alert_ownership_test.rb test/observability/security_event_boundary_test.rb
bin/rails test:system test/system/critical_failure_walk_test.rb
bin/verify
```
