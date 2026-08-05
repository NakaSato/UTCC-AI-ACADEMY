---
id: SPEC-0019
type: spec
title: Active-session visibility and revocation
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-05
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
enforced_by:
  - test/models/session_test.rb
  - test/controllers/session_management_test.rb
  - test/controllers/sessions_controller_test.rb
  - test/controllers/profiles_controller_test.rb
  - test/channels/application_cable/connection_test.rb
  - test/system/session_management_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001]
---

# Active-session visibility and revocation

> **Review state:** Accepted by the user on 2026-08-05. The implemented slice
> covers own-account visibility, minimized metadata, individual/all-other
> revocation, and the existing HTTP/WebSocket live-session boundary.

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

### Included

- Show the user's own live sessions in the profile/security area.
- Identify the current session without exposing a raw cookie or database ID.
- Revoke one other session or all other sessions; keep the current session.
- Enforce revocation through HTTP authentication and WebSocket connection
  boundaries.
- Use broad device-family and sign-in-time metadata only, with truthful
  Thai/English states.
- Keep the existing 30-day expiry, logout, password-change, and cleanup rules.

### Excluded

- Displaying exact geolocation, full request headers, passwords, signed cookies,
  or raw session identifiers.
- Changing the 30-day lifetime, adding idle expiry, or adding step-up auth before
  those policies are separately accepted.
- Adding administrator/support cross-account controls, persisted revocation
  history, or a new security-event audit record.
- Treating logout as proof that every already-running request or WebSocket has
  been synchronously terminated.
- Building a general security-event dashboard in this slice.

## Invariants

1. Session reads and revocations are scoped to the authenticated account; no
   support/admin target is authorized in this slice.
2. A revoked or expired session fails the same live-session lookup used by HTTP
   and WebSocket authentication.
3. A revocation request is idempotent and cannot revoke a session outside the
   approved target set through parameter tampering.
4. The current session cannot be revoked by the individual or bulk “other
   sessions” actions.
5. The UI exposes only approved, minimized metadata and does not reveal whether
   another account or session exists.
6. Failed, unauthorized, stale, or malformed actions leave session state and
   success audit evidence unchanged.
7. A destroyed session row provides the approved revocation evidence; no
   separate history is retained in this slice.
8. Existing expired-session cleanup remains unchanged because no separate
   revocation history is introduced.

## Acceptance Criteria

- [x] The user approves own-account visibility, broad device/time metadata,
      current-session protection, individual/all-other row destruction, no
      cross-account controls, unchanged 30-day expiry, and HTTP/new-WebSocket
      enforcement (`docs/decisions/adr-0019-session-visibility-and-revocation.md`).
- [x] An authenticated user sees only their own live session data and can revoke
      only another session in that account (`test/controllers/session_management_test.rb`).
- [x] Raw IDs, cookies, full user agents, and IP addresses are not exposed in
      the profile response (`test/controllers/session_management_test.rb`).
- [x] A current-session or cross-account signed token cannot revoke the target;
      stale requests do not report success (`test/controllers/session_management_test.rb`).
- [x] A destroyed session cookie fails ordinary HTTP authentication and a new
      WebSocket connection (`test/controllers/session_management_test.rb`,
      `test/channels/application_cable/connection_test.rb`).
- [x] Existing logout, password-change revocation, and live/expired boundaries
      remain covered (`test/controllers/sessions_controller_test.rb`,
      `test/controllers/profiles_controller_test.rb`, `test/models/session_test.rb`).
- [x] Thai and English profile screens explain current sessions, device family,
      sign-in time, and revoke outcomes (`test/system/session_management_walk_test.rb`).
- [x] Full repository verification passes (`bin/verify`).

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

The accepted policy closes the current handoff. A future cross-account,
historical-audit, idle-timeout, step-up, or immediate-WebSocket-termination
change must reopen this table before implementation.

| Review point | Accepted baseline |
| --- | --- |
| Visibility | Own live sessions; broad device family and sign-in time only. |
| User actions | Revoke one other session or all other sessions; current protected. |
| Admin authority | No cross-account admin/support action in this slice. |
| Enforcement | Same live row lookup for HTTP and new WebSocket connections. |
| Retention | Destroy revoked rows; existing expiry/cleanup unchanged. |
| Lifetime | Keep the 30-day absolute expiry. |
| Incident support | Truthful stale/revoke messages; no new support workflow. |

## Rollback and observability

- Rollback removes the management UI and mutation routes while preserving the
  existing live-session expiry, logout, and password-change behavior.
- Revoked rows are already destroyed by the accepted policy; no separate
  security history is created by this slice.
- Monitor aggregate revocation success/failure, stale attempts, expired-session
  use, and authentication denials without logging cookies or unnecessary request
  data.

## Verification

```bash
bin/docs
bin/rails test test/models/session_test.rb test/controllers/session_management_test.rb test/controllers/sessions_controller_test.rb test/controllers/profiles_controller_test.rb
bin/rails test test/channels/application_cable/connection_test.rb
bin/rails test:system test/system/session_management_walk_test.rb
bin/verify
```
