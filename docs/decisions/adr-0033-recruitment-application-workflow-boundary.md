---
id: ADR-0033
type: adr
title: Keep recruitment applications candidate-owned with an auditable organization-scoped pipeline
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0029, ADR-0032, SPEC-0026, SPEC-0029, SPEC-0032]
implemented_by:
  - SPEC-0033
  - app/models/recruitment/job_application.rb
  - app/models/recruitment/job_application_event.rb
  - app/controllers/recruitment/job_applications_controller.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/job_application_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
agent_writable: true
---

# Keep Recruitment Applications Candidate-Owned with an Auditable Organization-Scoped Pipeline

> [Decision Records](README.md) ·
> [Application-workflow specification](../specs/spec-recruitment-application-workflow.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-09 for candidate-owned
> consented applications, organization-scoped recruiter review, explicit stage
> transitions, withdrawal, bilingual next actions, event history, and audit
> boundaries.

## Context

M9 needs a hiring workflow, but M5 intentionally keeps candidate profiles
candidate-owned. A recruiter must be able to manage applications for jobs in
their own organization without receiving a global candidate directory or
silently reusing profile data. Status changes also need provenance so a
candidate can see the current stage and a reviewer can explain who changed it.

## Decision

- A student explicitly submits an application to a currently visible published
  job. Submission requires an existing candidate profile with application-data
  reuse consent; the submitted profile snapshot records the evidence available
  at that moment and is not a live recruiter view of the profile.
- Each application is unique per candidate and job and has an explicit,
  reversible-where-policy-allows lifecycle: `submitted`, `screening`,
  `interview`, `offer`, `accepted`, `rejected`, or `withdrawn`.
- Only the candidate can read their own applications and withdraw while the
  application is in a candidate-withdrawable stage. Only an admin or an active
  organization member in an approved recruitment role can read and transition
  applications for that organization's job posts.
- Every initial submission, withdrawal, and reviewer stage transition creates
  an immutable application event with actor, previous status, next status,
  note, and timestamp. A stale `lock_version` must not overwrite a concurrent
  decision.
- M9 interview scheduling, scorecards, offers, and candidate messages remain
  separate follow-up slices. This increment does not expose recruiter notes or
  candidate data outside the application boundary.

## Alternatives

### Reuse internship applications

Rejected. Internship applications have different capacity, mentor, academic,
and evaluation rules; merging the tables would weaken both permission models.

### Let recruiters browse candidate profiles before an application

Rejected. That would turn candidate-owned profile data into an employer-facing
directory without an approved disclosure, retention, or privacy policy.

### Store only the current status

Rejected. A mutable status without an event history cannot prove provenance,
support a candidate explanation, or diagnose a stale concurrent update.

## Consequences

- Candidates receive an explicit status and next-action explanation.
- Recruiters get an organization-scoped pipeline, not unrelated candidates.
- The snapshot is useful for application provenance but creates retention and
  deletion questions that require a human privacy decision.
- Interview, offer, communication, and notification behavior still need the
  next M9 slices and their own review.

## Fitness Functions

- A candidate cannot submit without a visible job, a student account, and
  explicit application-data reuse consent.
- A candidate cannot read or mutate another candidate's application.
- A recruiter cannot access applications from another organization.
- Database constraints enforce one application per candidate/job and valid
  statuses; application validation alone is not the state boundary.
- Every state mutation has an application event and audit record.
- `bin/docs` and focused application tests pass.
