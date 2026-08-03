---
id: ADR-0018
type: adr
title: Define the meaning and effects of learner-marked prior knowledge
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-08-10
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
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-002]
---

# Define the meaning and effects of learner-marked prior knowledge

> **Decision state:** The user approved on 2026-08-04 that “Mark as known”
> counts toward academic progress and course completion. Authority, evidence,
> provenance, reversibility, and the exact treatment of other downstream
> signals remain open and must be defined before implementation.

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

The accountable owners must decide:

1. Whether learners may mark a topic as known at all, or whether only an
   instructor, placement assessment, or verified evidence may do so.
2. Whether the mark is a private navigation preference, a course-scoped mastery
   signal, or an official completion record.
3. Whether it affects map display, next-topic navigation, prerequisites,
   progress percentages, XP, gems, streaks, activity, leaderboards, instructor
   reports, course completion, applied projects, or certificates.
4. Whether the mark is reversible, whether the learner must complete an
   assessment before unmarking, and how relearning is recorded.
5. What provenance, timestamp, actor, reason, confidence, and review state are
   stored; and who can correct or override the record.
6. Whether the rule differs by course, topic kind, assessment, role, or
   certificate-bearing course.
7. How existing completion data remains distinct from any new prior-knowledge
   data and how Thai/English copy communicates the difference.

Until those decisions are accepted, the safe engineering baseline is to keep
the current behavior: no prior-knowledge mutation and no inferred completion.

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

“Mark as known” is an academic progress signal and contributes to course
completion. This does not, by itself, define whether it also grants XP, gems,
streaks, leaderboard credit, instructor-report facts, applied-project credit,
or certificate eligibility. Those effects require explicit policy decisions.

## Consequences

- A prior-knowledge record must not be added to `TopicCompletion` unless the
  owners explicitly decide that it has the same academic meaning as a completed
  topic.
- If a new record is persisted, its actor, scope, lifecycle, correction, and
  concurrency rules need database constraints and focused tests.
- Any effect on unlocking or certificates changes the learner's academic path
  and needs an explicit review rather than an inferred convenience behavior.
- The knowledge map, learner progress, course catalog, reports, leaderboard,
  and certificate logic must consume the same approved distinction.

## Fitness Functions

- A learner-marked topic cannot silently become a completion, applied project,
  certificate, or report fact without an accepted policy and explicit provenance.
- Repeated, stale, unauthorized, cross-course, and conflicting marks resolve
  according to one server-side rule and do not create duplicate state.
- Every affected screen distinguishes prior knowledge from completed learning in
  Thai and English, or the approved policy treats them as the same state and the
  distinction is removed consistently.
- Removing or disabling the feature preserves historical academy completions and
  does not strand a learner behind an unapproved inferred state.
