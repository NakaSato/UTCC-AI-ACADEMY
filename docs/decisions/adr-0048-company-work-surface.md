---
id: ADR-0048
type: adr
title: Give a company a work surface, and leave the other three workspaces alone
status: accepted
owners: ["@product-owner", "@tech-lead", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0044, ADR-0041, ADR-0040, ADR-0037, ADR-0024]
implemented_by:
  - SPEC-0048
touches:
  - app/services/recruitment/company_dashboard.rb
  - app/controllers/recruitment/company_work_controller.rb
  - app/controllers/application_controller.rb
  - app/controllers/console_sessions_controller.rb
  - app/controllers/home_controller.rb
  - app/helpers/application_helper.rb
  - app/views/recruitment/company_work/show.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/company_work_test.rb
  - test/services/recruitment/company_dashboard_test.rb
  - test/controllers/workspace_navigation_test.rb
  - test/controllers/console_sessions_controller_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give a Company a Work Surface, and Leave the Other Three Workspaces Alone

> **Decision state:** Accepted by the user on 2026-08-12. This is the slice
> ADR-0044 point 8 deferred. It is one workspace, not four: a company member
> lands on the work waiting for them at `/company/:slug/work`, and the slug root
> stays the company's record. Every active member sees the whole board; the
> governed candidate figures keep the gate ADR-0037 put on them.

> [Decision Records](README.md) ·
> [Company work surface specification](../specs/spec-company-work-surface.md) ·
> [Role-aware workspaces decision](adr-0044-role-aware-workspaces.md) ·
> [Student internship request boundary](adr-0041-student-internship-request-boundary.md) ·
> [Privacy-safe recruitment reporting](adr-0037-privacy-safe-recruitment-reporting.md)

## Context

ADR-0044 split the navigation by workspace and deferred dashboard *content* to
its own slice, on the grounds that each workspace lands on the best screen that
already exists. Three of them genuinely do. `/admin` carries live metrics, an
approval queue, and the course catalog controls (M7-001 through M7-004);
`/instructor` carries the section's grade report and its lesson-integrity
switches; a student lands on the course catalog, which is what a learner came
for.

The company workspace is the one where that sentence was doing work it could not
support. A company member lands on `/company/:slug`: a members table with revoke
buttons, three links, and a pending-invitations list. It describes the company's
record. It says nothing about the students waiting on that company, which by now
is real inventory — an internship request queue, placements with a lifecycle,
weekly progress reports needing acknowledgement, business-case submissions, and
job applications. Every one of those has a screen. None of them has a number
anywhere a member would see it before opening the screen and counting.

`Recruitment::CompanyDashboard` was written during that slice and never wired to
anything: no route, no view, no test, and no specification names it. It has been
dead code since 2026-08-09.

## Problem frame

- **Affected user:** Company members — owners, recruiters, hiring managers,
  mentors, and company reviewers — and, second-hand, the students waiting on
  them.
- **Current behavior:** Signing in lands on the company's record. Work waiting
  on the company is discoverable only by opening each queue and looking.
- **Failure risk:** A dashboard becomes a place where counts about *people*
  accumulate without the governance the reporting screens already have; or four
  workspaces get invented content nobody asked for.
- **Success signal:** A member signs in and sees, without navigating, whether
  anyone is waiting on them — and every number on the screen is a queue they can
  open.

## Decision boundary

The accepted policy is:

1. **One workspace, not four.** Only the company workspace gains a surface.
   `/admin`, `/instructor`, and the catalog are unchanged; no summary content is
   invented for them in this slice.
2. **The work surface is its own screen at `/company/:slug/work`,** and `/`
   lands a company member there. The slug root keeps its present job — members,
   invitations, settings, and links — so each page answers one question. A
   member of more than one active organization still lands on the list, because
   they have a choice to make (ADR-0044 point 4 is otherwise unchanged).
   **`/console` lands them in the same place**, through one method both doors
   read: the console is where a company member actually signs in, and it had its
   own destination list that would otherwise have kept sending them to the
   record. Two front doors that disagree about where the front is are worse than
   either answer.
3. **It shows four things,** all of them already shipped and queryable:
   internship requests awaiting a decision, submitted progress reports nobody
   has acknowledged, open placements, and the company's business-case
   submissions and job applications.
4. **Every active member sees the same board.** Acting on an item is refused or
   allowed exactly where it is refused or allowed today — by the controller that
   owns the action. The surface adds no second authorization model, and a member
   who cannot decide a request still learns that a student is waiting.
5. **ADR-0037 is not relaxed.** Aggregate figures about candidates keep their
   reporter-role gate and their five-row suppression, because the surface asks
   `OrganizationReporting` for them rather than counting applications itself. A
   member outside the reporter roles sees the internship board and no
   application statistics.
6. **Counts only, with a link.** No row-level student data, no names, no free
   text from a request or a report. The screen says how many and where; the
   queue screens, which already scope what they show, say who.
