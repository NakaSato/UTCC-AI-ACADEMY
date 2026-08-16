---
id: SPEC-0032
type: spec
title: Candidate-owned explainable job match preview
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0029, ADR-0030, ADR-0031, ADR-0032, SPEC-0029, SPEC-0031]
implemented_by:
  - app/services/recruitment/job_match_preview.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - app/views/recruitment/job_posts/show.html.erb
  - test/models/recruitment/job_match_preview_test.rb
  - test/controllers/recruitment/job_match_preview_controller_test.rb
touches:
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
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-PROD-002, SKILL-AI-002]
min_reviewer_skills: [SKILL-ARCH-004, SKILL-TEST-001, SKILL-PROD-002, SKILL-AI-002]
---

# Candidate-Owned Explainable Job Match Preview

> [Executable Specifications](README.md) ·
> [Factor-preview boundary ADR](../decisions/adr-0032-factor-level-job-match-previews.md) ·
> [Job-discovery specification](spec-recruitment-job-discovery.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Job discovery now explains why a job was suggested, but M8 needs a more explicit
factor breakdown. The breakdown must help a candidate understand evidence and
missing information without becoming a hidden score, recruiter ranking, or
eligibility decision.

## Scope

### Included

- A read-time candidate-only preview on a visible public job.
- Factor cards for skill, experience, salary, location/work mode, explicit
  preferences, and learning/growth.
- Per-factor state (`match`, `partial`, `mismatch`, `unknown`), evidence, source,
  and uncertainty.
- Deterministic `rules_preview` logic using only candidate-controlled inputs and
  published job fields.

### Excluded

- Numeric aggregate scores, candidate ranking, eligibility decisions, or blocking
  a candidate from viewing or applying.
- Protected-characteristic or proxy inference.
- Recruiter-facing candidate comparisons, recruiter overrides, employer disclosure,
  vector retrieval, LLM ranking, and persistent match histories.

## Invariants

1. Only the signed-in student sees their own preview; staff never receives it.
2. Hidden, inactive, expired, or non-published jobs have no preview.
3. The preview always emits all six factor keys with evidence, source, and
   uncertainty; missing evidence is `unknown`.
4. The service has no aggregate score and cannot make a browsing, application,
   or eligibility decision.
5. The service reads only approved candidate fields and never protected traits.
6. Salary comparison does not perform currency conversion or infer total
   compensation; incomplete ranges are `unknown`.

## Acceptance Criteria

- [x] A student with a visible job can inspect all six factor explanations.
- [x] Each factor displays evidence, source, state, and limitation.
- [x] Missing profile data is presented as unknown rather than rejection.
- [x] Staff and hidden jobs receive no candidate match preview.
- [x] No numeric score or eligibility decision is rendered.
- [x] The service remains provider-neutral and introduces no new external data
      store or model dependency.

## Boundary Cases

- No profile or no structured facts produces unknown factors, not an error.
- Salary ranges with missing values or different currencies produce unknown.
- A preference mismatch remains explanatory and never prevents application.
- Pausing, closing, archiving, suspending the organization, or expiring a job
  removes the preview at the visibility boundary.

## Measurement contract

The preview emits no new durable outcome metric in this increment. Before a
future recruiter-facing or ranked release, Product and Data owners must define a
human-reviewed evaluation set, precision/acceptance baseline, explanation
satisfaction measure, override rate, and counter-metrics for privacy complaints,
unwanted applications, subgroup parity, and drift.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/job_match_preview_test.rb test/controllers/recruitment/job_match_preview_controller_test.rb
    bin/verify
