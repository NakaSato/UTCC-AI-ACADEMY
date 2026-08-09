---
id: ADR-0042
type: adr
title: Give teaching staff, administrators, and company members their own sign-in door
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0019, ADR-0024]
implemented_by:
  - SPEC-0042
touches:
  - app/controllers/console_sessions_controller.rb
  - app/controllers/crawlers_controller.rb
  - app/models/user.rb
  - app/views/console_sessions
  - app/views/shared/_auth_hero.html.erb
  - app/views/layouts/auth.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/console_sessions_controller_test.rb
agent_writable: true
requires_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give Teaching Staff, Administrators, and Company Members Their Own Sign-in Door

> **Decision state:** Accepted by the user on 2026-08-09. `/console` is a second
> sign-in screen for accounts with work outside the student experience. It
> authenticates on a student/staff ID **or** an email address, refuses accounts
> without console access without creating a session, and lands each role on its
> own console. `/login` is unchanged and still admits every role.

> **Amended by [ADR-0043](adr-0043-console-account-identity.md):** a console
> account no longer carries a student ID. Point 3 below reads username, email,
> or student ID; everything else stands.

> [Decision Records](README.md) ·
> [Console sign-in specification](../specs/spec-console-sign-in.md) ·
> [Console account identity](adr-0043-console-account-identity.md) ·
> [Session visibility decision](adr-0019-session-visibility-and-revocation.md) ·
> [Recruitment organization membership](adr-0024-recruitment-organization-membership.md)

## Context

Every account signs in at `/login` with a 13-digit student ID, including the
instructors, administrators, and company members who never take a course. The
screen is written for learners — its hero sells the AI Fundamental curriculum,
its second tab is student self-registration, and its help text tells staff that
"the instructor view unlocks automatically."

Three populations now have work behind that door. Teaching staff run sections
and grades at `/instructor`; administrators run accounts, courses, and the
approval queue at `/admin`; company members run job posts, internship programs,
applications, and business cases under `/recruitment`. A company recruiter in
particular is asked for a *student* ID they were only issued so the account
could exist, and is then dropped on the student catalog and left to find the
recruitment screens themselves.

Authentication itself is role-agnostic and should stay that way: the credential
check is the same one for everybody, and a second door must not become a second
authorization system.

## Problem frame

- **Affected user:** An instructor, administrator, or company member signing in
  to do work that has nothing to do with taking a course.
- **Current behavior:** One student-facing screen for everyone, a student-only
  credential label, and a landing page that is the wrong screen for all three.
- **Failure risk:** A second door becomes a second authentication path with its
  own weaker rules, or it answers "is this account staff?" for anyone holding a
  list of student IDs.
- **Success signal:** A console user recognizes the screen as theirs, signs in
  with a credential they think of as their own, and arrives on the console they
  came for.

## Decision boundary

The accepted policy is:

1. `/console` is a sign-in screen only. It creates the same `Session` row, with
   the same cookie, the same 30-day `Session::MAX_AGE`, and the same "remember
   me" behavior as `/login`. It is not a new session type and grants no
   permission that the role and membership records do not already grant.
2. Console access is `staff? || company_member?` — an instructor or admin role,
   or an **active** organization membership. Revoking a membership closes the
   door with no other action.
3. The form takes one identifier field. An entry containing `@` authenticates on
   `email_address`; anything else authenticates on `student_id`. Both columns are
   unique and normalized on the model. `/login` is untouched and still refuses an
   email address in its student-ID field.
4. An account without console access is refused **before** a session exists, and
   the refusal is worded identically to a wrong password. The screen must not be
   usable to learn which accounts are staff.
5. Sign-in lands on `/admin` for an administrator, `/instructor` for an
   instructor, and the organizations index for a company member — unless the
   visitor was deep-linked, in which case the stashed URL still wins.
6. `/console` is throttled with the same two rate-limit keys as `/login`: one on
   the source address, one on the identifier being tried.
7. `/console` is `noindex` and is listed in `robots.txt` alongside the other
   auth screens.
8. Out of scope for this decision: SSO, a separate console password policy,
   console-specific session lifetimes, a console-only logout destination, and
   any new role or permission. Sign-out continues to land on `/login`.

## Alternatives

### Keep one sign-in screen for everyone

Nothing to build and one code path to secure, but it keeps asking a company
recruiter for a student ID and keeps landing all three populations on a catalog
of courses they are not taking.

### Branch the existing screen on the credential typed

Detect an email at `/login` and route accordingly. Cheaper, but it changes a
screen that is deliberately student-shaped, and it silently loosens the existing
rule that `/login` authenticates on student ID only.

### A separate console screen sharing the authentication concern

A second controller, its own copy, its own throttle, and the same
`start_new_session_for`. Two screens, one session mechanism, one authorization
system.

### A separate console application or subdomain

Strongest separation, but a deployment, session-cookie, and operations problem
far out of proportion to a sign-in screen.

### Approved policy direction

The separate console screen sharing the authentication concern is selected. The
duplication is a form and a throttle; the session, the cookie, and every
authorization gate stay single-sourced.

## Consequences

- There are now two ways to authenticate. Any future change to session
  creation, expiry, or throttling has to be applied to both screens or moved
  into the shared concern.
- A console user with no email address on their account still signs in with
  their ID, so the email path is a convenience, never a requirement.
- The generic refusal means a console user who mistypes their password and a
  learner who wandered in read the same sentence. That is the intended trade:
  the screen tells nobody who is staff.
- The auth hero is now parameterized by scope. A third auth screen must supply
  its own copy or take the student default.
- Sign-out still returns to `/login`. A console-specific logout destination is a
  separate decision.

## Threat boundary

- `/console` is an unauthenticated, internet-facing form and is a credential
  stuffing target; both throttle keys are load-bearing.
- The identifier field accepts free text, so the branch on `@` must not become a
  way to select a column or a query — it selects between two fixed attribute
  names and nothing else.
- Refusal must be indistinguishable from failure, or the screen becomes an
  oracle for which accounts hold staff roles or company memberships.
- A revoked company membership must close the door on the next sign-in without
  needing a password change or an administrator action.

## Fitness Functions

- An account that is neither staff nor an active company member cannot obtain a
  session through `/console`, whatever credential it presents.
- A wrong password and a refused account produce the same response and the same
  message.
- A console sign-in creates exactly the same session record and cookie as a
  sign-in at `/login`.
- Each console role lands on its own console, and a stashed deep link still
  takes precedence over that default.
- `/console` asks not to be indexed and is disallowed in `robots.txt`.
