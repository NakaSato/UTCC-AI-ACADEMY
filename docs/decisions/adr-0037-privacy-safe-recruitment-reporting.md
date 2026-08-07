---
id: ADR-0037
type: adr
title: Start recruitment analytics with organization-scoped aggregate reporting and small-cell suppression
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@data-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0028, ADR-0033, ADR-0034, ADR-0036, SPEC-0026, SPEC-0028, SPEC-0033]
implemented_by:
  - SPEC-0037
  - app/services/recruitment/organization_reporting.rb
  - app/controllers/recruitment/reporting_controller.rb
  - app/views/recruitment/reporting/show.html.erb
touches:
  - app/services
  - app/controllers
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/services
  - test/controllers
agent_writable: true
enforced_by:
  - test/services/recruitment/organization_reporting_test.rb
  - test/controllers/recruitment/reporting_controller_test.rb
---

# Start Recruitment Analytics with Organization-Scoped Aggregate Reporting and Small-Cell Suppression

> [Decision Records](README.md) ·
> [Reporting specification](../specs/spec-recruitment-reporting.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Draft. This slice is implementation-approved by the user
> for local verification; Product, Privacy, Security, Recruitment, Data, and QA
> owners must approve the metric definitions and production reporting policy.

## Context

M13 calls for recruitment, internship, and AI-effectiveness insight. The
repository has workflow records, but no approved baseline, target, retention
policy, fairness definition, or reporting audience. A first slice should prove
the data seam without exposing candidate identities or presenting output counts
as business outcomes.

## Decision

- Add an organization-scoped report for active owners, recruiters, and hiring
  managers, plus administrators.
- Show job-post status counts and aggregate job-application status counts.
- Suppress application totals and status cells when fewer than five
  applications are in scope. The report shows `suppressed`, not an estimate.
- Include the source fields and an uncertainty notice: these are workflow
  counts, not hiring quality, fairness, AI effectiveness, or causal outcomes.
- Compute the report at read time; do not persist snapshots, candidate IDs,
  names, or application text in reporting records.

## Alternatives

### Show candidate-level rows in the analytics dashboard

Rejected. Recruiter pipeline pages already provide authorized candidate review;
analytics should minimize identity exposure.

### Publish exact small-team counts

Rejected for the first slice. Small cells can reveal participation or outcome
information and need a reviewed disclosure policy.

### Add fairness or AI-effectiveness scores immediately

Rejected. No approved protected-attribute policy, evaluation dataset, baseline,
counter-metric, or interpretation owner exists yet.

## Consequences

- Owners and hiring managers can verify that workflow data is aggregating in an
  organization boundary.
- Small organizations may see suppression instead of useful exact counts until
  a human Data/Privacy owner approves an alternative disclosure policy.
- Metrics remain descriptive outputs, not approved product outcomes.

## Fitness Functions

- Mentors, candidates, and unrelated users cannot access the report.
- No report response contains candidate names, IDs, statements, or notes.
- Application counts below the threshold are suppressed consistently.
- Source and uncertainty copy are displayed with every report.
- `bin/docs` and focused reporting tests pass.
