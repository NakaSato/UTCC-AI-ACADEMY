---
id: ADR-0054
type: adr
title: Give a teacher the course they teach, and keep the second pair of eyes
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-13
updated: 2026-08-13
review_by: 2026-11-11
supersedes: []
superseded_by: []
depends_on: [ADR-0013, ADR-0011, ADR-0005]
implemented_by:
  - SPEC-0054
touches: []
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give a Teacher the Course They Teach, and Keep the Second Pair of Eyes

> **Decision state:** **Accepted by the user on 2026-08-13**, who asked for a
> teaching dashboard where a teacher can create, update, enable and disable a
> course and approve certificates, and then asked for recommendations on the
> four questions that scope it. This answers all four. **Two of the four
> answers are refusals**, and both are recorded with what would have to change
> first.

> [Decision Records](README.md) ·
> [Teaching course authority specification](../specs/spec-teaching-course-authority.md) ·
> [Admin course lifecycle](adr-0013-admin-course-lifecycle.md) ·
> [Course completion certificates](adr-0011-course-completion-certificates.md) ·
> [Course-specific curricula](adr-0005-course-specific-curricula.md)

## Context

`/instructor` is one screen and three routes: a section's roster with each
student's progress, a grades CSV, and a per-topic proctoring switch. It is a
reporting surface. Everything about the course itself belongs to `/admin`.

That boundary was drawn on purpose. [ADR-0013](adr-0013-admin-course-lifecycle.md)
made a course's lifecycle an approval queue rather than a button: a transition
is requested, recorded, and decided, so publishing a course is never one
person's afternoon. The queue is the second pair of eyes, and it is the part of
this that must survive.

Two facts about the code decide the rest of the shape, and both were checked
rather than assumed.

**A course's words are not in the database.** `CourseCatalog::Course#title`,
`#description` and `#instructor` are `I18n.t("catalog.courses.<code>.…")`. The
`courses` table carries identity, taxonomy and numbers only — that is stated at
the top of the model and it is true. A course created through a form today would
render `translation missing` on every screen that names it, in both languages.

**A teacher cannot raise an approval request.** `ApprovalRequest` validates
`requester_is_approver`, and `APPROVER_ROLES` is `%w[admin]`. The queue an
instructor would use refuses them at the model.

## The four questions, and their answers

**1. Does a teacher author a course, or propose one?**

*Answered as recommended: propose.* The queue already models exactly this, and
it is what ADR-0013 bought. A teacher edits their course while it is a draft and
requests the transition that publishes it; an administrator decides. What
changes is one validation: `requester_is_approver` becomes "the requester is an
approver **or** teaches this course", and the decision rule is untouched —
`approvable_by?` still refuses the requester their own decision, so a teacher
cannot approve their own request and neither can the admin who raised one.

**2. Is "enable and disable" the lifecycle, or a new switch?**

*Answered as recommended: the lifecycle, and no new concept.* `draft`,
`published` and `archived` already answer "can a learner see this", and a second
per-section visibility switch would give that question two answers that can
disagree. Disabling is requesting `archived`; enabling is requesting
`published`.

**3. May a teacher approve a certificate?**

*Refused, and this is the answer most likely to be argued with.*
[ADR-0011](adr-0011-course-completion-certificates.md) deferred certificate
issuance and nothing has changed since: there is no artifact, no issuing rule,
no verification identity, and no route. `LearnerProgress` counts which courses
*would* earn one. An approval screen over that would be a button that approves
nothing, and the first person to click it would reasonably believe a student had
been certified.

What would have to come first is ADR-0011's own list: the completion-evidence
rule, the artifact, and a stable certificate identity. When those exist, who
approves is a small question. Until then, "approve" has no object.

**4. Which teacher?**

*Answered as recommended: the one who teaches it.* `Section#instructor` and
`Section.for_staff` already scope the dashboard to a staff member's own section,
and the same rule extends: a teacher reaches the course their section teaches,
and no other. Any-instructor would let one teacher archive another's course.

## Decision

1. **A teacher's course workspace lives on `/instructor`**, the screen they
   already have, scoped to the course their section teaches.

2. **A teacher edits their course's numbers while it is a draft** — level,
   credits, projects, hours, tags, and whether it is core. Not while it is
   published: a published course changing its credit count under enrolled
   students is a different decision, and it belongs in the queue with everything
   else that is visible.

3. **A teacher requests a lifecycle transition; an administrator decides.**
   `ApprovalRequest` widens by exactly one rule — the requester may be the
   course's teacher — and nothing else about the queue moves.

4. **Creating a course is not in this increment**, because a course created here
   would have no words. Course copy is `catalog.courses.<code>.*` in two locale
   files, and moving it into the database is its own decision with a real
   precedent to copy: `LandingText` already overrides locale copy from a table,
   memoised on `Current`, and that is the shape a `CourseText` would take. Named
   here so it stays a decision rather than an omission.

5. **Certificates are unchanged.** ADR-0011 stands.

6. **Every write is audited**, in the vocabulary that already exists:
   `course_state_changed` for the request, and a new `course_updated` for the
   metadata edit.

## Alternatives

### Give a teacher the admin console's Courses tab

Rejected. `/admin` is `allow_only :admin` for every tab it has, and widening it
per-tab would put the roster, the audit log and the permissions matrix one
mistake away from a teacher. The dashboard they already have is the right home.

### Let a teacher publish directly, without the queue

Rejected outright. It is the one thing ADR-0013 exists to prevent, and a course
going live is exactly the change worth a second reader.

### A per-section enable switch, leaving the lifecycle to admins

Rejected as the version that looks simpler and answers "can a learner see this"
twice. Two switches disagree eventually, and the one nobody remembers wins.

### Build certificate approval anyway

Rejected. There is nothing to approve. Building the screen first would create
the appearance of an issued certificate, which is worse than the absence of one.

## Consequences

- A teacher gains authority over the course they teach, bounded by the same
  queue an administrator uses, and gains nothing over any other course.
- `ApprovalRequest` admits a second kind of requester. `approvable_by?` is
  untouched, so nobody decides their own request — the property that makes the
  queue worth having.
- The teaching dashboard stops being read-only, which means it needs the
  optimistic locking and the audit trail the admin screens already have.
- Course creation stays with migrations and seeds until course copy moves into
  the database. That is a real gap and it is the next decision in this area.
- Certificates remain deferred, and the roadmap should stop implying otherwise
  where it does.

## Fitness Functions

- A teacher may edit only the course their section teaches, and only in draft.
- A teacher's lifecycle request creates the same `ApprovalRequest` an
  administrator's does, and neither may decide their own.
- No route lets a teacher publish, archive or create a course directly.
- Every metadata edit and every request leaves an audit event naming the course.
- The certificate surface is unchanged: no approval route exists.

## Decision owner

Product Owner and Academic owner for questions 1 to 3, Tech Lead for 4.
**Accepted by the user on 2026-08-13.**
