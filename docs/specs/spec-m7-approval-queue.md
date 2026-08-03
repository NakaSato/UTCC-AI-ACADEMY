---
id: SPEC-0014
type: spec
title: Persisted admin approval queue and decisions
status: draft
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0014, ADR-0013, SPEC-0013]
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Persisted admin approval queue and decisions

> **Review state:** The first request kind is approved as a course lifecycle
> transition targeting one persisted `Course`, with admin/academic approval and
> append-only decision history. This specification remains draft while exact
> role mapping, allowed transitions, downstream effects, privacy, and SLA rules
> are defined.

> [Executable Specifications](README.md) ·
> [M7 approval queue decision](../decisions/adr-0014-approval-queue-records.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Problem

The admin queue looks like a work queue but has no records behind it. Its rows,
SLA figures, and pending badge cannot identify a requester, target, decision
authority, outcome, or downstream change.

## Scope

### Included after policy approval

- Create course lifecycle transition requests targeting one persisted `Course`.
- Persist approved request kinds, targets, requesters, status, and timestamps.
- Persist append-only decisions with actor, outcome, timestamp, and approved
  note fields.
- Render only pending and historical records that the current administrator is
  authorized to see.
- Implement approved decision actions and their transactionally coupled
  downstream effects.
- Replace fabricated SLA figures with calculations from persisted timestamps or
  remove them until a valid measurement exists.
- Record decision audit events without duplicating unnecessary personal data.

### Excluded

- Inventing request producers for access, course, content, or data workflows.
- Treating a decision or audit event as a substitute for the approved downstream
  state change.
- Generic arbitrary-target JSON with no kind-specific validation.
- Notifications, email, escalation, or SLA automation unless separately
  approved.
- Feature-flag persistence, course metadata editing, and academic certificate
  policy.

## Invariants

1. Every rendered queue row maps to one persisted approval request and stable
   target; no locale array supplies a request, timestamp, count, or status.
2. A request has one accepted kind and state, one requester, and the target
   required by that kind's policy.
3. A decision records actor, timestamp, outcome, request, and approved note
   fields immutably; later correction creates a new record rather than erasing
   history.
4. An actor cannot decide a request unless the approved kind-specific authority
   policy permits it and separation-of-duties rules pass.
5. A successful decision, downstream effect, current request status, and audit
   event commit or roll back together.
6. An already-decided, stale, invalid, or unauthorized request cannot create a
   second successful outcome or misleading audit event.
7. The pending badge and any SLA value are derived from persisted request
   timestamps and the approved timezone/window, or are absent.
8. Empty, filtered, and failed states are localized and never replaced by
   plausible sample rows.
9. Queue output contains only approved requester/target fields and never raw
   learner identifiers or private payloads beyond the policy minimum.
10. Non-admin users cannot read the queue or post a decision directly.

## Acceptance Criteria

- [ ] The Product Owner, Tech Lead, and Academic Owner approve request kinds,
      states, authority, target fields, downstream effects, and correction rules
      (`docs/decisions/adr-0014-approval-queue-records.md`).
- [ ] The queue renders persisted pending requests and a truthful empty state
      when none exist (`test/controllers/admin_queue_test.rb`).
- [ ] Request and decision models enforce approved kinds, state transitions,
      target presence, actor rules, and immutable decision history
      (`test/models/approval_request_test.rb`, `test/models/approval_decision_test.rb`).
- [ ] An approved decision changes its downstream target and writes exactly one
      audit event in the same transaction
      (`test/controllers/admin_queue_test.rb`).
- [ ] Repeated, stale, invalid, unauthorized, and failed decisions leave
      request, target, decision history, and audit log unchanged
      (`test/controllers/admin_queue_test.rb`).
- [ ] Pending badges and SLA values derive from timestamps or are not rendered
      (`test/models/approval_request_test.rb`).
- [ ] Thai and English browser walkthroughs cover pending, decided, and empty
      states without exposing unapproved personal data
      (`test/system/admin_queue_walk_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- No requests exist, or all requests are decided.
- A request points to a deleted, archived, or no-longer-eligible target.
- The requester attempts to decide their own request.
- Two administrators submit decisions concurrently.
- A downstream mutation fails after the decision begins.
- A decision note is blank, too long, or contains a learner identifier not
  allowed by policy.
- A request is withdrawn, expires, or is re-submitted after rejection.
- A non-admin requests the queue or posts a guessed request/decision ID.
- Thai and English readers see the same state and timestamp semantics.

## Human Approval Workflow Handoff

Implementation is held until the accountable owners complete this table. The
agent can model and test a recorded workflow, but cannot decide what an
institutional approval means or which actor may grant it.

| Review point | Decision required |
| --- | --- |
| Request kinds and producers | Name the first real workflows and their target records. |
| States and re-review | Define pending, approved, rejected, withdrawn, expired, and correction behavior. |
| Authority | Name deciding roles, separation-of-duties, and self-approval rules. |
| Downstream effects | State exactly what each decision changes and what remains pending. |
| History and rollback | Choose immutable decision history, correction, reversal, and retention behavior. |
| Privacy and display | Approve requester/target fields, note limits, localization, and access scope. |
| Time/SLA | Define timezone, business hours, stale threshold, and empty/SLA behavior. |

## Rollback and observability

- A failed migration or decision must preserve existing audit history and avoid
  applying a partial downstream mutation.
- Log decision failures by request kind and reason without raw private payloads.
- Monitor pending age, decision failures, and transaction rollback counts only
  after the owning workflow and timezone are approved.

## Verification

```bash
bin/docs
bin/rails test test/models/approval_request_test.rb test/models/approval_decision_test.rb
bin/rails test test/controllers/admin_queue_test.rb
bin/rails test:system test/system/admin_queue_walk_test.rb
bin/verify
```