7. **An inactive organization has no work surface.** It is not reachable, the
   same way its other screens are not.

   **Amended 2026-08-12.** That second sentence was not true when it was
   written. The work surface and the reporting page both refused a suspended
   company; `/company/:slug` — its record — served a member normally, so this
   screen was the strictest rather than one of a set. The record screen now
   refuses a member too, which is what makes the sentence describe the system.

   Administrators are the deliberate exception, and `index` on the same
   controller already drew it: they see every organization while a member sees
   only active ones. It is not deference. `/admin` lists only active
   organizations and every membership action on the record screen redirects
   back to it, so refusing administrators as well would leave a suspended
   company with no screen anywhere that could manage it. An administrator
   therefore reaches the record and still does not reach the work surface —
   one screen manages a company, the other reports what is waiting on it, and
   there is nothing waiting on a company that is not operating.

## Alternatives

### A work section added to `/company/:slug`

No new route and no redirect change. Rejected: the members table and the day's
work are two unrelated jobs, and the page that already grew three link buttons
is the wrong place to settle the argument. A separate screen also lets `/` land
on work rather than on administration.

### Role-scoped content — each member sees only what they can act on

Truer to the five membership roles, and what the dead `CompanyDashboard` did:
its queue counts returned zero for a non-decider. Rejected as the default. It
puts a second authorization model beside the one every action already enforces,
and the failure it prevents is mild — a mentor learning that three students are
waiting on somebody else at their company — while the failure it causes is not:
a member sees an empty board and concludes there is no work. The candidate
figures are the exception, and they keep their gate.

### Dashboards for all four workspaces in one slice

Rejected as rework. Three workspaces already land on screens built for them; the
slice would mostly be redecorating them, and would bury the one real gap.

### Activity feed rather than queues

An event stream reads as busier and answers "what happened" well. Rejected: the
question a company member arrives with is "is anyone waiting on me", and a feed
answers that only by accident. Queues also have a natural empty state — nobody
is waiting — which a feed does not.

## Consequences

- A figure a reader cannot act on is still shown to them and is no longer
  linked. Decision 4 puts the whole board in front of every active member, and
  SPEC-0041 gives the internship request queue to deciders alone — so a mentor
  and an administrator were each handed a card leading to a 404 on a screen they
  are meant to be on. Corrected 2026-08-13: the count stays, the link is
  rendered only for a reader who may open where it points.

- A company member's front door changes. `/company/:slug` is still one click
  away and keeps its address, so any link to it is unaffected.
- `Recruitment::CompanyDashboard` stops being dead code, loses its
  decider-role gate on the three internship queues (decision 4), and gains the
  business-case submission count. Its delegation to `OrganizationReporting`
  stays exactly as written — that is decision 5's whole mechanism.
- Four counts run on each page load. They are indexed foreign-key counts against
  one organization, and the screen is not on a hot path; if that stops being
  true, the fix is caching, not fewer numbers.

  **Corrected 2026-08-12.** Four was never the number. The four are the
  dashboard's own; beneath them `OrganizationReporting` counted once per status
  across vocabularies of six and seven, and `postings` asked each relation twice.
  Measured, the screen cost 20 queries with the application figures suppressed
  and 27 without. It is 13 now, on both paths, because the counts are grouped —
  which is neither of the two options this paragraph offered, since every number
  on the board survived. The prediction that the remedy would be caching was
  wrong in the same way the count was: it assumed the cost came from how many
  numbers the screen asks for rather than from how it asks for them. A budget in
  `test/models/query_budget_test.rb` now holds the ceiling, so the next answer to
  this question is measured rather than estimated.
- The screen is bilingual, like every other. Both locale files gain one section.

## Fitness Functions

- `test/controllers/company_work_test.rb` — where `/` lands a member of one and
  of two companies, the refusal across companies and for a suspended one, the
  admin case, the absence of application figures for a non-reporter, the empty
  state, and that no student name or request text reaches the page.
- `test/services/recruitment/company_dashboard_test.rb` — the counts themselves,
  a mentor seeing the same internship figures as an owner, the five-row
  suppression inherited from `OrganizationReporting`, and acknowledged reports
  leaving the queue.
- `test/controllers/workspace_navigation_test.rb` — the four workspaces still
  land where they should and the company navigation leads with Work.
- `test/controllers/console_sessions_controller_test.rb` — the console door
  agrees with `/` for a member of one company and for a member of two.
- `bin/verify` runs the whole gate.

## Human decisions still required

None for this slice. Two adjacent questions stay open and are **not** answered
here:

- Whether the other three workspaces ever get summary content, and what it
  would be. Deferred with no owner assigned.
- Whether faculty or administrators see any of this. ADR-0041 decisions 2 and 7
  still gate that, and this surface is company-only until they are recorded.

## Decision owner

Product Owner, with Tech Lead, Recruitment domain owner, and Privacy owner.
Accepted by the user on 2026-08-12.
