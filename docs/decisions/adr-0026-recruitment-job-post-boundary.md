---
id: ADR-0026
type: adr
title: Keep job posts organization-scoped with explicit publication states
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0024, SPEC-0024]
implemented_by:
  - SPEC-0026
  - app/models/recruitment/job_post.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - db/migrate/20260807110000_create_recruitment_job_posts.rb
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
---

# Keep Job Posts Organization-Scoped with Explicit Publication States

> [Decision Records](README.md) ·
> [Job-management specification](../specs/spec-recruitment-job-management.md) ·
> [Organization membership ADR](adr-0024-recruitment-organization-membership.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for the first M2
> vertical slice: organization-scoped job posts, explicit publication states,
> lifecycle transitions, authorization, validation, and audit boundaries.

## Context

The recruitment platform has an organization and membership boundary, but no
job data model. Job content is consequential recruitment data, so a draft must
not become candidate-visible merely because a record exists. The first job
slice also needs a clear path from recruiter authoring through human review to
publication without adding AI, applications, or matching.

## Decision

- A job post belongs to exactly one organization and one creator User.
- Owners, recruiters, and hiring managers can view organization job posts;
  owners, recruiters, and hiring managers can author drafts; mentors cannot
  mutate job posts.
- Recruiters can submit complete drafts for review. Owners and hiring managers
  approve publication, pause or close published jobs, and archive records.
- The lifecycle is `draft → review → published → paused → published`, with
  close and archive transitions explicitly guarded. Archived records are not
  candidate-visible.
- Candidate-facing reads use a separate published-only scope that also checks
  active organizations and closing dates.
- Structured employment type, remote policy, salary range, location,
  department, team, category, seniority, and closing date are stored as fields;
  job templates and AI generation remain later work.
- Every lifecycle mutation is audited; publication does not trigger a
  notification or application workflow in this slice.

## Alternatives

### Store jobs directly on Organization without a lifecycle

Rejected. It would make draft content indistinguishable from candidate-visible
content and move a core authorization rule into controller conventions.

### Let recruiters publish immediately

Rejected for the first slice. Publication is an employment-facing action and
needs an explicit human approval boundary while the product policy is still
being reviewed.

### Build public search and applications together

Deferred. Search ranking, candidate consent, application retention, and hiring
workflow belong to later milestones and would make this first data boundary too
wide.

## Consequences

- A complete job takes an explicit review and approval step before visibility.
- Public job pages expose only approved structured content, not drafts or
  organization management data.
- The state machine and role matrix can be extended later for templates,
  applications, and AI suggestions without changing organization ownership.
- Hard deletion is limited to drafts; other records are archived for auditability.

## Fitness Functions

- A non-member cannot read an organization job post or mutate it.
- A mentor cannot create, edit, publish, pause, close, archive, or delete a job.
- A candidate-facing query returns only published jobs in active organizations
  whose closing date has not passed.
- Publication requires complete required fields and a review state.
- Illegal lifecycle transitions fail without changing the record.
- `bin/docs` and focused job model/controller tests pass.
