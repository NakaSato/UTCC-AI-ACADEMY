---
id: ADR-0028
type: adr
title: Keep internship programs, applications, mentors, and evaluations organization-scoped
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@academic-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-08-22
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0026, ADR-0027, SPEC-0024, SPEC-0026]
implemented_by:
  - SPEC-0028
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
---

# Keep Internship Programs, Applications, Mentors, and Evaluations Organization-Scoped

> [Decision Records](README.md) ·
> [Internship specification](../specs/spec-recruitment-internship-management.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for organization-scoped
> internship programs, student applications, capacity/review rules, mentor
> evaluations, provider-neutral suggestions, and audit boundaries.

## Context

Milestone M4 introduces internship programs alongside job posts. An internship
has learning outcomes and a finite student capacity, so it cannot be modelled as
a job-post flag. Applications contain student decisions and evaluations contain
academic or employment evidence; both require a narrow organization boundary,
explicit status transitions, and auditable human actions.

## Decision

- Store internship programs, applications, and evaluations as separate
  recruitment-domain records.
- Scope every management read and write through the owning organization.
- Allow only active organization authors to create or edit programs; require an
  assigned active organization mentor before publication.
- Allow signed-in students to apply only to published programs, with one
  application per program and a database-enforced capacity check during
  acceptance.
- Let students withdraw their own application; let authorized program reviewers
  accept or reject applications; let the assigned mentor or an authorized
  program owner submit one structured evaluation for an accepted application.
- Keep program publication separate from application acceptance and evaluation;
  no action automatically issues a certificate or changes academic records.
- Record consequential program, application, and evaluation actions in the
  existing audit stream without storing resume content or hidden AI scores.
- Provide a labelled local preview for internship description, learning
  roadmap, mentor guide, evaluation criteria, and final-project suggestions;
  suggestions remain separate review records and never publish a program.

## Alternatives

### Reuse job posts with an internship flag

Rejected. Internship capacity, learning outcomes, mentor assignment, and
evaluation evidence have different lifecycle and privacy rules than employment
job posts.

### Let applications be free-form comments on a program

Rejected. Comments cannot enforce one application per student, capacity, status,
withdrawal, or structured evaluation ownership.

### Allow any organization member to evaluate any student

Rejected. Evaluation authority must follow the assigned mentor or explicit
program-reviewer roles to limit sensitive student evidence.

## Consequences

- The program workflow is more explicit and queryable, with additional tables
  and lifecycle code.
- Student application and evaluation retention, eligibility, and certificate
  policy remain human-owned decisions.
- The first Internship Agent behavior is a deterministic preview, not an
  external-model claim. A future provider adapter must preserve the same
  provenance, uncertainty, and human-review boundary.

## Fitness Functions

- A program cannot publish without required learning, capacity, mentor, and
  logistics fields.
- A student cannot apply twice to one program or apply to an unpublished,
  closed, or full program.
- Concurrent application acceptance cannot exceed program capacity.
- A student can withdraw only their own application; organization boundaries
  prevent cross-company access.
- Only the assigned mentor or an authorized program reviewer can submit an
  evaluation for an accepted application.
- `bin/docs` and focused internship model/controller tests pass.
