---
id: SPEC-0037
type: spec
title: Privacy-safe organization-scoped recruitment reporting
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@data-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0028, ADR-0033, ADR-0037, SPEC-0026, SPEC-0028, SPEC-0033]
implemented_by:
  - app/services/recruitment/organization_reporting.rb
  - app/controllers/recruitment/reporting_controller.rb
  - app/views/recruitment/reporting/show.html.erb
  - config/routes.rb
  - test/services/recruitment/organization_reporting_test.rb
  - test/controllers/recruitment/reporting_controller_test.rb
enforced_by:
  - test/services/recruitment/organization_reporting_test.rb
  - test/controllers/recruitment/reporting_controller_test.rb
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
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-PROD-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-PROD-002]
---

# Privacy-Safe Organization-Scoped Recruitment Reporting

> [Executable Specifications](README.md) ·
> [Reporting ADR](../decisions/adr-0037-privacy-safe-recruitment-reporting.md) ·
> [Application-workflow specification](spec-recruitment-application-workflow.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Recruitment workflow records now support jobs and applications, but authorized
organization owners need a compact way to inspect aggregate workflow coverage.
The first report must make data lineage and disclosure limits visible before
the product claims hiring, fairness, or AI effectiveness outcomes.

## Scope

### Included

- Organization report route for administrators and active owner/recruiter/
  hiring-manager/company-reviewer members.
- Job-post status counts.
- Application status cells with a minimum reporting cell size of five.
- Total application count suppressed when the in-scope total is below five.
- Source and uncertainty copy.

### Excluded

- Candidate-level data, names, IDs, statements, notes, exports, or downloads.
- Cross-organization comparisons, candidate ranking, fairness metrics, AI
  effectiveness, causal interpretation, targets, alerts, and persistence.

## Invariants

1. Only an administrator or active organization owner, recruiter,
   hiring-manager, or company-reviewer member can access the report.
2. All queries are scoped to the requested organization.
3. The report contains no candidate identity or free-text application data.
4. Application totals and each status cell are suppressed when the total
   application population is below five.
5. Job-post status counts are descriptive and not presented as outcome claims.
6. The service is read-only and deterministic for the same database state.

## Acceptance Criteria

- [ ] An authorized hiring-team member can view job and application aggregates.
- [ ] A mentor, candidate, or unrelated organization member receives no report.
- [ ] Application totals and cells are suppressed for populations under five.
- [ ] A population of five or more shows exact status counts without candidate
      identities.
- [ ] The page states source and uncertainty limits.
- [ ] English and Thai copy remain aligned.

## Measurement Contract

These are descriptive workflow counts only. Product and Data owners must later
approve baseline, target, evaluation window, counter-metrics, fairness policy,
retention, and interpretation ownership before M13 is treated as an outcome
reporting milestone.

## Verification

    bin/docs
    bin/rails test test/services/recruitment/organization_reporting_test.rb test/controllers/recruitment/reporting_controller_test.rb
    bin/verify
