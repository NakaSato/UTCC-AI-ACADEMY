---
id: SPEC-0008
type: spec
title: Real course-scoped knowledge map
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-09
supersedes: []
superseded_by: []
depends_on: [SPEC-0003, ADR-0008]
implemented_by:
  - app/models/knowledge_map.rb
  - app/controllers/knowledge_maps_controller.rb
  - app/views/knowledge_maps/show.html.erb
touches:
  - app/models/knowledge_map.rb
  - app/controllers/knowledge_maps_controller.rb
  - app/views/knowledge_maps/show.html.erb
  - app/models/syllabus.rb
  - app/models/learner_progress.rb
enforced_by:
  - test/models/knowledge_map_test.rb
  - test/controllers/knowledge_maps_controller_test.rb
  - test/system/knowledge_map_walk_test.rb
agent_writable: false
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Real course-scoped knowledge map

> **Review state:** Accepted by the user on 2026-08-02 after the Product Owner
> and QA / SDET acceptance-test intent was reviewed against the recorded
> evidence.

> [Executable Specifications](README.md) ·
> [M5 architecture decision](../decisions/adr-0008-real-knowledge-map.md) ·
> [Roadmap Milestone 5](../roadmap.md#milestone-5--real-knowledge-map) ·
> [M4 course-specific curricula](spec-m4-course-specific-curricula.md)

## Problem

The knowledge map currently renders a static taxonomy with hardcoded totals,
hardcoded mastery, and fixed AI1101 links. It cannot reflect the selected
course's modules, topics, completions, or project prerequisites.

## Scope

### Included

- Derive map groups and leaves from the selected course's modules and topics.
- Derive learned counts from the selected course's completions.
- Support course and project modes with URL-preserved selection.
- Link every topic node to the selected course's lesson URL.
- Use the approved sequential prerequisite rule for project mode.
- Remove the non-functional “Mark as known” and settings controls from this
  slice.
- Safely normalize unknown course, mode, and node parameters.

### Excluded

- A general prerequisite graph editor or arbitrary cross-course edges.
- New map-specific persistence or mastery counters.
- A new learner action that bypasses lesson assessment.
- Rewriting the lesson renderer, grading protocol, or course curriculum data.
- Full map content authoring for every unmodeled catalog course.

## Invariants

1. Every rendered topic node belongs to the selected course.
2. Map topic totals equal `Syllabus.topic_count(selected_course)`.
3. Learned counts equal selected-course `TopicCompletion` rows and never include
   another course's rows.
4. A topic node's lesson link includes both its selected course code and topic
   key.
5. A project prerequisite is a topic in the same course that precedes the
   project under the approved prerequisite policy.
6. Unknown or cross-course node parameters never expose a topic from another
   course and resolve to a safe selected node.
7. No map-specific write is required to render or update node state.

## Acceptance Criteria

- [x] AI1101 and AI1102 render different map shapes and course-scoped totals
      (`test/models/knowledge_map_test.rb`,
      `test/controllers/knowledge_maps_controller_test.rb`).
- [x] Passing or recording a topic changes only that selected course's node
      state (`test/models/knowledge_map_test.rb`).
- [x] Course mode links every actionable topic to the matching course lesson
      (`test/controllers/knowledge_maps_controller_test.rb`).
- [x] Project mode exposes each selected-course project and its prerequisites
      according to the approved policy (`test/models/knowledge_map_test.rb`).
- [x] Unknown course, mode, and node parameters fall back safely without a
      cross-course topic (`test/controllers/knowledge_maps_controller_test.rb`).
- [x] A browser walkthrough demonstrates distinct AI1101 and AI1102 maps
      (`test/system/knowledge_map_walk_test.rb`).
- [x] Non-functional controls are removed or their approved behavior is covered
      by tests (`test/controllers/knowledge_maps_controller_test.rb`).

## Error and Boundary Cases

- A course with no own curriculum shows an empty safe map or the approved
  compatibility state; it must not attach another course's topics to its
  completions.
- An unknown node falls back to the selected course's first valid node.
- A topic key from another course is rejected even when supplied with a valid
  map course parameter.
- A course with no completed topics renders all nodes not started.
- A fully completed course renders all topic leaves complete and zero remaining.
- A project with no prerequisites renders an explicit empty prerequisite state.

## Resolved Review Decisions

- Sequential syllabus order is the prerequisite policy for M5.
- Project mode shows each project and its selected-course prerequisites.
- “Mark as known” and the non-functional settings control are removed from M5;
  a future audited learner action would require a new specification.

## Human Acceptance Record

The Product Owner and QA / SDET reviewed the implementation and automated
checks against the following evidence and boundaries before acceptance:

| Review point | Evidence | Accepted boundary |
| --- | --- | --- |
| Course-scoped shape, totals, mastery, and safe parameter fallback | [Model and controller tests](../../test/models/knowledge_map_test.rb) and [controller tests](../../test/controllers/knowledge_maps_controller_test.rb) | Selected-course isolation is required. |
| Project mode shows the project plus sequential same-course prerequisites | [Project-mode model/controller coverage](../../test/models/knowledge_map_test.rb) | This is the accepted learner-facing project workflow. |
| A catalog course without owned curriculum renders an empty safe map | [Unmodeled-course coverage](../../test/models/knowledge_map_test.rb) | Empty state is preferred to compatibility content. |
| Browser walkthrough exposes distinct AI1101 and AI1102 maps | [System walkthrough](../../test/system/knowledge_map_walk_test.rb) | The two-course walkthrough is the acceptance path. |
| “Mark as known” and settings controls are absent | [Controller control-boundary coverage](../../test/controllers/knowledge_maps_controller_test.rb) | Removal is the accepted learner experience. |

The approval is a human lifecycle decision; automated validation remains
evidence rather than a substitute for review.

## Verification

```bash
bin/docs
bin/rails test test/models/knowledge_map_test.rb test/controllers/knowledge_maps_controller_test.rb
bin/rails test:system test/system/knowledge_map_walk_test.rb
bin/verify
```
