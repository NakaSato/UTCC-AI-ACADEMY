---
id: ADR-0038
type: adr
title: Start recruitment communication with participant-scoped in-app application conversations
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0033, ADR-0037, SPEC-0033, SPEC-0037]
implemented_by:
  - SPEC-0038
  - app/models/recruitment/job_application_message.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/recruitment/job_applications/show.html.erb
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
enforced_by:
  - test/models/recruitment/job_application_message_test.rb
  - test/controllers/recruitment/job_applications_controller_test.rb
---

# Start Recruitment Communication with Participant-Scoped In-App Application Conversations

> [Decision Records](README.md) ·
> [Conversation specification](../specs/spec-recruitment-application-conversations.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-09 for the in-app
> conversation slice: participant-scoped access, immutable audited plain-text
> messages, no stage effects, and no external delivery. Product, Privacy,
> Security, Recruitment, and QA owners must still approve retention,
> moderation, notification, and production communication policy.

## Context

Candidates and hiring teams need a durable communication history tied to an
application. Email and external messaging add delivery, consent, retention,
identity, and support obligations that are not yet approved. The existing
application boundary already identifies the candidate and authorized hiring
team, so it can support a small in-app conversation.

## Decision

- Store plain-text messages on the application and show them only to the
  candidate or an active organization owner, recruiter, or hiring manager.
- Allow either participant boundary to send a message; the application state
  does not change when a message is sent.
- Keep messages in chronological history with sender and timestamp.
- Use no email, push, external messaging, automated outreach, AI-generated
  content, attachments, or candidate search.
- Do not add notification delivery until recipient selection, consent,
  frequency, moderation, and retention policies are approved.

## Alternatives

### Send every message by email immediately

Rejected. The production email provider, recipient consent, delivery failure,
unsubscribe, and retention policy are not approved for recruitment messaging.

### Let any organization member read the conversation

Rejected. Mentor and unrelated membership roles should not receive hiring
communications by default.

### Allow messages to change application stage

Rejected. Stage transitions remain explicit, permissioned, and evented through
the M9 workflow.

## Consequences

- Participants have one auditable, application-scoped communication history.
- Messages are plain text and intentionally lack moderation, notification, and
  attachment features until their owners define those policies.
- The first slice does not guarantee timely attention because no notification
  channel is enabled.

## Fitness Functions

- A candidate cannot read or write another candidate's conversation.
- A mentor, unrelated member, and outsider cannot read or write the conversation.
- Messages cannot mutate application status or expose recruiter-only notes.
- Message body length and persistence are database-backed and validated.
- `bin/docs` and focused conversation tests pass.
