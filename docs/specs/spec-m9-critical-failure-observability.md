---
id: SPEC-0020
type: spec
title: Critical-failure observability and alert ownership
status: accepted
owners: ["@tech-lead", "@platform-owner", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-06
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
  - app/services/observability
  - config/initializers/observability.rb
enforced_by:
  - test/observability/telemetry_contract_test.rb
  - test/observability/redaction_test.rb
  - test/observability/failure_signals_test.rb
  - test/observability/alert_ownership_test.rb
  - test/observability/security_event_boundary_test.rb
  - test/system/critical_failure_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-OPS-001, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-OPS-001, SKILL-TEST-001]
---

# Critical-failure observability and alert ownership

> **Review state:** Accepted by the user on 2026-08-06 for the provider-neutral
> event, redaction, ownership, correlation, runbook, and controlled-failure
> baseline. Production collector, destination, and retention activation remain
> a separate human-owned decision.

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

### Included

- Define critical user-facing symptoms, thresholds, severity, owners, response
  windows, suppression, escalation, and runbook links.
- Define minimum metrics/logs/traces for HTTP, database, jobs, mail, WebSockets,
  authentication, session security, and academic-integrity events.
- Define correlation fields, release/environment dimensions, redaction,
  sampling, access, retention, and destination boundaries.
- Define controlled failure tests and provider-neutral operational evidence.
- Clarify the boundary between durable domain records and transient telemetry.

### Excluded

- Selecting a monitoring vendor, paid plan, alert destination, or cloud provider
  without the Platform/Security/Privacy decision.
- Logging request bodies, learner answers, passwords, cookies, reset links, or
  raw student identifiers for convenience.
- Treating `/up` as a full dependency health check without an accepted contract.
- Building a dashboard without an owner, threshold, response action, and runbook.
- Automatic production remediation or destructive incident actions.
- Selecting a hosted monitoring provider, paid plan, production destination, or
  new telemetry retention policy in this slice.

## Invariants

1. Every actionable signal has an owner, severity, symptom, threshold, response
   window, runbook, escalation route, and suppression policy before it can be
   connected to an alert destination.
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
8. Alert thresholds and signal ownership are versioned with an accountable
   owner and review date; telemetry retention remains the current log policy
   until separately accepted.

## Acceptance Criteria

- [x] The user approves the provider-neutral signal baseline, including critical
      symptoms, thresholds, owners, runbooks, correlation, redaction, and
      controlled verification; hosted destination and retention activation are
      explicitly deferred (`docs/decisions/adr-0020-critical-failure-observability.md`).
- [x] The repository records a provider-neutral event/metric contract for HTTP,
      database, jobs, mail, WebSockets, and security events
      (`test/observability/telemetry_contract_test.rb`).
- [x] Prohibited fields are rejected or redacted, including credentials, cookies,
      reset links, request bodies, learner answers, and direct student IDs
      (`test/observability/redaction_test.rb`).
- [x] Controlled failures produce approved signals and correlation context
      without changing learner/domain data (`test/observability/failure_signals_test.rb`).
- [x] Each actionable signal links to an executable runbook and an owner
      (`docs/runbooks/rb-critical-failure-observability.md`,
      `test/observability/alert_ownership_test.rb`).
- [x] Security and academic-integrity telemetry excludes learner identity and
      durable event payloads by default (`test/observability/security_event_boundary_test.rb`).
- [x] Thai/English user-facing behavior remains generic and does not expose
      operational telemetry or reset data (`test/system/critical_failure_walk_test.rb`).
- [x] Full repository verification passes (`bin/verify`).

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

The accepted baseline closes the instrumentation handoff. Production collector,
destination, retention, residency, and paging activation must reopen this table
before being treated as operational readiness.

| Review point | Accepted baseline |
| --- | --- |
| Critical symptoms | HTTP, database, job, mail, WebSocket, and security-event failures. |
| Targets | Versioned thresholds, severity, response windows, and suppression rules. |
| Ownership | Platform Owner for operational signals; Security Owner for audit failures; Tech Lead escalation. |
| Signal contract | Structured JSON events and Rails notifications with request/job, release, and environment context. |
| Privacy | Allow-listed fields; prohibited secrets, learner work, direct IDs, email, and IP data are redacted. |
| Security | Security audit failures emit action/error class only; durable records remain separate. |
| Provider | No vendor, paid plan, production destination, or residency decision in this slice. |
| Verification | Isolated contract, redaction, failure-signal, ownership, security-boundary, and system tests. |

## Rollback and observability

- Rollback removes new instrumentation or event subscribers without changing
  learner-facing domain operations; preserve existing logs and durable event
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
