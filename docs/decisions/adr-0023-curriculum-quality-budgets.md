---
id: ADR-0023
type: adr
title: Define curriculum-scale accessibility and performance quality budgets
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner", "@accessibility-owner"]
created: 2026-08-03
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0020]
implemented_by:
  - app/services/quality/budget_policy.rb
  - test/quality/critical_journey_matrix_test.rb
  - test/quality/accessibility_contract_test.rb
  - test/quality/performance_budget_test.rb
  - test/quality/quality_gate_test.rb
  - test/observability/quality_signal_test.rb
  - test/system/quality_walk_test.rb
touches:
  - app/views
  - app/javascript
  - app/assets
  - test/system
  - test/models/query_budget_test.rb
  - docs/performance.md
  - docs/test-strategy.md
  - .github/workflows/ci.yml
  - lib
enforced_by:
  - test/quality/critical_journey_matrix_test.rb
  - test/quality/accessibility_contract_test.rb
  - test/quality/performance_budget_test.rb
  - test/quality/quality_gate_test.rb
  - test/observability/quality_signal_test.rb
  - test/system/quality_walk_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-OPS-001, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-OPS-001, SKILL-SPEC-002]
---

# Define curriculum-scale accessibility and performance quality budgets

> **Decision state:** Accepted by the user on 2026-08-08 for the repository
> quality-budget baseline, including the candidate worksheet defaults and
> automated contract evidence. Manual accessibility/content review and
> production release-gate activation remain separate human-owned decisions.

