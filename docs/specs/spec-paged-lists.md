---
id: SPEC-0051
type: spec
title: Paged lists, the page object, and the end of the audit log's truncation
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0050, ADR-0048, ADR-0044, ADR-0013]
implemented_by:
  - app/models/page.rb
  - app/models/admin_console.rb
  - app/models/audit_event.rb
  - app/helpers/application_helper.rb
  - app/views/shared/_pagination.html.erb
  - app/controllers/admin_controller.rb
  - app/controllers/academic_posts_controller.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/controllers/recruitment/internship_programs_controller.rb
  - app/controllers/recruitment/organizations_controller.rb
  - app/controllers/internship_request_decisions_controller.rb
  - app/controllers/internship_placements_controller.rb
enforced_by:
  - test/models/page_test.rb
  - test/controllers/notifications_test.rb
  - test/controllers/paged_lists_test.rb
  - test/models/query_budget_test.rb
  - test/models/audit_event_test.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - app/helpers
  - config/locales/en.yml
  - config/locales/th.yml
  - test
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-ARCH-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002]
---

# Paged Lists, the Page Object, and the End of the Audit Log's Truncation

> **Review state:** Accepted on 2026-08-12 on the authority of
> [ADR-0050](../decisions/adr-0050-paged-lists.md), which the user accepted the
> same day. Every product question this specification answers was answered
> there — the page size, the URL, the clamping rule, which lists page, and the
> removal of `AuditEvent::RECENT`. It corrects the decision's count: the
> enumeration produces **nine paged screens rather than the seven ADR-0050's
> consequences predicted**.
>
> **Two increments, both shipped on 2026-08-12.** Increment 1 (UX-008) is the
> nine screens inside ADR-0050's `touches`. Increment 2 (UX-009) is the six the
> first one named as growing and did not reach — the internship queues, the
> programs, a program's applications, the placements screen, and the
> organization index — which took the total to **fifteen screens and seventeen
> lists** and added the one rule increment 1 had no need of: a screen with more
> than one paged list gives each list its own param.
>
> The one list increment 2 left — **the notification bell** — is paged now too,
> on a screen of its own: it needed [ADR-0052](../decisions/adr-0052-notification-history.md)
> first, because the fix was a surface rather than a control. Sixteen screens,
> and nothing left on the list.

> [Executable Specifications](README.md) ·
> [Paged lists decision](../decisions/adr-0050-paged-lists.md) ·
> [Performance evidence](../performance.md) ·
> [Company work surface](spec-company-work-surface.md) ·
> [Admin console boundary](../decisions/adr-0013-admin-course-lifecycle.md)

## Problem

Every list screen in this application loads every row it can see. The admin
roster loads every account, the approval queue every request ever raised, the
Proposals tab every proposal, `/academic` every post an author can reach,
`/recruitment/jobs` every published job, a posting's applications every
applicant.

`docs/performance.md` says every screen is constant-cost in the size of the data
it folds and `query_budget_test.rb` holds it there. Both are true, and neither
is a bound on rows: **the budget counts queries, not rows.** A screen can ask
four questions and render ten thousand answers. What grows is the result set,
the HTML, the transfer, and the reader's ability to find anything.

One list had a bound, and its bound was worse than none. The audit log took
`AuditEvent::RECENT` — the most recent fifty rows after the level filter. The
model's own comment says an audit log you can clear is not one; a log whose
older half no route reaches is the same claim with the deletion moved into the
query. Nothing on the screen said so.

Classroom scale is real and none of this is urgent. It is also the argument that
was made about the company work surface before it turned out to be running 27
queries, and about the two locale files before they turned out to disagree in
nineteen places.

## Scope

**In:** one `Page` object; a pagination control; the screens named below; the
removal of `AuditEvent::RECENT`.

**Out:** infinite scroll, "load more", cursor paging, sorting controls, a
per-page selector, and any new dependency. ADR-0050 rejected the first two on
linkability and the back button, the third as a different object for a scale
nothing here reaches, and Kaminari and Pagy as more than this needs.

**Elsewhere:** the notification bell, which needed a screen rather than a
control — see "Grows, and now paged elsewhere" below.

## The page object

`Page` wraps a relation and the request's `?page=`, and answers with the records
for that page plus what a control needs. It is not an ActiveRecord model, has no
dependencies, and has no opinion about markup.

| Member | Rule |
| --- | --- |
| `Page::SIZE` | `25`. One constant, one place. A screen may pass `size:` with a sentence saying why; none does |
| `#param` | the name this page reads and writes in the URL, `"page"` unless a screen holds more than one paged list |
| `#records` | at most `size` rows, taken in SQL with `LIMIT`/`OFFSET`, never by loading the list and discarding most of it |
| `#count` | the rows in the whole relation, counted with `except(:order, :limit, :offset)` |
| `#number` | the clamped page — see below |
| `#pages` | `(count / size).ceil`, and **never less than 1**: an empty list is one page, not zero |
| `#first?` `#last?` `#previous` `#next` | what a control needs to decide what to draw |
| `#multiple?` | `pages > 1`; a control on a single page is noise and nothing renders one |
| `#window` | `[1, …, n-1, n, n+1, …, last]` with `nil` for a gap, so twenty pages is not twenty links |
| `Enumerable`, `#each`, `#empty?` | so a template iterates a page exactly as it iterated a relation |

