---
id: SPEC-0033
type: spec
title: Candidate-owned recruitment applications and auditable pipeline stages
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0029, ADR-0032, ADR-0033, SPEC-0026, SPEC-0029, SPEC-0032]
implemented_by:
  - app/models/recruitment/job_application.rb
  - app/models/recruitment/job_application_event.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications
  - db/migrate/20260808130000_create_recruitment_job_applications.rb
  - test/models/recruitment/job_application_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
enforced_by:
  - test/models/recruitment/job_application_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
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
agent_writable: true
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
---

# Candidate-Owned Recruitment Applications and Auditable Pipeline Stages

> [Executable Specifications](README.md) ·
> [Application boundary ADR](../decisions/adr-0033-recruitment-application-workflow-boundary.md) ·
> [Job-management specification](spec-recruitment-job-management.md) ·
> [Candidate-profile specification](spec-recruitment-candidate-profile.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Candidates can discover and preview jobs, but there is no durable application
record or shared stage language. M9 needs the smallest safe pipeline slice that
lets a candidate submit with explicit consent and lets an authorized hiring
team review only applications belonging to its organization.

## Scope

### Included

- Candidate submission to a visible published job.
- Candidate application list/detail and withdrawal.
- Organization job application list/detail for active recruitment members.
- Explicit stage transitions with optimistic locking and optional reviewer note.
- Immutable application event history and audit events.
- Candidate-visible current status and next action.
- Snapshot of the consented profile export at submission time.

### Excluded

- Interview scheduling, interview scorecards, offers, candidate messages,
  external email, automated rejection, ranking, and AI screening.
- Recruiter access to candidate profiles outside an application they are
  authorized to review.
- Numeric match scores or any stage transition made by an AI system.

## State Contract

| Current | Allowed next states |
| --- | --- |
| submitted | screening, rejected, withdrawn |
| screening | submitted, interview, rejected, withdrawn |
| interview | screening, offer, rejected, withdrawn |
| offer | interview, accepted, rejected, withdrawn |
| accepted | none |
| rejected | none |
| withdrawn | none |

Candidates may withdraw from `submitted`, `screening`, or `interview`.
Recruiters may use only the transitions above. `accepted` is reserved for the
future offer-acceptance slice; this increment only permits the state to be
represented in the persisted contract.

## Invariants

1. Only a student can be an application candidate.
2. A candidate can have at most one application for a given job post.
3. New applications require a published, active, non-expired job and a
   candidate profile whose application-data reuse consent is true.
4. Candidate reads and withdrawals are scoped by `candidate_id`; organization
   reads and reviewer transitions are scoped by the job's organization and
   active recruitment membership.
5. Every status mutation creates exactly one event with actor, old status, new
   status, and timestamp; terminal states cannot transition.
6. A stale optimistic-lock version cannot replace a newer stage decision.
7. The profile snapshot is captured only on submission and is not a live
   recruiter profile endpoint.
8. Application and event statuses are database-constrained to the declared
   state vocabulary.

## Acceptance Criteria

- [x] A consented student can submit once and see `submitted` plus a next action.
- [x] A student without consent, without a profile, or applying to a hidden or
      expired job is refused without creating a record.
- [x] The candidate can see only their own applications and can withdraw only
      from an allowed stage.
- [x] An authorized recruiter can list and inspect applications for their job;
      an unrelated member or outsider receives no application data.
- [x] An authorized recruiter can move an application through allowed stages;
      invalid transitions and stale versions are refused.
- [x] Each submission, transition, and withdrawal has an event and audit entry.
- [x] The UI renders the current stage and candidate next action in English and
      Thai.

## Threat and Privacy Notes

- Candidate IDs and profile snapshots are sensitive; routes never accept a
  candidate ID for candidate-facing reads.
- Organization membership is checked on every recruiter request; a job post
  ID alone is not authorization.
- The snapshot retention/deletion policy, disclosure of reviewer notes, and
  notification channels are human-owned follow-up decisions.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/job_application_test.rb test/controllers/recruitment/job_applications_controller_test.rb
    bin/verify
