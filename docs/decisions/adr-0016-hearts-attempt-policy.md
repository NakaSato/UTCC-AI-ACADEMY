---
id: ADR-0016
type: adr
title: Define the learner hearts attempt and refill policy
status: accepted
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: []
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
enforced_by:
  - test/models/learner_progress_test.rb
  - test/controllers/lesson_completion_test.rb
  - test/controllers/app_header_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define the learner hearts attempt and refill policy

> **Decision state:** Accepted by the user on 2026-08-04. Hearts remain a
> display-only learner signal: five hearts maximum, one heart per failed
> submission, and passive refill as each failure leaves the four-hour window.
> Zero hearts never blocks an attempt. No instructor or administrator grants,
> overrides, or persisted heart balance are introduced.

> [Decision Records](README.md) ·
> [M8 hearts specification](../specs/spec-m8-hearts-attempt-policy.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Context

`LearnerProgress` currently derives a heart count from failed submissions in a
four-hour window. The display has a maximum of five hearts, reaches zero after
enough recent failures, and passively refills as failures age out. The lesson
submission endpoint still accepts a graded attempt at zero hearts. No row stores
a heart balance, and no instructor or administrator override exists.

This is an academic and learner-experience rule, not merely a counter change.
Blocking a learner can affect practice, accessibility, assessment fairness,
course progress, support workload, and the meaning of completion evidence.

## Problem frame

- **Affected user:** A learner deciding whether they may continue practising,
  and staff supporting a learner who has exhausted the displayed hearts.
- **Current behavior:** Failed submissions reduce a derived display for four
  hours, but zero hearts does not block a new attempt.
- **Failure risk:** A punitive gate is introduced without an approved recovery,
  accommodation, explanation, or staff path; or a motivational counter remains
  confusing and untrustworthy.
- **Success signal:** Learners can predict what zero hearts means, staff can
  explain and support the rule, and progress/reporting remain consistent with
  the approved academic policy.

## Decision boundary

The accepted policy is:

1. Zero hearts never blocks a graded attempt; the server continues accepting
   attempts at zero.
2. Each failed submission contributes one recent failure to the display. A
   duplicate or concurrent failed submission follows the same existing
   submission semantics; no separate heart transaction is introduced.
3. The display has a maximum of five hearts. Each failure leaves the display
   after four hours, passively restoring one heart; no scheduled grant exists.
4. The rule is global and display-only. It does not vary by course, section,
   role, accessibility context, or assessment kind.
5. Instructors and administrators cannot grant, override, or edit hearts.
6. Hearts do not affect unlocking, completion, certificates, reports,
   notifications, or academic evidence.
7. Existing Thai and English heart copy remains aligned with the display-only
   behavior; no blocking or support workflow is exposed.

## Alternatives

### Keep hearts display-only

The existing derived counter remains a motivational signal and never prevents a
submission. This is reversible and preserves access, but may not deliver the
intended pacing or recovery behavior.

### Block every graded attempt at zero

This creates a clear pacing rule, but risks preventing practice, requires a
recovery and support path, and makes concurrency and accessibility decisions
mandatory.

### Block only selected attempts or contexts

For example, a policy could gate a new graded round while allowing review or
practice. This can reduce harm, but is harder to explain and test because the
server must classify every attempt consistently.

### Persist per-learner heart balances and grants

This supports explicit grants, overrides, and audit history, but introduces new
state, reconciliation, migration, privacy, and operational responsibilities.

The display-only option is selected. The other options remain documented as
rejected because they would introduce an academic gate, recovery workflow, and
persisted state that the owners did not approve.

## Consequences

- A gate cannot be implemented safely from the current display alone; the
  submission boundary, learner copy, recovery path, and staff support path must
  agree.
- A persisted balance would need transactional deduction/refill semantics and
  protection against duplicate or concurrent submissions.
- Any override or grant becomes an administrative mutation that needs actor,
  reason, scope, expiry, and audit rules.
- Removing or retaining hearts affects the M7 feature-flag policy and must not
  turn an unapproved academic rule into an admin toggle.

## Fitness Functions

- A learner-facing zero-heart state has one documented meaning in Thai and
  English, and the server enforces the same meaning as the interface.
- A failed, duplicate, concurrent, or unauthorized attempt cannot create a
  heart change inconsistent with the accepted policy.
- Any approved block, refill, grant, or override is covered by focused model,
  controller, and system tests, with no change to progress or completion rows
  on a rejected attempt.
- Missing or malformed policy state falls back to the approved safe behavior and
  is observable without exposing learner-level data.
