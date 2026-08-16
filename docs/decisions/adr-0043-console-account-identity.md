---
id: ADR-0043
type: adr
title: Identify console accounts by username or email and create them from the admin screen
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0042, ADR-0024]
implemented_by:
  - SPEC-0043
touches:
  - app/models/user.rb
  - app/models/admin_console.rb
  - app/models/audit_event.rb
  - app/controllers/admin_controller.rb
  - app/controllers/console_sessions_controller.rb
  - app/controllers/registrations_controller.rb
  - app/views/admin/_users.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - db/seeds.rb
enforced_by:
  - test/models/user_test.rb
  - test/controllers/admin_console_accounts_test.rb
  - test/controllers/admin_password_reissue_test.rb
  - test/controllers/console_sessions_controller_test.rb
agent_writable: true
requires_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Identify Console Accounts by Username or Email and Create Them From the Admin Screen

> **Decision state:** Accepted by the user on 2026-08-09. A console account
> carries no student ID. `users.student_id` becomes nullable and is required
> only at sign-up; a new `users.username` column joins it and `email_address` as
> the three columns that can identify an account, at least one of which every
> account must have. An admin creates console accounts from `/admin`.

> [Decision Records](README.md) ·
> [Console account identity specification](../specs/spec-console-account-identity.md) ·
> [Console sign-in decision](adr-0042-console-sign-in-boundary.md) ·
> [Recruitment organization membership](adr-0024-recruitment-organization-membership.md)

## Context

ADR-0042 gave staff and company members their own sign-in door but left them
holding a learner's credential: a 13-digit student ID, required on every account
because `student_id` was `NOT NULL` and the only thing sign-in authenticated on.
An instructor has no student card. A company recruiter has one solely because
the account could not exist without it.

That requirement also decided who could create these accounts, and the answer
was nobody. Sign-up produces learners and refuses anything without a 13-digit
ID; organization invitations only reach accounts that already exist. A real
instructor or company member could be onboarded only from a Rails console.

## Problem frame

- **Affected user:** An instructor, administrator, or company member being
  onboarded, and the administrator doing the onboarding.
- **Current behavior:** Every account must have a student ID; console accounts
  are created by hand in a shell or not at all.
- **Failure risk:** Making the ID optional leaves accounts nothing can identify;
  an admin creation form becomes a way to mint administrators, or leaks a
  password into a log.
- **Success signal:** An admin creates a working console account from a screen,
  hands over one first password, and the account signs in by a name its owner
  recognizes.

## Decision boundary

The accepted policy is:

1. `users.student_id` becomes nullable. It stays unique and 13 digits when
   present, and is **required at sign-up** through a `:registration` validation
   context, so every learner still has one.
2. A `users.username` column is added: unique, optional, 3–30 characters of
   lowercase letters, digits, dot, dash, and underscore, starting and ending
   alphanumeric, and containing at least one letter. The letter is required
   because console sign-in reads an all-digit entry as a student ID.
3. Every account must hold at least one of student ID, username, or email
   address. `User#identifier` returns them in that order, and is what screens
   print where they used to print the student ID.
4. Console sign-in tells the three apart by shape: `@` is an email address, all
   digits is a student ID, anything else is a username. The branch selects among
   three fixed attribute names and nothing else.
5. An administrator creates console accounts at `/admin` with a name, a
   username and/or an email, and one whitelisted access level: instructor,
   administrator, or company member. The role is never taken from posted account
   attributes.
6. "Company member" is not a role and never becomes one. It creates an ordinary
   account plus an **active** organization membership in the same transaction,
   under an organization role the admin picks — ADR-0024 is unchanged.
7. The first password is generated, satisfies the password policy, is shown to
   the admin exactly once in a flash, and is stored only as a digest. Nothing
   emails it; the account owner changes it on `/profile`.
8. Creating a console account writes an audit event at the `warn` level, naming
   the identifier, the person, and the access level — never the password.
9. Out of scope: SSO, self-service console sign-up, editing or deleting console
   accounts from this form, and bulk import.

**Amended 2026-08-09, same day:** points 10 and 11 were added once it was clear
the boundary above could strand a real person out of an account — a console
account with no email and a one-time password had no way back in at all.

10. A console account created here **requires** an email address. It is the only
    self-service route back into an account that has no student ID.
11. An administrator may reissue a console account's password from the roster.
    It generates a fresh temporary password under the same one-flash, digest-only
    rule, ends every session of that account, and is audited at `warn`. A learner
    is not eligible — `/forgot-password` reaches them without an administrator
    reading their new password — and an admin cannot reissue their own.

## Alternatives

### Keep `student_id` required and issue fake IDs

No schema change, but it puts a fabricated student number on staff and company
records, and every screen that prints an ID would print a lie.

### Make email the only console identifier

One fewer column. Rejected because it forces an address on every staff account,
gives no short handle to type, and makes the identifier the same field the
password-reset flow keys on.

### Username plus email, student ID optional

The selected shape. Three identifier columns, at least one required, each unique
and normalized, with the sign-in branch reading shape alone.

### A separate `staff_accounts` table

Cleanest separation of learner and staff identity, but it forks sessions,
authorization, notifications, and every association that points at `users` —
far out of proportion to making one column nullable.

## Consequences

- `student_id` is no longer a safe assumption anywhere. Screens print
  `User#identifier`; the admin roster searches all three columns.
- Sign-up keeps its rule through a validation context, so any future code path
  that creates a learner must save in that context or state the ID itself.
- An account can now exist that `/login` cannot admit — deliberately. Console
  accounts sign in at `/console`.
- The generated first password is shown in a flash. It reaches the admin's
  screen and no log; an admin who loses it before relaying it reissues one from
  the roster rather than recreating the account.
- Reissuing is a privileged read of someone else's credential. Confining it to
  console accounts keeps an administrator out of the recovery path for the
  hundreds of learners who have an email route of their own.
- A company account created here holds an active membership immediately, so the
  organization's screens open on the first sign-in.

## Threat boundary

- The creation form is an administrator-only privilege escalation path; the
  access level must come from a whitelist and never from posted attributes.
- The generated password is credential material: one flash, one digest, no log,
  no audit row, no email.
- Making `student_id` nullable weakens a uniqueness assumption only if blanks
  are stored as `""` — normalization to `nil` is what keeps the unique index
  honest across many identifier-less columns.
- An all-digit username would be unreachable through console sign-in and could
  shadow a student ID in an admin's mind; the format rule forbids it.

## Fitness Functions

- No account can be saved without at least one identifier.
- Sign-up still refuses an account with no student ID.
- A console account created from `/admin` has no student ID, signs in at
  `/console` by username or email, and cannot sign in at `/login`.
- A posted `role` on the creation form cannot change the access level granted.
- A company account and its membership are created together or not at all.
- The generated password appears in exactly one flash and in no audit row.
- A console account cannot be created without an email address.
- Reissuing a password ends every session of the account it belongs to, and is
  refused for a learner and for the acting administrator's own account.
