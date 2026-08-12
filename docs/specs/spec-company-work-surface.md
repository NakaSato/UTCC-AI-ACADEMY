---
id: SPEC-0048
type: spec
title: The company work surface at /company/:slug/work
status: accepted
owners: ["@product-owner", "@tech-lead", "@recruitment-domain-owner", "@privacy-owner", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0048, ADR-0044, ADR-0041, ADR-0040, ADR-0037, SPEC-0044, SPEC-0041, SPEC-0037]
implemented_by:
  - app/services/recruitment/company_dashboard.rb
  - app/controllers/recruitment/company_work_controller.rb
  - app/controllers/application_controller.rb
  - app/controllers/console_sessions_controller.rb
  - app/controllers/home_controller.rb
  - app/helpers/application_helper.rb
  - app/views/recruitment/company_work/show.html.erb
  - config/routes.rb
touches:
  - app/controllers
  - app/services
  - app/views
  - app/helpers
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/company_work_test.rb
  - test/services/recruitment/company_dashboard_test.rb
  - test/controllers/workspace_navigation_test.rb
  - test/controllers/console_sessions_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-PROD-001]
min_reviewer_skills: [SKILL-SPEC-002]
---

# The Company Work Surface at /company/:slug/work

> [Specifications](README.md) ·
> [Company work surface decision](../decisions/adr-0048-company-work-surface.md) ·
> [Role-aware workspaces specification](spec-role-aware-workspaces.md) ·
> [Student internship requests specification](spec-student-internship-requests.md) ·
> [Recruitment reporting specification](spec-recruitment-reporting.md)

## Problem

A company member signs in and lands on their company's record: a members table,
its pending invitations, and three links. Meanwhile students wait — on a
decision about an internship request, on an acknowledgement of the week they
just wrote up — and nothing on the screen says so. Finding out means opening
each queue and counting.

`Recruitment::CompanyDashboard` was written for this and left unwired: no route,
no view, no test, no specification. Its queue counts returned zero for any member
outside the decider roles, which is the opposite of the rule ADR-0048 records.

## Invariants

1. `/company/:slug/work` renders the work surface for one organization. The slug
   root `/company/:slug` is unchanged and keeps the members table, invitations,
   and links.
2. `/` lands a company member on the work surface of their single active
   organization, and on the organization list when they have more than one.
   Every other workspace's landing is untouched.
2a. `/console` sign-in lands a company member in the same place, through the
   same `ApplicationController#company_home_path`. Two doors reach this
   workspace and they must not disagree; the console door was the one that
   still handed a member of one company a list of one.
3. The surface is visible to any active member of the organization and to an
   administrator. A signed-in user who is neither gets the same
   `ActiveRecord::RecordNotFound` the company's other screens give them.
4. An organization that is not active has no work surface.
5. Every figure on the screen is a count with a link to the queue it counts.
   No student name, no request or report text, and no row-level record appears.
6. The three internship figures — requests awaiting a company decision, submitted
   progress reports with no acknowledgement, and open placements — are the same
   for every active member. Acting on any of them is authorized where it is
   authorized today, by the controller that owns the action.
7. Candidate application figures come from `Recruitment::OrganizationReporting`
   and from nowhere else, so the reporter-role gate and the five-row suppression
   of SPEC-0037 apply unchanged. A member outside the reporter roles sees the
   rest of the surface and no application figures at all.
8. The business-case figures are counts of the organization's own published
   cases, their open milestones, and the submissions made to them. They are not
   a queue: no review or acknowledgement state exists on a submission, and the
   screen does not imply one.
9. Both locales carry the whole screen. No English string is rendered to a Thai
   reader.

## Acceptance Criteria

1. An active member of one organization visiting `/` arrives at
   `/company/<slug>/work`.
2. An active member of two organizations visiting `/` arrives at the
   organization list, as before.
3. A member of organization A requesting organization B's work surface is
   refused with 404, whether or not B is active.
4. An administrator may open any active organization's work surface.
5. With three requests in `submitted` or `under_review`, the requests figure
   reads three and links to that organization's internship request queue.
6. A `mentor` — outside `InternshipRequest::DECIDER_ROLES` — sees the same three
   internship figures as an owner does.
7. A member outside `Recruitment::JobPost::AUTHOR_ROLES` sees no application
   figures, and the page still renders.
8. With four applications against the organization's job posts, the application
   figures are suppressed, because SPEC-0037's minimum cell size is five.
9. Submitted progress reports that have been acknowledged are not counted.
10. A member whose company has nothing waiting sees an explicit empty state, not
    a row of zeroes.
11. The company navigation's first entry leads to the work surface.
12. A company member signing in at `/console` lands on the work surface when
    they belong to one active organization, and on the chooser when they belong
    to two.

## Verification

- `test/controllers/company_work_test.rb` covers criteria 1 through 4, 7, 10,
  and 11: the landing redirect for one and for two organizations, the refusal
  across organizations, the admin case, the reporter gate, and the empty state.
- `test/services/recruitment/company_dashboard_test.rb` covers criteria 5, 6, 8,
  and 9 against the service: the counts themselves, a mentor seeing them, the
  suppression inherited from `OrganizationReporting`, and acknowledged reports
  dropping out.
- `test/controllers/workspace_navigation_test.rb` continues to cover where each
  workspace lands and what its navigation offers.
- `test/controllers/console_sessions_controller_test.rb` covers criterion 12:
  the console door's destination for a member of one company and of two.
- `bin/verify` runs the whole gate.

## Out of scope

- Summary content for the admin, instructor, and student workspaces. ADR-0048
  decision 1 keeps all three unchanged.
- Faculty and administrator visibility of internship work, which ADR-0041
  decisions 2 and 7 still gate.
- Row-level detail on the surface — names, request text, report text. The queue
  screens own that, along with the scoping that decides who reads it.
- Caching or background computation of the counts. They are indexed counts
  against one organization; if the page becomes hot, that is the moment to
  measure it.
- Notifications or digests derived from these counts. The bell already notifies
  on the events that create the work.
