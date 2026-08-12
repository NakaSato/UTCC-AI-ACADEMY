---
id: ADR-0013
type: adr
title: Define the admin course lifecycle and catalog boundary
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-03
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0008, SPEC-0008]
implemented_by: [M7-002]
touches:
  - app/models/course.rb
  - app/models/course_catalog.rb
  - app/controllers/admin_controller.rb
  - app/views/admin/_courses.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define the admin course lifecycle and catalog boundary

> **Decision state:** Accepted. The user approved the baseline implementation on
> 2026-08-03 and M7-002 shipped against it; the status was recorded here on
> 2026-08-12, when a review of overdue documents found this file still saying
> draft while its own text, the backlog's recorded approval, and the tests in
> `enforced_by` all said otherwise. The implementation policy below keeps
> existing learner records available while making lifecycle visibility and
> mutations explicit.

> [Decision Records](README.md) ·
> [M7 course administration specification](../specs/spec-m7-admin-course-lifecycle.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Context

The admin Courses tab renders five fabricated rows. The learner-facing catalog
already reads real `Course` records, but the course table does not show those
records, has no persisted lifecycle state, and has no safe mutation boundary.
The current `Course` row stores catalog taxonomy and course-scoped curriculum
identity; human-readable title, description, and instructor copy remain keyed
by course code in the locale files. Sections and enrolments are separate real
records.

A publish switch without a persisted state can claim that a learner-facing
change happened when it did not. Adding a state without defining its effect on
existing learners, completions, syllabus documents, and course URLs can make
academic records disappear or change meaning unexpectedly.

## Problem frame

- **Affected user:** An administrator deciding which courses are available and
  how to explain their current lifecycle to staff.
- **Current behavior:** The admin table shows sample codes, owners, section
  counts, student counts, and a non-functional live/draft switch.
- **Failure risk:** Staff may act on rows that do not exist, or believe a toggle
  changed learner access when it only changed pixels.
- **Success signal:** Every displayed row and count is sourced from the course,
  section, and enrolment records, and every lifecycle transition has an
  explicit learner-facing effect and audit event.

## Decision boundary

1. The Courses tab must read course identity from `Course` and counts from
   `Section`/`Enrollment`; it must not retain parallel Ruby rows.
2. Lifecycle state must be persisted on an authoritative course record or an
   explicitly related record with one documented source of truth.
3. The accepted state vocabulary is proposed as `draft`, `published`, and
   `archived`, but the Product Owner and Academic Owner must approve the exact
   meanings and allowed transitions.
4. A lifecycle mutation must define its effect on catalog visibility, direct
   course URLs, new enrolments, existing enrolments, progress, syllabus PDFs,
   certificates, and completed learners.
5. Course metadata without a persisted source—such as owner or faculty—must be
   removed from the table or labeled unavailable; it must not be inferred from
   locale copy.
6. Every successful mutation records actor, course, old state, new state, and
   timestamp in the existing audit boundary. A failed mutation records no
   success event.
7. Course code and curriculum identity remain stable unless a separate migration
   and academic policy explicitly authorizes a change.

## Approved implementation policy

- `lifecycle_state` is persisted directly on `Course`; existing courses are
  backfilled as `published` and newly created courses default to `draft`.
- The allowed transitions are `draft → published`, `published → archived`,
  and `archived → published`. Administrators are the acting role for this
  baseline, and the submitted predecessor state prevents stale form writes.
- Published courses appear in the learner catalog. Archived courses are hidden
  from discovery but remain accessible to learners who have recorded progress;
  their course, lesson, and historical records are not deleted.
- The admin table uses persisted course, section, and enrolment records. Owner
  and faculty columns are omitted until those fields have an authoritative
  source.
- Successful transitions create a warning-level audit event; failed transitions
  create no success event.

## Alternatives

### Add a lifecycle state directly to `Course`

One source of truth keeps learner queries, admin reads, and audit context close
to the course. It requires a migration and careful rules for legacy rows, but
is the recommended option if the state is intrinsic to catalog availability.

### Add a separate course-publication record

This can preserve the existing catalog table, but creates two records that must
agree about visibility, ownership, and history. It is justified only if
publication is independently versioned or scheduled by institutional workflow.

### Keep a boolean `published` flag

This is easy to implement but cannot express an intentional archive or future
states without overloaded meanings. It is rejected for the proposed lifecycle.

### Keep the table read-only and defer lifecycle controls

This is the safest first increment if publication policy is unresolved: real
rows and counts can ship while the non-functional switch is removed. It does
not satisfy the full M7 course-control goal, but avoids inventing academic
availability rules.

## Human decisions required

- Whether the state belongs directly on `Course` or in a separate publication
  record.
- Exact meanings and allowed transitions for draft, published, and archived.
- Who may create, publish, archive, restore, or edit a course, and whether an
  academic approver is required.
- Whether archived courses remain visible to enrolled learners and whether new
  enrolments are blocked immediately or at a term boundary.
- Whether direct URLs, syllabus downloads, progress views, certificates, and
  reports remain available for archived courses.
- Authoritative source for localized title/description/instructor and whether
  faculty/owner fields should become persisted data.
- Ordering/position behavior, duplicate codes, and curriculum changes after a
  course is published.
- Audit retention, correction, and rollback expectations.

## Consequences

- A real read-only table can be separated from lifecycle mutations if policy is
  not ready, reducing the first implementation risk.
- A persisted state makes catalog visibility a domain rule that must be applied
  consistently by catalog, course pages, lessons, maps, reports, and documents.
- Removing owner/faculty placeholders may make the table visually less rich
  until those fields have an approved source.
- Archive behavior becomes an academic-record decision, not merely an admin UI
  detail.

## Fitness Functions

- `bin/docs` validates the decision record, links, and review metadata.
- Future model and controller tests prove state transitions, authorization,
  learner-facing visibility, count accuracy, and failed-mutation behavior.
- A system walkthrough proves the approved transition and its effect in Thai and
  English.
- Audit tests prove that every successful mutation has one actor/time/state
  event and failed mutations do not create misleading success entries.
