---
id: ADR-0024
type: adr
title: Use organization memberships for recruitment company access
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: []
implemented_by:
  - SPEC-0024
  - app/models/organization.rb
  - app/models/organization_membership.rb
  - db/migrate/20260807090000_create_recruitment_foundation.rb
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
  - test/models/organization_test.rb
  - test/models/organization_membership_test.rb
  - test/controllers/recruitment/organizations_controller_test.rb
agent_writable: true
---

# Use Organization Memberships for Recruitment Company Access

> [Decision Records](README.md) ·
> [Recruitment foundation specification](../specs/spec-recruitment-foundation-organization-profiles.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for the first
> recruitment implementation slice: organization memberships, scoped access,
> candidate-profile privacy, and audit boundaries.

## Context

The existing application has one User identity with student, instructor, and
admin roles. The AI Recruitment Platform needs company users, organization
boundaries, and role-specific access, but it must not create a second
authentication system or make a global company role responsible for tenant
membership.

The first slice must also remain compatible with the existing student identity
and the current audit, session, storage, and notification boundaries.

## Decision

- A recruitment company is represented by an Organization.
- Access is represented by OrganizationMembership rows joining an existing User
  to an organization.
- Membership roles are owner, recruiter, hiring_manager, and mentor.
- The first slice lets an existing administrator create an organization,
  assign its owner, grant a member role, and revoke a non-owner membership.
- A user can belong to multiple organizations without changing the global User
  role.
- Candidate profiles belong to an existing student User, default to private,
  and are readable and writable only by that candidate in this slice.
- Organization and membership writes create audit events.

## Alternatives

### Add a global company role to User

Rejected for the first slice. It cannot express a user belonging to multiple
companies or having different responsibilities in each company.

### Create a separate company authentication system

Rejected. It would duplicate password, session, recovery, audit, and security
boundaries before the recruitment domain has validated its user model.

### Store organization and role fields directly on User

Rejected. It would prevent multi-organization membership and make future
recruiter, hiring-manager, and mentor permissions difficult to evolve.

## Consequences

- Company invitations, tenant administration, and external identity linking
  remain follow-up work.
- The existing student, instructor, and admin roles remain unchanged.
- Business-case and recruitment submissions must not reuse course submission
  records without a separate data-model decision.
- The organization owner is protected from revocation until ownership transfer
  is specified.

## Fitness Functions

- An organization has at most one active owner at the database level.
- A user has at most one membership row per organization.
- A non-member cannot read an organization's membership list.
- A candidate profile has exactly one owner and cannot be read through an
  organization route in the first slice.
- bin/docs and focused recruitment model/controller tests pass.
