---
id: ADR-0044
type: adr
title: Give each population its own navigation, front door, and company address
status: accepted
owners: ["@product-owner", "@tech-lead", "@recruitment-domain-owner"]
created: 2026-08-09
updated: 2026-08-13
review_by: 2026-11-07
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
> and where `/` lands. A company's screens move under `/company/:slug` and
> organizations are addressed by name in every URL. Dashboard *content* per
> role is explicitly a later slice.
>
> **Amended 2026-08-13:** the navigation is one dropdown at every width. The
> rail-plus-drawer pair it shipped with is gone — see point 2 and the
> consequences.
>
> **Amended 2026-08-09, same day:** the profile was briefly at the bare root
> (`/northstar`) before the `/company` prefix replaced it — see the alternative
> below. `Organization::RESERVED_SLUGS`, which that shape required, is gone.

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
  UI" becomes four layouts to keep in step; a company address collides with a
  real path.
- **Success signal:** Each population sees a navigation of doors it can open,
  lands somewhere it can act, and a company can put its address on a poster.

## Decision boundary

The accepted policy is:

1. `User#workspace` returns one of `:admin`, `:instructor`, `:company`,
   `:student`, in that order of precedence. **Membership is asked before role**,
   because a company member holds the student role.
2. One shell, not four layouts. The header, its navigation menu, and the front
   door all read the workspace; the layout, the account menu, notifications, and
   the language toggle stay shared.
3. Each workspace has a navigation of doors it can actually open, matching the
   `allow_only` on each controller and the membership scoping inside the company
   screens. An entry nobody in that workspace can open is a bug, not a hint.
4. `/` lands on the workspace's own home: `/admin`, `/instructor`, the company's
   profile, or the catalog. A company member in more than one organization lands
   on the list, since they have a choice to make.
5. The gamification strip is keyed on the workspace, not on `student?`.
6. A company lives under `/company/:slug` — the profile and everything scoped
   to it, including the screens whose controllers sit outside the recruitment
   module. The prefix is what keeps company names out of the root namespace, so
   no reserved-name list is needed and a company called "admin" is simply
   `/company/admin`.
7. `Organization#to_param` is the slug and `Organization.from_param!` is the one
   lookup, so no organization row id appears in any URL. `/recruitment` keeps
   only the candidate's half — jobs, applications, candidate profile — which is
   a section a student browses rather than an internal namespace leaking out.
8. **Out of scope, deferred to its own slice:** dashboard *content*. No new
   summary screens, counts, or activity feeds. Each workspace lands on the best
   screen that already exists.

   **Taken up for one workspace on 2026-08-12 by [ADR-0048](adr-0048-company-work-surface.md).**
   The company workspace gained a work surface at `/company/:slug/work` and `/`
   now lands a company member there rather than on the company's record, which
   amends point 4 for that workspace only. The admin, instructor, and student
   landings are unchanged, and summary content for them stays deferred.

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
it, spells out a code-level namespace, and points a nav item at a list rather
than at them.

### A company profile at the bare root, `/northstar`

Shortest possible address, and the first shape this took. Abandoned within the
day: it puts every company name in the same namespace as every route, so the
route has to be declared last and a reserved-name list has to be kept in step
with the router forever — a standing tax, and a silently unreachable profile
whenever someone forgets. The `/company` prefix costs eight characters and
removes the whole problem.

## Consequences

- `User#workspace` is now the single question the chrome asks. A fifth
  population means an entry there and a nav list, not a hunt through views.
- An instructor's nav is two items. That is honestly what an instructor has
  today; padding it would mean linking them to somebody else's coursework.
- A slug is now a public URL. Renaming an organization does not move it — the
  slug is set once at creation — and because the profile sits under `/company`,
  adding a top-level route can never collide with a company name.
- Organization ids are gone from URLs. Anything that stored one to rebuild a URL
  later had to store the slug instead; the internship-request notification did,
  and resolves old rows by id for as long as they exist.
- The company front door is a profile, not a dashboard. Until the next slice it
  is a members-and-details page, which is a truthful landing but not a summary.

## Fitness Functions

- Each of the four workspaces gets its own navigation, rendered once in the
  header dropdown. (Until 2026-08-13 it was rendered twice — a rail above
  1180px and a drawer below — and the fitness function was that the two agreed.
  One list in one place is the stronger version of that guarantee.)
- A company member sees no coursework entry and no heart counter, despite
  holding the student role; revoking the membership returns them to the learner
  app entirely.
- `/` lands each workspace on its own home.
- A company named after a route — "admin", "login" — is reachable at
  `/company/admin` and shadows nothing.
- A company profile and everything scoped to it share one prefix, and no
  organization row id appears in any URL.
