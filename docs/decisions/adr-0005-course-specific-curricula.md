---
id: ADR-0005
type: adr
title: Model course-specific curricula
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-01
updated: 2026-08-01
review_by: 2026-10-30
supersedes: []
superseded_by: []
depends_on: [SPEC-0003]
implemented_by:
  - db/migrate/20260802100000_add_course_to_course_modules.rb
  - app/models/syllabus.rb
  - app/models/leaderboard.rb
  - test/models/course_curriculum_test.rb
  - test/models/leaderboard_test.rb
touches:
  - app/models/course.rb
  - app/models/course_module.rb
  - app/models/topic.rb
  - app/models/syllabus.rb
  - app/models/learner_progress.rb
  - db/migrate
  - db/seeds.rb
enforced_by: []
agent_writable: false
---

# Model Course-Specific Curricula

> **Decision state:** Accepted by the Product Owner on 2026-08-01. This record
> authorizes the design direction only; migrations still require the accepted
> M4 specification and the M3 dependency to be resolved.

> [Decision Records](README.md) ·
> [M4 specification](../specs/spec-m4-course-specific-curricula.md) ·
> [Roadmap Milestone 4](../roadmap.md#milestone-4--course-specific-curricula) ·
> [Project Development Flow](../development-flow.md)

## Context

`CourseModule` and `Topic` currently describe one shared syllabus. `Course`
already exists as a catalog entity, but modules do not belong to it. The M4
roadmap requires at least two courses with different curricula while preserving
existing learner completion history and course-scoped progress.

The change affects database ownership, public topic URLs, completion identity,
progress denominators, lesson authorization, reports, and seed/fixture data.
Those rules must be agreed before a migration is written.

## Decision

Introduce an explicit `course_id` relationship on `course_modules`, enforce
module and topic ordering at the database boundary, and make all syllabus reads
require a selected course. Keep topic keys globally unique so existing URL
identifiers remain stable, and keep completions scoped to `(user, course,
topic)` as the current database uniqueness already requires.

The migration must:

1. Backfill the existing shared modules to AI1101 in one reversible migration.
2. Make module positions unique per course and topic positions unique within a
   course module.
3. Preserve existing topic keys while requiring the selected course in lesson,
   progress, and reporting queries.
4. Abort safely if an existing completion cannot be mapped to its original
   course and topic.

## Alternatives

### Add `course_id` to `course_modules`

Keeps modules reusable within one course and makes course ownership explicit.
It requires backfilling the current shared syllabus and revisiting every query
that currently assumes one global `Syllabus`.

### Add a course-module join table

Allows the same module definition to be reused by several courses. It avoids
duplicating module rows, but makes ordering, topic identity, and course-specific
overrides harder to enforce and explain.

### Keep one shared syllabus and filter at the application layer

Smallest migration, but it cannot satisfy the M4 requirement for distinct
course curricula and leaves the database unable to enforce ownership.

## Consequences

The chosen ownership and completion rules require a data migration, query
changes, seed/fixture updates, and a rollback plan. This ADR does not accept
the implementation specification or authorize deployment.

## Fitness Functions

- `bin/docs` validates this ADR's frontmatter, links, and lifecycle headings.
- The accepted ADR must name the migration order, rollback strategy, and
  database constraints before implementation begins.
- M4 acceptance tests must demonstrate two distinct course curricula and prove
  that cross-course topic access and completion reassignment are impossible.
