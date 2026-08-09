---
id: SPEC-0023
type: spec
title: Curriculum-scale accessibility and performance quality budgets
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner", "@accessibility-owner"]
created: 2026-08-03
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0023, ADR-0020]
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-OPS-001, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-OPS-001, SKILL-TEST-001]
---

# Curriculum-scale accessibility and performance quality budgets

> **Review state:** Accepted by the user on 2026-08-08 for the repository
> quality-budget baseline, including the candidate worksheet defaults and
> automated contract evidence. Manual accessibility/content review and
> production release-gate activation remain separate human-owned decisions.

> [Executable Specifications](README.md) ·
> [M9 quality decision](../decisions/adr-0023-curriculum-quality-budgets.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Problem

The application has selected query-budget tests and browser walkthroughs, but
not a complete, owned quality contract for accessibility and user-facing
performance as courses, records, bilingual content, and interactive frames
grow. A functional test pass does not prove that a learner can navigate the
course with assistive technology or load it within an acceptable budget.

## Implemented quality baseline

The repository now exposes one deterministic quality-policy source and contract
tests for the approved candidate accessibility, performance, query-growth,
failure-response, journey-matrix, and telemetry rules. Manual keyboard,
screen-reader, content, and Thai typography review remain human evidence and
are not replaced by these automated checks.

## Scope

### Included after policy approval

- Define supported browser, viewport, input, assistive technology, locale, zoom,
  motion, contrast, and network matrix.
- Define critical journeys, representative data sizes, response/payload/query
  budgets, and measurement environment.
- Add automated accessibility, browser, performance, and query-growth checks
  appropriate to each journey.
- Add manual review for interactions and content automated tools cannot validate.
- Define release blocking, waiver, remediation, trend, and ownership rules.
- Connect production performance symptoms to the approved observability boundary.

### Excluded

- Claiming WCAG conformance from one automated score or one browser.
- Optimizing arbitrary benchmark numbers without a user-facing symptom or
  approved budget.
- Copying production learner data into performance or accessibility fixtures.
- Replacing academic content review, translation review, security review, or
  usability research with a technical gate.
- Changing route behavior or adding a performance dependency before the target
  and trade-off are approved.

## Invariants

1. Every critical journey names its user, locale, supported environment,
   representative data size, accessibility checks, performance budget, owner,
   and release response.
2. Keyboard, screen-reader, focus, text scaling, contrast, reduced-motion,
   bilingual, and learning-critical failures are not hidden by an aggregate
   score.
3. Performance checks measure user-facing behavior and query/data growth rather
   than only controller execution time on a tiny fixture set.
4. Fixtures are deterministic, synthetic or sanitized, and include empty,
   typical, and growth-boundary cases.
5. A failed check either blocks the approved release path or creates an explicit
   human-owned waiver with reason, risk, expiry, and remediation.
6. Measurement and telemetry contain no learner answers, credentials, cookies,
   reset links, or unnecessary direct identifiers.
7. Accessibility and performance improvements cannot remove authorization,
   security, academic-integrity, or data-correctness behavior.

## Acceptance Criteria

- [ ] The Product Owner, Tech Lead, QA Owner, and Accessibility Owner approve
      the supported matrix, critical journeys, budgets, measurement environment,
      release response, waiver authority, and remediation cadence
      (`docs/decisions/adr-0023-curriculum-quality-budgets.md`).
- [ ] The route matrix covers learner, staff, academic-writing, document, and
      real-time paths with empty, typical, and growth-boundary data
      (`test/quality/critical_journey_matrix_test.rb`).
- [ ] Keyboard, focus, semantic structure, screen-reader labels, text scaling,
      contrast, reduced motion, and Thai/English states are checked on the
      approved journeys (`test/quality/accessibility_contract_test.rb`).
- [ ] Response, payload, query, and render budgets are measured against the
      approved environment and representative growth fixtures
      (`test/quality/performance_budget_test.rb`, `test/models/query_budget_test.rb`).
- [ ] Manual review covers the approved interaction/content cases that automated
      tools cannot prove (`docs/test-strategy.md`).
- [ ] A failure produces an owner, evidence, release decision, or expiring human
      waiver; it does not silently update the budget (`test/quality/quality_gate_test.rb`).
- [ ] Production symptom metrics use the approved redaction and correlation
      rules (`test/observability/quality_signal_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- A page passes an automated audit while focus order, keyboard use, screen-reader
  announcements, Thai line wrapping, or reduced-motion behavior is broken.
- A query count is constant but response size, render time, or network transfer
  grows with the curriculum.
- Empty, one-record, typical, and large-cohort/course states behave differently.
- A performance failure appears only on a slower mobile/network profile or in a
  Thai locale with different text lengths.
- A lazy-loaded frame, PDF, WebSocket, or background result is measured as if it
  were part of the initial page or is omitted despite being user-critical.
- A third-party font, script, image, or external service is slow or unavailable.
- A release needs a temporary waiver, the owner leaves, or the expiry passes
  while the defect remains.
- A quality tool emits URLs, page content, cookies, or student identifiers into
  its result artifact.

## Human Quality Handoff

The implementation baseline is complete. Manual review and production release
gating still require the accountable owners to complete the decisions in this
table.

| Review point | Decision required |
| --- | --- |
| Audience | Browser, device, assistive technology, locale, zoom, motion, network. |
| Journeys | Learner, staff, authoring, document, and real-time paths. |
| Accessibility | Target, severity, manual review, exception, and support process. |
| Performance | Latency, payload, query, render, concurrency, and growth budgets. |
| Fixtures | Synthetic data size, representative states, refresh and ownership. |
| Release gate | Block, warn, waiver, expiry, remediation, and escalation. |
| Operations | Production symptoms, privacy, trend review, and runbook ownership. |

## Quality-budget decision worksheet

This worksheet records the approved repository baseline. The values in the
middle column are not, by themselves, a production conformance claim, CI
threshold, or release gate.

| Decision | Candidate starting point | Required owner decision |
| --- | --- | --- |
| Accessibility target | WCAG 2.2 AA for critical journeys, plus manual keyboard and screen-reader review | Select the target, severity model, manual coverage, and support response |
| Audience matrix | Desktop and mobile supported browsers, keyboard-only, screen reader, zoom/text scaling, reduced motion, contrast, Thai and English | Name exact browser/OS/assistive-technology versions and review cadence |
| Critical journeys | Sign-in/recovery, catalog/course/lesson, progress/map, leaderboard, instructor/admin, academic reader/editor, syllabus PDF, notification/frame | Confirm routes, user roles, locale states, and learning-critical steps |
| Latency budget | Candidate lab budget p75 ≤ 2s and p95 ≤ 4s for initial critical interaction | Define metric, sampling, environment, concurrency, and final values |
| Transfer budget | Candidate lab budget p75 ≤ 1.5MB and p95 ≤ 3MB compressed initial transfer | Define resource scope, cache state, network profile, and final values |
| Query/data budget | Constant-cost route reads against empty, typical, and growth fixtures, using `docs/performance.md` baselines | Set route-specific ceilings and fixture sizes; approve exceptions |
| Failure response | Block accessibility, authorization, academic-integrity, and learning-critical failures; warn only for approved lower-risk exceptions | Name release authority, waiver shape, expiry, and escalation |
| Measurement ownership | CI/browser runner plus a named throttled mobile/network profile; synthetic or sanitized fixtures only | Name environment owner, refresh schedule, and evidence retention |
| Trend/operations | Route, locale, device, latency, payload, query-growth, defect, waiver, and escaped-regression trends linked to ADR-0020 | Name dashboard/runbook owner and review window |

No value becomes an enforced production gate until the required manual review,
operational owner decision, and activation record are written into the ADR or
an approved policy record.

## Current evidence and missing evidence

| Evidence | Current state | Gate consequence |
| --- | --- | --- |
| Query growth | `test/models/query_budget_test.rb` covers selected model/read paths; current snapshots are documented in `docs/performance.md` | Existing query tests remain active; curriculum-scale ceilings are not yet defined |
| Browser walkthroughs | Existing system walks cover learning, map, course, admin, academic-post, frame, and document paths | They are not an accessibility conformance matrix or performance benchmark |
| Accessibility contract | Implemented policy and semantic-landmark/system contract coverage encode the approved target and matrix; manual review remains pending | Production conformance still requires Accessibility/QA owner review |
| User-facing performance | Implemented policy encodes the approved latency/transfer budgets and the existing constant-cost query evidence | Production release gating still requires Tech/QA owner review |
| Production symptoms | ADR-0020 provides the telemetry boundary | Quality dimensions, redaction fields, dashboard, and owner remain to be selected |
| Waiver history | No quality-budget waiver register is defined | A release cannot claim an approved exception until the register and expiry owner exist |

## Rollback and observability

- Rollback removes or disables a new quality gate without weakening existing
  security, data, or functional behavior; preserve the failed evidence and
  waiver history.
- A performance optimization that changes data, caching, or rendering must have
  a release record and a rollback/compatibility plan.
- Review trends in user-facing latency, payload, query growth, accessibility
  defects, waivers, and escaped regressions after each curriculum increment.

## Verification

```bash
bin/docs
bin/rails test test/quality/critical_journey_matrix_test.rb test/quality/accessibility_contract_test.rb test/quality/performance_budget_test.rb
bin/rails test test/quality/quality_gate_test.rb test/observability/quality_signal_test.rb test/models/query_budget_test.rb
bin/rails test:system test/system/quality_walk_test.rb
bin/verify
```
