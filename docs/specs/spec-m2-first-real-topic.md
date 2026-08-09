---
id: SPEC-0001
type: spec
title: Deliver the first real bilingual AI1101 topic
status: accepted
owners: ["@product-owner", "@instructor"]
created: 2026-08-01
updated: 2026-08-09
review_by: 2026-08-23
supersedes: []
superseded_by: []
depends_on: []
implemented_by: [8cf9dc3]
touches:
  - app/models/lesson_content.rb
  - app/controllers/lessons_controller.rb
  - app/views/lessons/_theory.html.erb
  - app/views/lessons/_exercise.html.erb
  - app/views/lessons/_code.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models/placeholder_content_test.rb
  - test/controllers/lesson_completion_test.rb
enforced_by:
  - test/models/placeholder_content_test.rb
  - test/controllers/lesson_completion_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-TEST-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-TEST-001]
---

# First Real Bilingual AI1101 Topic

> [Executable Specifications](README.md) ·
> [Milestone 2](../roadmap.md#milestone-2--first-real-topic) ·
> [Project Development Flow](../development-flow.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> **Review state:** Accepted by the Product Owner and instructor on 2026-08-01.
> The approved objectives, invariants, grading criteria, and acceptance intent
> are implementation authority for M2-001.

## Problem

Every syllabus topic currently renders the same placeholder lesson. That makes
the four-step flow demonstrable, but it does not prove that the content seam can
carry a real topic with its own objectives, bilingual copy, assessment, and
feedback.

## Scope

### Included

- Topic `1-1`, **What AI is, and actually does**.
- A Thai and English lesson that expresses the same approved objectives.
- One topic-specific exercise with a server-side answer key.
- One topic-specific applied or coding task with server-side criteria.
- Topic-specific feedback, completion, progress, and next-topic behavior.
- Instructor review and a small student validation session recorded as evidence.

### Excluded

- Replacing content for the remaining placeholder topics.
- Changing the four-step lesson flow, submission model, or progress schema.
- Selecting the complete AI1101 curriculum or changing course taxonomy.
- Production deployment or external email delivery.

## Proposed learning objectives

The learner should be able to:

1. Explain AI as a system that uses data and rules or learned models to produce
   predictions, classifications, recommendations, or generated outputs.
2. Distinguish an AI capability from a deterministic rule or ordinary software
   automation using a concrete business example.
3. Identify the input, output, and evaluation question in a small AI use case.
4. State one limitation or risk that must be checked before trusting an AI
   output.

The Product Owner and instructor must confirm or revise these objectives before
acceptance.

## Invariants

1. Topic `1-1` never renders the placeholder lesson copy after this spec is
   accepted and implemented.
2. Thai and English objective lists have the same length and preserve the same
   order and meaning.
3. The answer key and coding criteria remain server-side and are never rendered
   before a graded submission.
4. A failed attempt is recorded without awarding completion; a passing attempt
   records the same topic key used by the lesson URL.
5. Completing topic `1-1` unlocks only the syllabus-defined next topic; no
   unrelated topic becomes available.

## Acceptance Criteria

- [ ] Given a learner opens topic `1-1`, when the theory step renders, then the
      copy is topic-specific in Thai and English and names the approved
      objectives (`test/models/placeholder_content_test.rb`).
- [ ] Given the learner switches locale, when the same topic renders, then the
      objective and lesson structures remain positionally aligned
      (`test/models/placeholder_content_test.rb`).
- [ ] Given a learner submits an incorrect exercise or incomplete code, when the
      server grades it, then the attempt is retained and the topic is not
      completed (`test/controllers/lesson_completion_test.rb`).
- [ ] Given a learner submits the approved exercise and code, when both server
      verdicts pass, then topic `1-1` is completed and the next-topic link uses
      `Syllabus.topic_after("1-1")` (`test/controllers/lesson_completion_test.rb`).
- [ ] Given a page is rendered before submission, when its HTML is inspected,
      then answer keys and code patterns are absent
      (`test/controllers/lesson_completion_test.rb`).
- [ ] Given the instructor and a small student group review the lesson, when
      their findings are recorded, then unresolved content issues are listed
      before the item moves to complete (`docs/backlog.json`).

## Error and Boundary Cases

- Unknown topic keys continue to be rejected by the existing controller.
- Locked topics remain inaccessible even if a learner posts a valid answer.
- A locale missing a topic field fails the parity test rather than falling back
  silently.
- Repeated passing submissions remain idempotent for topic completion while
  preserving the attempt history.

## Verification

```bash
bin/rails test test/models/placeholder_content_test.rb test/controllers/lesson_completion_test.rb
bin/docs
bin/verify
```
