---
id: SPEC-0036
type: spec
title: Provider-neutral student internship preparation assistance
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@academic-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0028, ADR-0036, SPEC-0028]
implemented_by:
  - app/services/recruitment/internship_application_assistant.rb
  - app/controllers/recruitment/internship_programs_controller.rb
  - app/views/recruitment/internship_programs/show.html.erb
  - test/services/recruitment/internship_application_assistant_test.rb
  - test/controllers/recruitment/internship_programs_controller_test.rb
enforced_by:
  - test/services/recruitment/internship_application_assistant_test.rb
  - test/controllers/recruitment/internship_programs_controller_test.rb
touches:
  - app/services
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - test/services
  - test/controllers
agent_writable: true
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002, SKILL-AI-004]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002, SKILL-AI-004]
---

# Provider-Neutral Student Internship Preparation Assistance

> [Executable Specifications](README.md) ·
> [Internship-assistance ADR](../decisions/adr-0036-internship-preparation-assistance.md) ·
> [Internship-management specification](spec-recruitment-internship-management.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Students can apply to a published internship program, but do not receive
structured prompts for preparing around its learning outcomes. M12 needs a
safe first slice that helps a student prepare without making placement or
academic decisions.

## Scope

### Included

- Read-time checklist on the applicant's own published program view.
- Status-aware items for pending, accepted, rejected, and withdrawn states.
- Program-derived prompts from published learning outcomes and required skills.
- Source labels and an uncertainty statement.
- Deterministic `rules_preview` behavior with no external provider.

### Excluded

- Student matching, ranking, acceptance, rejection, mentor notes, progress
  scoring, evaluation drafting, academic decisions, messaging, and persistent
  agent memory.

## Invariants

1. Only the application student can receive the checklist.
2. The service reads only published program fields and the student's own
   application status and statement presence.
3. The service cannot mutate an application, program, evaluation, or outcome.
4. Every item has a source and the result has an uncertainty statement.
5. The assistant never invents skills, learning outcomes, progress, or grades.
6. The same application and program state produce the same checklist.

## Acceptance Criteria

- [ ] A student sees stage-appropriate preparation items on their application.
- [ ] A mentor/reviewer does not receive the student-only checklist through the
      organization view.
- [ ] Another student cannot receive the checklist for someone else's record.
- [ ] The checklist never changes application or evaluation state.
- [ ] Rejected and withdrawn applications receive reflection guidance, not an
      action implying placement or appeal.
- [ ] English and Thai copy identify the guidance as advisory.

## Verification

    bin/docs
    bin/rails test test/services/recruitment/internship_application_assistant_test.rb test/controllers/recruitment/internship_programs_controller_test.rb
    bin/verify
