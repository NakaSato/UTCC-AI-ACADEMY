---
id: SPEC-0010
type: spec
title: UTCC SSO and safe account linking
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-09
supersedes: []
superseded_by: []
depends_on: [ADR-0010]
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-TEST-001]
---

# UTCC SSO and safe account linking

> **Review state:** Draft and blocked on institutional identity-provider and
> account-linking decisions. No SSO callback or credential flow is authorized
> until ADR-0010 is accepted.

> [Executable Specifications](README.md) ·
> [M6 SSO architecture decision](../decisions/adr-0010-utcc-sso-account-linking.md) ·
> [Roadmap Milestone 6](../roadmap.md#milestone-6--institutional-access-and-documents) ·
> [M6 syllabus PDF](spec-m6-course-syllabus-pdf.md)

## Problem

The login screen shows a disabled UTCC SSO affordance, while learners must
currently use local student-ID credentials. The system needs a university
identity path without creating duplicate academy accounts, assigning roles from
untrusted provider data, or removing a controlled local emergency path.

## Scope

### Included after the identity decision

- Add one approved provider adapter and its callback boundary.
- Validate the provider response before any account lookup or session creation.
- Bind a verified external `(issuer, subject)` to exactly one local user.
- Support the approved first-login/linking flow without email-only matching.
- Preserve local roles, progress, sessions, and emergency-access behavior.
- Provide safe failure, logout, unlink/recovery, and audit outcomes according to
  the accepted institutional policy.

### Excluded

- Supporting multiple providers in the first slice.
- Automatically assigning local roles from arbitrary provider groups.
- Importing a university roster, course enrollment, or student profile beyond
  the approved minimum identity claim.
- Logging or storing raw tokens, assertions, authorization codes, or provider
  profile payloads.
- Replacing the local authentication implementation or changing course progress.

## Invariants

1. A verified `(issuer, subject)` maps to at most one local `User`.
2. One local `User` cannot have two external identities that violate the
   accepted provider/linking policy.
3. An email address alone never links an external identity to a local account.
4. No session is created until issuer, audience, signature, expiry, state,
   nonce, and PKCE checks required by the chosen protocol pass.
5. Local role and authorization state remain authoritative unless an accepted
   mapping policy explicitly says otherwise.
6. A failed or replayed callback cannot create an account, link an identity, or
   reveal whether a local account exists.
7. SSO outages leave local emergency access available only under the accepted
   owner, rate-limit, session, and audit policy.
8. Tokens, assertions, codes, and raw provider payloads never reach logs,
   fixtures, audit records, or browser-visible errors.

## Acceptance Criteria

- [ ] The accepted provider metadata and callback URI are configured without
      secrets in the repository (`test/controllers/sso_callbacks_test.rb`).
- [ ] A valid provider callback signs in an already-linked user without creating
      a duplicate (`test/controllers/sso_callbacks_test.rb`).
- [ ] The approved first-login/linking flow binds the exact accepted identity
      claim and rejects email-only matches (`test/models/external_identity_test.rb`,
      `test/controllers/sso_linking_test.rb`).
- [ ] Invalid issuer, audience, signature, expiry, state, nonce, or PKCE input
      cannot create a session or link an account (`test/controllers/sso_callbacks_test.rb`).
- [ ] A concurrent first-login race preserves identity uniqueness and produces
      one local account (`test/models/external_identity_test.rb`).
- [ ] Provider failure returns a safe local-login fallback without account
      enumeration or sensitive logging (`test/controllers/sso_callbacks_test.rb`).
- [ ] Local role, progress, emergency-access, logout, unlink, and recovery rules
      follow the accepted policy (`test/controllers/sso_account_policy_test.rb`).
- [ ] A browser walkthrough covers linked login, first linking, provider failure,
      and local emergency sign-in (`test/system/sso_account_walk_test.rb`).

## Boundary cases and unresolved policy

- Missing or changed provider claims must fail closed and route to support rather
  than guess a link.
- A provider subject reused with a different issuer is a different external
  identity; issuer normalization must be explicitly defined.
- A local account with no approved link must not be silently replaced by a new
  account.
- A user must understand whether “log out” ends only the academy session or also
  the university provider session.
- The emergency path must define who can use it, how it is recovered, and what
  audit trail is retained.

## Human Identity Review Handoff

Implementation is intentionally held until the Product Owner, Tech Lead,
Security Owner, and UTCC identity owner record the following choices. The agent
can expose the trust boundaries and threat controls, but cannot select the
institution's provider contract or acceptable identity risk.

| Review point | Evidence | Decision required |
| --- | --- | --- |
| Provider protocol, issuer, metadata, client, and redirect URI | [ADR-0010 alternatives](../decisions/adr-0010-utcc-sso-account-linking.md#alternatives) | Provide the approved provider contract and protocol. |
| Stable identity claim and linking proof | [Proposed identity boundary](../decisions/adr-0010-utcc-sso-account-linking.md#proposed-boundary) | Choose the claim and self-service, staff-assisted, or provisioned linking flow. |
| Local emergency access | [Threat model controls](../decisions/adr-0010-utcc-sso-account-linking.md#threat-model-and-minimum-controls) | Name eligibility, owner, recovery, rate limits, session, and audit rules. |
| Roles and institutional claims | [Local authorization consequence](../decisions/adr-0010-utcc-sso-account-linking.md#consequences) | Confirm local roles remain authoritative and define any approved mapping. |
| Logout, unlink, recovery, and outage behavior | [Boundary cases](#boundary-cases-and-unresolved-policy) | Approve learner/support behavior for each failure and recovery path. |
| Privacy and operational ownership | [ADR-0010 human decisions](../decisions/adr-0010-utcc-sso-account-linking.md#human-decisions-required) | Name privacy, retention, data-residency, provider, and incident owners. |

After these choices are recorded, the spec owner should add the real enforcing
test paths to `enforced_by`, accept the invariant and acceptance-test intent,
and only then enable the SSO control.

## Rollback and observability

- Keep the SSO control disabled until provider configuration and callback tests
  pass; rollback removes the callback route and leaves local sign-in intact.
- Count callback successes, validation failures, duplicate-link attempts, and
  provider errors without logging identity tokens or student identifiers.
- Alerting and provider outage response require an accountable operator before
  production release.

## Verification

```bash
bin/docs
bin/rails test test/models/external_identity_test.rb test/controllers/sso_callbacks_test.rb
bin/rails test:system test/system/sso_account_walk_test.rb
bin/verify
```
