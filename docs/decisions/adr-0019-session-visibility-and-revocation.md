---
id: ADR-0019
type: adr
title: Define active-session visibility and revocation
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
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
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define active-session visibility and revocation

> **Decision state:** Agent-prepared draft. The Product Owner, Tech Lead,
> Security Owner, and Privacy Owner must decide what session information may be
> shown and who may revoke which sessions before implementation.

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

The accountable owners must decide:

1. Whether users see all active sessions, only non-current sessions, or a
   summary; and whether IP address, user agent, creation time, last activity,
   approximate location, or other metadata is displayed.
2. Whether users may revoke one session, all other sessions, or the current
   session; and what confirmation and recovery language applies.
3. Whether administrators may view or revoke another user's sessions, which
   roles may do so, what reason is required, and what audit data is retained.
4. Whether revocation destroys the row, records a revocation state, or uses a
   separate security-event record; and how expired-row cleanup works.
5. What revocation means for in-flight HTTP requests, WebSockets, notifications,
   remembered cookies, and concurrent requests.
6. Whether the 30-day absolute limit remains appropriate, and whether idle or
   step-up authentication is needed for sensitive actions.
7. What a user sees when the current session is revoked elsewhere and how a
   suspected compromise is escalated without exposing account existence.

Until those decisions are accepted, the current 30-day lookup boundary and
current logout/password-change behavior remain unchanged.

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

No option is selected by this draft.

## Consequences

- Session management is a security control, not only a profile-page feature;
  every authentication consumer must use the same live/revoked boundary.
- Displaying IP addresses and user agents requires data minimization, locale,
  timezone, retention, and access decisions.
- Revocation must be idempotent and safe when the browser retries or two support
  actors act at once.
- If historical revocation events are required, they must not store cookies,
  raw session identifiers, passwords, or unnecessary request data.
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
- A live WebSocket may outlast the page that opened it; revocation must define
  whether the connection is closed immediately or denied on its next action.

## Fitness Functions

- A revoked or expired session cannot authenticate ordinary requests or a new
  WebSocket connection, even when its signed cookie is replayed.
- A user cannot list, revoke, or infer another user's sessions through IDs,
  parameters, response differences, or stale URLs.
- A successful revocation creates exactly the approved security/audit evidence;
  failed, unauthorized, or stale actions create no misleading success event.
- Session pages reveal only approved metadata and never raw cookies, passwords,
  full request headers, or unnecessary personal data.
