---
id: SPEC-0034
type: spec
title: Provider-neutral advisory recruiter next-action assistance
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0033, ADR-0034, SPEC-0033]
implemented_by:
  - app/services/recruitment/job_application_assistant.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications/show.html.erb
  - test/services/recruitment/job_application_assistant_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
enforced_by:
  - test/services/recruitment/job_application_assistant_test.rb
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

# Provider-Neutral Advisory Recruiter Next-Action Assistance

> [Executable Specifications](README.md) ·
> [Recruiter-assistance ADR](../decisions/adr-0034-recruiter-advisory-next-action-assistance.md) ·
> [Application-workflow specification](spec-recruitment-application-workflow.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Recruiters can inspect an application pipeline, but a growing pipeline makes it
easy to miss the next manual review step. M10 needs an advisory assistant that
surfaces workflow attention without turning candidate data into an automated
employment decision.

## Scope

### Included

- Read-time assistance on an organization-authorized application detail page.
- One recommendation: review, continue screening, prepare interview, review
  offer workflow, or close the record based on the current stage.
- A deterministic attention flag when the stage has exceeded its review-age
  threshold.
- Source fields, threshold, and uncertainty shown to the recruiter.

### Excluded

- Candidate ranking, numeric scores, eligibility, rejection, disqualification,
  stage changes, contacting candidates, offers, scheduling, and comparison.
- Protected characteristics, proxy features, resume content, external data,
  model providers, vector search, persistent recommendations, and background
  agent execution.

## Decision Table

| Stage | Advisory action | Attention threshold |
| --- | --- | --- |
| submitted | Review application | 7 days |
| screening | Continue screening review | 5 days |
| interview | Prepare interview follow-up | 3 days |
| offer | Review offer workflow | 2 days |
| accepted, rejected, withdrawn | Close record | none |

## Invariants

1. Only a recruiter already authorized to view the application can receive the
   assistant output.
2. The service returns exactly one advisory action and never mutates records.
3. The action is derived only from application status, application timestamp,
   and the latest stage event timestamp.
4. Every output includes source labels and an uncertainty statement.
5. No numeric candidate score, ranking, protected trait, or candidate comparison
   is produced.
6. The assistant is deterministic for the same application and reference time.

## Acceptance Criteria

- [ ] An authorized recruiter sees an advisory next action and its source.
- [ ] A stage past its threshold is marked for attention without changing the
      application status.
- [ ] Terminal stages return a close-record action without an attention flag.
- [ ] Candidate and unauthorized users cannot access the recruiter panel.
- [ ] The service has no external provider, persistence, or side effect.
- [ ] English and Thai copy explain that a human recruiter remains responsible.

## Verification

    bin/docs
    bin/rails test test/services/recruitment/job_application_assistant_test.rb test/controllers/recruitment/job_applications_controller_test.rb
    bin/verify
