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
  - app/models/teaching_console.rb
  - app/models/syllabus_builder.rb
  - app/models/syllabus_text.rb
  - app/views/instructor/show.html.erb
  - app/views/instructor/_course.html.erb
  - app/views/instructor/_syllabus.html.erb
  - config/routes.rb
enforced_by:
  - test/controllers/teaching_course_authority_test.rb
  - test/controllers/teaching_console_tabs_test.rb
  - test/controllers/syllabus_builder_test.rb
  - test/models/syllabus_text_test.rb
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

  > **Partly answered since.** The syllabus panel needed the same move for
  > *lesson* copy and made it — see "The syllabus a teacher may shape" below.
  > `SyllabusText` is the `LandingText`-shaped table this bullet asked for,
  > covering topic names and module titles. A course's own catalogue title and
  > summary are still locale-only, so creating a course is still refused; what
  > has changed is that the precedent now exists in this area rather than only
  > next to it.
- **Removing a lesson.** `topic_completions` and `prior_knowledges` are
  `dependent: :destroy`, and `submissions` and `proctor_events` hold a foreign
  key to `topics`. Destroying a topic therefore either erases what learners
  finished or fails on the constraint — there is no third outcome. Taking a
  lesson out of a syllabus is a **retirement**: the row stays, stops being
  offered, and stops counting toward a denominator. That reaches into progress,
  the leaderboard and certificates, so it is its own decision and no route
  pretends otherwise. *Adding* a lesson is in, through the queue — see below.
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
| **Rename a lesson, in both languages** | `PATCH /instructor/syllabus/topic/:topic_key` | Their course only, draft only |
| **Move a lesson within its module** | `PATCH /instructor/syllabus/move/:topic_key` | Their course only, draft only |
| **Ask for a new lesson** | `POST /instructor/syllabus/lesson` | Their course only; an administrator decides |

**Their course** is `Section.for_staff(Current.user)`'s course, and only when
that section's `instructor_id` is them. `Course#taught_by?` asks the same
question from the other end, and `ApprovalRequest` uses it.

**The permitted fields** are `level`, `credits`, `projects`, `hours`, `core` and
`certificate`. Not `code`, which is the identity every locale key and completion
row is joined by. Not `lifecycle_state`, which belongs to the queue. Not
`learners` or `rating`, which are measured rather than set.

## The shape of the console

Course authority gave `/instructor` a fourth panel, and four panels stacked down
one column put two screens of settings between a teacher and the question they
opened the screen with: *who is behind?* So the screen tabs, with the component
`/admin` already uses — the same bar, the same underline, the same count pill.

**Above the bar, on every tab:** the section's name, the four cohort figures, and
the grades export. They answer "how is this section doing?" whichever panel is
open, and a tab that hid them would make the export look like a roster feature.

**The bar:** `roster` · `topics` · `course` · `syllabus` · `integrity`, in that order, roster
first because it is what the screen is opened for. `TeachingConsole` owns the
list.

**The URL is the state.** `?tab=` selects the panel; the default tab's link
carries no query string; an unknown tab opens the roster rather than nothing —
`AdminConsole.tab_for`'s rule, and for the same reason. Every write on this
screen redirects back to the tab it was made on, so a teacher who toggles six
lessons stays where the switches are.

**The course and syllabus tabs are absent, not merely closed**, for staff who teach nothing
(invariant 6). `?tab=course` typed by an administrator opens the roster.

**A pill counts what is off its default, never what merely exists**: the roster
pill counts the students under the *behind* line, the integrity pill counts the
lessons whose student-facing log is hidden. A tab with nothing to flag wears no
pill. A plain size on a tab — "48" beside Roster — reads as an alert and is not
one.

## The syllabus a teacher may shape

ADR-0054 refused course creation because a course's words are
`catalog.courses.<code>.*` in two locale files. Building the syllabus panel found
the refusal understated the problem: **a topic's name was its position.**
`Syllabus.topic_name` read
`course.curricula.<CODE>.modules[i].topics[j]`, indexed by
`course_modules.number` and `topics.position`, and module titles and
descriptions the same way. Moving one lesson up renamed every lesson below it,
in Thai and English at once; adding one left a blank where a name should be.

`SyllabusText` is the fix, and it is `LandingText`'s shape for `LandingText`'s
reasons: `(key, locale, value)`, keyed on the stable `topics.key` that every
completion, prior-knowledge row and integrity setting already joins by. The
locale files stay the shipped default and still render on a fresh install; a row
shadows one string in one language. `Syllabus` reads a name in three tries —
override, then the copy shipped at that position, then whatever language it was
written in. **Position is the fallback now, not the identity.**

Two consequences worth stating, because neither is obvious:

1. **A reorder pins the names it is about to move.** A lesson nobody has renamed
   has no row, so its name is still read off its position — swapping two
   untouched lessons would still swap their names. `SyllabusBuilder#swap!`
   therefore writes down what both lessons are called, in every language, before
   it moves them. The first reorder is exactly when position stops describing the
   syllabus, and that is the honest place to stop deferring to the shipped copy.
