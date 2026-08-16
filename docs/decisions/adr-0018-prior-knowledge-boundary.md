---
id: ADR-0018
type: adr
title: Define the meaning and effects of learner-marked prior knowledge
status: accepted
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-05
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - app/models/topic_completion.rb
  - app/models/learner_progress.rb
  - app/models/knowledge_map.rb
  - app/models/syllabus.rb
  - app/controllers
  - app/views/knowledge_maps
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by:
  - test/models/prior_knowledge_test.rb
  - test/models/learner_progress_test.rb
  - test/models/knowledge_map_test.rb
  - test/controllers/prior_knowledges_controller_test.rb
  - test/controllers/knowledge_maps_controller_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-002]
---

# Define the meaning and effects of learner-marked prior knowledge

> **Decision state:** Accepted by the user on 2026-08-05. A learner may mark a
> topic as known for the selected course, and may reverse that mark. It counts
> toward knowledge-map progress and course completion only. It does not grant
> XP, gems, streaks, awards, reports, applied work, certificates, or unlocking.

> [Decision Records](README.md) ·
> [M8 prior-knowledge specification](../specs/spec-m8-prior-knowledge.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Context

The knowledge map is a read model derived from syllabus topics and
`TopicCompletion` rows. It currently has no prior-knowledge record or mutation
route. The locale files contain “Mark as known” copy, but the control is not
rendered. A completion currently means the learner completed an academy
learning action; it contributes to progress, XP, gems, streaks, leaderboards,
reports, unlocking, and course completion.

Allowing a learner to mark a topic as already known could reduce unnecessary
repetition, but it could also turn an unverified claim into completion evidence.
The distinction matters for prerequisites, applied projects, certificates,
instructor reporting, and academic integrity.

## Problem frame

- **Affected user:** A learner with relevant prior study, and instructors or
  academic staff who rely on progress and completion signals.
- **Current behavior:** No prior-knowledge action exists; only recorded academy
  completions count as mastery.
- **Failure risk:** A self-attestation silently grants progress, unlocks,
  certificate eligibility, or leaderboard credit without an approved evidence
  rule; or learners are forced through content they can already demonstrate.
- **Success signal:** The map explains what “known” means, navigation and
  academic evidence are kept distinct unless explicitly joined, and every
  affected downstream calculation follows one approved rule.

## Decision boundary

The accepted policy is:

1. A signed-in learner may create or reverse their own prior-knowledge mark for
   a valid topic in the selected course. No staff verification or override path
   is introduced in this increment.
2. The mark is stored in a separate, course-scoped record with the learner,
   course, topic, and timestamp. The database enforces foreign keys and one mark
   per learner/course/topic; repeated requests are idempotent.
3. The mark contributes to the knowledge map's learned total and the course's
   academic progress and completion calculation. Existing academy completions
   remain separate and are never rewritten.
4. The mark does not affect lesson unlocking, next-topic navigation, XP, gems,
   streaks, activity, awards, leaderboards, instructor reports, applied work,
   certificates, or any other downstream signal.
5. Reversal deletes only the learner's own prior-knowledge record. It leaves
   academy completion, submission, and applied timestamps unchanged.
6. Thai and English copy explain the exact limited effect. A future change to
   authority, verification, scope, or downstream effects requires a new policy
   review before implementation.

## Alternatives

### Keep prior knowledge as a navigation-only preference

Store or derive a learner's “skip/review later” preference without changing
completion, unlocking, reporting, or credentials. This protects academic
evidence and is reversible, but may not provide the intended accelerated path.

### Treat self-attestation as learned progress

The learner's mark creates the same completion evidence as finishing the lesson.
This is simple and convenient, but is difficult to defend for certificates,
reports, and prerequisite mastery without assessment or provenance.

### Require a placement check or instructor verification

Prior knowledge can affect official progress only after an approved assessment
or staff review. This protects academic meaning, but adds workflow, support
cost, and a clear authority requirement.

### Separate “known” from “completed” with explicit downstream rules

A persisted prior-knowledge record can influence selected navigation or
unlocking behavior while remaining excluded from completion and credentials.
This is more expressive, but creates two kinds of learner state that every
screen and report must explain consistently.

### Approved policy direction

“Mark as known” is a learner-owned academic progress signal and contributes to
course completion. It is deliberately excluded from XP, gems, streaks, activity,
awards, leaderboards, reports, applied-project credit, certificates, and
unlocking. The record remains separate from academy completion so the policy can
be reversed without rewriting learning evidence.

## Consequences

- A prior-knowledge record remains separate from `TopicCompletion`; completion
  timestamps and applied timestamps are never copied or rewritten.
- The persisted record's actor, course/topic scope, uniqueness, timestamp, and
  concurrency behavior are enforced by foreign keys, a unique index, and focused
  model/controller tests.
- The knowledge map and course progress consume the approved union of completion
  and prior-knowledge topics; XP, activity, awards, reports, and certificates
  consume completion evidence only.

## Fitness Functions

- A learner-marked topic cannot silently become an applied project, certificate,
  or report fact; its separate row preserves learner provenance and timestamp.
- Repeated, stale, unauthorized, cross-course, and conflicting marks resolve
  according to one server-side rule and do not create duplicate state.
- Every affected screen distinguishes prior knowledge from completed learning in
  Thai and English, or the approved policy treats them as the same state and the
  distinction is removed consistently.
- Removing or disabling the feature preserves historical academy completions and
  leaves the learner's completion evidence unchanged after prior-knowledge rows
  are removed according to the approved rollback procedure.
