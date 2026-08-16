---
id: ADR-0045
type: adr
title: Render error pages through the app, and keep flat files for when it is gone
status: accepted
owners: ["@tech-lead", "@platform-owner", "@product-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0020, ADR-0044]
implemented_by:
  - SPEC-0045
touches:
  - app/models/http_error.rb
  - app/controllers/errors_controller.rb
  - app/controllers/concerns/localization.rb
  - app/views/layouts/error.html.erb
  - app/views/errors/show.html.erb
  - lib/error_pages.rb
  - lib/templates/error_page.html.erb
  - lib/tasks/error_pages.rake
  - config/application.rb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/errors_test.rb
  - test/models/http_error_test.rb
  - test/lib/error_pages_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Render Error Pages Through the App, and Keep Flat Files for When It Is Gone

> **Decision state:** Accepted by the user on 2026-08-09. Failed requests are
> re-dispatched through the router to a controller that renders a bilingual,
> branded page and, for a 5xx, the request id support needs. The flat files in
> `public/` stay — regenerated from the same copy — as the fallback for failures
> the app cannot answer at all.

> [Decision Records](README.md) ·
> [Error pages specification](../specs/spec-error-pages.md) ·
> [Critical-failure observability](adr-0020-critical-failure-observability.md) ·
> [Role-aware workspaces decision](adr-0044-role-aware-workspaces.md)

## Context

Every failure in the app ended on a generated Rails page: English only,
unstyled, and identical to the one every other Rails app ships. A Thai student
who mistyped a course code got "The page you were looking for doesn't exist" in
a typeface the academy does not use, with no way back to anything. There were
five such files — 400, 404, 406, 422, 500 — and nothing for the statuses a
visitor actually meets during a deploy: 502, 503, 504.

The app had also grown reasons to say more than "not found". Six controllers
rate-limit, three roles are refused different screens, and SPEC-0020 stamps a
request id on every 5xx event — a number that is useless to the person reporting
the failure because no screen has ever shown it to them.

Two constraints shape the answer. The first is that an error page must render
when the app is broken: the layout that carries a learner's gem count, streak
and notification bell reads the database on every screen, and a 500 *raised by*
the database would raise again on the page reporting it. The second is that some
failures happen where there is no app at all — Render answers a request while
the container restarts — and no controller can be reached to describe them.

## Decision

1. `config.exceptions_app = routes`. A failed request has its path rewritten to
   its status code and is dispatched back through the router.
2. `ErrorsController` inherits `ActionController::Base`, not
   `ApplicationController`. It runs no authentication, no authorization, no
   observability callback and no browser gate; it reads the locale and nothing
   else. Its layout renders no counter, no bell and no session-dependent footer.
3. `HttpError` holds the shape and the locale files hold the words. Ten statuses
   have copy of their own — 400, 403, 404, 406, 422, 429, 500, 502, 503, 504 —
   and every other 4xx or 5xx borrows its family's, so a status nobody
   enumerated still renders a page.
4. A 5xx page prints `request.request_id`. It is the same value the
   observability event carries (SPEC-0020), which is what turns "it broke" in a
   support message into one grep.
5. The flat files in `public/` are generated, not written:
   `bin/rails error_pages:build` renders them from the same locale copy, and a
   test fails when what is committed no longer matches. They print Thai and
   English together, because a file cannot negotiate a language, and inline
   every rule, because a page reporting that the app is down must not need it.
6. The live pages get a second address at `/errors/:code`. The flat files shadow
   `/404` and `/500` whenever the static file server is on, so without it the
   pages would have no URL anyone could open to review them.

## Alternatives

**Keep the flat files as the only error pages.** This is Rails' default and it
costs nothing. It also means the pages can never be bilingual for a Thai-first
app, never carry a request id, and never look like the product — and it leaves
502, 503 and 504 with no page at all.

**Rescue in `ApplicationController` instead.** `rescue_from` would give branded
pages for exceptions raised inside a controller, which is most of them. It does
nothing for a routing error, which never reaches a controller, and it renders
through the application layout — the one that reads the database. It would
answer the common case and fail the case that matters.

**Ten templates, one per status.** Rejected: the statuses differ by three
strings and by whether the visitor can do anything, which is data, not markup.
Ten templates would have drifted within a release, and would still not answer a
status nobody had thought to add.

**Write the flat files by hand.** Rejected for the same reason the app is
bilingual by locale file rather than by duplication: eight files of near
identical inline CSS would drift from the copy the moment a translator touched
`error_pages`, and nobody looks at a 503 page while it is right.

**Point Render at a maintenance page for 502/503/504.** Out of scope here, and
not a substitute: the platform's own page appears when the container is gone,
which is the one moment the repository cannot influence. The generated files
give that configuration something on-brand to point at when it is set up.

## Consequences

- Every failure now renders in the visitor's language, on the brand, with one
  way out. A 5xx carries a reference number a student can quote.
- A new status needs copy in two locale files and nothing else.
- The error page is the one screen that must not read the database, and its
  independence is asserted rather than assumed —
  `test/controllers/errors_test.rb` runs `/errors/500` inside `assert_no_queries`.
- `switch_locale` moved out of `ApplicationController` into a `Localization`
  concern so both controllers can share it.
- The generated files in `public/` are now build output. Editing one by hand is
  a test failure, which is the intent.
- Fixed while proving this out: the three subscribers in
  `Observability::Instrumentation` named `Telemetry` unqualified. A subscriber
  block outlives the class that registered it, so after the first reload in
  development every 5xx raised `NameError` inside the subscriber instead of
  reporting the failure.

## Fitness Functions

- `test/controllers/errors_test.rb` — every named status renders at its own
  path with its own status; an unnamed status falls back to its family; the page
  is noindex and uncached; a 5xx carries the request id and a 4xx does not; a
  non-HTML request gets the status and no body; the page renders with no
  database query; and a missing route reaches the branded page through
  `exceptions_app`.
- `test/models/http_error_test.rb` — the fallback in both directions, and that
  every named status has copy in both locales.
- `test/lib/error_pages_test.rb` — the committed files in `public/` match the
  copy, carry both languages, and reference no stylesheet or script.
- `bin/verify` runs the whole gate.
