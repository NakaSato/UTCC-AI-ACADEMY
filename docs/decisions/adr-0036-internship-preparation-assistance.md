---
id: ADR-0036
type: adr
title: Start the AI internship agent with student-controlled preparation guidance
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@academic-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0028, ADR-0035, SPEC-0028, SPEC-0035]
implemented_by:
  - SPEC-0036
  - app/services/recruitment/internship_application_assistant.rb
  - app/controllers/recruitment/internship_programs_controller.rb
  - app/views/recruitment/internship_programs/show.html.erb
touches:
  - app/services
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - test/services
  - test/controllers
agent_writable: true
enforced_by:
  - test/services/recruitment/internship_application_assistant_test.rb
  - test/controllers/recruitment/internship_programs_controller_test.rb
---

# Start the AI Internship Agent with Student-Controlled Preparation Guidance

> [Decision Records](README.md) ·
> [Internship-assistance specification](../specs/spec-internship-application-assistance.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-09 for the advisory
> student internship-preparation slice: a student-owned checklist with
> deterministic rules_preview behavior, published-program data scope, source
> and uncertainty disclosure, and no matching, evaluation, or academic
> decisions. Product, Academic, legal, Security, Recruitment, Privacy, Data,
> and QA owners must still review it before production use.

## Context

The M12 roadmap proposes assistance with internship matching, mentorship,
progress, and evaluation. Those actions affect academic and employment
decisions. The existing published-program and student-application boundary can
support a safer first increment: guidance for a student's own preparation,
without matching, accepting, evaluating, or contacting anyone.

## Decision

- Add a provider-neutral, read-time preparation checklist to the student's own
  published internship application view.
- Derive items only from the published program's learning outcomes and required
  skills plus the student's own application status and statement presence.
- Label the checklist advisory and show source and uncertainty copy.
- Do not rank students, recommend acceptance, write evaluations, mutate
  applications, reveal mentor-only notes, or send messages.
- Keep mentorship, progress telemetry, and evaluation assistance for separate
  policy-reviewed slices.

## Alternatives

### Match students to programs automatically

Rejected. Matching requires an approved objective, evidence policy, fairness
review, student consent, and human override workflow.

### Generate or submit an academic evaluation

Rejected. Evaluation affects learning and institutional records and must remain
human-owned until academic policy and evidence boundaries are approved.

### Use mentor notes as assistant context

Rejected. Mentor and reviewer records are organization- and academic-role
scoped, not part of the student's self-service boundary.

## Consequences

- Students get practical preparation prompts tied to the published program.
- Guidance is intentionally generic and cannot determine placement, learning
  progress, or evaluation outcomes.
- Future agent slices need explicit academic, privacy, and fairness review.

## Fitness Functions

- Only the applicant receives the checklist.
- The assistant has no external side effect or persistent recommendation.
- It reads no reviewer, mentor, or evaluation-private data.
- `bin/docs` and focused internship-assistance tests pass.
