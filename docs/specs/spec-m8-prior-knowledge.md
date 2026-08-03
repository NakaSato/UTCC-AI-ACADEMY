---
id: SPEC-0018
type: spec
title: Learner-marked prior knowledge and downstream progress policy
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-08-10
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
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-TEST-001]
---

# Learner-marked prior knowledge and downstream progress policy

> **Review state:** The user approved that “Mark as known” contributes to
> academic progress and course completion. This specification remains draft
> and blocked on authority, provenance, reversibility, and the remaining
> downstream effects. The knowledge map remains read-only until those rules are
> defined and verified.

> [Executable Specifications](README.md) ·
> [M8 prior-knowledge decision](../decisions/adr-0018-prior-knowledge-boundary.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Problem

The repository has copy for “Mark as known” but no record or server action. A
learner may need to skip familiar material, yet an unverified mark could be
mistaken for academy-completed learning and change unlocking, reporting, or
credentials.

## Scope

### Included after policy approval

- Define the prior-knowledge state and its relationship to `TopicCompletion`.
- Define learner, instructor, assessment, and administrator authority.
- Define course/topic scope, provenance, timestamp, reversibility, correction,
  and stale-write behavior.
- Define effects on navigation, prerequisites, progress, XP, gems, streaks,
  leaderboards, reports, completion, applied work, and certificates.
- Provide truthful Thai/English labels, explanations, confirmation, and error
  states.

### Excluded

- Inferring prior knowledge from browsing, imported profiles, or AI guesses.
- Granting official completion, applied credit, certificates, or grades without
  an explicit approved evidence rule.
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

- [ ] The Product Owner and Academic Owner approve the meaning, authority,
      provenance, reversibility, and downstream effects of prior knowledge
      (`docs/decisions/adr-0018-prior-knowledge-boundary.md`).
- [ ] Before approval, the knowledge map exposes no active mutation and no
      prior-knowledge mark changes progress (`test/controllers/knowledge_maps_controller_test.rb`).
- [ ] After approval, authorized actors can create, view, reverse, or request
      correction of the approved prior-knowledge state
      (`test/controllers/prior_knowledge_controller_test.rb`).
- [ ] Course/topic scope, uniqueness, stale writes, provenance, and database
      invariants are enforced (`test/models/prior_knowledge_test.rb`).
- [ ] The approved policy is applied consistently to map navigation, course
      progress, unlocking, reporting, leaderboards, and certificates
      (`test/models/prior_knowledge_policy_test.rb`).
- [ ] Existing academy completions and applied timestamps are not rewritten by
      a prior-knowledge mutation (`test/models/topic_completion_test.rb`).
- [ ] Thai and English browser walkthroughs explain the mark and its exact
      effects without promising unsupported credit
      (`test/system/prior_knowledge_walk_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

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

Implementation is held until the accountable owners complete this table.

| Review point | Decision required |
| --- | --- |
| Meaning | Navigation preference, mastery signal, or official completion. |
| Authority | Learner self-mark, placement assessment, instructor, or combination. |
| Scope | Course, section, topic kind, role, and certificate context. |
| Downstream effects | Map, unlocking, progress, XP/gems, reports, leaderboard, certificates. |
| Evidence | Provenance, assessment, confidence, review state, timestamp, and reason. |
| Reversal | Who can unmark/correct, when, and how historical effects are handled. |
| Academic safety | Assessment integrity, accommodations, fairness, and learner copy. |
| Operations | Audit, migration, support, monitoring, and rollback. |

## Rollback and observability

- Keep the current read-only map and academy-completion semantics as the rollback
  target until the policy is accepted and verified.
- Disabling prior knowledge must not delete or rewrite `TopicCompletion` rows;
  preserve approved history and apply the migration/read fallback.
- Monitor aggregate marks, reversals, verification outcomes, and fallback use;
  do not log learner answers or unnecessary personal data.

## Verification

```bash
bin/docs
bin/rails test test/models/prior_knowledge_test.rb test/models/prior_knowledge_policy_test.rb test/models/topic_completion_test.rb
bin/rails test test/controllers/knowledge_maps_controller_test.rb test/controllers/prior_knowledge_controller_test.rb
bin/rails test:system test/system/prior_knowledge_walk_test.rb
bin/verify
```
