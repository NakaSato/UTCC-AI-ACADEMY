---
id: ADR-0050
type: adr
title: Give a list a page, and stop the audit log truncating
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0048, ADR-0044, ADR-0013]
implemented_by:
  - SPEC-0051
touches:
  - app/models/page.rb
  - app/models/admin_console.rb
  - app/models/audit_event.rb
  - app/helpers/application_helper.rb
  - app/controllers/admin_controller.rb
  - app/controllers/academic_posts_controller.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - app/controllers/recruitment/job_applications_controller.rb
  - app/views/shared/_pagination.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/models/page_test.rb
  - test/controllers/paged_lists_test.rb
  - test/models/query_budget_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give a List a Page, and Stop the Audit Log Truncating

> **Decision state:** Accepted by the user on 2026-08-12, who chose paging long
> lists over adding a frontend library. No JavaScript is added by this decision
> and none is needed by it.

> [Decision Records](README.md) ·
> [Paged lists specification](../specs/spec-paged-lists.md) ·
> [Performance evidence](../performance.md) ·
> [Company work surface](adr-0048-company-work-surface.md) ·
> [Role-aware workspaces](adr-0044-role-aware-workspaces.md)

## Context

Twenty-five list screens load every row they can see. The admin roster loads
every account, the Proposals tab every proposal, `/academic-posts` every post an
author can reach, a posting's applications every applicant. None of them
paginates, and only one has any bound at all: the audit log takes
`limit(AuditEvent::RECENT)`, which is 50.

`docs/performance.md` says every screen is constant-cost in the size of the data
it folds, and `query_budget_test.rb` holds it there. That is true and it is not
the whole story: **the budget counts queries, not rows.** A screen can ask four
questions and render ten thousand answers. The cost that grows is the SQL result
set, the HTML, the transfer, and the reader's ability to find anything — and
`Quality::BudgetPolicy` already sets a `initial_transfer_p75_bytes` budget that
nothing currently enforces on a list.

The audit log is the sharper problem, because its bound is worse than none. The
model says an audit log you can clear is not one; a log you can only read the
most recent fifty rows of is a log with the older half quietly removed, and
nothing on the screen says so. The row is still in the table, and there is no
route by which anybody reaches it.

Classroom scale is real and this is not urgent. It is also exactly the argument
that was made about the company work surface before it turned out to be running
27 queries, and about the two locale files before they turned out to disagree in
nineteen places. A bound that only holds while the data stays small is a bound
somebody will discover the hard way.

## Decision

1. **One page object, no gem.** `Page` wraps a relation and the request's
   `?page=`, and answers with the records for that page plus what a pagination
   control needs: the number, the count of pages, whether there is a previous
   and a next. It is roughly forty lines and it has no opinion about markup.

   Kaminari and Pagy were both considered and both rejected. The coding standard
   requires an accepted ADR for any dependency, naming alternatives *including
   no dependency*; here the no-dependency option is small, and both gems bring
   view helpers whose markup would have to be fought back into the Tailwind
   token system — the same reason ADR-0007 took Tiptap for behavior and refused
   its styling.

2. **The URL carries the page**, as `?page=2`, beside the `tab`, `role`, `q`,
   `level`, and `group` params already there. A page is therefore linkable,
   correct under the back button, survives a reload, and works with JavaScript
   off. Infinite scroll is rejected for the opposite of each of those.

3. **An impossible page clamps to a real one.** Page 0, page 99 of 3, `page=abc`,
   and `page=-1` all land on the nearest real page rather than 404 or an empty
   screen. This is the rule `AdminConsole.tab_for` and `role_filter` already run
   on: whitelist-or-default, never a crash from a URL a person edited. A row
   deleted while somebody reads the last page is ordinary, not an error.

4. **Twenty-five per page**, one constant, one place. A screen may pass its own
   only with a sentence saying why. The number is a judgement, not a
   measurement: it is what fits a laptop screen without scrolling twice.

5. **A page costs exactly one more query** — the count — and never one per row.
   `query_budget_test.rb` gains that assertion, because the whole point of a
   bound is lost if reaching for it grows the query count instead.

6. **A filter change returns to page 1, and a page link keeps the filter.**
   Anything else shows a reader an empty screen for a page that exists under a
   filter they are no longer using. The pagination control therefore renders
   with the current query parameters and only the page replaced.

