---
id: SPEC-0028
type: spec
title: Organization-scoped internship programs, student applications, and evaluations
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@academic-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-22
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0026, ADR-0028, SPEC-0024, SPEC-0026]
implemented_by:
  - app/models/recruitment/internship_program.rb
  - app/models/recruitment/internship_application.rb
  - app/models/recruitment/internship_evaluation.rb
  - app/controllers/recruitment/internship_programs_controller.rb
  - app/controllers/recruitment/internship_applications_controller.rb
  - app/controllers/recruitment/internship_evaluations_controller.rb
  - app/controllers/recruitment/internship_suggestions_controller.rb
  - app/services/recruitment/internship_suggestion_generator.rb
  - app/models/recruitment/internship_program_suggestion.rb
  - db/migrate/20260808090000_create_recruitment_internship_programs.rb
  - db/migrate/20260808100000_create_recruitment_internship_program_suggestions.rb
  - test/models/recruitment/internship_program_test.rb
  - test/models/recruitment/internship_application_test.rb
  - test/controllers/recruitment/internship_programs_controller_test.rb
  - test/controllers/recruitment/internship_applications_controller_test.rb
  - test/controllers/recruitment/internship_evaluations_controller_test.rb
  - test/models/recruitment/internship_program_suggestion_test.rb
  - test/controllers/recruitment/internship_suggestions_controller_test.rb
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
enforced_by:
  - test/models/recruitment/internship_program_test.rb
  - test/models/recruitment/internship_application_test.rb
  - test/controllers/recruitment/internship_programs_controller_test.rb
  - test/controllers/recruitment/internship_applications_controller_test.rb
  - test/controllers/recruitment/internship_evaluations_controller_test.rb
  - test/models/recruitment/internship_program_suggestion_test.rb
  - test/controllers/recruitment/internship_suggestions_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
---

# Organization-Scoped Internship Programs, Student Applications, and Evaluations

> [Executable Specifications](README.md) ·
> [Internship boundary ADR](../decisions/adr-0028-recruitment-internship-program-boundary.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Draft. Academic and Product owners must confirm student
> eligibility, paid/unpaid policy, evaluation retention, and certificate rules.

## Problem

Organizations need a structured way to publish internships with explicit
learning outcomes and capacity. Students need to apply and withdraw without
losing visibility into their status. Mentors need a bounded, reviewable place to
evaluate accepted participants. The workflow must not expose one organization’s
students or let a race exceed program capacity.

## Scope

### Included

- Organization-scoped internship program creation, editing, review, publish,
  pause, close, and archive states.
- Program fields for duration, capacity, mentor, required skills, learning
  outcomes, working days, remote policy, compensation, certificate policy, and
  equipment.
- Public published-program discovery for signed-in candidates.
- One student application per program, application status, and withdrawal.
- Authorized application acceptance/rejection with capacity enforcement.
- One structured evaluation per accepted application, owned by the assigned
  mentor or an authorized program reviewer.
- A provider-neutral, rules-based preview for program description, learning
  roadmap, mentor guide, evaluation criteria, and final-project suggestions.
- Bilingual UI and audit events for consequential actions.

### Excluded

- External model providers, matching, screening, interviews, offers,
  certificates, payroll, and academic credit.
- Resume collection, protected-characteristic inference, and ranking.
- Email delivery or automatic status changes outside explicit user actions.

## Statuses and authority

| Record | Statuses | Allowed actor |
| --- | --- | --- |
| Program | draft, review, published, paused, closed, archived | organization author; publication by owner/hiring manager |
| Application | pending, accepted, rejected, withdrawn | student owns withdrawal; program reviewer decides |
| Evaluation | draft, submitted | assigned mentor or program reviewer |

## Invariants

1. Every program, application, and evaluation belongs to one organization
   boundary through its program/application.
2. A program has one active creator and, before publication, one active mentor
   from the same organization.
3. A published program has complete duration, capacity, learning-outcome,
   logistics, and compensation-policy fields.
4. A student may have at most one application per program; only a student may
   create one, and only while the program is published and not full or closed.
5. Accepting applications is serialized on the program row and never makes
   accepted applications exceed `max_students`.
6. Students can withdraw only their own pending or accepted application.
7. Only an active organization reviewer may accept/reject an application; a
   mentor may evaluate only an accepted application in their organization.
8. Each accepted application has at most one evaluation; evaluation submission
   requires a rating, outcome result, feedback, and next steps.
9. Program publication, application decisions, withdrawals, and evaluations do
   not automatically issue certificates or alter academic records.
10. Raw student profile data, protected characteristics, and hidden ranking
    signals are not copied into program or application records.
11. Every program suggestion stores provider, source, uncertainty, and review
    status; accepting a description changes only an editable program.

## Acceptance Criteria

- [ ] An authorized organization user can create and publish a complete
      internship program.
- [ ] A student can see published programs, apply once, view status, and
      withdraw their own application.
- [ ] A reviewer can accept or reject applications, and capacity cannot be
      exceeded.
- [ ] An assigned mentor can submit and update one structured evaluation for an
      accepted participant.
- [ ] Mentors and non-members cannot access another organization’s management
      records.
- [ ] Program and application transitions are auditable in English and Thai.
- [ ] Authors can generate, edit, accept, reject, and regenerate labelled
      provider-neutral program suggestions without automatic publication.

## Error and Boundary Cases

- Suspended organizations are hidden from public discovery and reject writes.
- Draft, review, paused, closed, or archived programs cannot receive new
  applications.
- Duplicate applications are rejected by both model validation and a unique
  database index.
- A full program rejects new applications and concurrent acceptance beyond
  capacity.
- Rejected or withdrawn applications cannot be accepted or evaluated.
- A malformed program/application/evaluation ID is not-found within the current
  organization boundary.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/internship_program_test.rb test/models/recruitment/internship_application_test.rb test/models/recruitment/internship_evaluation_test.rb test/models/recruitment/internship_program_suggestion_test.rb test/controllers/recruitment/internship_programs_controller_test.rb test/controllers/recruitment/internship_applications_controller_test.rb test/controllers/recruitment/internship_evaluations_controller_test.rb test/controllers/recruitment/internship_suggestions_controller_test.rb
    bin/verify
