---
id: ADR-0044
type: adr
title: Give each population its own navigation, front door, and company address
status: accepted
owners: ["@product-owner", "@tech-lead", "@recruitment-domain-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0042, ADR-0043, ADR-0024]
implemented_by:
  - SPEC-0044
touches:
  - app/models/user.rb
  - app/models/organization.rb
  - app/models/notification.rb
  - app/helpers/application_helper.rb
  - app/controllers/home_controller.rb
  - app/controllers/recruitment/organizations_controller.rb
  - app/views/shared/_app_header.html.erb
  - app/views/shared/_app_nav_menu.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/workspace_navigation_test.rb
  - test/controllers/company_profile_test.rb
  - test/models/organization_slug_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give Each Population Its Own Navigation, Front Door, and Company Address

> **Decision state:** Accepted by the user on 2026-08-09. One shell, four
> workspaces: `User#workspace` decides the navigation, the gamification strip,
> and where `/` lands. A company's profile moves to `/:slug` — `/northstar` —
> and organizations are addressed by name in every URL. Dashboard *content* per
> role is explicitly a later slice.

> [Decision Records](README.md) ·
> [Role-aware workspaces specification](../specs/spec-role-aware-workspaces.md) ·
> [Console sign-in decision](adr-0042-console-sign-in-boundary.md) ·
> [Recruitment organization membership](adr-0024-recruitment-organization-membership.md)

## Context

ADR-0042 and ADR-0043 gave staff and company members a door and an identity, and
then dropped them into a learner's app. One navigation served everyone —
Catalog, My Learning, Course, Lesson, Map, Progress, Ranking — with two extra
entries bolted on for staff, and `/` forked only for admins. A recruiter signing
in landed on a list of organizations under a header advertising coursework, over
a strip counting hearts they cannot lose.

The heart counter is the sharpest version of the problem. It was gated on
`student?`, which is *true* for a company member: company reach is an
organization membership and never a role (ADR-0024), so a recruiter holds the
default student role forever. Asking the role gave them a learner's app.

Their company's address had the same flavour. `/recruitment/organizations/7` is
an internal path with a row id in it, offered to the one population most likely
to want to link to the page from somewhere else.

## Problem frame

- **Affected user:** Instructors, administrators, and company members using an
  app whose chrome describes somebody else's job.
- **Current behavior:** One nav for four populations, a learner front door for
  three of them, and a row id where a company's name should be.
- **Failure risk:** Role checks scattered through views drift apart; a "separate
  UI" becomes four layouts to keep in step; a vanity URL at the root shadows
  real paths.
- **Success signal:** Each population sees a navigation of doors it can open,
  lands somewhere it can act, and a company can put its address on a poster.

## Decision boundary

The accepted policy is:

1. `User#workspace` returns one of `:admin`, `:instructor`, `:company`,
   `:student`, in that order of precedence. **Membership is asked before role**,
   because a company member holds the student role.
2. One shell, not four layouts. The header, the burger drawer, and the front
   door all read the workspace; the layout, the account menu, notifications, and
   the language toggle stay shared.
3. Each workspace has a navigation of doors it can actually open, matching the
   `allow_only` on each controller and the membership scoping inside the company
   screens. An entry nobody in that workspace can open is a bug, not a hint.
4. `/` lands on the workspace's own home: `/admin`, `/instructor`, the company's
   profile, or the catalog. A company member in more than one organization lands
   on the list, since they have a choice to make.
5. The gamification strip is keyed on the workspace, not on `student?`.
6. A company's profile is `/:slug`. The route is declared **last**, so every
   real path wins, and `Organization::RESERVED_SLUGS` forbids a name that a real
   path would shadow — a test keeps the list and the routes in step.
7. `Organization#to_param` is the slug, so the workspace routes behind the
   profile carry the name too. `Organization.from_param!` is the one lookup.
   The id-based profile URL still resolves and redirects to the name.
8. **Out of scope, deferred to its own slice:** dashboard *content*. No new
   summary screens, counts, or activity feeds. Each workspace lands on the best
   screen that already exists.

## Alternatives

### One shell, role-aware nav and home

The selected shape. One place to reason about chrome, one predicate to test, and
no screen has to opt in.

### A second "console" layout for staff, admin, and company

A cleaner visual split, and no risk to student screens. Rejected for now: two
layouts to keep in step, and every console view must opt in — a lot of surface
for a change whose substance is which links appear.

### Role checks inline in the header

What the code did. Cheapest to write and the reason a recruiter got a heart
counter: `student?` is not the question, and each new check gets it wrong
independently.

### Keep `/recruitment/organizations/:id`

No routing risk at all, but it hands a company an internal URL with a row id in
it, and a nav item pointing at a list rather than at them.

## Consequences

- `User#workspace` is now the single question the chrome asks. A fifth
  population means an entry there and a nav list, not a hunt through views.
- An instructor's nav is two items. That is honestly what an instructor has
  today; padding it would mean linking them to somebody else's coursework.
- A slug is now a public URL. Renaming an organization does not move it — the
  slug is set once at creation — but adding a top-level route means adding to
  `RESERVED_SLUGS`, and the test says so out loud.
- Organization ids are gone from URLs. Anything that stored one to rebuild a URL
  later had to store the slug instead; the internship-request notification did,
  and resolves old rows by id for as long as they exist.
- The company front door is a profile, not a dashboard. Until the next slice it
  is a members-and-details page, which is a truthful landing but not a summary.

## Fitness Functions

- Each of the four workspaces gets its own navigation, and the burger drawer
  never disagrees with the rail.
- A company member sees no coursework entry and no heart counter, despite
  holding the student role; revoking the membership returns them to the learner
  app entirely.
- `/` lands each workspace on its own home.
- Every top-level route segment that a valid slug could shadow is reserved, and
  an organization cannot be created with a reserved name.
- A company profile is reachable at its name, and the id-based URL redirects
  there rather than serving a second copy.
