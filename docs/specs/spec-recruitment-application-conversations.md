---
id: SPEC-0038
type: spec
title: Participant-scoped in-app recruitment application conversations
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0033, ADR-0038, SPEC-0033]
implemented_by:
  - app/models/recruitment/job_application_message.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications/show.html.erb
  - db/migrate/20260808140000_create_recruitment_job_application_messages.rb
  - test/models/recruitment/job_application_message_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
enforced_by:
  - test/models/recruitment/job_application_message_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
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
agent_writable: true
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
---

# Participant-Scoped In-App Recruitment Application Conversations

> [Executable Specifications](README.md) ·
> [Conversation ADR](../decisions/adr-0038-in-app-application-conversations.md) ·
> [Application-workflow specification](spec-recruitment-application-workflow.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

Recruitment applications have stage history but no shared place for a
candidate and authorized hiring team to communicate. The first communication
slice must avoid external delivery and preserve the application privacy
boundary.

## Scope

### Included

- Plain-text messages stored on a job application.
- Candidate access to their own conversation.
- Owner, recruiter, hiring-manager, or company-reviewer access for that
  application's organization.
- Chronological sender/timestamp history.
- Audit events for message creation.

### Excluded

- Email, push, SMS, external messaging, attachments, moderation, read receipts,
  automated or AI-generated messages, notification delivery, and stage changes.

## Invariants

1. A message belongs to exactly one application and one sender.
2. Only the application candidate or an active organization owner, recruiter,
   hiring manager, or company reviewer can read or create messages.
3. Mentors and unrelated organization members cannot access the conversation.
4. Message creation never changes application status or stage history.
5. Message body is non-empty, plain text, and at most 4,000 characters.
6. Every created message has a sender, timestamp, and audit event.

## Acceptance Criteria

- [ ] Candidate and authorized recruiter can exchange messages on an application.
- [ ] Messages render in chronological order with sender and timestamp.
- [ ] Candidate cannot access another candidate's messages.
- [ ] Mentor, outsider, and unrelated organization member receive no message data.
- [ ] Message creation does not mutate application status.
- [ ] English and Thai copy state that this is in-app communication only.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/job_application_message_test.rb test/controllers/recruitment/job_applications_controller_test.rb
    bin/verify