7. **The audit log stops truncating.** `AuditEvent::RECENT` is removed and the
   tab pages instead. This is the only behavior change in the decision that a
   person will notice as new capability rather than as an unchanged screen: rows
   older than the most recent fifty become reachable for the first time.

8. **Lists that are bounded by construction are deliberately not paged.** A
   business case's participants, an organization's memberships, a placement's
   weekly reports, a proposal's decisions, the suggestions on one posting — each
   is bounded by something real (a cohort, a term, a company's staff), and a
   pagination control on a list of four is noise. The specification names them,
   so leaving them alone stays a decision rather than an oversight.

   It also names the lists that are **neither** — which grow with the
   institution and were outside this decision's `touches`. Calling those bounded
   would have been untrue, and leaving them unlisted would have made the
   omission invisible, so they were named as the follow-up they were. UX-009
   shipped that follow-up the same day: the internship queues, the programmes, a
   programme's applicants, the placements screen and the organization index all
   page now, and the specification's table is the register of both increments.

   One is still open, and deliberately: **the notification bell**, capped at
   eight with no route to the ninth. That is this decision's own defect in
   miniature, and the fix is a screen rather than a page — a route, a place in
   the navigation, and a rule about what a read notification does. A new surface
   is an ADR, not one more `Page.new`.

9. **The control is a `nav` a keyboard can use.** Links, not buttons; an
   accessible name; the current page marked with `aria-current="page"`; both
   locales. `Quality::BudgetPolicy::FAILURE_RESPONSE` makes accessibility
   blocking rather than advisory, and a pagination control is exactly the kind
   of thing that gets shipped as unlabelled arrows.

## Alternatives

### Add Kaminari or Pagy

Rejected, as above. Neither is a bad library; both are more than this needs, and
both arrive with markup and locale conventions that this application would spend
its time overriding. The forty lines are cheaper to own than the override layer.

### Load more, or infinite scroll

Rejected. It needs JavaScript for something that currently needs none, it cannot
be linked to or returned to, it breaks the back button, and on the audit log it
would make "is this all of it?" permanently unanswerable.

### Raise the truncation limit and leave everything else

Rejected as the version of this that looks cheap and answers nothing. The audit
log's problem is not that fifty is too few; it is that a limit with no way past
it is invisible to the reader.

### Page everything at once

Rejected. Twenty-five lists span eight specifications, and a control on a list
of four participants is worse than no control. The rule is "lists that grow with
the institution", and the specification names which those are.

## Consequences

- **Nine** screens gain a page and a control. Every other list is unchanged, and
  the specification records why.

  This paragraph said seven when the decision was accepted, counted from the
  four lists the context above names plus the audit log. The enumeration in
  SPEC-0051 found two more inside the same four controllers: the approval queue,
  which is every course-lifecycle request ever raised, and the public job search
  at `/recruitment/jobs`, which is the most-read list in the application and
  grows with every partner. Neither is a scope change — both are lists that grow
  with the institution, which is the rule this decision gave — but the number
  was wrong, and a consequence that predicts a count is worth correcting rather
  than rounding to.

  The follow-up increment took it to **fifteen screens and seventeen lists**, in
  four controllers this decision did not name. That is this decision applied
  rather than extended — the rule was always "lists that grow with the
  institution" — and SPEC-0051's table is the register of which are which.
- The audit log gains reachable history and loses `RECENT`; the constant and its
  test go with it.
- Each paged screen adds exactly one query. The per-screen figures in
  `docs/performance.md` move by one, and the table is updated with them.
- `Page` is a new shared object with no dependencies and no styling. If a later
  screen needs cursor paging over an ordered set, that is a different object and
  a different decision; this one is offset paging, which is correct and cheap at
  the scale this application runs at, and gets slow at a depth nothing here
  reaches.
- Deep pages remain honest but not fast: `OFFSET 10000` is a full scan in
  Postgres. Nothing in this application has ten thousand rows in one list, and
  the day something does, the fix is a cursor rather than a bigger offset.

## Fitness Functions

- A list the specification names as paged renders at most twenty-five rows for
  any request, whatever the data size — asserted by growing a fixture rather
  than by reading the code.
- An impossible page number renders the nearest real page and never a 404 or an
  empty list.
- A paged screen's query count does not change when its row count grows.
- The pagination control carries the current filter parameters, and a filter
  change lands on page 1.
- `AuditEvent` has no `RECENT` constant and no `limit` on the tab's query.

## Decision owner

Product Owner and Tech Lead, with the QA owner for the accessibility contract.
**Accepted by the user on 2026-08-12.**
