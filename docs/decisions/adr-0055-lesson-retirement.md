---
id: ADR-0055
type: adr
title: Retire a lesson rather than delete it
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-14
updated: 2026-08-14
review_by: 2026-11-12
supersedes: []
superseded_by: []
depends_on: [ADR-0054, ADR-0013]
implemented_by:
  - SPEC-0055
touches:
  - app/models/topic.rb
  - app/models/syllabus.rb
  - app/models/syllabus_builder.rb
  - app/models/approval_request.rb
  - db
enforced_by:
  - test/controllers/lesson_retirement_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Retire a Lesson Rather Than Delete It

> **Decision state:** **Accepted by the user on 2026-08-14**, taking Option B as
> drafted, including both halves of the semantic choice: a retired lesson leaves
> every denominator and keeps counting for whoever already finished it. Built the
> same day — see [SPEC-0055](../specs/spec-lesson-retirement.md).
>
> It was drafted rather than built first because removal has no safe
> implementation and choosing one is not an inference an agent may make.

> [Decision Records](README.md) ·
> [Teaching course authority](adr-0054-teaching-course-authority.md) ·
> [Teaching course authority specification](../specs/spec-teaching-course-authority.md) ·
> [Admin course lifecycle](adr-0013-admin-course-lifecycle.md)

## Context

A teacher can now add a lesson to their own syllabus: they ask, and an
administrator decides it in the queue (SPEC-0054). The symmetric action — taking
one out — was left unbuilt and no route pretends to offer it.

The reason is that **`Topic` has no safe delete.** Four tables point at it, and
they disagree about what should happen:

| Table | Association | What `topic.destroy` does |
| --- | --- | --- |
| `topic_completions` | `dependent: :destroy` | **Erases what learners finished.** |
| `prior_knowledges` | `dependent: :destroy` | Erases what a learner declared they already knew. |
| `submissions` | plain `belongs_to :topic` | Foreign key violation, or an orphan. |
| `proctor_events` | plain `belongs_to :topic` | Foreign key violation, or an orphan — and these are the academic-integrity record. |

So the two available outcomes today are *destroy a learner's record of work* or
*raise on the constraint*. There is no third, and neither is a feature.

There is a second reason, less obvious and more important. A completion is
evidence: it is what `InstructorReport` averages, what the leaderboard ranks,
what `MyLearning` shows a student about their own past, and what a certificate
would one day be issued against. Deleting the lesson deletes the evidence that
somebody did the work — retroactively, for everybody, because one teacher decided
next term's syllabus should be shorter.

## The question this actually asks

Not "how do we delete a row" but **what does a syllabus mean over time?**

The syllabus is currently written as though it were a single present-tense fact:
`Syllabus.topic_count` is *the* number of topics, and every learner's progress is
a fraction of it. A course that changes between cohorts breaks that assumption
whatever mechanism does the changing — a retirement no more and no less than a
delete. That is worth deciding once, here, rather than discovering it later.

## Alternatives

### A. Hard delete, guarded

Refuse the removal when any completion, submission or proctor event points at the
topic; allow it otherwise.

- **For:** no schema change, no read-path change, and the common case — a lesson
  added by mistake and removed the same afternoon — works.
- **Against:** the answer to "can I remove this?" becomes "it depends who has
  already opened it", which is unpredictable in the middle of a term and gets
  steadily rarer as a cohort progresses. It also does nothing for the real case,
  which is retiring a lesson that *has* been taught.

### B. Retirement (recommended)

Add `topics.retired_at`. A retired topic keeps every row that points at it and:

- does not appear in the syllabus, the course page, or the knowledge map;
- is not reachable as a lesson, and `next_topic_key` skips it;
- **does not count toward any denominator** — `topic_count`,
  `applied_topic_count`, `InstructorReport`, the leaderboard;
- **keeps counting in the numerator for whoever already finished it**, so nobody's
  past progress falls when a course is edited;
- is still nameable, so a completion, a submission and an integrity case can all
  still say which lesson they were about.

- **For:** honest about time, destroys nothing, and the audit and integrity
  records stay intact.
- **Against:** it touches every read path that counts topics, and the numerator/
  denominator rule above is a genuine semantic choice — a learner who finished 10
  of 12 keeps 10, but the course is now out of 11.

## Decision

**Option B**, with removal going through the approval queue exactly as addition
does — a teacher asks, an administrator decides, and the decision is audited.
`ApprovalRequest` already carries a `payload` and a per-kind `apply!` for this.

Option A is not a smaller version of B; it is a different feature that solves the
mistake case only, and it would still leave "retire a taught lesson" unanswered.

## What the decision settled

1. **Retired lessons leave the denominator.** `Syllabus` is the single boundary
   every screen reads a topic set through, so the filter lives there and nowhere
   else.
2. **A finished-but-retired lesson still counts for the learner who finished it.**
   The numerator is their completions, which are untouched; the denominator has
   lost the lesson. 12 of 11 is therefore reachable, and the three `percent`
   helpers clamp to 100 rather than printing 109%.
3. **Undoing a retirement is a second request kind, not a button.** Recorded
   first as an absence, then built to that description on 2026-08-15:
   `syllabus_lesson_restored` goes through the same queue, and retiring and
   restoring share one pending request per lesson so a lesson cannot have both
   waiting on it. Building it also fixed a defect it exposed — a retired lesson
   used to sit in the teacher's outline looking exactly like a live one,
   offering an "ask to retire" the validation would then refuse.
4. **A retired lesson stays nameable.** `Syllabus.topic_name` deliberately does
   not filter retired lessons — keeping the row and then refusing to name it
   would be the delete this app does not do.
5. **The queue binds an administrator too.** There is no direct route; the only
   caller of `retire_lesson!` is `ApprovalRequest#apply!`.

## Fitness Functions

Written before the decision so it would arrive with the tests that hold it. All
of them exist now, in `test/controllers/lesson_retirement_test.rb`.

- **No route destroys a topic.** A test walks every route and asserts none calls
  `Topic#destroy` — the property that holds today and must survive either option.
- **A retired lesson leaves the denominator and keeps its numerator.** A learner
  who finished 10 of 12 reads 10 of 11 after one of the two they had not reached
  is retired, and 10 of 11 — not 9 — after one they *had* finished is retired.
- **A retired lesson is unreachable but still nameable.** `GET /lesson?topic=` on
  it refuses; its completion, its submissions and its integrity case still print
  its name.
- **Retirement goes through the queue.** No direct route retires a lesson, the
  requester cannot decide their own request, and every decision is audited —
  the same three properties `syllabus_lesson_added` is already held to.
- **`topics.key` is never rewritten**, retired or not. Already enforced by
  `test/controllers/syllabus_builder_test.rb`.

## Consequences

- Until this is decided, `SyllabusBuilder` has no removal method and no route
  offers one. That is recorded in SPEC-0054's Scope as a refusal with its reason,
  not as an omission.
- Whichever option is chosen, `topics.key` stays the identity a completion joins
  by. Neither option renumbers keys.

## Decision owner

The Product Owner, with the Tech Lead on the read-path cost and the Academic
Owner on questions 1 and 2 — whether a course that loses a lesson changes what
past cohorts are measured against is an academic question before it is a
technical one.
