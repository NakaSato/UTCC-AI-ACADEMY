---
id: SPEC-0025
type: spec
title: Recruitment organization invitations for registered users
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0025, SPEC-0024]
implemented_by:
  - app/models/organization_invitation.rb
  - app/controllers/recruitment/organization_invitations_controller.rb
  - app/models/notification.rb
  - db/migrate/20260807100000_create_organization_invitations.rb
  - test/models/organization_invitation_test.rb
  - test/controllers/recruitment/organization_invitations_controller_test.rb
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
---

# Recruitment Organization Invitations for Registered Users

> [Executable Specifications](README.md) ·
> [Invitation ADR](../decisions/adr-0025-recruitment-in-app-invitations.md) ·
> [Organization membership ADR](../decisions/adr-0024-recruitment-organization-membership.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted by the user on 2026-08-08 for the first invitation
> slice. This spec covers registered-user invitations only; it does not accept
> external company onboarding or email delivery.

## Problem

The recruitment foundation can create organization memberships, but company
owners need a consent-preserving way to request access for existing staff. The
workflow must not expose organization data to an invitee before acceptance or
allow a copied invitation token to be redeemed by another account.

## Scope

### Included

- Organization invitations for existing registered non-admin users.
- Recruiter, hiring-manager, and mentor invitation roles.
- Owner/admin invitation creation with an expiring opaque token.
- In-app notification with a link to the invitation.
- Invitee-only invitation view, accept, and decline actions.
- Atomic membership creation on acceptance.
- Pending-invitation uniqueness, audit events, English/Thai copy, and tests.

### Excluded

- Email delivery, external users, company self-registration, and identity
  linking.
- Inviting administrators or transferring organization ownership.
- Editing, revoking, or resending invitations before a separate policy exists.
- Job posts, applications, public candidate search, resumes, or AI features.

## Invariants

1. An invitation belongs to one organization, inviter, and existing invitee.
2. The inviter is an administrator or active owner of the organization.
3. The invitee is not an administrator and cannot be the inviter.
4. Invitation roles are limited to recruiter, hiring-manager, mentor, and
   company-reviewer — every membership role except ownership.
5. Only one pending invitation exists for an organization/invitee pair; the
   database enforces this for concurrent requests.
6. The token is stored only as a digest, is generated at creation, and expires
   after seven days.
7. Only the intended authenticated invitee can read or mutate an invitation.
8. An invitation can transition from pending to accepted or declined once;
   expired invitations cannot transition.
9. Acceptance creates one active membership atomically and is idempotent when
   the membership already exists with the invited role.
10. Declining never creates or changes an organization membership.
11. Invitation creation, acceptance, and decline produce audit events with the
    actor and organization context; token values are never audited.

## Acceptance Criteria

- [x] An active organization owner can invite an existing non-admin user with a
      permitted role and the invitee receives an in-app notification
      (`test/controllers/recruitment/organization_invitations_controller_test.rb`).
- [x] A non-owner member cannot create an invitation, and an administrator can
      create one (`test/controllers/recruitment/organization_invitations_controller_test.rb`).
- [x] An invitation is visible and actionable only to its intended invitee
      (`test/controllers/recruitment/organization_invitations_controller_test.rb`).
- [x] The invitee can accept once and receives an organization membership with
      the invited role (`test/controllers/recruitment/organization_invitations_controller_test.rb`).
- [x] The invitee can decline once without receiving organization access
      (`test/controllers/recruitment/organization_invitations_controller_test.rb`).
- [x] Duplicate pending invitations, invalid roles, administrator invitees,
      self-invitations, and expired tokens are rejected
      (`test/models/organization_invitation_test.rb`).
- [x] Invitation state transitions and membership creation are auditable, and
      token values do not appear in audit parameters
      (`test/controllers/recruitment/organization_invitations_controller_test.rb`).

## Error and Boundary Cases

- A suspended organization cannot create or accept invitations.
- A revoked or inactive owner cannot create invitations.
- A pending invitation cannot be duplicated, including by concurrent inserts.
- A user who already has an active membership cannot be invited again.
- A wrong authenticated user receives not-found rather than confirmation that
  an invitation exists.
- A missing, expired, declined, accepted, or revoked token is unavailable.
- A notification may be disabled by the existing feature flag; invitation
  persistence and authorization remain correct regardless.
- No invitation endpoint accepts an actor or organization from the request to
  establish authorization; current session and persisted membership decide.

## Verification

    bin/docs
    bin/rails test test/models/organization_invitation_test.rb test/controllers/recruitment/organization_invitations_controller_test.rb
    bin/verify
