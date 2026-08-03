---
id: SPEC-0019
type: spec
title: Active-session visibility and revocation
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0019]
implemented_by: []
touches:
  - app/models/session.rb
  - app/controllers/concerns/authentication.rb
  - app/controllers/sessions_controller.rb
  - app/controllers/profiles_controller.rb
  - app/controllers
  - app/views/profiles
  - app/channels/application_cable/connection.rb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001]
---

# Active-session visibility and revocation

> **Review state:** Draft and blocked on security, privacy, authority, and
> retention policy. Existing logout, password-change revocation, and 30-day
> expiry remain unchanged until the contract is accepted.

> [Executable Specifications](README.md) ·
> [M9 session decision](../decisions/adr-0019-session-visibility-and-revocation.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Problem

Users cannot inspect or individually revoke active sessions. A stolen or
forgotten cookie can remain accepted until the 30-day absolute limit unless the
user changes their password or support intervenes. Session metadata is also
personal data and must be exposed only within an approved account/security
boundary.

## Scope

### Included after policy approval

- Show an approved active-session list or summary in the account/security area.
- Identify the current session without exposing a raw cookie or database ID.
- Revoke one session, all other sessions, or the approved target set.
- Enforce revocation through HTTP authentication and WebSocket connection
  boundaries.
- Add approved user/admin authorization, confirmation, audit, retention, and
  support behavior.
- Define expired-session cleanup and truthful Thai/English states.

### Excluded

- Displaying exact geolocation, full request headers, passwords, signed cookies,
  or raw session identifiers.
- Changing the 30-day lifetime, adding idle expiry, or adding step-up auth before
  those policies are separately accepted.
- Revoking sessions by a client-supplied user ID without server-side authority.
- Treating logout as proof that every already-running request or WebSocket has
  been synchronously terminated.
- Building a general security-event dashboard in this slice.

## Invariants

1. Session reads and revocations are scoped to the authenticated account or an
   explicitly authorized support/admin target.
2. A revoked or expired session fails the same live-session lookup used by HTTP
   and WebSocket authentication.
3. A revocation request is idempotent and cannot revoke a session outside the
   approved target set through parameter tampering.
4. The current session can be revoked only through an explicitly approved flow;
   a bulk “other sessions” action cannot accidentally end the request executing
   it.
5. The UI exposes only approved, minimized metadata and does not reveal whether
   another account or session exists.
6. Failed, unauthorized, stale, or malformed actions leave session state and
   success audit evidence unchanged.
7. Every approved cross-account revocation includes the required actor, target,
   reason, timestamp, and privacy-safe audit fields.
8. Expired-session cleanup cannot remove required security history if the
   accepted policy retains a separate revocation event.

## Acceptance Criteria

- [ ] The Product Owner, Tech Lead, Security Owner, and Privacy Owner approve
      visible metadata, target set, authority, revocation semantics, WebSocket
      behavior, retention, and cleanup (`docs/decisions/adr-0019-session-visibility-and-revocation.md`).
- [ ] Before approval, no active-session list or new revoke endpoint is exposed;
      existing logout and password-change behavior remains covered
      (`test/controllers/sessions_controller_test.rb`, `test/controllers/profiles_controller_test.rb`).
- [ ] An authenticated user sees only their approved active-session data and can
      revoke only the approved target set (`test/controllers/session_management_test.rb`).
- [ ] An unauthorized user, guessed ID, stale form, or cross-account request
      cannot list or revoke another account's sessions
      (`test/controllers/session_management_test.rb`).
- [ ] A revoked/expired cookie fails ordinary HTTP authentication and a new
      WebSocket connection (`test/models/session_test.rb`, `test/channels/application_cable/connection_test.rb`).
- [ ] Approved admin/support revocation enforces role, reason, audit, and
      minimized target data (`test/controllers/admin_session_management_test.rb`).
- [ ] Thai and English screens explain current session, revoke success/failure,
      expiry, and compromise support without overstating termination timing
      (`test/system/session_management_walk_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- The current session is the only live session, or it is revoked in another tab.
- Two tabs revoke the same session, or a request arrives after the row is gone.
- A session reaches the 30-day boundary during list or revoke processing.
- The user agent or IP address is missing, malformed, shared, or too long to
  render safely.
- A user changes their password while a session-revocation request is in flight.
- A WebSocket was opened before revocation and sends an action afterward.
- An administrator loses the required role or target scope between display and
  mutation.
- Expired rows are cleaned up while an incident or audit record still requires
  privacy-safe evidence.

## Human Session-Security Handoff

Implementation is held until the accountable owners complete this table.

| Review point | Decision required |
| --- | --- |
| Visibility | Session fields, current-session label, device naming, locale/timezone. |
| User actions | Individual, other-sessions, current-session, confirmation, recovery. |
| Admin authority | Roles, target scope, reason, approval, and audit fields. |
| Enforcement | HTTP, WebSocket, notifications, in-flight requests, and races. |
| Retention | Expired-row cleanup, revocation history, IP/user-agent retention. |
| Lifetime | Keep 30-day absolute expiry or review idle/step-up alternatives. |
| Incident support | Compromise messaging, escalation owner, and safe account handling. |

## Rollback and observability

- Rollback removes the new management UI and mutation route while preserving
  the existing live-session expiry, logout, and password-change behavior.
- Do not delete session rows or security history merely to roll back the UI;
  follow the approved retention and cleanup policy.
- Monitor aggregate revocation success/failure, stale attempts, expired-session
  use, and authentication denials without logging cookies or unnecessary request
  data.

## Verification

```bash
bin/docs
bin/rails test test/models/session_test.rb test/controllers/session_management_test.rb test/controllers/sessions_controller_test.rb
bin/rails test test/controllers/admin_session_management_test.rb test/channels/application_cable/connection_test.rb
bin/rails test:system test/system/session_management_walk_test.rb
bin/verify
```
