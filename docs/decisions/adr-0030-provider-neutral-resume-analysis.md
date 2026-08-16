---
id: ADR-0030
type: adr
title: Keep resume analysis provider-neutral, evidence-bound, and candidate-reviewed
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0029, SPEC-0029]
implemented_by:
  - SPEC-0030
  - app/models/recruitment/candidate_resume_analysis.rb
  - app/models/recruitment/candidate_resume_finding.rb
  - app/services/recruitment/candidate_resume_analysis_generator.rb
  - app/controllers/recruitment/candidate_resume_analyses_controller.rb
  - db/migrate/20260808110000_create_recruitment_candidate_resume_analyses.rb
touches:
  - app/models
  - app/controllers
  - app/services
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/candidate_resume_analysis_test.rb
  - test/models/recruitment/candidate_resume_finding_test.rb
  - test/controllers/recruitment/candidate_resume_analyses_controller_test.rb
agent_writable: true
---

# Keep Resume Analysis Provider-Neutral, Evidence-Bound, and Candidate-Reviewed

> [Decision Records](README.md) ·
> [Resume-analysis specification](../specs/spec-recruitment-resume-analysis.md) ·
> [Candidate-profile specification](../specs/spec-recruitment-candidate-profile.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for the provider-neutral,
> evidence-bound, candidate-reviewed resume-analysis boundary. No production
> model provider or consequential downstream use is selected or authorized.

## Context

M6 needs resume parsing and useful structure without turning extraction into a
hidden hiring judgment. A resume is candidate-owned sensitive data. The system
must preserve what was observed, what was inferred, how uncertain the result is,
and what the candidate corrected before any result becomes a profile fact.

## Decision

- Persist one analysis record per explicit candidate request, with provider,
  source label, source metadata, generation time, status, and uncertainty.
- Persist each finding separately with a bounded kind, evidence, source type,
  confidence, inference flag, and review status.
- Use `rules_preview` as the only provider in this increment. Plain-text resumes
  use bounded section-label rules; PDF and Word resumes record metadata and an
  explicit not-parsed uncertainty finding.
- Require candidate review for every finding. A correction changes the proposed
  value and keeps the original evidence visible; accepting is separate from
  applying.
- Apply only accepted fact-compatible findings to the candidate-owned profile,
  preserving `document_extracted` source and confidence. ATS signals, strengths,
  gaps, seniority, and uncertainty remain analysis evidence until a later policy
  explicitly defines their use.
- Do not read, infer, store, expose, or rank by protected characteristics.
  Resume analysis is not a candidate score, recommendation, or recruiter search.

## Alternatives

### Call a hosted model directly from the profile form

Rejected. It would bind the product to a provider before data residency,
retention, redaction, evaluation, and human-review policy are approved.

### Apply extracted facts automatically

Rejected. Extraction is uncertain and a candidate correction is a required
control, not an optional UI enhancement.

### Treat ATS signals as ranking features

Rejected. ATS readiness is an inspectable workflow signal only in this increment;
it must not become a proxy score for selection.

## Consequences

- The first increment provides useful, bounded text parsing while clearly
  disclosing that PDF and Word text is not yet extracted.
- Candidates must spend time reviewing findings, and product measurement must
  track correction and acceptance rates before any provider is expanded.
- A future provider can be added behind the same persisted evidence contract,
  but it must pass privacy, subgroup accuracy, retention, and human-review gates.

## Fitness Functions

- A missing resume or non-owner request cannot create an analysis.
- Every finding exposes evidence, source type, confidence, and whether it is an
  inference; every candidate action is audited.
- Only candidate-owned analyses and findings are reachable through the route.
- Apply requires accepted findings and never applies non-fact analysis signals.
- The rules provider emits no protected-characteristic fields and never ranks a
  candidate.
- `bin/docs` and focused analysis tests pass.
