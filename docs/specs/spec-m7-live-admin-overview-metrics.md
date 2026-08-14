---
id: SPEC-0012
type: spec
title: Live admin Overview metrics
status: accepted
owners: ["@product-owner", "@tech-lead", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-14
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0012, SPEC-0008]
implemented_by: [M7-001]
touches:
  - app/models/admin_console.rb
  - app/models/admin_overview.rb
  - app/views/admin/_overview.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/controllers/admin_test.rb
enforced_by:
  - test/controllers/admin_test.rb
  - test/controllers/admin_overview_test.rb
  - test/system/admin_overview_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Live admin Overview metrics

> **Review state:** Accepted. The baseline slice was approved on 2026-08-03 and
> M7-001 shipped against it; the status was recorded here on 2026-08-12, when a
> review of overdue documents found this file still saying draft while its own
> text, the backlog's recorded approval, and the tests in `enforced_by` all said
> otherwise. This specification authorizes the four aggregate counts below;
> future adoption, activity, and health metrics remain subject to their own
> source and privacy review.

> [Executable Specifications](README.md) ·
> [M7 architecture decision](../decisions/adr-0012-live-admin-overview-metrics.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Problem

The admin Overview presents hardcoded numbers and operational stories as if
they were measured application state. This can mislead administrators about
enrolment, adoption, recent actions, and service health.

## Scope

### Included after human review

- Define a small set of aggregate Overview metrics against existing database
  records.
- Expose those metrics through a read-only query boundary used by the view.
- Replace approved fabricated cards with live values and localized labels.
- Remove or show unavailable any panel whose source is not approved.
- Add focused model, controller, and browser coverage for data changes,
  authorization, empty states, and Thai/English rendering.

### Approved baseline metrics

The first slice displays these current-record counts:

| Card | Definition |
| --- | --- |
| Total accounts | Count of `User` records. |
| Student accounts | Count of users with the `student` role. |
| Staff accounts | Count of users with the `instructor` or `admin` role. |
| Topic completions | Count of `TopicCompletion` records. |

The adoption, activity, and health panels are removed until their authoritative
sources, time semantics, and privacy boundaries are approved.

> **Approved 2026-08-14.** The hold above is lifted. The adoption, activity and
> health panels ship, together with a name-collision count and three CSV reports,
> on the definitions recorded in the handoff table below — every one of them
> counted off records the app already keeps. The user approved all seven review
> points as proposed.
>
> Two things were settled before the review rather than by it. **Invariant 5**:
> the collision panel was first written listing names beside student IDs, and was
> rewritten to report counts alone — a list of learners and their identifiers is
> exactly what this boundary may not return. And the design's health caption,
> *"checked automatically every 5 minutes"*, was refused: nothing runs that
> schedule, so the panel says "checked when this page is opened". A status panel
> claiming a freshness it does not have is worse than one admitting it is a spot
> check.

### Excluded

- Course administration, course lifecycle mutations, approval decisions, and
  persisted feature flags.
- Inventing faculty or organization membership from localized course copy.
- Treating record creation as a human activity feed without an event policy.
- Claiming service uptime, queue lag, registrar sync, SSO health, or storage
  usage without authoritative telemetry.
- Exposing learner-level names, identifiers, or sensitive progress details.

## Invariants

1. Every rendered metric has an approved definition, source, time window, and
   timezone.
2. A metric value is derived from current authoritative records or is rendered
   as unavailable; no hardcoded operational value may reach the Overview.
3. Empty source data produces a truthful localized empty state and never a
   plausible-looking zero or percentage unless zero is the defined result.
4. Only an authorized administrator can access the Overview query boundary.
5. The query boundary returns aggregate values and approved labels, not raw
   learner records or private identifiers.
6. A source-record change is reflected by the next uncached request, or the
   accepted cache freshness is displayed and tested.
7. Invalid or missing time-window parameters use the approved default rather
   than changing the query scope unpredictably.

## Acceptance Criteria

- [ ] The Product Owner and Tech Lead approve the metric table: name,
      definition, source, filter, window, timezone, and empty state
      (`docs/decisions/adr-0012-live-admin-overview-metrics.md`).
- [ ] Each approved card changes when its source records change and no longer
      reads from the fabricated Overview constants
      (`test/models/admin_overview_test.rb`).
- [ ] Undefined adoption, activity, and health panels are removed or show the
      approved unavailable state; their old sample rows are never rendered
      (`test/controllers/admin_test.rb`).
- [ ] Non-admin users cannot access the Overview query or its data
      (`test/controllers/admin_test.rb`).
- [ ] Empty tables, rolling-window boundaries, and the Asia/Bangkok timezone
      follow the approved definitions (`test/models/admin_overview_test.rb`).
- [ ] Thai and English labels, values, and empty states are present and do not
      expose raw identifiers (`test/system/admin_overview_walk_test.rb`).
- [ ] The full verification gate passes after implementation (`bin/verify`).

## Error and boundary cases

- No users, sections, courses, or completions exist.
- A record falls exactly on either side of the approved rolling-window boundary.
- A course or user is missing an organization/faculty attribute required by an
  approved breakdown; it must be counted according to the recorded fallback,
  not guessed from copy.
- A source query fails or is stale; the UI must use the approved unavailable or
  stale state and must not reuse a fabricated fallback.
- A non-admin requests the tab directly or changes query parameters.

## Human Metric and Privacy Review Handoff

Implementation is held until the Product Owner, Tech Lead, and Privacy Owner
complete this table. The agent may prepare the query and test structure after
the choices are recorded, but cannot define operational meaning by inference.

**Completed 2026-08-14.** Every row below was approved as proposed. The column is
kept headed *Decision* and the wording is the implementation's own, so the table
stays checkable against the code rather than becoming a summary of it.

| Review point | Decision required | Decision (approved 2026-08-14) |
| --- | --- | --- |
| Core cards | Name each metric and approve source tables, filters, and formula. | Unchanged — the four counts approved in the baseline slice. |
| Active/adoption meaning | Choose the event, rolling window, timezone, denominator, and zero/empty behavior. | Active = a `sessions` row created, a `topic_completions.learned_at`, a `submissions.created_at`, or an `audit_events.created_at` within a rolling 7 days. Denominator: every account with that faculty. A faculty with no active account renders 0%, not blank. Sessions alone would understate badly — `Session` is never touched after creation (`Session::MAX_AGE`), so a daily user who signed in a fortnight ago has one fortnight-old row. |
| Breakdown dimensions | Approve a persisted faculty/organization source or defer the breakdown. | `users.faculty`, a persisted column. Nothing is inferred from localized course copy. Null renders as "No faculty recorded" and is counted, so the rows still sum to `User.count`. |
| Activity feed | Choose authoritative event types, retention, display fields, and privacy limits, or remove it. | `AuditEvent` only — its `ACTIONS` allow-list is the event policy this row asks for. Newest 6. Display fields: the localized action sentence, the actor's name, and the timestamp. **The actor is staff-facing by construction** (audited actions are console and teaching actions), but this is the row most in need of a privacy answer. |
| Health panel | Name telemetry sources and freshness/SLO semantics, or remove it. | Live probes, not telemetry, and no SLO is claimed: `SELECT 1`; a Solid Queue heartbeat within 5 minutes; a cache `fetch` round-trip; storage root writability. The design's caption "checked automatically every 5 minutes" was **not** used — nothing runs that schedule, so the caption reads "checked when this page is opened". |
| Refresh and failure state | Choose cache freshness, stale labeling, and query-failure behavior. | No cache, so nothing can be stale. Every check runs through one rescue and reports `down` with the error class; a status panel that 500s is the one failure mode a status panel may not have. |
| Localization/accessibility | Approve Thai/English copy, number formatting, labels, and accessible empty states. | Both locales carry every label, each panel has its own empty state, and the status dots are `aria-hidden` with the state also written as text. |

## Rollback and observability

- The slice can be rolled back by hiding the new Overview metrics while leaving
  source records untouched; it must not restore fabricated values.
- Log query failures without learner identifiers or raw metric payloads.
- If caching is approved, record freshness and query latency so stale data is
  distinguishable from a real zero.

## Verification

```bash
bin/docs
bin/rails test test/models/admin_overview_test.rb test/controllers/admin_test.rb
bin/rails test:system test/system/admin_overview_walk_test.rb
bin/verify
```
