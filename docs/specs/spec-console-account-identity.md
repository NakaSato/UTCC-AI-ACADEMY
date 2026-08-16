---
id: SPEC-0043
type: spec
title: Console account identity, admin-created accounts, and the identifier model
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0043, ADR-0042, ADR-0024, SPEC-0042, SPEC-0024]
implemented_by:
  - app/models/user.rb
  - app/controllers/admin_controller.rb
  - app/controllers/console_sessions_controller.rb
  - app/controllers/registrations_controller.rb
  - app/views/admin/_users.html.erb
  - db/migrate/20260809200000_add_username_to_users.rb
  - db/seeds.rb
touches:
  - app/controllers
  - app/models
  - app/views/admin
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
  - test/controllers/registrations_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-ARCH-004]
min_reviewer_skills: [SKILL-SPEC-002]
---

# Console Account Identity, Admin-Created Accounts, and the Identifier Model

> [Specifications](README.md) ·
> [Console account identity decision](../decisions/adr-0043-console-account-identity.md) ·
> [Console sign-in specification](spec-console-sign-in.md)

## Problem

SPEC-0042 gave staff and company members their own door but not their own
identity: `users.student_id` was `NOT NULL`, so an instructor with no student
card and a recruiter who has never enrolled were both issued 13-digit student
numbers to make an account exist at all. The same rule made the accounts
uncreatable — sign-up demands an ID and refuses to grant a role, and an
organization invitation can only reach an account that is already there.

A console account needs a name of its own and a screen that makes one.

## Invariants

1. `users.student_id` is nullable, unique when present, and 13 digits when
   present. It is required only under the `:registration` validation context,
   which `RegistrationsController#create` saves in.
2. `users.username` is unique and optional, matching `User::USERNAME_FORMAT`:
   3–30 characters of `a-z`, `0-9`, `.`, `-`, `_`, starting and ending
   alphanumeric, containing at least one letter.
3. All three identifier columns normalize to lowercase, strip surrounding
   whitespace, and store blank as `NULL`, so a cleared field cannot collide
   under a unique index.
4. Every account holds at least one of student ID, username, or email address —
   `User#is_identifiable`. `User#identifier` returns the first present, in that
   order.
5. Console sign-in reads the identifier by shape: containing `@` → email,
   all digits → student ID, otherwise → username.
6. `POST /admin/console-accounts` is admin-only and accepts exactly `name`,
   `username`, and `email_address` as account attributes. `role` is never read
   from them; access comes from a whitelisted `access` param in
   `AdminConsole::CONSOLE_ACCESS` (`instructor`, `admin`, `company`).
7. `access: "company"` requires an **active** organization and creates the
   account and its active membership in one transaction, at an organization role
   `OrganizationMembership::ROLES` accepts. The account's `role` column stays
   `student`.
8. The first password comes from `User.generate_temporary_password`, always
   satisfies the password policy, is shown once in a flash, and is persisted
   only as a digest — not in the audit row, not in a log, not in an email.
9. Creating a console account writes one `console_account_created` audit event
   at `warn` level carrying the identifier, the name, and the access key.
10. Screens that used to print `user.student_id` print `User#identifier`; the
    admin roster search covers name, student ID, username, and email.
11. A console account cannot be created without an email address — the account
    has no student ID and its first password is shown once, so an address is its
    only self-service way back in.
12. `POST /admin/users/:id/password` is admin-only and reissues a console
    account's password under the same rules as the first one: generated, shown
    once, digest-only. It destroys every session of that account and writes a
    `console_password_reissued` audit event at `warn`. It refuses an account
    without console access, and refuses the acting administrator's own.

## Acceptance Criteria

- An account with no student ID, no username, and no email is invalid.
- An account with only a username, or only an email, is valid.
- Sign-up still refuses an account with no student ID.
- A username of `ab`, 31 characters, all digits, containing a space or `!`, or
  starting or ending with `-` is refused; `Wichai` is accepted as `wichai`.
- An admin creates an instructor account with no student ID, and it opens
  `/console` by username, in any case and with surrounding whitespace.
- An admin creates a company account; the user's role stays `student`, an active
  membership exists at the chosen organization role, and `console_access?` is
  true.
- A company account posted without an active organization creates nothing.
- An invalid organization role creates neither the account nor the membership.
- `access: "student"`, or any value outside the whitelist, creates nothing.
- A `role` posted among the account attributes does not change what is granted.
- A duplicate username creates nothing.
- The flash carries a generated password that authenticates the new account.
- The audit row is `warn`, names the identifier, and does not carry the password.
- A non-admin posting to the endpoint creates nothing and lands on `/`.
- A console account posted with a blank email address creates nothing.
- A reissued password authenticates the account, the previous password stops
  working, and every session of that account is gone.
- The roster offers the reissue control for console accounts and not for
  learners; posting it for a learner, or for the acting admin, changes no digest.
- The reissue audit row is `warn`, names the identifier, and omits the password.
- A non-admin cannot reissue a password.

## Verification

- `test/models/user_test.rb` covers the identifier model: the registration
  context, the at-least-one rule, username format and uniqueness, normalization,
  `identifier` fallback, and that generated passwords satisfy the policy.
- `test/controllers/admin_console_accounts_test.rb` covers every acceptance
  criterion for the creation screen, including the rollback, the whitelist, the
  ignored role, the one-time password, and the audit row.
- `test/controllers/admin_password_reissue_test.rb` covers the reissue: who is
  eligible, the session sweep, the one-time password, and the audit row.
- `test/controllers/console_sessions_controller_test.rb` covers sign-in by
  username for accounts that have no student ID at all.
- `test/controllers/registrations_controller_test.rb` continues to prove sign-up
  requires a student ID and cannot grant a role.
- `env RAILS_ENV=test bin/rails db:seed:replant` proves the seeds build the same
  three console accounts on an empty database; `bin/verify` runs the full gate.

### Walking it by hand

`db/seeds.rb` provisions one account per population, in development and test
only, all with the password `utcc2026`:

| Population | Signs in at | With |
| --- | --- | --- |
| Student | `/login` | `2011071730001` |
| Instructor | `/console` | `wichai` or `wichai@utcc.ac.th` |
| Administrator | `/console` | `utcc-admin` or `admin@utcc.ac.th` |
| Company owner | `/console` | `northstar` or `recruiter@northstar.co.th` |

The three console accounts carry no student ID and cannot sign in at `/login`.
Seeding a database that predates this change upgrades those rows in place —
matched by the student ID they used to have, which is then cleared.
