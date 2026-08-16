---
id: ADR-0017
type: adr
title: Define the Helping Hand award and community interaction boundary
status: accepted
owners: ["@product-owner", "@academic-owner", "@tech-lead", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-05
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - app/models/learner_progress.rb
  - app/models
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by:
  - test/models/awards_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define the Helping Hand award and community interaction boundary

> **Decision state:** Accepted by the user on 2026-08-05. Defer the Helping Hand
> feature until an approved, moderated community feature exists. Keep the badge
> visible but explicitly unavailable; it remains unearnable and introduces no
> forum, peer-review, moderation, staff-override, or award-credit records.

> [Decision Records](README.md) ·
> [M8 community specification](../specs/spec-m8-helping-hand-community.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Context

The award shelf contains a `Helping Hand` badge whose English hint says
“Answer 10 forum questions” and whose Thai hint says the equivalent. The award
rule is currently `forum_helper?`, which always returns false because the
application has no forum question or answer records. The landing page's
“community” content is marketing copy, not a learner interaction boundary.

Making the badge earnable therefore requires a product and teaching decision,
not just a counter. A community feature would introduce learner-generated
content, identity and visibility rules, moderation, reporting, academic
integrity concerns, privacy obligations, and an operational owner.

## Problem frame

- **Affected user:** A learner deciding whether and how to help peers, plus
  instructors or moderators responsible for the quality and safety of those
  interactions.
- **Current behavior:** The badge is visible but cannot be earned; no forum or
  peer-review record exists.
- **Failure risk:** The interface promises a social behavior the product does
  not support, or a rushed interaction feature rewards spam, unsafe advice,
  plagiarism, harassment, or exposure of learner data.
- **Success signal:** The academy either removes/relabels the unsupported
  promise or records approved, useful, safe contributions with a rule learners
  can understand and staff can moderate.

## Decision boundary

The accepted deferral policy is:

1. Do not add a forum, course Q&A, structured peer review, instructor-led
   discussion, or another learner-to-learner interaction feature in this scope.
2. Keep `forum_helper?` false and do not create forum, peer-review,
   contribution, moderation, reporting, or award-credit records or endpoints.
3. Keep the Helping Hand badge visible, but use Thai and English copy that says
   it is unavailable until a moderated community feature exists.
4. Do not let the badge affect progress, grades, completion, certificates,
   reports, access, notifications, or any other academic state.
5. Do not add staff grants, moderation queues, retraction rules, or support
   workflows for a feature that does not exist.
6. Revisit this ADR before any community implementation. A future feature needs
   a new or amended policy covering educational outcome, contribution evidence,
   identity, visibility, moderation, safety, privacy, award semantics, and
   operations.

## Alternatives

### Remove or defer the award

The product avoids promising a behavior it cannot support. This is the smallest
and safest option, but removes a visible community motivation until a later
decision.

### Redefine the award around existing learning evidence

The badge could reward a verifiable non-social behavior already recorded by the
academy. This is cheap and safe, but it changes the meaning of “Helping Hand”
and may reward the wrong teaching outcome.

### Add a staff-moderated course Q&A

Learners ask course-scoped questions and answers become award-eligible only
after an approved quality signal. This creates a bounded learning loop, but
requires moderation capacity, abuse handling, notification policy, and durable
records.

### Add structured peer review

Learners review approved work using a rubric rather than open discussion. This
can align better with pedagogy and academic writing, but needs assignment,
anonymity, conflict, feedback-quality, and assessment rules.

The remove-or-defer option is selected for the current increment. The other
options remain future alternatives and require a separate approved policy before
implementation.

## Consequences

The community boundary has the following consequences:

- The current increment adds no learner-authored content, community data,
  migrations, moderation operations, or notification paths.
- The badge remains a truthful, visible placeholder rather than promising a
  forum that learners cannot use.
- Progress, grades, completion, certificates, reports, access, and privacy
  boundaries remain unchanged because no community evidence is introduced.
- A future community feature will create an operational duty for reports,
  response times, retention, takedown, and escalation. Without an owner, it
  must remain disabled.

## Fitness Functions

- Every earnable Helping Hand contribution comes from a server-side record with
  an actor, target scope, accepted quality state, and timestamp.
- A learner cannot earn credit through self-answering, duplicate requests,
  client-supplied approval, deleted content, or unmoderated content when the
  policy requires review.
- Learner-generated content is visible only to the approved audience, and
  moderation/report actions do not reveal reporter identity beyond policy.
- The award hint, earned state, and community UI are consistent in English and
  Thai and never describe an unavailable feature as active; the current copy and
  unearnable rule are covered by `test/models/awards_test.rb`.
