---
id: ADR-0016
type: adr
title: Define the learner hearts attempt and refill policy
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
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
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define the learner hearts attempt and refill policy

> **Decision state:** Agent-prepared draft. The Product Owner and Academic
> Owner must decide whether hearts are display-only or an attempt gate, and
> what learner support and override rules apply before the current behavior is
> changed.

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

The accountable owners must decide:

1. Whether zero hearts blocks any new graded attempt, only selected attempt
   kinds, or no attempt at all.
2. Whether a failure costs a heart on every attempt, only once per topic/round,
   or according to another approved rule.
3. Whether refill remains passive time-based recovery, becomes a scheduled
   grant, or has another duration and maximum.
4. Whether a learner may continue an in-flight attempt after reaching zero, and
   how duplicate or concurrent submissions are handled.
5. Whether an instructor or administrator can grant an exception, who may do so,
   for how long, with what audit event, and without exposing unnecessary data.
6. Whether course, section, role, accessibility, or assessment context changes
   the rule.
7. How the rule affects topic unlocking, completion, certificates, reports,
   notifications, and learner-facing Thai/English explanations.

Until those decisions are accepted, the safe engineering baseline is to retain
the current display-only behavior and not persist or enforce a new gate.

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

No option is selected by this draft. The display-only baseline remains the
fallback until the human policy is accepted.

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