2. **A rename pins both languages, and never deletes back to the default.**
   `LandingText` drops a row that matches the shipped copy so nothing shadows the
   file with a duplicate. That rule cannot hold here: "the default" for a topic is
   whatever lesson happens to sit where this one sits, so deferring to it would
   put the name back on a footing a reorder can move.

**`topics.key` is never rewritten.** "1-1" may end up sitting third. The key is
identity, not a description — it is what `/lesson?topic=` carries, and a reorder
that renumbered keys would detach every learner's progress from the lesson they
finished.

**Neither write is audited**, for the reason `AuditEvent` gives for leaving the
landing page's card reorder out of `ACTIONS`: they change neither what exists nor
who can do what, and they are the noisiest controls a teacher has. Adding and
removing a lesson *does* change what exists, which is the other half of why that
goes through the queue, where every decision is recorded.

## Asking for a lesson

Renaming and reordering change how a syllabus reads. Adding a lesson changes what
exists, so it is a request — the same queue, the same `approvable_by?`, the same
refusal of anybody's own request, as publishing the course.

The queue had to widen to hold one. `from_state` and `to_state` were the whole
payload of a lifecycle move and were `NOT NULL`; a lesson request has no states
to move between. So both became nullable, required now only for the lifecycle
kind, and a `payload` json column carries what the lesson needs to exist:
module, kind, minutes, and a name in each language. Everything arrives with the
request because **approving it is what creates the row** — there is nowhere else
for a name to come from at decision time.

Two smaller rules fall out:

- **A lesson request does not go stale when the course moves.** `decide!` checks
  `course.lifecycle_state == from_state` only for a lifecycle request; a lesson
  is not about the course's state, so publishing the course mid-queue does not
  invalidate it. It is also why the request route is not gated on `draft?` —
  asking is reasonable in either state, and the decision is the check.
- **A new lesson's key is minted past the collisions.** `Topic.key_for` derives a
  key from a position and `topics.key` is globally unique, so a module that has
  lost a lesson would mint a key it already used. The derived key is a starting
  point; the first free one wins.

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
9. Both locales carry every string, tab labels included.
10. An unknown or forbidden `?tab=` opens the roster; it never errors and never
    opens an empty screen.
11. A tab's pill counts a deviation worth acting on, or the tab wears no pill.
12. A lesson keeps `topics.key` through any reorder, so no completion is ever
    detached from the lesson it was earned on.
13. A reorder changes no lesson's name, whether or not that lesson had been
    renamed first.
14. A lesson has a name in both languages or the write is refused.
15. Renaming and reordering write no audit event; adding a lesson is a queue
    decision, which does.
16. A lesson exists only because an administrator approved it, and nobody
    approves their own request.
17. A new lesson never takes a key another lesson already holds.
18. No route destroys a topic. Removing one is a retirement and is not built.

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
- Each of the four tabs shows its own panel and no other; the figures and the
  export are present on all four.
- A plain `GET /instructor` opens the roster, and the roster's own tab link
  carries no query string.
- `?tab=gradebook` opens the roster. `?tab=course` opens the roster for an
  administrator, whose bar has no course tab at all.
- Hiding one lesson's log puts a `1` on the integrity tab; the roster pill
  equals the count of students under `InstructorReport::BEHIND`.
- Staff with no section get the notice and no bar.
- The syllabus tab draws every module and every lesson of the teacher's course,
  in order, each with a rename form and its move controls.
- A rename in both languages is readable in both languages afterwards; a blank
  one answers `flash.topic_name_blank` and stores nothing.
- Moving a lesson changes its position, changes no name anywhere in the course —
  including lessons never renamed — and changes no `topics.key`.
- The first and last lessons of a module answer `flash.topic_not_moved` rather
  than wrapping.
- Both edit routes refuse a published course, another teacher's course, and a
  student, with the same three answers `PATCH /instructor/course` gives.
- Asking for a lesson creates a pending request and no topic; approving it
  creates the topic with both names readable; rejecting it creates nothing.
- A request missing a name, a positive duration, a real module, or a known kind
  answers `flash.lesson_request_invalid` and is not queued.
- Three lessons added in a row hold three distinct keys.
- A lesson request raised before the course is published is still decidable
  after it.

## Verification

- `test/controllers/teaching_course_authority_test.rb` — every row above, from
  both sides. The widened validation was checked by removing it: without the
  teacher rule, the request test fails.
- `test/controllers/teaching_console_tabs_test.rb` — the bar: what each tab
  opens, what stays above it, the default and the unknown tab, and both pills.
- `test/controllers/syllabus_builder_test.rb` — the two writes and the four
  refusals, including that a reorder moves no names and rewrites no keys.
- `test/models/syllabus_text_test.rb` — the override table itself. The
  load-bearing test is *"a reorder moves lessons without moving their names"*:
  it was written against the old positional read first, where it failed.
- `test/models/approval_request_test.rb` — the queue's own rules, unchanged.
- `test/operations/locale_parity_test.rb` — both locales carry the new copy.

## Consequences

- The teaching dashboard stops being read-only and gains the audit trail and the
  refusals the admin screens already have.
- Course creation stays with migrations and seeds until course copy moves into
  the database. That is the next decision in this area, and it is named in
  ADR-0054 rather than left to be discovered.
- Certificates remain exactly as ADR-0011 left them.
