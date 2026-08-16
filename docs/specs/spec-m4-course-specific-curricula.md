---
id: SPEC-0003
type: spec
title: Course-specific curricula
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-01
updated: 2026-08-01
review_by: 2026-10-30
supersedes: []
superseded_by: []
depends_on: [SPEC-0002]
implemented_by:
  - db/migrate/20260802100000_add_course_to_course_modules.rb
  - app/models/course.rb
  - app/models/course_module.rb
  - app/models/topic.rb
  - app/models/syllabus.rb
  - app/models/course_catalog.rb
  - app/models/instructor_report.rb
  - app/controllers/courses_controller.rb
  - app/controllers/lessons_controller.rb
  - app/models/leaderboard.rb
  - app/controllers/leaderboards_controller.rb
  - app/views/leaderboards
  - db/seeds.rb
touches:
  - app/models/course.rb
  - app/models/course_module.rb
  - app/models/topic.rb
  - app/models/syllabus.rb
  - app/models/learner_progress.rb
  - app/controllers/lessons_controller.rb
  - db/migrate
  - db/seeds.rb
  - test/models
  - test/controllers
enforced_by:
  - test/models/learner_progress_test.rb
  - test/models/topic_completion_test.rb
  - test/controllers/lesson_completion_test.rb
  - test/models/placeholder_content_test.rb
  - test/models/course_curriculum_test.rb
  - test/controllers/course_curriculum_test.rb
  - test/system/course_curriculum_walk_test.rb
  - test/models/leaderboard_test.rb
  - test/controllers/leaderboard_frame_test.rb
  - test/models/instructor_report_test.rb
agent_writable: false
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-ARCH-003, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-TEST-001]
---

# Course-specific curricula

> **Review state:** Accepted by the Product Owner and Tech Lead on 2026-08-01.
> M4 implementation is authorized after the M3 learner-validation dependency is
> resolved.

> [Executable Specifications](README.md) ·
> [M3 foundation-course specification](spec-m3-foundation-course.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Roadmap Milestone 4](../roadmap.md#milestone-4--course-specific-curricula)

## Problem

All courses currently reuse one shared module and topic syllabus. A learner
therefore sees the same curriculum structure regardless of the selected course,
and progress, locking, reporting, and completion denominators cannot represent
course-specific requirements.

## Scope

### Included

- Associate each course module with exactly one course.
- Preserve stable topic identity while making topic ordering unique within a
  course.
- Migrate the current shared syllabus to AI1101 without changing existing
  completion records.
- Resolve lesson, progress, map, instructor-report, and leaderboard queries by
  the selected course.
- Add at least one second course with a deliberately different module/topic
  shape in seeds and fixtures.
- Define course-specific completion denominators and certificate requirements.

### Excluded

- Writing the full content for every course in the catalog.
- Changing the lesson renderer or grading protocol.
- Replacing topic completion history with a destructive migration.
- Changing the AI1101 content or claiming M3 learner validation.

## Decisions resolved by ADR-0005

1. Completions remain scoped to `(user, course, topic)`.
2. Topic keys remain globally unique while lesson requests require a selected
   course.
3. `course_id` is added directly to `course_modules`.
4. Existing modules are backfilled to AI1101 in one reversible migration, which
   aborts safely if an existing completion cannot be mapped.

## Invariants

1. Every course module belongs to exactly one course, and a course cannot have
   duplicate module positions.
2. Every topic belongs to one course through its module, and positions are
   unique within that course module.
3. A lesson, progress denominator, report, and leaderboard query uses the
   selected course rather than a process-wide shared syllabus.
4. Existing completion records remain attributable to their original course
   after migration; no migration silently reassigns a learner's history.
5. A locked topic in one course cannot be opened by supplying a topic key from
   another course.

## Acceptance Criteria

- [ ] Two seeded courses expose different module/topic structures
      (`test/models/course_curriculum_test.rb`).
- [ ] Course/module/topic uniqueness and foreign-key rules are enforced at the
      database and model boundaries (`test/models/course_curriculum_test.rb`).
- [ ] Lesson URLs resolve only within the selected course and reject cross-course
      topic access (`test/controllers/lessons_controller_test.rb`).
- [ ] Progress denominators, locked/current/done states, reports, and
      leaderboards use the selected course (`test/models/course_curriculum_test.rb`,
      `test/controllers/lessons_controller_test.rb`).
- [ ] Existing completion records survive the migration unchanged
      (`test/models/topic_completion_test.rb`).
- [ ] A browser walkthrough demonstrates two distinct course curricula
      (`test/system/course_curriculum_walk_test.rb`).

## Verification

```bash
bin/docs
bin/rails test test/models/course_curriculum_test.rb test/controllers/lessons_controller_test.rb
bin/rails test:system test/system/course_curriculum_walk_test.rb
bin/verify
```

Implementation must still wait for the M3 learner-validation dependency. The
existing `enforced_by` tests are the current baseline; M4-specific tests named
in the acceptance criteria do not exist until implementation begins.
