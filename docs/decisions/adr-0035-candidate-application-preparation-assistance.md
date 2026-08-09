---
id: ADR-0035
type: adr
title: Start the AI candidate agent with candidate-controlled application preparation guidance
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0033, ADR-0034, SPEC-0033, SPEC-0034]
implemented_by:
  - SPEC-0035
  - app/services/recruitment/candidate_application_assistant.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications/show.html.erb
touches:
  - app/services
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - test/services
  - test/controllers
agent_writable: true
enforced_by:
  - test/services/recruitment/candidate_application_assistant_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
---

# Start the AI Candidate Agent with Candidate-Controlled Application Preparation Guidance

> [Decision Records](README.md) ·
> [Candidate-assistance specification](../specs/spec-candidate-application-assistance.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-09 for the advisory
> candidate application-preparation slice: a candidate-owned checklist with
> deterministic rules_preview behavior, source and uncertainty disclosure, and
> the prohibition on acting for the candidate. Legal, security, recruitment,
> privacy, data, and QA owners must still review it before production or
> external candidate use.

## Context

The M11 roadmap describes a career assistant that can help candidates find work,
track applications, prepare for interviews, and plan learning. Auto-apply and
employer contact are explicitly sensitive actions. The existing candidate-owned
application view provides a safe boundary for a first slice: guidance can be
generated from the candidate's own application stage without contacting anyone
or exposing recruiter-only information.

## Decision

- Add a provider-neutral, read-time preparation checklist to the candidate's
  own application detail page.
- Derive checklist items from the application stage, job-post fields already
  visible to the candidate, and the candidate's submitted statement presence.
- Label every item as advisory and identify its source and uncertainty.
- Do not call an external model, persist recommendations, submit an
  application, contact an employer, infer qualifications, or expose recruiter
  notes and stage-transition notes.
- Keep the assistant candidate-only. Recruiters continue to use the separate
  M10 workflow assistant.

## Alternatives

### Auto-apply to matching jobs

Rejected. Explicit candidate permission, scope, revocation, rate limits,
artifact review, and audit policy are not yet approved.

### Read recruiter notes to tailor preparation

Rejected. Recruiter notes are organization-private and are not part of the
candidate disclosure boundary.

### Use resume or profile inference immediately

Rejected for this slice. The candidate can review their own profile, but an
agent must not invent qualifications or turn unreviewed extraction into advice.

## Consequences

- Candidates get a small, transparent preparation aid inside an application
  they own.
- Guidance is generic and cannot replace a real interview, career, or legal
  advisor.
- Future candidate-agent features need separate permission, tool, retention,
  and evaluation boundaries.

## Fitness Functions

- Only the application candidate receives the checklist.
- The checklist has no external side effect and no persistent agent record.
- No recruiter-only event notes, protected traits, or inferred qualifications
  are read or emitted.
- `bin/docs` and focused candidate-assistance tests pass.
