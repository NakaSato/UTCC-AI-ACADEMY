---
id: ADR-0008
type: adr
title: Derive the knowledge map from course curricula
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-10-31
supersedes: []
superseded_by: []
depends_on: [SPEC-0003]
implemented_by: []
touches:
  - app/models/knowledge_map.rb
  - app/controllers/knowledge_maps_controller.rb
  - app/views/knowledge_maps/show.html.erb
  - app/models/syllabus.rb
enforced_by:
  - test/models/knowledge_map_test.rb
  - test/controllers/knowledge_maps_controller_test.rb
agent_writable: false
requires_skills: [SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-002]
---

# Derive the knowledge map from course curricula

> **Decision state:** Accepted by the Product Owner and Tech Lead on 2026-08-02
> after review of the sequential prerequisite, project-mode, and control
> decisions. This authorizes implementation against SPEC-0008.

> [Decision Records](README.md) ·
> [M5 specification](../specs/spec-m5-real-knowledge-map.md) ·
> [Roadmap Milestone 5](../roadmap.md#milestone-5--real-knowledge-map) ·
> [M4 course-specific curricula](../specs/spec-m4-course-specific-curricula.md)

## Context

The current map is a static taxonomy with invented totals, invented mastery,
hardcoded project markers, a fixed AI1101 link, and controls that do not perform
an operation. M4 now makes `CourseModule`, `Topic`, and course-scoped
completions authoritative, so the map should read the same curriculum and
learner state as course and progress screens.

## Decision

Build the map as a course-scoped read model derived from `Syllabus` and
`TopicCompletion`:

1. Modules are the top-level map groups and topics are their leaves.
2. The URL carries `course`, `mode`, and selected node; an invalid course or
   node falls back to AI1101 and its first valid node.
3. Course mode shows every module/topic. Project mode shows project topics and
   their prerequisite topics from the selected course.
4. A topic is a prerequisite of a project when it precedes that project in the
   selected course's syllabus order. This is a sequential baseline until a
   human-approved graph model exists.
5. “Mark as known” and settings are removed from the first M5 slice unless the
   Product Owner explicitly chooses a persisted learner action and its policy.
6. Node totals and states are computed from the selected course's topics and
   completions; no map-specific mastery counters are stored.

## Alternatives

### Keep the static taxonomy and replace only its counts

Smallest UI change, but the taxonomy cannot represent course-specific modules,
topic URLs, or project prerequisites without a second source of truth.

### Add a separate knowledge-map graph table

Supports arbitrary relationships, but creates a second curriculum graph that
can drift from course modules and topics. It is deferred until sequential
prerequisites prove insufficient.

### Derive a sequential map from the course syllabus (recommended baseline)

Uses existing M4 ownership and ordering, makes the first vertical slice
explainable, and is reversible. Its limitation is that non-linear prerequisites
must wait for an explicit graph decision.

## Consequences

The map becomes course-aware and its totals cannot drift from progress. Existing
static locale node keys will need a compatibility or removal plan, and the
project mode must explain the prerequisite rule. The selected node must link to
`lesson_path(course:, topic:)`, so a map node cannot silently open another
course.

## Resolved human decisions

- Sequential syllabus order is the M5 prerequisite baseline.
- Project mode is a filtered project-plus-prerequisite view.
- “Mark as known” and the non-functional settings control are removed from the
  M5 slice.

## Fitness Functions

- `bin/docs` validates lifecycle metadata, links, and skill references.
- Map totals equal `Syllabus.topic_count(course)` and selected-course learned
  completions.
- Every actionable node link carries both the selected course and topic key.
- A cross-course topic or unknown node cannot be opened through map parameters.
