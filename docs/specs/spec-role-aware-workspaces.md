---
id: SPEC-0044
type: spec
title: Role-aware navigation, front doors, and company profile addresses
status: accepted
owners: ["@product-owner", "@tech-lead", "@recruitment-domain-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0044, ADR-0042, ADR-0043, ADR-0024, SPEC-0042, SPEC-0043]
implemented_by:
  - app/models/user.rb
  - app/models/organization.rb
  - app/helpers/application_helper.rb
  - app/controllers/home_controller.rb
  - app/controllers/recruitment/organizations_controller.rb
  - app/views/shared/_app_header.html.erb
  - config/routes.rb
touches:
  - app/controllers
  - app/models
  - app/helpers
  - app/views/shared
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/workspace_navigation_test.rb
  - test/controllers/company_profile_test.rb
  - test/models/organization_slug_test.rb
  - test/models/user_test.rb
  - test/controllers/app_header_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-PROD-001]
min_reviewer_skills: [SKILL-SPEC-002]
---

# Role-Aware Navigation, Front Doors, and Company Profile Addresses

> [Specifications](README.md) ·
> [Role-aware workspaces decision](../decisions/adr-0044-role-aware-workspaces.md) ·
> [Console sign-in specification](spec-console-sign-in.md)

## Problem

Four populations share one Rails app and shared one navigation. A recruiter
browsed the recruitment screens under a header offering Catalog, Lesson, Map and
Ranking, over a strip counting hearts, and reached their company at
`/recruitment/organizations/7`. The heart counter was gated on `student?` —
which is true for a company member, because company reach is a membership and
never a role — so asking the role handed them a learner's app.

## Invariants

1. `User#workspace` returns `:admin`, `:instructor`, `:company`, or `:student`,
   resolved in that order. Membership is checked **before** role.
2. `app_nav_items` returns one list per workspace. The desktop rail and the
   burger drawer render the same list.
3. Every navigation entry is a screen that workspace can open: an instructor's
   entries pass `allow_only :staff`, an admin's pass `allow_only :admin`, and a
   company member's are membership-scoped inside their controllers.
4. `/` renders the catalog for `:student` and redirects `:admin` to `/admin`,
   `:instructor` to `/instructor`, and `:company` to their company's profile —
   or to the organizations list when they belong to more than one.
5. The hearts counter and the refill timer render only for `:student`.
6. `GET /company/:slug` serves a company profile, and every screen scoped to a
   company sits under the same prefix — including the internship-request queue
   and settings, whose controllers live outside the recruitment module.
7. Because company names sit under `/company`, no reserved-name list exists: a
   company called "admin" is `/company/admin` and shadows nothing.
8. `Organization#to_param` is the slug and `Organization.from_param!` is how a
   controller resolves one, so no organization row id appears in any URL.
9. `/recruitment` keeps the candidate's half only — jobs, applications, and the
   candidate profile.
10. Profile visibility is unchanged by the address: members and admins only.
11. Anything that stores an organization reference in order to rebuild a URL
    later stores the slug; rows written before this resolve their stored id.
12. The screen is bilingual: every navigation label exists in both locale files.

## Acceptance Criteria

- A student's nav includes Catalog and Map and excludes Instructor and
  Organizations.
- An instructor's nav is exactly Instructor and Academic writing.
- An admin's nav is exactly Admin and Organizations — `/instructor` reports on
  a section an admin does not teach, though the route still admits them.
- A company member's nav is exactly Organizations, Business cases, and
  Internships, and includes no coursework entry.
- The burger drawer renders the same labels as the rail.
- A company member sees no hearts counter, despite `student?` being true.
- Revoking the only membership returns that account to the learner navigation.
- `/` lands a student on the catalog, an instructor on `/instructor`, an admin
  on `/admin`, and a single-organization company member on `/company/:slug`.
- A member opens their company at `/company/north-star`; `company_path` builds
  the name, not the row id.
- A non-member and an unknown name both get 404; a signed-out visitor is sent to
  the front door.
- `/admin`, `/map`, and `/login` still reach their own screens.
- An organization named "Admin" is created and reachable at `/company/admin`.
- Nested workspace paths carry the slug and the same prefix — including
  `/company/:slug/internship`.

## Verification

- `test/controllers/workspace_navigation_test.rb` covers all four navigations,
  the drawer, the four front doors, the hearts strip, and the revoked member.
- `test/controllers/company_profile_test.rb` covers the company address, its
  visibility, that real paths are not shadowed, and the nested URLs.
- `test/models/organization_slug_test.rb` covers slug derivation, `to_param`,
  `from_param!`, and that a route-shaped name is fine under the prefix.
- `test/models/user_test.rb` covers `workspace` precedence, including an
  instructor who is also a company member.
- `test/controllers/app_header_test.rb` continues to cover the strip for staff.
- `bin/verify` runs the whole gate.

## Out of scope

Dashboard **content** per role — summary cards, counts, pipelines, recent
activity — is deliberately not in this slice (ADR-0044, point 8). Each workspace
lands on the best screen that already exists today. The company front door is a
profile, not a summary, until that slice is specified.
