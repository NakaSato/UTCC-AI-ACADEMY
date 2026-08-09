---
id: SPEC-0026
type: spec
title: Recruitment organization job management and publication workflow
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0026, SPEC-0024, SPEC-0025]
implemented_by:
  - app/models/recruitment/job_post.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - db/migrate/20260807110000_create_recruitment_job_posts.rb
  - test/models/recruitment/job_post_test.rb
  - test/controllers/recruitment/job_posts_controller_test.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - db/migrate
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/job_post_test.rb
  - test/controllers/recruitment/job_posts_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
---

# Recruitment Organization Job Management and Publication Workflow

> [Executable Specifications](README.md) ·
> [Job-management ADR](../decisions/adr-0026-recruitment-job-post-boundary.md) ·
> [Organization membership ADR](../decisions/adr-0024-recruitment-organization-membership.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted by the user on 2026-08-08 for the first M2
> implementation slice. This is not the full hiring workflow.

## Problem

Companies need a structured place to author job opportunities, review them,
and publish only approved content. The existing platform can identify an
organization and its members but cannot distinguish company drafts from
candidate-visible jobs.

## Scope

### Included

- Organization-scoped job posts with structured recruitment fields.
- Draft, review, published, paused, closed, and archived lifecycle states.
- Draft authoring by owners, recruiters, and hiring managers.
- Review submission by authors and publication by owners or hiring managers.
- Pause, close, archive, and draft-only delete controls.
- Candidate-facing published-job index and detail pages.
- Organization authorization, publication visibility rules, audit events,
  English/Thai copy, and focused tests.

### Excluded

- AI job creation, templates, recommendations, or inclusive-language analysis.
- Applications, interviews, offers, candidate search, matching, or recruiter
  agents.
- Public unauthenticated access, salary benchmarking, or external integrations.
- Organization self-registration, email invitations, ownership transfer, and
  custom per-organization permission policies.

## Fields

- Title, summary, description
- Category, department, team, seniority
- Employment type: full time, part time, internship, contract, freelance
- Location and remote policy: onsite, hybrid, remote
- Salary minimum, salary maximum, and currency
- Closing date

## Lifecycle

```text
Draft ──submit──> Review ──publish──> Published ──pause──> Paused
  │                  │                   │  │               │
  └─delete/archive   └─request changes───┘  └─close─────────┘
                                                         │
                                      Draft/Review/Closed/Paused ──archive──> Archived
```

## Invariants

1. Every job post belongs to one organization and creator; the organization
   cannot be changed through the job-post form.
2. Job status is limited to draft, review, published, paused, closed, or
   archived, and the database rejects unknown values.
3. Only active organization members with owner, recruiter, or hiring-manager
   roles can author or view organization job posts; mentors are read-only.
4. Publication is allowed only from review and only when title, summary,
   description, employment type, location, remote policy, category, and
   seniority are present.
5. Salary values are non-negative; when both exist, minimum cannot exceed
   maximum.
6. A candidate-facing query returns only published jobs in active organizations
   with no past closing date.
7. Published, paused, closed, and archived records cannot be hard-deleted;
   only drafts may be deleted.
8. Lifecycle transitions are explicit and invalid transitions preserve the
   previous status and timestamps.
9. Every create, update, delete, and lifecycle mutation records the current
   actor and job context; public reads do not create audit events.
10. Job-post parameters cannot select a different organization or creator from
    the authenticated request context.

## Acceptance Criteria

- [x] An authorized organization member can create and edit a structured draft
      (`test/controllers/recruitment/job_posts_controller_test.rb`).
- [x] A mentor and a non-member cannot mutate or read organization job posts
      (`test/controllers/recruitment/job_posts_controller_test.rb`).
- [x] A recruiter can submit a complete draft for review, while only an owner
      or hiring manager can publish it
      (`test/controllers/recruitment/job_posts_controller_test.rb`).
- [x] Published jobs are visible through the candidate-facing surface, while
      drafts, paused, closed, archived, and expired jobs are not
      (`test/controllers/recruitment/job_posts_controller_test.rb`).
- [x] Pause, close, archive, request-changes, and draft-only delete enforce the
      lifecycle and role rules
      (`test/controllers/recruitment/job_posts_controller_test.rb`).
- [x] Invalid salary ranges, missing publication fields, unknown statuses, and
      illegal transitions are rejected without partial writes
      (`test/models/recruitment/job_post_test.rb`).
- [x] Job creation, updates, publication, and closure are auditable without
      storing candidate or secret data
      (`test/controllers/recruitment/job_posts_controller_test.rb`).

## Error and Boundary Cases

- A suspended organization cannot create, publish, or expose job posts.
- A closing date equal to today remains visible until the end of the date;
  past dates are hidden from candidates.
- A job with only one salary bound is valid; both bounds must be non-negative.
- A review request for an incomplete draft returns a validation error and keeps
  the job in draft.
- A stale or missing job ID returns not-found without revealing another
  organization's record.
- Archived records remain in the organization management list for audit history
  but never appear in candidate-facing queries.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/job_post_test.rb test/controllers/recruitment/job_posts_controller_test.rb
    bin/verify
