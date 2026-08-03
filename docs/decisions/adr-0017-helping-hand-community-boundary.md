---
id: ADR-0017
type: adr
title: Define the Helping Hand award and community interaction boundary
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
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
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define the Helping Hand award and community interaction boundary

> **Decision state:** Agent-prepared draft. The Product Owner, Academic Owner,
> and Privacy Owner must decide whether a learner-to-learner interaction is an
> appropriate academy feature before the award is made earnable.

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

The accountable owners must decide:

1. Whether the academy needs a forum, course Q&A, structured peer review,
   instructor-led discussion, or no in-product community feature.
2. What “helping” means educationally and what evidence qualifies: an accepted
   answer, useful review, citation, explanation, or another behavior.
3. Who may ask, answer, review, edit, hide, report, or moderate; whether student
   and instructor identities are shown; and what visibility scope applies.
4. Whether an answer needs instructor acceptance or another quality signal before
   it contributes to the award.
5. How spam, self-answering, duplicate answers, collusion, harassment, unsafe
   advice, plagiarism, and personal data are handled.
6. How edits, deletion, moderation, rejected answers, account removal, and
   appeals affect the contribution and any already-earned award.
7. Whether the award is removed, renamed, or retained while the feature remains
   unavailable, and how Thai/English copy communicates the state.

Until those decisions are accepted, the safe engineering baseline is to keep the
award unearnable and avoid creating an unmoderated learner communication path.
The existing copy should not be treated as evidence that a forum exists.

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

No option is selected by this draft.

## Consequences

The community boundary has the following consequences:

- Learner-authored content must be treated as untrusted input and rendered with
  the same sanitization and authorization discipline as academic posts.
- The public/learner/staff boundary must define which content and identity
  fields are visible; private learner data must not enter award copy or logs.
- A contribution record and an award calculation should be separate boundaries:
  moderation or deletion must not silently rewrite immutable history.
- A community feature creates an operational duty for reports, response times,
  retention, takedown, and escalation. Without an owner, do not enable it.

## Fitness Functions

- Every earnable Helping Hand contribution comes from a server-side record with
  an actor, target scope, accepted quality state, and timestamp.
- A learner cannot earn credit through self-answering, duplicate requests,
  client-supplied approval, deleted content, or unmoderated content when the
  policy requires review.
- Learner-generated content is visible only to the approved audience, and
  moderation/report actions do not reveal reporter identity beyond policy.
- The award hint, earned state, and community UI are consistent in English and
  Thai and never describe an unavailable feature as active.
