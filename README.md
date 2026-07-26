# UTCC AI Fundamental

A learning platform for UTCC students getting started with AI — a course catalog, lessons that grade an exercise and a coding task as you go, and progress that follows you across the app. Thai-first interface with an English toggle.

Rails 8.1 · Ruby 3.4.10 · SQLite · Hotwire (importmap, no Node)

![The course catalog — the first screen a signed-in student sees](docs/screenshots/catalog.png)

## Getting started

```bash
bin/setup      # install gems, prepare the database, then start the server
bin/dev        # start the server on http://localhost:3000
```

Use `bin/dev` rather than `bin/rails server` — it runs the Tailwind watcher alongside Puma, so CSS changes actually rebuild.

`bin/setup` seeds four demo accounts (development and test only). Password `utcc2026` for all of them:

| Student ID | Who |
| --- | --- |
| `2011071730001` | student, with a few topics already finished |
| `2011071730002` | student, further along |
| `2011071730801` | instructor |
| `2011071730802` | admin |

## Everyday commands

```bash
bin/rails test                             # run the tests
bin/rails test test/models/user_test.rb:12 # run one test
bin/ci                                     # the full pipeline: lint, security scans, tests (run locally — there is no CI service)
bin/rubocop -a                             # autocorrect style
bin/rails admin:create                     # create or promote an admin
```

## The screens

`/` is two different pages: a marketing landing page for a signed-out visitor, and the course catalog once you sign in. Behind the login there are eight screens — catalog, course, lesson, my learning, knowledge map, progress, leaderboard, instructor — plus `/admin`.

Screen state lives in the query string rather than in client-side JS: filter chips, lesson steps, tabs and the selected node on the knowledge map are all plain links, so any view of a screen is a URL you can share.

## Accounts and roles

Students sign in with their **student ID** — 13 digits, as printed on the student card — not an email. Sign-up asks for a name, that ID and a password; an email address is optional and only matters for password reset.

- `/register` — sign up
- `/login` — sign in
- `/forgot-password` — request a reset link (only reaches accounts that have an email)
- `/reset-password/:token` — set a new password

A password is 8–72 characters with at least one letter and one digit, is not one of the handful everyone tries first, and is not the student's own ID.

The landing page is public; everything else requires an account, because `ApplicationController` applies `require_authentication` globally — a new public action must opt out with `allow_unauthenticated_access`.

`users.role` is `student`, `instructor` or `admin`, and admin is a superset of instructor. Sign-up always produces a student. `/instructor` needs staff, `/admin` needs admin, and `/admin` is the only place a role can be granted — so the **first** admin comes from `bin/rails admin:create`. An admin's home is `/admin`, not the catalog.

No mail delivery is configured in development (`raise_delivery_errors = false`), so reset emails go nowhere. Preview the template at `/rails/mailers`, or grab the reset URL from `log/development.log`.

## Language

Thai is the default locale, English the fallback, and the toggle lives in the header. **Every word a human reads is in `config/locales/{th,en}.yml`** — the Ruby side holds only numbers, taxonomy and shape. The two files are 1:1 in structure, and several values are arrays consumed by index, so a key added to one must be added to the other at the same position.

The toggle posts to `POST /language/:locale` rather than linking to it: Turbo prefetches links on hover, and a GET would switch language just by pointing at the button.

## Design

Crimson `#A81E32` on cream, IBM Plex Sans Thai, Tailwind v4 through `tailwindcss-rails` (still no Node, no npm).

**`app/assets/tailwind/application.css` is the entire stylesheet and the single source of truth for the visual tokens** — an `@theme` block, a small `@layer base`, and a handful of `@utility` escape hatches for gradients and clip-paths that cannot be expressed as utilities. There are no component classes: recipes are repeated as utilities in the markup, and no hex value belongs anywhere but that `@theme` block. Read it before making visual changes.

`docs/design-system.md` documents the **earlier** port from [eng.utcc.ac.th](https://eng.utcc.ac.th) (maroon, Noto Sans Thai Looped, daisyUI anatomy). The app UI has since moved on — treat that document as background on the reference site, not as a description of the current tokens.

## What is real, and what is not

**Users, sessions and progress are persisted; the learning material is not.**

A learner's progress is genuinely recorded — `topic_completions` holds one row per learner per topic, and the catalog, My Learning and the dashboard all count off it. Everything else is placeholder:

- **Courses, lessons and topics are not tables.** They are plain-Ruby modules of frozen constants in `app/models/`, which is why every course shares one syllabus and shows the same topic total. Controllers are three or four lines: read a param, ask a module, assign.
- **Grading runs in the browser**, so the answer key is public and `POST /lesson/complete` trusts what it is told. A student can report a completion they did not earn. Server-side grading is the fix, and the completions table is the half of it that now exists.
- **The leaderboard and the instructor report are still frozen constants**, as are hearts, awards, badges and notifications.
- **`/admin` is the exception** — its Users tab is real records, and it is the only screen backed by the database rather than a module. Its other five tabs are placeholder.
- The landing page's content is still hardcoded in `HomeController#index`.

See `CLAUDE.md` for the architecture in detail.
