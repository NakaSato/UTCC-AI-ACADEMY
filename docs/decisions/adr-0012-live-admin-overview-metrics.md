---
id: ADR-0012
type: adr
title: Replace fabricated admin Overview metrics with defined live metrics
status: accepted
owners: ["@product-owner", "@tech-lead", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-12
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: [SPEC-0008]
implemented_by: [M7-001]
touches:
  - app/models/admin_console.rb
  - app/views/admin/_overview.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/controllers/admin_test.rb
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Replace fabricated admin Overview metrics with defined live metrics

> **Decision state:** Accepted. The user approved the baseline implementation on
> 2026-08-03 and M7-001 shipped against it; the status was recorded here on
> 2026-08-12, when a review of overdue documents found this file still saying
> draft while its own text, the backlog's recorded approval, and the tests in
> `enforced_by` all said otherwise. The Product Owner and Tech Lead still own any
> future metric definitions, while the Privacy Owner must approve whether any
> activity or breakdown view exposes identifiable information.

> [Decision Records](README.md) ·
> [M7 Overview specification](../specs/spec-m7-live-admin-overview-metrics.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Context

The admin header already counts live `User`, `Section`, and
`TopicCompletion` records. The Overview tab below it still renders hardcoded
card values, faculty adoption percentages, activity entries, and service-health
claims from `AdminConsole`. Those values look operational but do not come from
records or monitored services.

An administrator must be able to distinguish a measured value from a design
placeholder. The first M7 slice should establish that boundary without silently
inventing event history, faculty ownership, uptime, or activity semantics.

## Decision boundary

1. Every displayed Overview value must have a named definition, source record or
   query, time window, timezone, and empty-state behavior.
2. The implementation will use a read-only admin Overview query boundary rather
   than embedding ad hoc counts in the template.
3. Existing live header counts may be reused only when their definitions are
   documented and covered by tests.
4. A panel with no approved source or semantics must be removed or shown as
   unavailable; it must not retain fabricated values.
5. Activity and health claims require actual authoritative records or telemetry.
   `created_at` rows alone must not be presented as human-readable operational
   actions or service uptime.
6. Metrics must be aggregate by default and must not expose learner names,
   identifiers, or sensitive activity details without an explicit privacy review.

## Approved baseline slice

The first implementation uses four aggregate counts from current authoritative
records:

| Card | Source and definition |
| --- | --- |
| Total accounts | `User.count` |
| Student accounts | `User.student.count` |
| Staff accounts | `User.instructor.count + User.admin.count` |
| Topic completions | `TopicCompletion.count` |

The adoption, activity, and service-health panels are removed from the live
Overview until their sources and semantics receive separate approval.

## Alternatives

### Keep the current placeholders

This preserves the visual design but continues to present fictional operational
information as fact. It is rejected for the production Overview.

### Replace every panel with live data in one increment

This gives a richer dashboard, but requires approved definitions for adoption,
activity, health, faculty ownership, time windows, and telemetry sources before
the first safe release. It is too broad for the first M7 slice.

### Ship defined live core metrics and remove undefined panels

This is the recommended boundary. It makes the Overview truthful using data
that already exists, while keeping adoption, activity, and health as explicit
follow-up decisions. The trade-off is a temporarily smaller dashboard.

## Human decisions required

- Which core metrics are required, and what exact records and filters define
  each one.
- Whether “active” means sign-in, lesson access, submission, completion, or
  another event, and which rolling window and timezone apply.
- Whether adoption must be grouped by a persisted faculty/organization field;
  no grouping should be inferred from names or static copy.
- Whether activity is needed now, and which authoritative event types and
  privacy-safe fields it may show.
- Which monitored dependencies, if any, are authoritative for a health panel.
- Empty-state, stale-data, caching, refresh, and localization expectations.

## Consequences

- The Overview may initially contain fewer panels, but every remaining number
  can be explained and reproduced from current data.
- The fabricated arrays in `AdminConsole` must not be used by the live Overview
  after implementation; unrelated placeholder tabs remain separate work.
- A future activity or health panel will need its own source and specification
  rather than borrowing the metric query boundary by implication.
- Aggregate queries and explicit time windows reduce privacy and timezone risk,
  but require product copy to explain what a metric means.

## Fitness Functions

- `bin/docs` validates this decision's review metadata and links.
- Model and controller tests prove that displayed values change when the source
  records change and that fabricated constants are not rendered.
- Tests cover empty data, timezone boundaries, admin authorization, and
  aggregate-only output.
- A browser walkthrough demonstrates the approved metrics and truthful empty
  states in Thai and English.
