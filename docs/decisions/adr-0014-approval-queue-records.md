---
id: ADR-0014
type: adr
title: Define approval queue records and decision history
status: draft
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0013, SPEC-0013]
implemented_by: []
touches:
  - app/models/audit_event.rb
  - app/controllers/admin_controller.rb
  - app/views/admin/_queue.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define approval queue records and decision history

> **Decision state:** The user approved on 2026-08-04 that the first real
> request kind is a course lifecycle transition targeting one persisted
> `Course`, with admin/academic approval and append-only decision history.
> Exact role mapping, transition states, downstream effects, privacy, and SLA
> rules remain implementation prerequisites.

> [Decision Records](README.md) ·
> [M7 approval queue specification](../specs/spec-m7-approval-queue.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Context

The admin queue currently renders four hardcoded pending rows, static SLA
figures, and a pending badge. No request record, requester, target, decision,
actor, timestamp, or downstream effect exists. The two visible approval buttons
are intentionally absent because there is nowhere safe to write their result.

The queue must not become a generic JSON inbox that can claim an academic or
access decision happened without a durable target, authorized actor, and
recorded outcome. It also must not display a fabricated backlog when no real
request producer exists.

## Problem frame

- **Affected user:** An administrator reviewing requests that require a decision
  before a learner-facing or staff-facing change takes effect.
- **Current behavior:** Four sample rows look pending but cannot be traced to a
  requester or acted on.
- **Failure risk:** An admin may believe access, course, content, or data was
  approved when no state changed, or a decision may be overwritten without a
  history.
- **Success signal:** Every displayed queue row is a persisted request, every
  decision names actor/time/state, and the downstream effect is explicit and
  auditable.

## Decision boundary

1. Approval requests must be persisted records with a stable identifier,
   approved kind, requester, target, status, and timestamps.
2. Decision history must be durable and append-only; a current request status
   alone is not enough to explain who decided what and when.
3. The queue reads pending requests from the database. With no real requests it
   renders a truthful empty state rather than sample rows or static counts.
4. A decision is authorized by request kind and actor policy, is idempotent for
   an already-decided request, and runs in one transaction with its approved
   downstream effect and audit event.
5. A failed, unauthorized, stale, or already-decided action creates no new
   successful decision or misleading audit entry.
6. Requests and decisions must not store unnecessary learner data; the queue
   shows approved aggregate or identifying fields only.
7. A request producer is responsible for creating a request only after its own
   validation succeeds; the queue does not infer requests from arbitrary rows.

### Approved first request kind

The first producer is a course lifecycle transition request. Its target is one
persisted `Course` record. The decision uses append-only history and requires an
authorized administrative or academic approver; exact role mapping and allowed
transitions remain to be defined in the executable specification.

## Alternatives

### Request record plus immutable decision records

The request owns current status and target, while each decision is an append-only
record with actor, timestamp, outcome, and note. This preserves history and
supports correction or re-review policies, at the cost of an extra table and
transaction boundary. It is the recommended option.

### One mutable request row with decision columns

This is smaller, but a second decision overwrites the first unless a separate
audit convention is trusted to reconstruct history. It is insufficient for
institutional or access decisions where history matters.

### Reuse `AuditEvent` as the queue

Audit events record what happened, not a pending request with a target, current
status, or decision authority. Treating them as a work queue would mix immutable
history with mutable workflow state and is rejected.

### Keep the queue as a read-only placeholder

This avoids a premature workflow policy but leaves administrators looking at
fictional requests. It is acceptable only as a temporary state while the queue
is changed to a truthful empty state and the records remain deferred.

## Human decisions required

- Which request kinds are real in M7 and what target record each kind names.
- Required request fields, requester roles, target visibility, and retention.
- Request states and allowed transitions, including withdrawal, expiry,
  rejection, re-submission, and re-review.
- Decision authority by kind, separation-of-duties rules, and whether the
  requester may decide their own request.
- Exact downstream effect of approval/rejection for access, courses, content,
  and data; an audit row alone is not an effect.
- Whether decisions may be corrected, reversed, or superseded and how that is
  shown to the requester.
- Note content, privacy, localization, notification, SLA, and timezone rules.
- Which existing workflows will create the first real requests.

## Consequences

- The first queue implementation may show an empty state until a real producer
  exists; this is more trustworthy than preserving the current sample rows.
- Immutable decision history supports audit and review, but requires clear
  correction semantics and careful transaction boundaries.
- Each request kind needs a narrow adapter for authorization and downstream
  effects rather than a controller full of kind-specific conditionals.
- Static SLA cards must be removed or computed only from persisted timestamps.

## Fitness Functions

- `bin/docs` validates the decision record and human-review metadata.
- Model and controller tests prove request visibility, authorization,
  idempotency, transaction rollback, and decision history.
- A browser walkthrough shows real pending, decided, and empty states in Thai
  and English.
- Audit tests prove every successful decision has actor, time, state, and target
  context without leaking unnecessary learner data.
