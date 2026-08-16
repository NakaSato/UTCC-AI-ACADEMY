---
id: SPEC-0013
type: spec
title: Real admin course catalog and lifecycle states
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-03
updated: 2026-08-12
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: [ADR-0013, ADR-0008, SPEC-0008]
implemented_by: [M7-002]
touches:
  - app/models/course.rb
  - app/models/course_catalog.rb
  - app/controllers/admin_controller.rb
  - app/views/admin/_courses.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by:
  - test/models/course_test.rb
  - test/models/admin_course_catalog_test.rb
  - test/controllers/admin_courses_test.rb
  - test/system/admin_courses_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Real admin course catalog and lifecycle states

> **Review state:** Accepted. The baseline was approved on 2026-08-03 and M7-002
> shipped against it; the status was recorded here on 2026-08-12, when a review
> of overdue documents found this file still saying draft while its own text,
> the backlog's recorded approval, and the tests in `enforced_by` all said
> otherwise. The specification separates the real-row read model from the
> approved lifecycle mutations; future scheduling, ownership metadata, and
> academic workflow can extend it only through a new decision.

> [Executable Specifications](README.md) ·
> [M7 course lifecycle decision](../decisions/adr-0013-admin-course-lifecycle.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Problem

The admin Courses tab presents fabricated course rows and a non-functional
state switch. Administrators cannot trust its codes, counts, ownership labels,
or claim that a change affects the learner-facing catalog.

## Scope

### Included after policy approval

- Read course rows from `Course` records in catalog order.
- Count sections from `Section` and enrolled students from `Enrollment`.
- Display only persisted or locale-keyed metadata with an explicit source.
- Persist and validate the approved course lifecycle state and transitions.
- Apply the approved state consistently to learner-facing catalog and course
  access behavior.
- Record successful lifecycle mutations in `AuditEvent`.
- Provide localized empty, invalid-search, authorization, and mutation-failure
  states.

### Excluded

- Creating or editing academic curriculum content.
- Inferring owner or faculty from localized strings.
- Renaming course codes or migrating course curricula as part of the admin UI.
- Approval queue records or feature-flag persistence.
- Certificate issuance, SSO, or changes to learner progress semantics.
- Scheduling publication or archival unless explicitly selected in ADR-0013.

### Approved implementation policy

- Persist `draft`, `published`, and `archived` on `Course`.
- Allow only `draft → published`, `published → archived`, and
  `archived → published`, performed by administrators.
- Backfill existing courses as published; new course rows default to draft.
- Show published courses in the learner catalog. Hide archived courses from
  discovery while preserving access for learners with recorded progress.
- Keep course, curriculum, completion, enrolment, and audit records intact.
- Show persisted course title, section count, and enrolment count; omit
  unsourced owner/faculty fields.

## Invariants

1. Every Courses-tab row maps to exactly one persisted `Course` record.
2. Section and student counts are scoped to that course's persisted records and
   never come from constants or locale arrays.
3. A lifecycle state is one of the accepted values and every transition is
   checked against the approved actor and predecessor-state rules.
4. A failed, unauthorized, stale, or invalid transition changes no course state
   and creates no successful audit event.
5. A successful transition writes one audit event containing actor, course,
   previous state, new state, and timestamp.
6. Course code, curriculum associations, completion rows, and historical audit
   events remain stable across lifecycle changes.
7. Learner-facing visibility and direct URL behavior follow the approved state
   policy; the admin table cannot claim a change that those screens ignore.
8. Missing source metadata is displayed as the approved unavailable state, never
   as a fabricated owner, faculty, or student count.
9. Non-admin users cannot read or mutate the admin course controls.
10. Search matches only approved persisted or locale-keyed course fields and
    cannot broaden access to another course through unsanitized query input.

## Acceptance Criteria

- [x] The Product Owner and Academic Owner approve the lifecycle state table,
      transitions, actor rules, and learner-facing effects
      (`docs/decisions/adr-0013-admin-course-lifecycle.md`).
- [x] The admin Courses tab lists current `Course` rows and no fabricated row
      remains (`test/controllers/admin_courses_test.rb`).
- [x] Section and enrolled-student counts agree with persisted records,
      including zero-section and zero-enrolment courses
      (`test/models/admin_course_catalog_test.rb`).
- [x] Approved metadata sources are documented in the UI/spec, and owner or
      faculty data without a source is not rendered as fact
      (`test/controllers/admin_courses_test.rb`).
- [x] Valid lifecycle transitions update the learner-facing catalog according
      to policy and create one complete audit event
      (`test/controllers/admin_courses_test.rb`, `test/models/course_test.rb`).
- [x] Invalid, unauthorized, duplicate, stale, or failed transitions leave the
      course and audit log unchanged (`test/controllers/admin_courses_test.rb`).
- [x] Thai and English browser walkthroughs show the approved course state and
      safe empty/error behavior (`test/system/admin_courses_walk_test.rb`).
- [x] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- A course has no sections or enrolments.
- A course has completions or active enrolments when an archive is requested.
- A course state is changed between form render and submit.
- A request repeats the same transition or submits an unknown state.
- A course code is valid but its locale copy is missing in one language.
- Search input contains SQL wildcard characters, HTML, or another course code.
- An instructor or student requests the admin tab or posts a lifecycle mutation.
- A lifecycle mutation succeeds in the database but audit writing fails; the
  transaction boundary must prevent a misleading success state.

## Human Academic Review Handoff

Implementation is held until the Product Owner, Tech Lead, and Academic Owner
complete this table. The agent can implement a recorded policy, but cannot
declare that a course is academically available or withdrawn.

| Review point | Decision required |
| --- | --- |
| State meanings | Define draft, published, archived and whether any additional state is required. |
| Transitions and actors | Name who may create, publish, archive, restore, or edit and whether approval is required. |
| Existing learners | Define access, progress, reporting, syllabus, and certificate behavior after archival. |
| Catalog and URLs | Decide whether unpublished/archived courses are hidden, redirected, or read-only. |
| Metadata source | Approve title, description, instructor, faculty, owner, and ordering sources. |
| Curriculum changes | Define whether publication freezes curriculum or permits versioned changes. |
| Audit and rollback | Define retention, correction, idempotency, and support rollback behavior. |

## Rollback and observability

- A failed policy migration or mutation must be reversible without deleting
  courses, completions, enrolments, or audit history.
- Lifecycle transitions log actor and state identifiers but not unnecessary
  learner identifiers or raw learner records.
- Monitor transition failures and stale-form conflicts separately from ordinary
  course reads.

## Verification

```bash
bin/docs
bin/rails test test/models/admin_course_catalog_test.rb test/models/course_test.rb
bin/rails test test/controllers/admin_courses_test.rb
bin/rails test:system test/system/admin_courses_walk_test.rb
bin/verify
```
