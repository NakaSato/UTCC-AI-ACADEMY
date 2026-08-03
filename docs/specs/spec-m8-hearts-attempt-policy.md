---
id: SPEC-0016
type: spec
title: Learner hearts attempt, refill, and support policy
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0016]
implemented_by: []
touches:
  - app/models/learner_progress.rb
  - app/controllers/lessons_controller.rb
  - app/models/submission.rb
  - app/views/shared/_app_header.html.erb
  - app/views/lessons/show.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Learner hearts attempt, refill, and support policy

> **Review state:** Draft and blocked on academic and product policy. The
> current derived, non-blocking counter remains unchanged until the owners
> approve the behavior below.

> [Executable Specifications](README.md) ·
> [M8 hearts decision](../decisions/adr-0016-hearts-attempt-policy.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Problem

The application shows hearts derived from recent failed submissions, but the
meaning of zero hearts is not defined beyond the display. Learners and staff do
not have an approved answer to whether another attempt is allowed, when hearts
return, or how an exception is handled.

## Scope

### Included after policy approval

- Define the heart cost, maximum, refill timing, and zero-heart meaning.
- Define which lesson submission kinds and learner contexts are affected.
- Define duplicate/concurrent submission behavior at the server boundary.
- Define learner-facing explanations and Thai/English localization.
- Define instructor/administrator support, override, expiry, and audit behavior
  if the approved policy requires them.
- Preserve consistent effects across submissions, progress, unlocking,
  completion, certificates, and reports.

### Excluded

- Choosing the academic policy on behalf of the Product Owner or Academic Owner.
- Adding a generic admin toggle for hearts before the policy is accepted.
- Changing awards, leaderboards, forums, prior-knowledge marking, or
  notifications except where the accepted hearts rule explicitly requires it.
- Treating a browser counter as authorization to accept or reject an attempt.
- Deleting historical submissions or fabricating a balance for existing learners.

## Invariants

1. The server, not the browser display, decides whether a submission is allowed.
2. A rejected attempt does not create a submission, completion, progress, or
   misleading heart deduction unless the accepted policy explicitly defines a
   recorded rejection.
3. Duplicate and concurrent requests cannot deduct or grant more than the
   accepted policy permits.
4. Heart state never bypasses course access, proctoring, authorization, or
   assessment integrity rules.
5. A missing, malformed, or unavailable heart policy resolves to the approved
   safe fallback and is visible to operations without exposing learner data.
6. Any staff grant or override names an authorized actor, reason, scope, and
   expiry when the approved policy requires persisted support actions.
7. The learner-facing meaning and recovery timing are consistent in English and
   Thai.
8. Completion, certificate eligibility, instructor reporting, and leaderboard
   calculations use the approved attempt semantics rather than a display-only
   counter.

## Acceptance Criteria

- [ ] The Product Owner and Academic Owner approve zero-heart behavior, heart
      cost, refill, affected attempt kinds, exceptions, and support authority
      (`docs/decisions/adr-0016-hearts-attempt-policy.md`).
- [ ] Before approval, the current display-only behavior remains unchanged and
      no new persisted gate or admin control is exposed
      (`test/controllers/lesson_completion_test.rb`).
- [ ] After approval, allowed and rejected submissions follow the policy at the
      server boundary (`test/controllers/lesson_completion_test.rb`).
- [ ] Heart deduction/refill or the approved derived behavior is correct at
      zero, maximum, time-window, duplicate, and concurrent boundaries
      (`test/models/learner_progress_test.rb`).
- [ ] Support grants or overrides, if approved, enforce authority, scope,
      expiry, and audit behavior (`test/controllers/admin_hearts_test.rb`).
- [ ] Thai and English learner states explain remaining hearts, zero-heart
      behavior, and recovery without contradicting the server
      (`test/system/hearts_policy_walk_test.rb`).
- [ ] Existing submissions, completions, course unlocking, certificates, and
      reports remain consistent after migration (`test/models/hearts_policy_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- A learner reaches zero while a lesson page or submission is already open.
- Two tabs submit at the same time, or a browser retries after a timeout.
- A failure occurs exactly at the refill boundary or a clock changes timezone.
- A learner has no submissions, more failures than the maximum, or old failures
  outside the window.
- A learner changes course, section, role, or language while a policy is active.
- An instructor or administrator requests support without the required authority,
  reason, scope, or expiry.
- A policy row or grant is missing, duplicated, malformed, expired, or deleted.
- A rejected submission must not appear as a passed attempt or alter unrelated
  progress and completion evidence.

## Human Hearts Policy Handoff

Implementation is held until the accountable owners complete this table.

| Review point | Decision required |
| --- | --- |
| Meaning | Display-only, block at zero, or selected-context gate. |
| Cost | Which failed attempts consume a heart and when. |
| Recovery | Maximum, refill duration, scheduled grants, and offline behavior. |
| Scope | Global, course, section, role, assessment, or learner-specific rule. |
| Support | Instructor/admin authority, override reason, expiry, and appeal path. |
| Academic effect | Impact on practice, unlocking, completion, certificates, and reports. |
| Safety and inclusion | Accessibility, accommodations, learner communication, and privacy. |
| Operations | Audit fields, monitoring, correction, migration, and rollback. |

## Rollback and observability

- Keep the current display-only behavior as the rollback target until a new
  policy has demonstrated safe enforcement.
- If persisted state is introduced, rollback must stop enforcement or restore
  the approved safe fallback without deleting submissions, completions, grants,
  or audit history.
- Monitor rejected attempts, refill/override failures, and fallback use with
  aggregate data only; do not put learner answers or unnecessary identifiers in
  logs.

## Verification

```bash
bin/docs
bin/rails test test/models/learner_progress_test.rb test/controllers/lesson_completion_test.rb
bin/rails test test/models/hearts_policy_test.rb test/controllers/admin_hearts_test.rb
bin/rails test:system test/system/hearts_policy_walk_test.rb
bin/verify
```
