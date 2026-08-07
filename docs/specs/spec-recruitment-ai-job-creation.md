---
id: SPEC-0027
type: spec
title: Provider-neutral recruitment job suggestions and human review
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0027, SPEC-0026]
implemented_by:
  - app/models/recruitment/job_post.rb
  - app/models/recruitment/job_post_suggestion.rb
  - app/services/recruitment/job_suggestion_generator.rb
  - app/controllers/recruitment/job_suggestions_controller.rb
  - db/migrate/20260807130000_create_recruitment_job_post_suggestions.rb
  - test/models/recruitment/job_post_suggestion_test.rb
  - test/controllers/recruitment/job_suggestions_controller_test.rb
touches:
  - app/models
  - app/controllers
  - app/services
  - app/views
  - db/migrate
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/job_post_suggestion_test.rb
  - test/controllers/recruitment/job_suggestions_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-AI-001, SKILL-AI-002, SKILL-TEST-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-AI-002, SKILL-TEST-001]
---

# Provider-Neutral Recruitment Job Suggestions and Human Review

> [Executable Specifications](README.md) ·
> [Suggestion ADR](../decisions/adr-0027-provider-neutral-job-suggestions.md) ·
> [Job-management specification](spec-recruitment-job-management.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Draft for Product Owner, Tech Lead, Security/Privacy, and
> Recruitment Domain review. The first provider is a labelled local preview,
> not an external AI integration.

## Problem

Recruiters need help turning structured hiring inputs into useful job content,
but suggestions must remain inspectable, reversible, and subordinate to human
publication approval. The platform must establish that workflow without
inventing a model provider or sending candidate data to an external service.

## Scope

### Included

- Employer inputs for hiring reason and number of positions.
- A provider-neutral suggestion record attached to a job post.
- A rules-based preview provider that generates summary, description,
  requirements, interview questions, and inclusive-language suggestions.
- Source label, uncertainty label, provider, model, and input-context metadata.
- Generate, edit, accept, reject, and regenerate actions for job authors.
- Applying accepted summary/description content to editable drafts only.
- Audit events and bilingual review UI.

### Excluded

- External model providers, API keys, prompts sent over the network, or model
  training use.
- Candidate profiles, resumes, protected characteristics, ranking, matching,
  screening, or automatic rejection.
- Automatic publication, salary benchmarking, hiring-time prediction, and
  legal/compliance claims.
- Applications, interviews, offers, and job templates.

## Suggestion kinds

| Kind | Applies to job field | Review purpose |
| --- | --- | --- |
| `summary` | `summary` | Candidate-facing role summary |
| `description` | `description` | Responsibilities and deliverables |
| `requirements` | None | Required and preferred qualifications |
| `interview_questions` | None | Draft interview prompts for human review |
| `inclusive_language` | None | Language-review observations |

## Invariants

1. Every suggestion belongs to one job post and requesting user; the job post
   organization cannot be changed by suggestion parameters.
2. Suggestion kinds and statuses are restricted to the approved sets.
3. Every suggestion stores provider, source label, and uncertainty; the first
   provider is `rules_preview` and must not be displayed as an external model.
4. Only active organization owners, recruiters, and hiring managers can create
   or review suggestions; mentors and non-members cannot access them.
5. Suggestion generation uses only approved employer inputs from its job post;
   candidate data and protected characteristics are not part of the context.
6. A pending or edited suggestion can be accepted, edited, rejected, or
   regenerated; accepted and rejected suggestions cannot be silently changed.
7. Accepting summary or description content updates only a draft or paused job;
   published, review, closed, and archived jobs are never overwritten.
8. Accepting a suggestion never changes job status and cannot bypass the
   existing review and owner/hiring-manager publication gate.
9. Every generation and review action records the current actor, job, kind, and
   decision; raw tokens and candidate data are never stored in the audit row.
10. If generation fails, no partial suggestion batch is committed.

## Acceptance Criteria

- [ ] An authorized job author can generate labelled suggestions from employer
      inputs (`test/controllers/recruitment/job_suggestions_controller_test.rb`).
- [ ] A suggestion displays its provider, source, uncertainty, and review state
      (`test/controllers/recruitment/job_suggestions_controller_test.rb`).
- [ ] An author can edit and accept a summary suggestion, which updates an
      editable job without publishing it
      (`test/controllers/recruitment/job_suggestions_controller_test.rb`).
- [ ] An author can reject and regenerate a suggestion without changing the
      job status (`test/controllers/recruitment/job_suggestions_controller_test.rb`).
- [ ] Mentors and non-members cannot generate or review suggestions
      (`test/controllers/recruitment/job_suggestions_controller_test.rb`).
- [ ] Suggestions reject invalid kinds, statuses, blank content, and invalid
      provenance (`test/models/recruitment/job_post_suggestion_test.rb`).
- [ ] Published jobs cannot be overwritten by accepting a suggestion
      (`test/models/recruitment/job_post_suggestion_test.rb`).
- [ ] Generation and review actions are auditable
      (`test/controllers/recruitment/job_suggestions_controller_test.rb`).

## Error and Boundary Cases

- A suspended organization cannot generate or review suggestions.
- An archived or closed job has no suggestion actions.
- A published job may be read, but accepting a suggestion against it is
  rejected without changing content or timestamps.
- A malformed or missing suggestion ID returns not-found within the current
  organization boundary.
- Regeneration rejects the previous pending/edited suggestion only after the
  replacement is available; a failed replacement leaves the old suggestion.
- Source context contains only allow-listed job-input keys.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/job_post_suggestion_test.rb test/controllers/recruitment/job_suggestions_controller_test.rb
    bin/verify