**An impossible page clamps to a real one.** `page=0`, `page=-1`, `page=abc`,
`page=99` of 3, `page[]=1`, and a missing param all land on the nearest real
page. This is the rule `AdminConsole.tab_for` and `role_filter` already run:
whitelist-or-default, never a crash or a 404 from a URL a person edited. A row
deleted while somebody reads the last page is ordinary, not an error.

**A page costs exactly one more query — the count — and never one per row.**

## The URL

The page is `?page=2`, beside the `tab`, `role`, `q`, `level`, `query`,
`category`, `employment_type`, `location`, and `remote_policy` params these
screens already keep their state in. A page is therefore linkable, correct under
the back button, survives a reload, and works with JavaScript off.

`ApplicationHelper#page_url` builds a link from `request.path` and the current
query string with the page replaced, because `url_for` carries route segments
and drops exactly the params these screens use. **Page 1 is the bare URL**, so
the first page of a list has one address rather than two.

**A filter change returns to page 1** — the filter chips and search forms carry
no page, so submitting one drops it. Anything else shows a reader an empty
screen for a page that exists under a filter they are no longer using.

**One screen, more than one paged list: one param each.** The placements screen
holds three lists that grow, and a single `?page=` would move all three at once
— a reader paging into the hosting list would find the supervising one had
jumped too. Each page therefore names the param it owns (`hosting_page`,
`supervising_page`, `administering_page`), and `page_url` replaces that one and
carries every other param through, pages included. A screen with a single paged
list uses `page` and says nothing.

## The control

`app/views/shared/_pagination.html.erb`, rendered with `page:`, and nothing else
about it is per-screen.

- A `nav` with an accessible name (`pagination.label`), because a pagination
  control is exactly the kind of thing that ships as two unlabelled arrows and
  `Quality::BudgetPolicy::FAILURE_RESPONSE` makes accessibility blocking rather
  than advisory.
- **Links, not buttons.** A page is a place, not an action.
- Previous and Next, each carrying `rel`, and rendered as inert text at the ends
  rather than as links to nowhere.
- Every number in `#window` is a link with `aria-label` `pagination.go_to`, and
  the current one carries `aria-current="page"`.
- A line naming the page, the total pages, and the row count.
- Both locales, under a top-level `pagination.*` key.

## Which lists page

Sixteen screens and eighteen lists. The first nine are increment 1, inside the
four controllers ADR-0050 named; six more are increment 2; the sixteenth is the
notification history, which needed a decision of its own before it could exist
(ADR-0052).

| Screen | List | Why it grows |
| --- | --- | --- |
| `/admin?tab=users` | every account | one row per person who ever signed up |
| `/admin?tab=queue` | every approval request | appended, never pruned |
| `/admin?tab=proposals` | every proposal | appended, never pruned |
| `/admin?tab=audit` | every audit event | appended, never pruned, never deletable |
| `/academic` | posts an author owns or collaborates on | a career's worth of drafts |
| `/recruitment/jobs` | every published job, filtered | one row per posting per partner |
| `/company/:slug/job_posts` | a company's postings | every posting it ever wrote |
| `/company/:slug/job_posts/:id/applications` | a posting's applicants | one row per applicant |
| `/recruitment/job-applications` | a candidate's applications | one row per application they send |
| `/company/:slug/internship` | a company's incoming internship requests | one row per student per term, forever |
| `/recruitment/internships` | every published programme | one row per programme per partner |
| `/company/:slug/internship_programs` | a company's programmes | every programme it ever wrote |
| `/company/:slug/internship_programs/:id` | a programme's applicants | one row per applicant |
| `/internships/placements` | placements this company hosts (`hosting_page`) | its whole hosting history |
| `/internships/placements` | placements this account supervises (`supervising_page`) | a career of assignments |
| `/internships/placements` | every placement, for an administrator (`administering_page`) | the institution's whole history |
| `/company` | organizations this account can see | every partner ever created |
| `/notifications` | a reader's whole notification history | one row per thing anybody tells them, on the only channel there is |

**Increment 1 is nine, and ADR-0050's consequences predicted seven.** The prediction
was made from the four lists its context names plus the audit log; the
enumeration adds the approval queue, which is every course-lifecycle request
ever raised, and the public job search, which is the most-read list in the
application and the one that grows with every partner. Neither is a scope
change: both are in controllers the decision already named, and both are lists
that grow with the institution, which is the rule the decision gave.

The approval queue was read from its template rather than from the controller —
`AdminConsole.queue` twice, once to ask whether it was empty and once to render
it. It is assigned in the controller now, which is also one query fewer than
before.

## Bounded by construction, and deliberately not paged

A control on a list of four is worse than no control. Each of these is bounded
by something real, and leaving it alone is a decision rather than an oversight.

