---
id: SPEC-0018
type: spec
title: Learner-marked prior knowledge and downstream progress policy
status: accepted
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-05
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: [ADR-0018]
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-TEST-001]
---

# Learner-marked prior knowledge and downstream progress policy

> **Review state:** Accepted by the user on 2026-08-05. Learners may create and
> reverse course-scoped prior-knowledge marks. The marks affect knowledge-map
> progress and course completion only; all other downstream signals remain
> completion-based.

> [Executable Specifications](README.md) ·
> [M8 prior-knowledge decision](../decisions/adr-0018-prior-knowledge-boundary.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Problem

The repository has copy for “Mark as known” but no record or server action. A
learner may need to skip familiar material, yet an unverified mark could be
mistaken for academy-completed learning and change unlocking, reporting, or
credentials.

## Scope

### Included

- Persist a learner-owned, course-scoped prior-knowledge record separate from
  `TopicCompletion`.
- Provide idempotent create and reversible delete operations for valid topics.
- Include prior knowledge in knowledge-map totals and course progress/completion.
- Keep unlocking, next-topic navigation, XP, gems, streaks, activity, awards,
  leaderboards, reports, applied work, and certificates completion-based.
- Provide truthful Thai/English labels, explanation, confirmation, and error
  states.

### Excluded

- Inferring prior knowledge from browsing, imported profiles, or AI guesses.
- Granting official completion, applied credit, certificates, or grades without
  an explicit approved evidence rule.
- Adding staff verification, moderation, correction, or override workflows.
- Editing historical `TopicCompletion` rows to represent a new self-attestation.
- Course-wide or institution-wide bypasses from a client-supplied parameter.
- Changing syllabus prerequisite order or curriculum taxonomy in this slice.

## Invariants

1. The server validates the course, topic, actor, scope, and policy before
   creating or changing a prior-knowledge record.
2. Prior knowledge and academy completion remain separate records unless the
   accepted policy explicitly defines identical semantics.
3. A prior-knowledge mark affects only the downstream behaviors named by the
   accepted policy; it cannot leak into unapproved progress, reporting,
   leaderboard, certificate, or assessment calculations.
4. Duplicate, stale, unauthorized, cross-course, and malformed mutations leave
   prior-knowledge and completion state unchanged.
5. A learner can see what the mark changes, what it does not change, and how to
   reverse or request correction in the active locale.
6. Instructor or administrator overrides require the accepted authority,
   provenance, reason, scope, and audit behavior.
7. Removing the feature preserves academy completions and resolves any remaining
   prior-knowledge state according to the approved migration rule.
8. All affected read models use the same course-scoped policy and do not invent
   a second meaning for the mark.

## Acceptance Criteria

- [x] The user approves learner self-marking, course scope, reversibility, and
      the limited downstream effects (`docs/decisions/adr-0018-prior-knowledge-boundary.md`).
- [x] A valid mark is persisted separately, idempotently, with foreign keys and
      course/topic scope (`test/models/prior_knowledge_test.rb`).
- [x] Learners can create and reverse their own marks; invalid courses, topics,
      and project-mode requests are rejected
      (`test/controllers/prior_knowledges_controller_test.rb`).
- [x] Map progress and course completion include prior knowledge while XP, gems,
      activity, awards, reports, applied work, certificates, and unlocking do not
      (`test/models/learner_progress_test.rb`, `test/models/knowledge_map_test.rb`).
- [x] Thai and English map copy explains the exact limited effect and the map
      exposes no prior-knowledge control in project mode
      (`test/controllers/knowledge_maps_controller_test.rb`).
- [x] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- A learner marks an unknown topic, a topic in another course, or a locked topic.
- The learner submits the same mark twice or submits from two stale tabs.
- An instructor attempts to verify a mark without the approved course/section
  authority.
- A learner reverses a mark after it affected navigation or a report.
- A prior-knowledge record exists when a course is archived, a topic changes, or
  a certificate is requested.
- The feature is disabled after records exist; migration and read behavior must
  follow the accepted rollback rule.
- A locale is missing the distinction between known, completed, applied, and
  verified states.
- A direct request tries to set `learned_at`, `applied_at`, certificate credit,
  or another downstream field through the prior-knowledge endpoint.

## Human Prior-Knowledge Policy Handoff

The accepted policy closes the current handoff. A future authority, verification,
or downstream-effect change must reopen this table before implementation.

| Review point | Decision required |
| --- | --- |
| Meaning | Learner-owned academic prior-knowledge signal; it contributes to course completion. |
| Authority | The learner may mark or reverse their own course-scoped record. |
| Scope | One valid course/topic pair; no staff or cross-course override. |
| Downstream effects | Map progress and course completion only. |
| Evidence | User, course, topic, and marked timestamp; no assessment claim. |
| Reversal | The learner deletes their own mark; academy completions remain unchanged. |
| Academic safety | Copy names excluded XP, activity, awards, reports, applied work, certificates, and unlocking. |
| Operations | Foreign keys, unique index, idempotent writes, and full verification. |

## Rollback and observability

- Keep the current academy-completion semantics as the rollback target; remove
  prior-knowledge rows and restore map/progress reads to completion-only.
- Disabling prior knowledge must not delete or rewrite `TopicCompletion` rows;
  preserve approved history and apply the migration/read fallback.
- Monitor aggregate marks, reversals, verification outcomes, and fallback use;
  do not log learner answers or unnecessary personal data.

## Verification

```bash
bin/docs
bin/rails test test/models/prior_knowledge_test.rb test/models/learner_progress_test.rb test/models/knowledge_map_test.rb
bin/rails test test/controllers/knowledge_maps_controller_test.rb test/controllers/prior_knowledges_controller_test.rb
bin/verify
```
