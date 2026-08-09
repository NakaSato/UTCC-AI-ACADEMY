---
id: ADR-0025
type: adr
title: Use secure in-app invitations for registered recruitment staff
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0024]
implemented_by:
  - SPEC-0025
  - app/models/organization_invitation.rb
  - app/controllers/recruitment/organization_invitations_controller.rb
  - db/migrate/20260807100000_create_organization_invitations.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - db/migrate
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
enforced_by:
  - test/models/organization_invitation_test.rb
  - test/controllers/recruitment/organization_invitations_controller_test.rb
agent_writable: true
---

# Use Secure In-App Invitations for Registered Recruitment Staff

> [Decision Records](README.md) ·
> [Recruitment invitation specification](../specs/spec-recruitment-invitations.md) ·
> [Organization membership ADR](adr-0024-recruitment-organization-membership.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for the registered-user
> in-app invitation boundary, including intended-invitee privacy, one-time
> state transitions, membership creation, token redaction, and audit behavior.

## Context

The organization foundation can create memberships administratively, but the
roadmap requires a company to invite permitted staff. Existing accounts do not
necessarily have an email address, and the repository has not selected a
production transactional-email provider. The next slice therefore needs a
useful invitation workflow without creating a second identity or an unreviewed
email-delivery dependency.

## Decision

- Invitations target existing registered non-admin users by account identity.
- An active organization owner or administrator may create an invitation for a
  recruiter, hiring manager, mentor, or company reviewer role — the membership
  roles minus ownership, which is never invitable.
- Each invitation has an opaque, expiring token, is delivered through the
  existing in-app notification bell, and is visible only to the intended user.
- The intended user may accept or decline once. Accepting creates the scoped
  organization membership atomically; declining does not create access.
- A pending invitation for the same organization and user is unique at the
  database level.
- Administrators retain the direct membership grant/revoke controls from the
  foundation slice.
- Email delivery, external users, ownership transfer, and job-posting remain
  outside this increment.

## Alternatives

### Send invitations by email

Deferred. Email is useful for external company staff, but the repository has no
production provider decision and many existing accounts have no email address.
The invitation record can later gain an email-delivery adapter without changing
the membership boundary.

### Let any organization member invite staff

Rejected for this slice. Recruiter, hiring-manager, and mentor authority is
not yet differentiated enough to grant access safely. Ownership is the narrow
company-side authority until a permission matrix is approved.

### Reuse direct membership grants

Insufficient. A direct grant cannot express user consent, expiration, or a
safe pending state before access is created.

## Consequences

- The first invitation experience is in-app and limited to users who already
  have accounts.
- Invitation tokens are not recoverable from a digest if a notification is
  lost; the user must receive a new invitation after expiry or revocation is
  specified.
- Membership creation and invitation state changes are auditable.
- A later email or external-identity design must preserve the same intended
  user and organization authorization checks.

## Fitness Functions

- A token is stored only as a digest and cannot be used by a different user.
- Expired, declined, accepted, and revoked invitations cannot create access.
- An organization/user pair has at most one pending invitation.
- Accepting an invitation creates at most one membership, even under a retry.
- `bin/docs` and focused invitation model/controller tests pass.