| List | Bound |
| --- | --- |
| A business case's participants | a project cohort |
| A business case's pending invitations | what is outstanding, which is cleared by accepting |
| A business case's comments | one case's thread, over a term |
| An organization's memberships | a company's staff |
| An organization's pending invitations | as above |
| A placement's weekly progress reports | the weeks of one placement |
| A proposal's decisions | at most one per transition, and two statuses are terminal |
| A posting's AI suggestions | one generation |
| A program's AI suggestions | one generation |
| An application's messages | one conversation |
| Job recommendations | `first(5)`, by construction |
| A student's discovery dismissals | an undo list for one reader |
| A profile's live sessions | the devices one person is signed in on |
| `/admin?tab=courses` | the curriculum |
| `/admin?tab=sections` | a term's cohorts — and it is a picker whose selected row must always be on screen, not a feed |
| `/admin?tab=integrity` | open cases, grouped in Ruby from unreviewed events and cleared by reviewing them. Not a relation; paging it would mean paging learners, which is a different object and a different decision |
| A student's own internship requests and open placements | one student's own |
| `/contributors` | four editorial entries |

## Grows, and now paged elsewhere

**The notification bell** was the one list this document left open. It is capped
at `Notification::RECENT` — eight rows — and nothing reached the ninth, which is
the audit log's defect in miniature. It was not fixed here because **the fix is
a screen, not a page**: the bell is a dropdown in the header, and paging a
dropdown is not what a reader of it wants.

That screen exists now. [ADR-0052](../decisions/adr-0052-notification-history.md)
answered the five questions it needed — where it lives, history rather than
inbox, that reading it marks nothing read, that the bell keeps its eight and
gains a link, and that nothing is deleted — and [SPEC-0053](spec-notification-history.md)
records what shipped. The panel still shows eight; the link at the foot of it is
the route the ninth row was missing.

**Nothing is left on this list.**

## Invariants

1. A list this specification names as paged renders at most `Page::SIZE` rows for
   any request, whatever the data size.
2. An impossible page number renders the nearest real page. Never a 404, never
   an empty list, never a raised exception.
3. A paged screen's query count does not change when its row count grows, and a
   page costs exactly one query more than the unpaged list did.
4. A page link carries the current query parameters with only its own page
   param replaced; a filter control carries no page at all.
   4a. Where a screen holds more than one paged list, each list owns a distinct
   param, and a link into one leaves the others where the reader left them.
5. `Page::SIZE` is 25, in one place.
6. A list that fits on one page renders no control.
7. The control is a named `nav` of links, with the current page marked
   `aria-current="page"`, in both locales.
8. `AuditEvent` has no `RECENT` constant, and nothing limits the audit tab's
   query. Every row ever written is reachable from the screen.
9. The level filter and every other filter runs in SQL before the page is taken,
   so a page holds what survived the filter rather than what preceded it.

## Acceptance Criteria

- Given 33 accounts, `/admin?tab=users` renders 25 rows and `?page=2` renders 8.
- Given 60 audit events, `/admin?tab=audit` renders 25, and the oldest — the
  sixtieth row back, which no route reached before — renders on page 3.
- Given 26 warn-level events, `?tab=audit&level=warn&page=2` renders 1 row and
  its control links carry `level=warn`.
- Given 27 accounts, the role chips on `?tab=users&role=student&page=2` link
  without a page number.
- Given 27 published jobs, `/recruitment/jobs?query=bangkok&page=2` renders the
  remainder and its control links carry `query=bangkok`.
- Given 26 posts, `?page=0`, `?page=-1`, `?page=abc` and `?page=99` all render a
  non-empty list with a 200, and `?page=99` renders the last page's row.
- Given one post, no `nav[aria-label="Pages"]` is rendered.
- On page 2 of a paged list, the control contains `a[aria-current=page]` reading
  "2", an `a[rel=prev]`, and no `button`.
- Given 26 placements a company hosts, `/internships/placements` renders 25 and
  `?hosting_page=2` renders 1, while `?supervising_page=2` leaves the hosting
  list on page 1 — and on `?supervising_page=3` the hosting control's links
  still carry `supervising_page=3`.
- `AuditEvent.const_defined?(:RECENT)` is false.

## Verification

- `test/models/page_test.rb` — size, count, clamping, the window, the SQL, and
  the two-query cost.
- `test/controllers/paged_lists_test.rb` — every screen in the table above, by
  growing the data rather than by reading the code; the filter contract; the
  edited URL; the accessibility contract.
- `test/models/query_budget_test.rb` — a page costs one query more than the
  unpaged list, and the same however many rows arrive.
- `test/models/audit_event_test.rb` — the filter runs before the page, and
  `RECENT` is gone and stays gone.
- `test/operations/locale_parity_test.rb` — the `pagination.*` keys exist in
  both files.

## Consequences

- Sixteen screens gain a page and a control; every other list is unchanged and
  this document records why.
- The audit log gains reachable history and loses `RECENT`.
- Each paged screen costs one more query, and the approval queue costs one
  fewer; `docs/performance.md` carries the figures.
- Deep pages remain honest but not fast: `OFFSET 10000` is a full scan in
  Postgres. Nothing here has ten thousand rows in one list, and the day
  something does, the fix is a cursor rather than a bigger offset.