> [Decision Records](README.md) ·
> [M9 quality specification](../specs/spec-m9-curriculum-quality-budgets.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Context

The repository already has a performance note and query-budget tests for selected
read models, plus semantic Rails views and browser system tests. It does not yet
define a curriculum-scale accessibility target or a user-facing performance
budget for the main learner, staff, academic-writing, and document paths. As the
number of topics, courses, records, bilingual strings, and interactive frames
grows, a page can remain functionally correct while becoming inaccessible or
unacceptably slow.

Automated checks are useful evidence but cannot choose the academy's supported
devices, assistive technologies, acceptable latency, or exceptions for a known
content trade-off. A score without an owner and a correction path is not a
quality policy.

## Problem frame

- **Affected user:** Learners and staff using keyboard navigation, screen
  readers, mobile devices, slower networks, or larger course/cohort data sets;
  the team responsible for keeping the curriculum usable as it grows.
- **Current behavior:** Some query budgets and system walks exist, but there is
  no agreed WCAG target, route matrix, device/network baseline, latency budget,
  payload budget, accessibility exception process, or trend owner.
- **Failure risk:** New content or UI silently excludes users, introduces slow
  screens that are discovered through complaints, or creates brittle gates that
  optimize synthetic scores while harming real learning flows.
- **Success signal:** Critical journeys stay usable for the approved audience,
  regressions are detected before release, and every exception has an owner,
  reason, expiry, and remediation path.

## Decision

The quality contract must define one measurable baseline for critical journeys:

1. Set the accessibility target and supported combinations of browser, viewport,
   keyboard, screen reader, zoom/text scaling, reduced motion, color contrast,
   Thai/English locale, and mobile/network conditions.
2. Set performance budgets for user-facing latency and resource behavior, plus
   query/data-growth budgets where those protect the same experience.
3. Name representative routes and datasets: authentication, catalog/course,
   lesson/progress, knowledge map, leaderboard, instructor/admin, academic
   reader/editor, PDF download, and notification/frame paths as applicable.
4. Define automated checks, manual review, realistic fixtures, measurement
   environment, sampling, trend reporting, and the release gate for a failure.
5. Define exception, waiver, and remediation rules; a score must not hide a
   keyboard, screen-reader, Thai text, security, or learning-critical failure.
6. Connect production symptom metrics to ADR-0020 while keeping test data and
   telemetry free of learner content and unnecessary identifiers.

The WCAG level, latency values, device matrix, and exception authority are
encoded as the user-approved repository baseline. Manual review, production
release-gate activation, and future changes remain human-owned decisions.

## Implemented quality baseline

The approved candidate defaults are encoded in
`app/services/quality/budget_policy.rb` and protected by focused contract
tests. They cover WCAG 2.2 AA, desktop/mobile and keyboard/screen-reader
environments, Thai/English journeys, p75/p95 interaction and transfer budgets,
constant-cost query growth, blocking versus expiring-waiver responses, and
privacy-safe quality telemetry dimensions. This baseline is accepted repository
policy evidence; it is not by itself a production conformance claim or a waiver
approval.

## Quality-budget review worksheet

The following are candidate starting points for owner review, not approved
targets. Each owner must select, replace, or explicitly defer the value and
record the evidence location before it becomes a release gate.

| Decision | Candidate starting point | Owner decision/evidence |
| --- | --- | --- |
| Accessibility conformance | WCAG 2.2 AA for critical learner and staff journeys, with manual keyboard and screen-reader review | Pending Product Owner and Accessibility Owner |
| Supported browsers/devices | Current supported desktop and mobile browsers, one keyboard-only path, one screen reader path, Thai and English, zoom/text scaling, reduced motion, and contrast modes | Pending QA and Accessibility Owner |
| Critical journey set | Sign-in/recovery, catalog/course/lesson, progress/map, leaderboard, instructor/admin, academic reader/editor, syllabus PDF, and notification/frame paths | Pending Product Owner and QA Owner |
| User-facing latency | Candidate lab budget: p75 ≤ 2 seconds and p95 ≤ 4 seconds for the initial critical page interaction; define whether this means server response, meaningful paint, or interaction-ready | Pending Tech Lead and Product Owner |
| Initial transfer | Candidate lab budget: p75 ≤ 1.5 MB compressed and p95 ≤ 3 MB for an initial critical page; measure HTML, CSS, JavaScript, fonts, and images consistently | Pending Tech Lead and QA Owner |
| Query/data growth | Preserve constant-cost reads; route-specific ceilings must be based on the current `docs/performance.md` baseline plus an approved growth fixture | Pending Tech Lead and Data/QA Owner |
| Measurement environment | Named CI/browser runner plus a documented throttled mobile/network profile; no production learner data in fixtures | Pending QA Owner and Platform Owner |
| Release response | Accessibility, authorization, academic-integrity, and learning-critical failures block; other failures warn only with an expiring waiver | Pending Product Owner and Accessibility Owner |
| Waiver authority | One named owner, evidence link, risk statement, remediation due date, and maximum expiry; no silent threshold edits | Pending Product Owner and Tech Lead |
| Trend owner | Monthly route/locale/device trend review linked to ADR-0020 symptom telemetry and a remediation backlog | Pending Product Owner and On-call/Platform Owner |

The candidate values are intentionally easy to revise before implementation.
They must not be copied into CI, dashboards, or release gates until the
accountable owners complete the final column.

## Alternatives

### Rely on human review and existing query tests

This has little tooling cost and preserves judgment, but regressions are easy to
miss between reviews and do not produce a comparable curriculum-scale trend.

### Add automated accessibility and performance gates only

This gives repeatable feedback in CI, but automated tools miss some interaction,
content, Thai typography, screen-reader, and real-network failures and can
encourage score chasing.

### Use a route matrix with automated checks plus targeted manual review

This combines repeatability with human testing for high-risk journeys. It costs
more and requires a maintained matrix, but is the recommended shape for an
education product with bilingual and assistive-technology needs.

### Measure production only

Real-user data reflects actual conditions, but a failure reaches learners before
the team can correct it and may create privacy/consent obligations.

No final thresholds or option are selected by this draft.

## Consequences

- Quality work becomes part of curriculum and release planning rather than an
  end-of-project audit.
- Budgets can constrain visual, content, data, and interaction choices; those
  trade-offs need an owner rather than a silent relaxation.
- A representative fixture set must grow with courses, cohorts, locales, and
  academic content without copying production learner data.
- Accessibility and performance defects need different diagnosis paths, but both
  require visible severity, owner, evidence, and remediation date.

## Fitness Functions

- Critical journeys have an approved accessibility target and performance budget
  measured on a named environment, route, locale, and representative dataset.
- A keyboard, screen-reader, text-scaling, contrast, reduced-motion, Thai-copy,
  or learning-critical failure cannot be waived as a cosmetic score issue.
- Query budgets and response budgets are checked against growing fixtures, not
  only the small seed database.
- A failed quality check is tied to a release decision, owner, evidence, and
  remediation/waiver expiry rather than being deleted or silently loosened.
