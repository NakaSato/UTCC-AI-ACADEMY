---
id: ADR-0031
type: adr
title: Keep job discovery candidate-controlled and advisory
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0029, ADR-0030, SPEC-0026, SPEC-0029]
implemented_by:
  - SPEC-0031
  - app/services/recruitment/job_discovery.rb
  - app/services/recruitment/job_alert_notifier.rb
  - app/models/recruitment/saved_job.rb
  - app/models/recruitment/job_discovery_dismissal.rb
  - app/models/recruitment/job_discovery_preference.rb
  - db/migrate/20260808120000_create_recruitment_job_discovery.rb
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
  - test/models/recruitment/job_discovery_test.rb
  - test/models/recruitment/saved_job_test.rb
  - test/controllers/recruitment/job_discovery_controller_test.rb
agent_writable: true
---

# Keep Job Discovery Candidate-Controlled and Advisory

> [Decision Records](README.md) ·
> [Job-discovery specification](../specs/spec-recruitment-job-discovery.md) ·
> [Job-management specification](../specs/spec-recruitment-job-management.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for candidate-controlled
> search, saved/dismissed jobs, explainable advisory recommendations, consented
> in-app alerts, and privacy boundaries. No consequential ranking is authorized.

## Context

M7 needs to make published jobs easier to discover than keyword search alone,
while preserving candidate choice and avoiding a hidden hiring score. Saved
jobs, dismissed recommendations, profile signals, and alert preferences are
candidate-owned data. Alerts are a separate communication permission and must
not be implied by profile visibility or application-reuse consent.

## Decision

- Search only published, active, non-expired job posts. Search filters are
  structured and query text is escaped before it reaches SQL.
- Store saved jobs and dismissed recommendations per student with database
  uniqueness, never on an organization-wide candidate record.
- Compute recommendations using a local `rules_preview` service from published
  job text, the candidate's own facts, and explicit discovery preferences.
- Explain every recommendation with matched profile/preference evidence and a
  fixed uncertainty statement. Do not show a hiring probability or ranking score.
- Store alert consent, enabled state, frequency, and last-delivery time separately
  from profile consent. Deliver only in-app, at most daily or weekly, and only
  when the candidate has opted in. Visiting discovery is the current delivery
  trigger; email and background scheduling remain future adapters.
- Allow dismissal and restoration without changing the candidate profile or job
  publication state.

## Alternatives

### Use one global recommendation score

Rejected. A numeric score would invite consequential ranking before calibration,
fairness, explanation, and human-review policy exist.

### Send alerts by email by default

Rejected. It creates an external communication and retention boundary that M7
does not yet have permission or provider policy to establish.

### Persist every recommendation as a durable candidate decision

Rejected for this increment. The rules preview is derived from current published
jobs and candidate-controlled inputs; saved/dismissed actions are the durable
candidate decisions.

## Consequences

- Discovery is immediately useful without adding a model provider or search
  dependency.
- Recommendations can change when a job, profile fact, or preference changes;
  saved and dismissed choices remain stable.
- In-app alert delivery is intentionally limited until an approved scheduler,
  notification policy, and outcome measurement exist.
- A future semantic search provider must preserve the explanation, consent,
  rate-limit, and no-ranking boundaries rather than bypassing them.

## Fitness Functions

- Non-published, inactive, and expired jobs never appear in candidate discovery.
- A saved job or dismissal belongs to exactly one student/job pair.
- Recommendations exclude dismissed and saved jobs and expose reasons plus
  uncertainty without a hiring score.
- Alerts cannot be enabled without consent and cannot deliver more often than the
  selected daily or weekly interval.
- Staff and other students cannot mutate another student's discovery state.
- `bin/docs` and focused discovery tests pass.
