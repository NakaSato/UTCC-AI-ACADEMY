---
id: SPEC-0024
type: spec
title: Recruitment foundation organization membership and candidate profiles
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-11-05
supersedes: []
superseded_by: []
depends_on: [ADR-0024]
implemented_by:
  - app/models/organization.rb
  - app/models/organization_membership.rb
  - app/models/candidate_profile.rb
  - app/controllers/recruitment/organizations_controller.rb
  - app/controllers/recruitment/candidate_profiles_controller.rb
  - db/migrate/20260807090000_create_recruitment_foundation.rb
  - db/migrate/20260809140000_allow_company_reviewer_invitations.rb
  - test/models/organization_test.rb
  - test/models/organization_membership_test.rb
  - test/models/candidate_profile_test.rb
  - test/controllers/recruitment/organizations_controller_test.rb
  - test/controllers/recruitment/candidate_profiles_controller_test.rb
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
  - test/models/candidate_profile_test.rb
  - test/controllers/recruitment/organizations_controller_test.rb
  - test/controllers/recruitment/candidate_profiles_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-TEST-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-TEST-001]
---

# Recruitment Foundation: Organization Membership and Candidate Profiles

> [Executable Specifications](README.md) ·
> [ADR-0024 organization membership](../decisions/adr-0024-recruitment-organization-membership.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted by the user on 2026-08-08 for the first
> implementation slice. This specification does not accept the full AI
> Recruitment Platform roadmap.

## Problem

The repository has a working student identity, staff authorization, audit log,
storage, and notification foundation, but no organization boundary or
candidate-profile boundary for recruitment work. The first slice must establish
those seams without creating a parallel authentication system or exposing
candidate data to other users.

## Scope

### Included

- Admin-created organizations with a unique slug.
- One active organization owner and membership roles for recruiter,
  hiring-manager, mentor, and company-reviewer.
- Admin-only creation, member granting, and non-owner membership revocation.
- Organization index and detail views for administrators and active members.
- A private, student-owned candidate profile with headline, summary, preferred
  location, and visibility state.
- Server-side authorization, database constraints, audit events, and focused
  English/Thai interface copy.

### Excluded

- Company self-registration or email invitations.
- Job creation, publication, applications, interviews, offers, or matching.
- Public candidate search or employer access to candidate profile data.
- Resume uploads, parsing, skill extraction, or AI recommendations.
- New authentication providers or a global company role on User.
- Organization deletion, ownership transfer, or suspension workflows.
- REST API endpoints.

## Invariants

1. Every organization has a non-empty name, a unique normalized slug, and one
   creator.
2. An organization has at most one active owner; the database enforces this.
3. A user has at most one membership row per organization.
4. Membership role and status values are restricted to the accepted sets.
5. Only an administrator can create organizations, grant memberships, or revoke
   memberships in this slice.
6. An active member can read only organizations to which they belong; a
   non-member cannot infer the membership list through a direct URL.
7. The active owner cannot be revoked until ownership transfer is specified.
8. Every candidate profile belongs to exactly one student user and defaults to
   private visibility.
9. A candidate can read and mutate only their own profile; organization members
   cannot read candidate profiles in this slice.
10. Organization and membership writes are auditable with the acting user.

## Acceptance Criteria

- [x] An administrator can create an organization and assign one non-admin
      account as its owner (test/controllers/recruitment/organizations_controller_test.rb).
- [x] A student or instructor cannot create an organization or grant a
      membership (test/controllers/recruitment/organizations_controller_test.rb).
- [x] An administrator can grant recruiter, hiring-manager, mentor, or
      company-reviewer membership and can revoke a non-owner membership
      (test/controllers/recruitment/organizations_controller_test.rb,
      test/models/organization_membership_test.rb).
- [x] A duplicate membership and a second active owner are rejected by the
      model/database boundary (test/models/organization_membership_test.rb).
- [x] A member can view their organization, while a non-member receives a safe
      not-found response (test/controllers/recruitment/organizations_controller_test.rb).
- [x] A student can create and update a private candidate profile, and another
      authenticated user cannot read it (test/controllers/recruitment/candidate_profiles_controller_test.rb).
- [x] Candidate profile visibility cannot grant access through an organization
      route because no such route exists in this slice
      (test/controllers/recruitment/candidate_profiles_controller_test.rb).
- [x] Organization creation and membership changes produce audit events
      (test/controllers/recruitment/organizations_controller_test.rb).

## Error and Boundary Cases

- Blank names and slugs are rejected; a slug is derived from the name only when
  the submitted slug is blank.
- Duplicate slugs and memberships return validation errors without a partial
  organization or membership.
- An admin cannot assign an admin as a company member in this slice.
- Revoking an owner is rejected without changing membership state.
- A suspended or revoked membership cannot authorize an organization read.
- A candidate profile with invalid visibility or overlong content is rejected
  without changing the saved profile.
- No controller action accepts a user or role from the request as an
  authorization grant; persisted membership and current user identity decide.

## Verification

    bin/docs
    bin/rails test test/models/organization_test.rb test/models/organization_membership_test.rb test/models/candidate_profile_test.rb test/controllers/recruitment/organizations_controller_test.rb test/controllers/recruitment/candidate_profiles_controller_test.rb
    bin/verify
