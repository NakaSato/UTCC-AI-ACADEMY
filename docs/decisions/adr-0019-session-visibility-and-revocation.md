---
id: ADR-0019
type: adr
title: Define active-session visibility and revocation
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-05
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: []
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
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define active-session visibility and revocation

> **Decision state:** Accepted by the user on 2026-08-05. An authenticated user
> may review their own live sessions using minimized metadata and revoke one
> other session or all other sessions. Current-session protection, HTTP and new
> WebSocket enforcement, and the existing 30-day expiry remain in force.

> [Decision Records](README.md) ·
> [M9 session specification](../specs/spec-m9-session-visibility-and-revocation.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Context

The application stores one database row per signed-in session with user agent,
IP address, user, and timestamps. A signed cookie points to the row; the
authentication boundary accepts only sessions younger than the 30-day absolute
`Session::MAX_AGE`. Logging out destroys the current row, and changing a
password destroys the user's other sessions.

There is no user-visible active-session list, no individual revoke action, and
no administrator support path for a suspected compromise. WebSocket connection
authentication also reads the session row, so the accepted revocation behavior
must cover both ordinary requests and live channels.

Session metadata is security-sensitive personal data. An implementation must
not turn IP addresses, user-agent strings, integer row IDs, or administrator
visibility into a new privacy or account-enumeration problem.

## Problem frame

- **Affected user:** A learner or staff member trying to identify and end a
  session on a shared, lost, or compromised device; support staff handling a
  suspected account compromise.
- **Current behavior:** The user can end only the current session directly;
  password change ends other sessions as a side effect; session age is enforced
  but not shown or individually revocable.
- **Failure risk:** A stolen cookie remains usable until expiry, a legitimate
  user is locked out by an unsafe bulk action, or sensitive session metadata is
  exposed to the wrong actor.
- **Success signal:** An authorized actor can recognize and revoke the intended
  session, the revoked cookie fails on the next authenticated boundary, and the
  action is understandable, audited, and privacy-safe.

## Decision boundary

The accepted policy is:

1. An authenticated user sees only their own live sessions, ordered newest
   first. The profile shows only a broad device family and sign-in time; it does
   not show IP addresses, full user-agent strings, approximate location, raw
   cookies, or database identifiers.
2. The current session is labeled and cannot be revoked by the individual or
   “other sessions” actions. The user may revoke one other session or all other
   sessions. The UI uses truthful Thai and English success and stale-session
   messages.
3. There is no administrator or support cross-account session-management path
   in this increment. A client-supplied identifier cannot widen account scope.
4. Revocation destroys the targeted session row. Opaque signed IDs with a
   dedicated purpose are used in mutation links; raw row IDs are not exposed.
   Repeated or stale revocation requests are safe and do not report success.
5. HTTP authentication and new WebSocket authentication continue to use the
   same `Session.live` lookup, so a destroyed session's signed cookie fails at
   both boundaries. Already-open WebSockets and in-flight requests are not
   promised synchronous termination by this slice.
6. The 30-day absolute session lifetime, logout behavior, password-change
   revocation, and existing expired-row cleanup remain unchanged. No idle
   timeout, step-up authentication, persisted revocation history, or new admin
   audit record is introduced.
7. The profile exposes no historical session list after rows are destroyed and
   retains only the existing server-side session metadata under the current
   application retention behavior.

## Alternatives

### Keep expiry and password-change revocation only

This has no new privacy surface and is already implemented, but leaves a stolen
cookie usable until expiry and requires a password change for a narrower action.

### User-managed sessions with row destruction

The account owner sees approved metadata and revokes a row by destroying it.
This is simple and makes the existing `Session.live` lookup the enforcement
point, but requires careful current-session, race, WebSocket, and audit rules.

### Persisted revocation state and security events

Keep the session row and record `revoked_at`, actor, reason, and event history.
This improves incident reconstruction and support, but increases retention,
privacy, schema, and cleanup obligations.

### Admin-only session termination

Support staff can end sessions without exposing metadata to learners. This can
help incident response, but is slower for a user with a lost device and creates
an authority and insider-risk boundary.

### Approved policy direction

User-managed sessions with row destruction is selected for this increment, with
own-account scope, broad device/time metadata, current-session protection, and
no administrator cross-account controls. Persisted revocation history and
support workflows remain future policy work.

## Consequences

- Session management is a security control, not only a profile-page feature;
  every authentication consumer must use the same live/revoked boundary.
- The profile intentionally trades exact device recognition for reduced
  exposure by showing only a broad device family and sign-in time.
- Revocation is idempotent and safe when the browser retries or two tabs act at
  once; row destruction keeps the existing authentication boundary simple.
- Historical revocation events, admin support controls, and immediate closure
  of already-open channels remain outside this increment.
- A shorter lifetime, idle timeout, or step-up challenge changes the user
  experience and needs a separate measurable security decision if not covered
  by the accepted policy.

## Threat boundary

- A stolen signed cookie is bearer material; signature validity alone is not
  sufficient after a row is revoked.
- A user may be malicious or mistaken about which device a user-agent string
  represents; the UI must confirm the target without claiming exact location.
- An administrator is a privileged actor; cross-account session operations need
  explicit authorization, reason, audit, and privacy limits.
- A live WebSocket may outlast the page that opened it; this increment denies
  the revoked cookie on a new connection and does not claim immediate closure
  of an already-open connection.

## Fitness Functions

- A revoked or expired session cannot authenticate ordinary requests or a new
  WebSocket connection, even when its signed cookie is replayed.
- A user cannot list, revoke, or infer another user's sessions through IDs,
  parameters, response differences, or stale URLs.
- A successful revocation destroys exactly the approved session row; failed,
  unauthorized, or stale actions create no misleading success event.
- Session pages reveal only approved metadata and never raw cookies, passwords,
  full request headers, or unnecessary personal data.
