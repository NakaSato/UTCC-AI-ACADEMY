---
id: ADR-0032
type: adr
title: Start matching with candidate-owned factor previews instead of consequential ranking
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0029, ADR-0030, ADR-0031, SPEC-0029, SPEC-0031]
implemented_by:
  - SPEC-0032
  - app/services/recruitment/job_match_preview.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - app/views/recruitment/job_posts/show.html.erb
touches:
  - app/models
  - app/controllers
  - app/services
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/job_match_preview_test.rb
  - test/controllers/recruitment/job_match_preview_controller_test.rb
agent_writable: true
---

# Start Matching with Candidate-Owned Factor Previews Instead of Consequential Ranking

> [Decision Records](README.md) ·
> [Match-preview specification](../specs/spec-recruitment-match-preview.md) ·
> [Job-discovery specification](../specs/spec-recruitment-job-discovery.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for candidate-owned,
> factor-level, provider-neutral job-match previews. Numeric scores,
> recruiter-facing candidate views, override policies, screening use, and other
> consequential ranking remain prohibited.

## Context

M8 proposes semantic retrieval, vector search, LLM ranking, and a numeric match
signal. The current repository has no approved recruiter access to candidate
profiles and no human-reviewed matching dataset or fairness monitoring contract.
Introducing a score now would create a consequential signal before its weighting,
calibration, privacy, and override policy can be reviewed.

## Decision

- Begin with a candidate-owned, per-job preview generated at read time from the
  candidate's own profile facts, salary/location fields, discovery preferences,
  and the published job post.
- Show six factor cards: skill, experience, salary, location/work mode,
  preferences, and learning/growth. Each card includes state, evidence, source,
  and uncertainty.
- Use deterministic rules as `rules_preview`; do not introduce vector stores,
  hosted models, aggregate scores, or ranking.
- Treat missing evidence as `unknown`, never as a negative decision. A mismatch
  is explanatory only and cannot block browsing or applying.
- Keep the preview candidate-only. Recruiter views, candidate sharing, recorded
  overrides, and screening influence require a later approved boundary.

## Alternatives

### Add the proposed 98% score immediately

Rejected. A number would be read as a ranking or eligibility signal without an
approved dataset, calibration, fairness review, or human override workflow.

### Persist every factor calculation

Rejected for the first slice. The preview is derived from current data and should
not become a stale employment record; future evaluation telemetry must be
designed with retention and consent first.

### Expose candidate profiles to recruiters now

Rejected. M5 deliberately keeps the self-service profile boundary private until
visibility, application reuse, and employer disclosure are approved.

## Consequences

- Candidates get inspectable explanations immediately, without a new model or
  ranking dependency.
- Matching quality cannot yet be measured as recruiter acceptance or placement;
  the next design must define a human-reviewed evaluation set and counter-metrics.
- Recruiter override and employer-side comparison remain visible gaps rather than
  silently becoming hidden behavior.

## Fitness Functions

- A preview is unavailable to staff and for hidden jobs.
- Every factor has evidence, source, and uncertainty; no factor exposes a score.
- Missing evidence produces `unknown`, not rejection or ineligibility.
- Protected characteristics are not read or emitted by the preview service.
- `bin/docs` and focused match-preview tests pass.
