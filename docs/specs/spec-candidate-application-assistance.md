---
id: SPEC-0035
type: spec
title: Provider-neutral candidate application preparation assistance
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0033, ADR-0035, SPEC-0033]
implemented_by:
  - app/services/recruitment/candidate_application_assistant.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications/show.html.erb
  - test/services/recruitment/candidate_application_assistant_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
enforced_by:
  - test/services/recruitment/candidate_application_assistant_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
touches:
  - app/services
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - test/services
  - test/controllers
agent_writable: true
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002, SKILL-AI-004]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002, SKILL-AI-004]
---

# Provider-Neutral Candidate Application Preparation Assistance

> [Executable Specifications](README.md) ·
> [Candidate-assistance ADR](../decisions/adr-0035-candidate-application-preparation-assistance.md) ·
> [Application-workflow specification](spec-recruitment-application-workflow.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Candidates can see their application stage, but they do not yet receive a
structured, candidate-owned prompt for what to prepare next. M11 needs a safe
first slice that helps with preparation without acting on the candidate's
behalf or exposing private recruiter information.

## Scope

### Included

- Read-time checklist on the candidate's own application detail page.
- Stage-aware items for submitted, screening, interview, offer, and terminal
  application states.
- Source labels and an uncertainty statement.
- Deterministic `rules_preview` behavior with no external provider.

### Excluded

- Auto-apply, employer contact, interview scheduling, offer negotiation,
  candidate ranking, qualification inference, recruiter-note access, external
  messaging, and persistent agent memory.

## Invariants

1. Only the application candidate can receive the checklist.
2. The service reads only the application status, statement presence, and
   candidate-visible job fields.
3. The service returns preparation guidance only; it cannot mutate an
   application or contact another party.
4. Every checklist item has an explicit source and the full result has an
   uncertainty statement.
5. The assistant never invents experience, skills, certifications, or outcomes.
6. The same application and reference state produce the same checklist.

## Acceptance Criteria

- [ ] A candidate sees stage-appropriate preparation items on their application.
- [ ] A recruiter can view the application but not the candidate checklist.
- [ ] Another candidate and an unauthenticated user receive no checklist.
- [ ] The checklist never changes application state or creates an outbound side
      effect.
- [ ] Terminal applications receive closure/reflection guidance, not an action
      that implies re-opening or appealing the decision.
- [ ] English and Thai copy identify the guidance as advisory.

## Verification

    bin/docs
    bin/rails test test/services/recruitment/candidate_application_assistant_test.rb test/controllers/recruitment/job_applications_controller_test.rb
    bin/verify
