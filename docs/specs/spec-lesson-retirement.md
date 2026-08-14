---
id: SPEC-0055
type: spec
title: Retiring a lesson without retiring its history
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-14
updated: 2026-08-14
review_by: 2026-08-28
supersedes: []
superseded_by: []
depends_on: [ADR-0055, ADR-0054, ADR-0013]
implemented_by:
  - app/models/topic.rb
  - app/models/syllabus.rb
  - app/models/syllabus_builder.rb
  - app/models/approval_request.rb
  - app/controllers/instructor_controller.rb
  - app/views/instructor/_syllabus.html.erb
  - config/routes.rb
enforced_by:
  - test/controllers/lesson_retirement_test.rb
  - test/controllers/syllabus_builder_test.rb
touches:
  - app/controllers
  - app/models
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db
  - test
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-ARCH-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002]
---

# Retiring a Lesson Without Retiring Its History

> **Review state:** Accepted on 2026-08-14 on the authority of
> [ADR-0055](../decisions/adr-0055-lesson-retirement.md), which the user accepted
> the same day by taking Option B as drafted — including both halves of the
> semantic choice.

> [Executable Specifications](README.md) ·
> [Lesson retirement decision](../decisions/adr-0055-lesson-retirement.md) ·
> [Teaching course authority](spec-teaching-course-authority.md)

## Problem

`topic.destroy` has never had a safe outcome. `topic_completions` and
`prior_knowledges` are `dependent: :destroy`, so it erases what learners
finished; `submissions` and `proctor_events` hold a foreign key, so it fails on
the constraint. SPEC-0054 gave a teacher their syllabus and stopped at removal
for exactly this reason.

## Scope

**In:** retiring a lesson through the approval queue, and the read-path change
that makes a retired lesson stop being offered.

**Out:**

- **Un-retiring.** `retired_at` is nullable and nothing sets it back. When it is
  wanted it is a second request kind, not a button — recorded so its absence is a
  decision rather than an oversight.
- **Deleting a topic.** No route does, and none may.

## The rule

`topics.retired_at`. A retired lesson:

| | |
| --- | --- |
| Appears in the syllabus, course page, knowledge map | **No** |
| Is reachable at `/lesson?topic=` | **No** — `flash.topic_missing` |
| Counts toward a denominator | **No** — `topic_count`, `applied_topic_count`, `InstructorReport`, the catalogue |
| Counts for a learner who already finished it | **Yes** |
| Can still be named | **Yes** |
| Keeps its completions, submissions, proctor events | **Yes** — untouched |
| Appears in "topics students struggle with" | **No** — the panel asks what to fix in the syllabus as it stands |

**One boundary enforces it.** Every screen reads its topic set through
`Syllabus.topics`, `topic_keys` or `topic_count` — the catalogue's counts, the
lesson's next key, the knowledge map, the integrity switches and both progress
models — so the filter lives in `Syllabus` and nowhere else. `Syllabus.topic_name`
is the one deliberate exception: it looks through retired lessons too, because a
completion and an integrity case still have to say which lesson they meant.

**The numerator outlives the denominator.** A learner who finished 12 of 12 and
then sees one retired has 12 completions and 11 lessons. That is the accepted
semantics, not a bug — so the three `percent` helpers clamp to 100 rather than
printing 109%.

## Invariants

1. No route destroys a `Topic`.
2. A retirement happens only through the queue; `retire_lesson!`'s only caller is
   `ApprovalRequest#apply!`.
3. Nobody decides their own retirement request.
4. One pending retirement per lesson.
5. A retirement request names a lesson that is this course's and still live.
6. Retiring changes no `topic_completions`, `submissions`, `prior_knowledges` or
   `proctor_events` row.
7. A retired lesson is still nameable in every language it has a name in.
8. A learner's percentage never exceeds 100 and never falls because a lesson was
   retired.
9. Both locales carry every string.

## Acceptance Criteria

- Asking creates a pending request and retires nothing; approving retires the
  lesson and creates and destroys no rows; rejecting leaves it live.
- A second request for the same lesson answers
  `flash.retirement_request_invalid`.
- Another course's lesson, an unknown key, a teacher who does not teach the
  course, and a student are each refused.
- After retirement: the lesson is absent from `topic_keys`, `keys_in`, `modules`
  and `topic_count`; `Syllabus.topic(key)` is nil; `topic_name(key)` is unchanged.
- A learner who had finished it keeps a positive percentage, and that percentage
  is at most 100.
- It leaves the Teaching console's hardest-topics panel while its submissions
  stay in the table.
- Opening it answers `flash.topic_missing`.
- The decision is audited as `lesson_retirement_decided`, at `warn`, and the
  sentence contains no interpolated hash.

## Verification

- `test/controllers/lesson_retirement_test.rb` — every row above, including the
  guard that nothing in the syllabus path calls `Topic#destroy`.
- `test/controllers/syllabus_builder_test.rb` — the addition half of the same
  queue, and that `topics.key` survives a reorder.

## Consequences

- The syllabus stops being a present-tense fact. A course can lose a lesson
  without rewriting what past cohorts were measured against, which is what
  ADR-0055 set out to make possible.
- `percent` clamping is now load-bearing rather than defensive, in three models.
- Un-retiring is the next thing somebody will want, and it is deliberately not
  here.
