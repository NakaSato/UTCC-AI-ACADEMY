---
id: SPEC-0002
type: spec
title: Complete the AI1101 foundation course content
status: proposed
owners: ["@product-owner", "@instructor"]
created: 2026-08-01
updated: 2026-08-01
review_by: 2026-08-15
supersedes: []
superseded_by: []
depends_on: [SPEC-0001]
implemented_by: []
touches:
  - app/models/lesson_content.rb
  - app/controllers/lessons_controller.rb
  - app/views/lessons
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models/placeholder_content_test.rb
  - test/controllers/lesson_completion_test.rb
  - test/system/learning_walk_test.rb
enforced_by:
  - test/models/placeholder_content_test.rb
  - test/controllers/lesson_completion_test.rb
  - test/system/learning_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-TEST-001]
---

# Complete the AI1101 Foundation Course

> [Executable Specifications](README.md) ·
> [Milestone 3](../roadmap.md#milestone-3--complete-foundation-course) ·
> [M2 first-topic specification](spec-m2-first-real-topic.md) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Proposed. The Product Owner and instructor must assign
> content owners, approve objectives, and confirm the review cadence before
> implementation begins.

## Problem

M2 proves that one topic can carry unique bilingual content and topic-scoped
grading. The remaining AI1101 topics still fall back to shared placeholder
content, so learners cannot complete a coherent foundation course.

## Scope

### Included

Create approved Thai and English theory, exercise, applied/coding task, feedback,
objectives, and summary content for these remaining topics:

| Key | Topic |
| --- | --- |
| 1-2 | Types of data |
| 1-3 | Measuring data quality |
| 2-1 | How models learn |
| 2-2 | Loss and metrics |
| 2-3 | Supervised vs. Unsupervised |
| 2-4 | Overfitting and regularization |
| 3-1 | Prepare data with pandas |
| 3-2 | Train, evaluate, tune |
| 4-1 | How LLMs work |
| 4-2 | Writing prompts that work |
| 5-1 | Assessing the business case |
| 5-2 | Thai business case study |
| 6-1 | Bias in data |
| 6-2 | Data privacy |

Preserve the existing four-step lesson flow, server-side grading boundary,
progress/unlocking model, and Thai/English locale parity.

### Excluded

- Changing course taxonomy or adding new AI1101 topics.
- Replacing the lesson renderer with a new frontend architecture.
- Production email, deployment, or external content-management features.
- Marking content complete without instructor and learner review evidence.

## Invariants

1. Every syllabus topic has a unique content definition; no topic silently falls
   back to the shared placeholder once M3 is accepted.
2. Every topic has matching Thai and English objective, exercise, feedback, and
   assessment structures in the same order.
3. Every answer key and grading pattern remains server-side.
4. A passing assessment records the topic key in the URL and unlocks only the
   syllabus-defined next topic.
5. A content change cannot alter progress denominators or completion semantics.

## Acceptance Criteria

- [ ] Every listed topic renders unique Thai and English content
      (`test/models/placeholder_content_test.rb`).
- [ ] Every listed topic has an objective-to-assessment mapping reviewed by an
      instructor (`test/models/placeholder_content_test.rb`).
- [ ] Failed and successful attempts preserve existing recording and unlocking
      behavior (`test/controllers/lesson_completion_test.rb`).
- [ ] At least one browser walkthrough per module demonstrates the four-step
      path (`test/system/learning_walk_test.rb`).
- [ ] Terminology and positional locale structures remain aligned
      (`test/models/placeholder_content_test.rb`).
- [ ] Each module has instructor review and small learner-test evidence recorded
      before the backlog item is completed (`docs/backlog.json`).

## Error and Boundary Cases

- A missing topic translation fails validation rather than falling back silently.
- A topic-specific answer key cannot be exposed in rendered HTML.
- Locked topics remain inaccessible even when a valid answer is posted.
- Repeated passing attempts remain idempotent for completion records.

## Verification

```bash
bin/rails test test/models/placeholder_content_test.rb test/controllers/lesson_completion_test.rb
bin/rails test:system test/system/learning_walk_test.rb
bin/docs
bin/verify
```

