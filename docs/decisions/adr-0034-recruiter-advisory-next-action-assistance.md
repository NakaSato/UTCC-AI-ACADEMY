---
id: ADR-0034
type: adr
title: Start the AI recruiter agent with advisory application next-action assistance
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0033, SPEC-0033]
implemented_by:
  - SPEC-0034
  - app/services/recruitment/job_application_assistant.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications/show.html.erb
touches:
  - app/services
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - test/services
  - test/controllers
enforced_by:
  - test/services/recruitment/job_application_assistant_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
agent_writable: true
---

# Start the AI Recruiter Agent with Advisory Application Next-Action Assistance

> [Decision Records](README.md) ·
> [Recruiter-assistance specification](../specs/spec-recruiter-advisory-assistance.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-09 for the provider-neutral
> advisory next-action boundary and local verification. Legal, Security,
> Recruitment, Privacy, Data, and QA review remains required before production
> or consequential use.

## Context

The M10 roadmap asks for an AI recruiter agent, but automated screening,
ranking, rejection, contacting, and offers are consequential employment actions.
The existing M9 pipeline already contains authorized application status and
event history. That is enough for a small assistant that helps a recruiter
notice what to review next without evaluating candidate quality.

## Decision

- Add a provider-neutral, read-time assistant for one authorized application.
- Derive one advisory next action from the application status, latest event,
  and elapsed time since the relevant stage began.
- Show the source fields and uncertainty next to the recommendation. The
  recruiter must decide and perform any action manually.
- Use no model vendor, external data, vector store, candidate ranking, score,
  protected characteristic, candidate comparison, or outbound communication.
- Do not persist a recommendation; the application event history remains the
  authoritative record.

## Alternatives

### Rank applications by predicted hiring probability

Rejected. There is no approved evaluation dataset, fairness contract, or
override policy, and a rank would be read as a consequential employment signal.

### Let the assistant advance stages automatically

Rejected. Stage transitions require an authorized human and an auditable event.

### Use an external LLM immediately

Rejected for this slice. The data disclosure, prompt-injection, retention,
egress, provider, and evaluation boundaries are not approved.

## Consequences

- Recruiters receive a small, explainable attention cue from workflow data they
  are already authorized to view.
- The assistant cannot reduce candidate review quality to a score or make a
  hiring decision.
- A future agent may add richer assistance only after tool scope, identity,
  budget, kill-switch, data disclosure, and human approval policies are named.

## Fitness Functions

- The assistant is unavailable outside the organization-scoped application
  boundary.
- Every recommendation contains source fields and an uncertainty statement.
- The service has no ranking, score, stage mutation, candidate comparison, or
  outbound side effect.
- It reads only application workflow fields and never protected traits.
- `bin/docs` and focused assistant tests pass.
