---
id: SPEC-0054
type: spec
title: A teacher's authority over the course they teach
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-13
updated: 2026-08-13
review_by: 2026-08-27
supersedes: []
superseded_by: []
depends_on: [ADR-0054, ADR-0013, ADR-0011]
implemented_by:
  - app/controllers/instructor_controller.rb
  - app/models/approval_request.rb
  - app/models/course.rb
  - app/views/instructor/_course.html.erb
  - config/routes.rb
enforced_by:
  - test/controllers/teaching_course_authority_test.rb
  - test/models/approval_request_test.rb
touches:
  - app/controllers
  - app/models
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-ARCH-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002]
---

# A Teacher's Authority Over the Course They Teach

> **Review state:** Accepted on 2026-08-13 on the authority of
> [ADR-0054](../decisions/adr-0054-teaching-course-authority.md), which the user
> accepted the same day by taking all four recommendations. Two of those four
> are refusals — course creation and certificate approval — and both are
> recorded here as scope rather than omission.

> [Executable Specifications](README.md) ·
> [Teaching course authority decision](../decisions/adr-0054-teaching-course-authority.md) ·
> [Admin course lifecycle](spec-m7-admin-course-lifecycle.md) ·
> [Course completion certificates](spec-m6-course-completion-certificates.md)

## Problem

`/instructor` was one screen and three routes: a roster, a grades CSV, and a
per-topic proctoring switch. Everything about the course itself lived in
`/admin`, which is `allow_only :admin` on every tab it has. A teacher could see
how their students were doing and change nothing about what they were doing.

## Scope

**In:** the course a teacher's section teaches — its numbers while it is a
draft, and a request to move its lifecycle.

**Out, and refused rather than deferred by accident:**

- **Creating a course.** A course's words are `catalog.courses.<code>.*` in two
  locale files; the table carries identity, taxonomy and numbers only. A course
  created through a form would render `translation missing` on every screen that
  names it. Moving that copy into the database is its own decision, and
  `LandingText` is the precedent to copy.
- **Approving a certificate.** [ADR-0011](../decisions/adr-0011-course-completion-certificates.md)
  deferred issuance and nothing has changed: no artifact, no issuing rule, no
  verification identity, no route. An approval button over that approves
  nothing, and the first person to click it would believe a student had been
  certified.

## What a teacher may do

| Action | Route | Boundary |
| --- | --- | --- |
| Read their section's roster and progress | `GET /instructor` | Unchanged |
| Download grades | `GET /instructor/grades` | Unchanged |
| Toggle lesson proctoring per topic | `PATCH /instructor/integrity/:topic_key` | Unchanged |
| **Edit their course's numbers** | `PATCH /instructor/course` | Their course only, draft only |
| **Request a lifecycle transition** | `POST /instructor/course/transition` | Their course only; an administrator decides |

**Their course** is `Section.for_staff(Current.user)`'s course, and only when
that section's `instructor_id` is them. `Course#taught_by?` asks the same
question from the other end, and `ApprovalRequest` uses it.

**The permitted fields** are `level`, `credits`, `projects`, `hours`, `core` and
`certificate`. Not `code`, which is the identity every locale key and completion
row is joined by. Not `lifecycle_state`, which belongs to the queue. Not
`learners` or `rating`, which are measured rather than set.

## The queue keeps its second pair of eyes

`ApprovalRequest` widens by one rule and no more: a requester may be an approver
**or** the teacher of the course. `approvable_by?` is untouched, so it still
refuses the requester their own decision — a teacher cannot approve their own
request, and neither can the administrator who raised one. That refusal is why
the queue exists (ADR-0013), and it is the property to protect if this ever
changes again.

## Invariants

1. A teacher edits only the course their own section teaches.
2. A teacher edits it only while it is a draft; a published course changes
   through the queue.
3. `code`, `lifecycle_state`, `learners` and `rating` are not writable here,
   whatever the form is made to post.
4. A teacher's transition request creates the same `ApprovalRequest` an
   administrator's does, and changes no lifecycle state by itself.
5. Nobody decides their own request.
6. An administrator holds the staff role, teaches nothing, and is therefore
   offered no course on this screen.
7. A student reaches none of these routes.
8. Every edit and every request leaves an audit event naming the course.
9. Both locales carry every string.

## Acceptance Criteria

- A teacher patches `credits`, `level`, `projects`, `hours`, `core`,
  `certificate` on their draft course; the values change and one
  `course_updated` event is written.
- The same patch carrying `code`, `lifecycle_state`, `learners` and `rating`
  changes none of them and still saves the permitted field.
- Patching a published course writes nothing and answers
  `flash.course_not_editable`.
- A teacher's transition request creates a pending `ApprovalRequest`, leaves the
  course in `draft`, is not `approvable_by?` the teacher, and is
  `approvable_by?` an administrator.
- Another teacher's course answers `flash.course_not_yours` and writes nothing.
- An administrator sees no `[data-course-code]` panel and cannot request a
  transition.
- A student is redirected to the root from both routes.

## Verification

- `test/controllers/teaching_course_authority_test.rb` — every row above, from
  both sides. The widened validation was checked by removing it: without the
  teacher rule, the request test fails.
- `test/models/approval_request_test.rb` — the queue's own rules, unchanged.
- `test/operations/locale_parity_test.rb` — both locales carry the new copy.

## Consequences

- The teaching dashboard stops being read-only and gains the audit trail and the
  refusals the admin screens already have.
- Course creation stays with migrations and seeds until course copy moves into
  the database. That is the next decision in this area, and it is named in
  ADR-0054 rather than left to be discovered.
- Certificates remain exactly as ADR-0011 left them.
