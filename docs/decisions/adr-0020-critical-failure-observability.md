---
id: ADR-0020
type: adr
title: Define critical-failure observability and alert ownership
status: draft
owners: ["@tech-lead", "@platform-owner", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: []
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
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-OPS-001, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-OPS-001, SKILL-SPEC-002]
---

# Define critical-failure observability and alert ownership

> **Decision state:** Agent-prepared draft. The Tech Lead, Platform Owner,
> Security Owner, and Privacy Owner must decide which failures require action,
> where signals may be sent, and who owns each response before instrumentation
> or alerts are added.

> [Decision Records](README.md) ·
> [M9 observability specification](../specs/spec-m9-critical-failure-observability.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Context

The application has a basic `/up` boot health endpoint, Rails and job logs, a
Solid Queue backend, password-reset mail, Action Cable notifications, and
security-relevant records such as `AuditEvent`, `ProctorEvent`, and `Session`.
The repository does not yet define a production monitoring contract for failed
jobs, mail delivery, WebSocket behavior, database capacity, application errors,
or security events. A green boot check therefore does not prove that the
academy can deliver mail, process jobs, serve authenticated screens, or surface
an integrity/security problem.

Adding a vendor or collecting every request body would create cost and privacy
risk without defining the user-visible failure or an owner who will respond.

## Problem frame

- **Affected user:** Learners and staff who currently may discover a broken
  background or application path only after a delayed or missing result; the
  on-call/platform owner who needs actionable evidence.
- **Current behavior:** `/up` checks that the app boots, while logs and durable
  tables exist without a named symptom metric, threshold, runbook, or alert
  owner for the critical dependencies.
- **Failure risk:** Silent mail/job/WebSocket/database failure, alert noise that
  is ignored, or telemetry that leaks student work, identifiers, credentials, or
  security details.
- **Success signal:** An owner can detect and triage an agreed critical failure
  within the agreed response window using redacted, correlated signals and an
  executable runbook.

## Decision

The design must establish a provider-neutral observability contract before a
provider or broad instrumentation is chosen:

1. Define critical user-facing symptoms and the minimum RED/USE signals for
   HTTP requests, database health/capacity, Solid Queue jobs, mail delivery,
   Action Cable/WebSockets, and authentication/security events.
2. Give every actionable alert one severity, owner, response window, runbook,
   suppression rule, and escalation path.
3. Carry a privacy-safe correlation/request identifier and release/environment
   metadata across logs, metrics, traces, jobs, and alerts where technically
   possible.
4. Redact credentials, session cookies, passwords, request bodies, learner
   answers, direct student identifiers, and unnecessary IP/profile data before
   telemetry leaves the application boundary.
5. Keep durable domain evidence (`AuditEvent`, proctor records, job failure
   records, mail delivery evidence) distinct from short-retention operational
   telemetry; one must not be treated as a substitute for the other.
6. Validate signals with controlled failure tests before calling the production
   path ready.

The provider, storage location, retention duration, and alert channel remain
human-owned decisions and are not selected by this draft.

## Alternatives

### Keep logs and `/up` only

This has minimal cost and no new telemetry surface, but it discovers many
failures through user reports and cannot reliably distinguish symptoms,
versions, or affected scope.

### Provider-neutral structured metrics and logs first

Define a small contract and emit aggregate signals that can later feed a chosen
backend. This limits lock-in and scope, but still requires an operational owner,
collection path, and a later provider decision.

### Adopt a full hosted observability platform now

This can provide dashboards, traces, alerting, and retention quickly, but creates
vendor, cost, data-transfer, and configuration commitments before the academy's
SLOs and privacy boundaries are approved.

### Store all events in the application database

This keeps data in one boundary, but adds write load, retention pressure, and
coupling between the user-facing path and its monitoring system.

No provider or final implementation option is selected by this draft.

## Consequences

- Monitoring becomes an owned operational capability rather than a collection of
  ad hoc log lines.
- Every alert adds response work; unowned or non-actionable alerts should not be
  created.
- Provider-neutral event names and redaction rules make later backend selection
  easier, but require disciplined schemas and compatibility tests.
- Security and academic-integrity events may need separate access, retention,
  and escalation from ordinary application errors.
- Controlled failure tests and runbooks become release evidence for critical
  background and real-time paths.

## Threat and privacy boundary

- Telemetry is an additional copy of data and must be treated as a separate
  trust boundary with access control, retention, and deletion rules.
- An exception or failed job may contain request parameters or student work;
  default event fields must be allow-listed, not serialized wholesale.
- Security signals must not reveal whether a student account exists to an
  untrusted caller, and alerts must not contain active reset links or cookies.
- Sampling and aggregation must preserve incident usefulness without making
  learner-level tracking the default.

## Fitness Functions

- Each actionable signal names a symptom, threshold, owner, severity, runbook,
  and escalation route; an unowned alert is rejected by review.
- A controlled job, mail, WebSocket, database, and application-error failure
  produces the intended signal without leaking prohibited data.
- Logs and metrics can be correlated by release/environment/request context
  without requiring a learner identifier or raw request body.
- A healthy `/up` response cannot be presented as proof that every required
  dependency is healthy unless the accepted policy explicitly defines it so.
