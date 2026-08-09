---
id: SPEC-0042
type: spec
title: Console sign-in for teaching staff, administrators, and company members
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0042, ADR-0019, ADR-0024, SPEC-0019, SPEC-0024]
implemented_by:
  - app/controllers/console_sessions_controller.rb
  - app/views/console_sessions/new.html.erb
  - app/models/user.rb
  - config/routes.rb
touches:
  - app/controllers
  - app/models/user.rb
  - app/views/console_sessions
  - app/views/shared/_auth_hero.html.erb
  - app/views/layouts/auth.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/console_sessions_controller_test.rb
  - test/controllers/indexing_test.rb
  - test/controllers/crawlers_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-ARCH-004]
min_reviewer_skills: [SKILL-SPEC-002]
---

# Console Sign-in for Teaching Staff, Administrators, and Company Members

> [Specifications](README.md) ·
> [Console sign-in decision](../decisions/adr-0042-console-sign-in-boundary.md) ·
> [Session visibility specification](spec-m9-session-visibility-and-revocation.md)

## Problem

Instructors, administrators, and company members sign in through a screen built
for learners: it asks for a student ID, offers student self-registration beside
it, and lands every role on the course catalog. A company recruiter has a
student ID only because the account required one, and after signing in has to
navigate to the recruitment screens unaided.

They need a door of their own that asks for a credential they recognize and
opens on the work they came to do — without becoming a second authentication
system with rules of its own.

## Invariants

1. `GET /console` renders the sign-in screen; `POST /console` attempts it. One
   path, one helper, matching the `/login` convention.
2. A console sign-in creates a session through the same
   `Authentication#start_new_session_for` used by `/login`: same `Session` row,
   same signed cookie, same `Session::MAX_AGE`, same "remember me" semantics.
3. Console access is `User#console_access?` — `staff?` (instructor or admin) or
   `company_member?`, where a company member holds an **active**
   `OrganizationMembership`. A revoked membership is not a membership.
4. The identifier field authenticates on `email_address` when the submitted
   value contains `@`, on `student_id` when it is all digits, and on `username`
   otherwise — see SPEC-0043, which added the username column and made the
   student ID student-only. No other column is reachable from that field.
5. An account without console access receives no session, and its refusal
   message is identical to the one a wrong password receives.
6. On success the destination is the stashed `return_to_after_authenticating`
   URL when one exists; otherwise `/admin` for an admin, `/instructor` for an
   instructor, and the recruitment organizations index for a company member.
7. `POST /console` carries two rate limits, keyed on the request IP and on the
   submitted identifier, at the same 10-per-3-minutes as `/login`.
8. `/console` renders `noindex, nofollow` and appears in
   `CrawlersController::DISALLOWED`.
9. The screen is bilingual: every string it renders exists in both
   `config/locales/en.yml` and `config/locales/th.yml`.
10. `/login` is unchanged — it still authenticates on student ID only, still
    admits every role, and still offers registration.

## Acceptance Criteria

- An instructor signing in at `/console` reaches `/instructor` with a session
  cookie set.
- An administrator signing in at `/console` reaches `/admin`.
- A member of an active organization reaches the recruitment organizations
  index, whether they typed their student ID or the email address on their
  account, in any case or with surrounding whitespace.
- A learner with no staff role and no membership submits correct credentials,
  receives no session cookie, and is returned to `/console` with the generic
  failure message.
- A member whose membership has been revoked is refused the same way.
- An instructor submitting a wrong password and a learner submitting a correct
  one receive the same message.
- A blank identifier is refused without error.
- A visitor sent to the front door from a deep-linked recruitment screen returns
  to that screen after signing in at `/console`.
- Eleven failed attempts against one identifier from eleven different addresses
  are throttled with the shared `flash.login_throttled` message.
- The console screen shows the console hero copy; `/login` continues to show the
  student hero copy.
- The console screen links to `/login` for students and offers no registration
  link.

## Verification

- `test/controllers/console_sessions_controller_test.rb` covers every acceptance
  criterion above, including the throttle and the indistinguishable-refusal rule.
- `test/controllers/indexing_test.rb` asserts `/console` asks not to be indexed.
- `test/controllers/crawlers_test.rb` asserts the `robots.txt` disallow list.
- `test/controllers/sessions_controller_test.rb` continues to prove `/login` is
  unchanged, including that it refuses an email address in its student-ID field.
- `bin/verify` runs the whole gate: docs freshness, RuboCop, Brakeman,
  bundler-audit, importmap audit, and the full test suite.

### Walking it by hand

`db/seeds.rb` provisions one account per console population, in development and
test only, all with the password `utcc2026`:

| Population | Sign in with | Lands on |
| --- | --- | --- |
| Instructor | `wichai` or `wichai@utcc.ac.th` | `/instructor` |
| Administrator | `utcc-admin` or `admin@utcc.ac.th` | `/admin` |
| Company owner | `northstar` or `recruiter@northstar.co.th` | their company at `/company/:slug` |

None of the three has a student ID — see SPEC-0043. The company account carries
no role either: its reach is an active `owner` membership of the seeded
organization, which is what invariant 3 requires. The demo student
`2011071730001` is the negative case: correct password, no console.
