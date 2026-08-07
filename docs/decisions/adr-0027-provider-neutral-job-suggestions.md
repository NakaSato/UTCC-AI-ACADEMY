---
id: ADR-0027
type: adr
title: Persist provider-neutral job suggestions with human review
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0026, SPEC-0026]
implemented_by:
  - SPEC-0027
  - app/models/recruitment/job_post_suggestion.rb
  - app/services/recruitment/job_suggestion_generator.rb
  - app/controllers/recruitment/job_suggestions_controller.rb
  - db/migrate/20260807130000_create_recruitment_job_post_suggestions.rb
touches:
  - app/models
  - app/controllers
  - app/services
  - app/views
  - db/migrate
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/job_post_suggestion_test.rb
  - test/controllers/recruitment/job_suggestions_controller_test.rb
agent_writable: true
---

# Persist Provider-Neutral Job Suggestions with Human Review

> [Decision Records](README.md) ·
> [AI job-creation specification](../specs/spec-recruitment-ai-job-creation.md) ·
> [Job-management ADR](adr-0026-recruitment-job-post-boundary.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Draft. This increment creates the review boundary and a
> rules-based preview provider; a human Product, Technical, Security/Privacy,
> and Recruitment Domain review is required before connecting an external AI
> provider.

## Context

Milestone M3 calls for AI assistance while keeping recruiters in control. The
repository has no approved model provider, model-retention policy, or external
AI security boundary. Writing generated text directly into a job post would
erase provenance and make it difficult to distinguish employer-authored text
from a suggestion.

## Decision

- Store each suggestion separately from the job post with kind, content,
  provider, model, source label, uncertainty, status, and review actor.
- Use a provider interface. The first implementation uses a clearly labelled
  `rules_preview` provider so the workflow is demonstrable without claiming an
  external model was used.
- Generate suggestions only from approved employer job inputs; do not include
  candidate profiles, protected characteristics, or hidden ranking data.
- Let an authorized organization job author generate, edit, accept, reject, or
  regenerate each suggestion.
- Accepting a summary or description suggestion updates the draft job only;
  other suggestion kinds remain reviewable evidence attached to the job.
- No suggestion can publish a job. The existing review and owner/hiring-manager
  publication workflow remains mandatory.
- Record provider and uncertainty labels with every suggestion and audit each
  generation and review action without storing secret tokens.

## Alternatives

### Call an external model directly from the controller

Rejected. It would couple domain behavior to an unapproved provider, make
timeouts and data egress implicit, and prevent deterministic local verification.

### Overwrite job fields with generated text

Rejected. It loses the original suggestion, provenance, review decision, and
ability to compare major edits.

### Wait for the provider decision before building any workflow

Rejected for this increment. The review boundary and data contract can be
validated safely with the rules preview provider before external connectivity
is approved.

## Consequences

- The first generated content is a preview, not a claim that an AI model ran.
- A future provider adapter must preserve the suggestion schema, provenance,
  uncertainty, consent, and audit behavior.
- Suggestions increase storage and review complexity, but preserve reversibility
  and human accountability.

## Fitness Functions

- Every suggestion has a provider, source label, uncertainty, and review state.
- A suggestion cannot be accepted by a user outside the organization job-author
  boundary.
- Accepted suggestions never change a published job or bypass publication.
- A generated suggestion contains only the approved job-input context.
- `bin/docs` and focused suggestion model/controller tests pass.
