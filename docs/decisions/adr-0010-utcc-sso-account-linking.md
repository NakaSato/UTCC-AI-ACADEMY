---
id: ADR-0010
type: adr
title: Define the UTCC SSO and account-linking boundary
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-09
supersedes: []
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - app/models/user.rb
  - app/models/session.rb
  - app/controllers/sessions_controller.rb
  - app/views/shared/_auth_sso.html.erb
  - config/routes.rb
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define the UTCC SSO and account-linking boundary

> **Decision state:** Agent-prepared draft. The institution must provide and
> approve the protocol, issuer, claims, account-linking policy, emergency-access
> owner, and privacy/security controls before implementation.

> [Decision Records](README.md) ·
> [M6 SSO specification](../specs/spec-m6-utcc-sso-account-linking.md) ·
> [Roadmap Milestone 6](../roadmap.md#milestone-6--institutional-access-and-documents) ·
> [Current local authentication](../../app/controllers/sessions_controller.rb)

## Context

The application currently authenticates students with a local student ID and
password, stores expiring local sessions, and renders a disabled UTCC SSO
button. M6 calls for university sign-in, account linking, preserved local
emergency access, and safe SSO failure behavior, but the repository contains
no UTCC identity-provider metadata or approved account-linking policy.

An SSO implementation is an authentication boundary, not a cosmetic login
button. The academy must not create duplicate accounts, assign roles from an
untrusted claim, or link a university identity to the wrong student because an
email address happens to match.

## Decision

This draft proposes a replaceable provider-adapter and immutable external
identity boundary; the protocol and institutional policies remain pending.

## Proposed boundary

1. A provider adapter owns protocol discovery, authorization redirects, callback
   validation, token exchange, and provider-specific claim mapping.
2. An `ExternalIdentity` record owns the immutable `(issuer, subject)` binding
   to one local `User`; the provider subject is never replaced by an email.
3. The local `User` remains the owner of roles, course progress, sessions, and
   emergency local credentials.
4. Account linking is an explicit authenticated flow or an institution-approved
   exact student-identity claim flow; first-login email matching alone is never
   sufficient.
5. SSO failure returns the learner to local sign-in without exposing whether a
   student ID or external identity exists.

The provider adapter must be replaceable without changing `User`, progress, or
authorization rules. No provider credential, token, assertion, or raw profile
payload may be stored in Git, fixtures, logs, or audit messages.

## Alternatives

### Keep the disabled SSO affordance

Avoids identity risk and dependency cost, but leaves the university access goal
unmet and continues to present a non-functional control.

### OIDC provider adapter

Uses an issuer, discovery metadata, authorization-code flow, state, nonce, PKCE,
and signed ID-token validation. It is a compact modern boundary if UTCC supplies
OIDC metadata, but the exact claims and institutional registration still need
confirmation.

### SAML provider adapter

May fit an existing university identity service, but requires metadata,
certificate rollover, assertion-consumer-service rules, and more provider-
specific XML handling. It should be selected only if UTCC requires it.

### Match a first SSO login to a local email address

Small implementation, but unsafe as an identity proof: email normalization,
reassignment, aliases, and unverified claims can link the wrong academy account.
This option is rejected as a standalone linking rule.

## Threat model and minimum controls

- Validate issuer, audience, signature, expiry, nonce, state, and PKCE at the
  callback boundary; do not trust decoded claims without verification.
- Allow callbacks only for registered providers and exact application redirect
  URIs; reject open redirects and arbitrary issuer parameters.
- Keep provider `subject` and issuer unique at the database boundary; handle a
  race between two first-login callbacks without creating duplicate users.
- Treat provider role/group claims as input to an explicit mapping policy; local
  authorization remains authoritative.
- Do not log tokens, assertions, authorization codes, student IDs, or raw
  provider payloads. Record only a privacy-safe outcome and correlation ID.
- Preserve a documented local emergency path with rate limits, session expiry,
  revocation, and an accountable owner; do not silently weaken local password
  controls during SSO failure.

## Consequences

- The first implementation adds a durable external-identity binding rather than
  altering the existing `User` identifier.
- Provider outages do not make the local session or local emergency path claim
  success; the learner receives a safe, actionable fallback.
- Account-linking support and unlink/recovery behavior require support ownership
  and audit rules before production use.
- The provider's privacy, data-retention, service-availability, and procurement
  terms become release gates.

## Human decisions required

- UTCC provider, protocol, issuer/discovery metadata, client registration, and
  redirect URI owner.
- Stable identity claim and proof needed to link to `student_id`.
- Whether linking is self-service, staff-assisted, or institution-provisioned.
- Local emergency-access eligibility, owner, recovery process, and audit policy.
- Role/group claim mapping and whether any institutional role may override local
  roles.
- Logout, unlink, account-recovery, provider-outage, and duplicate-identity
  support behavior.
- Privacy, retention, data-residency, and security review owners.

## Fitness Functions

- `bin/docs` validates lifecycle metadata and skill references.
- Future identity tests must prove issuer/subject uniqueness, no email-only
  linking, local role ownership, safe callback rejection, and duplicate-race
  behavior.
- A system walkthrough must cover first login, an already-linked login, a failed
  provider callback, local emergency sign-in, and logout without exposing tokens.
