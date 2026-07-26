<img src="app/assets/images/utcc-eng-shield.svg" alt="UTCC" width="88" height="88">

# UTCC AI Academy by Upperclassman

A learning platform for UTCC students getting started with AI — a course catalog, lessons that grade an exercise and a coding task as you go, and progress that follows you across the app. Thai-first interface with an English toggle.

Rails 8.1 · Ruby 3.4.10 · SQLite · Hotwire (importmap, no Node)

![The course catalog — the first screen a signed-in student sees](docs/screenshots/catalog.png)

---

## Contents

- [Getting started](#getting-started)
- [Everyday commands](#everyday-commands)
- [The screens](#the-screens)
- [Accounts and roles](#accounts-and-roles)
- [Language](#language)
- [Design](#design)
- [How we work](#how-we-work)
- [Technical overview](#technical-overview)
  - [Stack](#stack)
  - [Repository layout](#repository-layout)
  - [Request path](#request-path)
  - [Data model](#data-model)
  - [Progress: the one thing that is recorded](#progress-the-one-thing-that-is-recorded)
  - [Placeholder content: the app's central pattern](#placeholder-content-the-apps-central-pattern)
  - [Authentication and authorization](#authentication-and-authorization)
  - [Routing](#routing)
  - [Views and layouts](#views-and-layouts)
  - [Frontend](#frontend)
  - [Internationalisation](#internationalisation)
  - [Infrastructure](#infrastructure)
  - [Tests and CI](#tests-and-ci)
- [What is real, and what is not](#what-is-real-and-what-is-not)

---

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

---

# Technical overview

## Stack

| Layer | Choice | Notes |
| --- | --- | --- |
| Framework | Rails 8.1, module `UtccAiFundamental` | `config.load_defaults 8.1` |
| Language | Ruby 3.4.10 | `Data.define`, endless methods, `it` block param, pattern matching |
| Database | SQLite (`sqlite3` >= 2.1) | one file in development and test; four in production |
| Web server | Puma, fronted by Thruster in the container | |
| Assets | Propshaft | no Sprockets manifest, no `app/assets/config/` |
| CSS | Tailwind v4 via `tailwindcss-rails` | standalone binary, no npm, no PostCSS |
| JS | importmap-rails + Turbo + Stimulus | no Node, no bundler, no `package.json` |
| Auth | Rails 8 `generate authentication` + `bcrypt` | cookie sessions in a table, no Devise |
| Background jobs | `solid_queue` | in-process under Puma |
| Cache | `solid_cache` | |
| WebSockets | `solid_cable` | nothing uses it yet |
| Deploy | Kamal + Docker | `config/deploy.yml` |
| Tests | Minitest (**not** RSpec), parallel | Capybara + selenium present, unused |
| Lint / security | `rubocop-rails-omakase`, Brakeman, bundler-audit, `importmap audit` | all wired into `bin/ci` |

There is **no Redis, no Memcached and no separate job runner** — every piece of infrastructure is a SQLite database.

## Repository layout

```
app/
  assets/tailwind/application.css   the whole stylesheet: @theme, @layer base, @utility
  controllers/
    concerns/authentication.rb      Current.user, require_authentication, session cookie
    concerns/authorization.rb       the allow_only macro
  helpers/application_helper.rb     nav items per role, footer columns per session
  javascript/controllers/           Stimulus, auto-registered by filename
  models/                           two Active Record classes; the rest are placeholder modules
  views/
    layouts/application.html.erb    app chrome
    layouts/auth.html.erb           split-screen sign-in/sign-up/reset
    shared/                         header, app header, footer, auth hero, language toggle
config/
  ci.rb                             the pipeline bin/ci runs
  locales/{th,en}.yml               every word a human reads
  routes.rb                         one line per verb, plain-English URLs
db/
  schema.rb                         users, sessions, topic_completions — that is all
  {queue,cache,cable}_schema.rb     the solid_* databases, kept separate on purpose
  seeds.rb                          fenced to Rails.env.local?; must stay idempotent
lib/tasks/admin.rake                bin/rails admin:create
docs/design-system.md               background on the earlier eng.utcc.ac.th port
```

## Request path

Every request goes through `ApplicationController`, which is short and does four things:

```ruby
class ApplicationController < ActionController::Base
  include Authentication      # adds a global before_action :require_authentication
  include Authorization       # after Authentication, so /login wins over a role redirect
  allow_browser versions: :modern
  stale_when_importmap_changes
  around_action :switch_locale
  helper_method :progress     # the header's gem and streak counters, on every screen
end
```

`progress` is `Current.user&.progress || LearnerProgress.new(nil)` — a null-object fallback so the helper is safe on the one screen that renders without a user.

Controllers below it are deliberately tiny: read a param, validate it against a whitelist, ask a module, assign. `ProgressController` is 238 bytes; `LeaderboardsController` is 154. **A param is never trusted and never raises** — each controller falls back to a default (`CourseCatalog::FILTERS.include?`, `LessonContent.step_for`, `Leaderboard.tab_for`, `AdminConsole.tab_for`). `AdminConsole.tab_for` matters twice over: the tab name is interpolated into a `render` path, so anything but a whitelisted value would be a template-injection foothold.

## Data model

Three tables. That is the whole schema (`db/schema.rb`, version `2026_07_26_093000`):

**`users`** — `student_id` (unique, 13 digits, normalised to lowercase and stripped), `name`, `password_digest`, `role` (default `"student"`, not null), optional `email_address` (unique), `faculty`, `study_year`.

```ruby
enum :role, ROLES.index_by(&:itself), default: "student", validate: true
```

`validate: true` is deliberate: the admin form posts a role from params, and without it an unknown value raises `ArgumentError` instead of failing validation.

**`sessions`** — `user_id`, `ip_address`, `user_agent`. Rails 8's generated authentication: the cookie holds a session id, so signing out is a row deletion.

**`topic_completions`** — `user_id`, `course_code`, `topic_key`, `learned_at` (not null), `applied_at` (nullable). Unique index on `[user_id, course_code, topic_key]`, plus `[user_id, learned_at]` for the activity grid.

One row per learner per topic, carrying both timestamps, because a topic cannot be applied without first being learned and the UI shows them as two bars over the same list. A topic is named by **strings, not foreign keys** — `course_code` from `CourseCatalog` and a `"<module>-<position>"` `topic_key` from `Syllabus` — and both are validated against those modules:

```ruby
validates :course_code, inclusion: { in: ->(_) { CourseCatalog.codes } }
validates :topic_key,   inclusion: { in: ->(_) { Syllabus.topic_keys } }
```

That validation is the whole reason this works without Course and Topic tables: a row can never name a course or topic that does not exist.

`TopicCompletion.record` is **idempotent** — a `find_or_initialize_by` that never moves a timestamp already set, and that fills both stamps when the first report is an `applied` one. The exercise and the coding task each report a pass on every run; re-running the lesson writes no second row and inflates no count.

## Progress: the one thing that is recorded

`LearnerProgress` is an ordinary class over those rows, and the worked example of what replacing a placeholder looks like — it kept the reader methods the views already called, so nothing in the views changed when it landed.

It loads a learner's rows **once** and folds them in Ruby rather than aggregating in SQL: the volume is one row per topic per student, the date arithmetic wants `Time.zone` rather than SQLite's, and the screens ask for six different cuts of the same rows.

The display conventions live in the class, not the table:

```ruby
XP_PER_LEARNED = 120     GEMS_PER_LEARNED = 5     XP_PER_LEVEL = 400
XP_PER_APPLIED = 60      GEMS_PER_APPLIED = 10    ACTIVITY_DAYS = 84  # 12 weeks, 28 to a row
```

Keep the gem values in step with the `gems` figures in the `quiz` and `code_task` Stimulus controllers — the sidebar counter moves client-side before the row is written.

What it derives: per-course counts, `courses` (the catalog with this learner's numbers filled in), the two My Learning tabs, totals and percentages **counted across started courses only**, `minutes_studied` (from the syllabus budget — wall-clock time is not recorded), XP, level, gems, `streak` (yesterday still counts as the head of a run), `learned_this_week`, the 84-day activity heat array, `rank` (nil until the learner records anything), and the dashboard's four tiles.

Denominators come from `Syllabus.topic_count` / `applied_topic_count`, not from per-course numbers. Every course therefore shows the same total — deliberate, because a course whose stat tile and progress bar disagreed could never be finished.

Recording happens **from the browser**: `rewards_controller.js` POSTs to `POST /lesson/complete` when `quiz` or `code_task` announces a pass (`kind: "learned"` and `"applied"`). `LessonsController#complete` whitelists the kind, calls `TopicCompletion.record`, and returns `201` with no body — nothing on the lesson screen reads the new totals. It is rate-limited to 30 in 3 minutes.

## Placeholder content: the app's central pattern

`app/models/` holds **two** Active Record classes (`User`, `TopicCompletion`, plus `Session`). Everything else is a module of frozen constants and `Data.define` value objects: `CourseCatalog`, `Syllabus`, `LessonContent`, `LearnerProfile`, `KnowledgeMap`, `Leaderboard`, `InstructorReport`, `Proctoring`, `AdminConsole`.

The split inside them is consistent:

- **Ruby holds numbers, taxonomy and shape** — course codes, credits, ratings, percentages, the tree structure, which module is locked.
- **The locale files hold every word.** The `Data` objects reach copy through `I18n.t` in their own methods: `course.title` is `I18n.t("catalog.courses.#{code}.title")`.

```ruby
Course = Data.define(:code, :credits, :rating, :projects, :hours, :level, :core,
                     :certificate, :tags, :learners, :learned, :applied, :next_key) do
  def topics = Syllabus.topic_count
  def title = I18n.t("catalog.courses.#{code}.title")
  def started? = learned.positive?          # no enrol button — the first finished topic is the enrolment
  def completed? = learned >= topics
end
```

⚠️ **Several joins between Ruby and the locale files are positional, not keyed.** `Syllabus::ENTRIES[i]` lines up with `course.modules[i]`; likewise `InstructorReport::HARD_TOPIC_PERCENTS`, `LearnerProfile::AWARDS`, `Leaderboard::FIGURES`, `LearnerProgress#dashboard_stats`, `LessonContent::BLOCKS`, and every `AdminConsole` array with its `admin.*` counterpart. Inserting a row in one place without the other silently shifts every label after it. `test/models/placeholder_content_test.rb` exists mainly to catch that, and asserts across **both** locales.

Replacing a placeholder with a real model means keeping the same reader methods — the views only ever call those.

## Authentication and authorization

Built on Rails 8's `bin/rails generate authentication`, plus a hand-written `RegistrationsController` since the generator omits sign-up.

- `Current.user` / `Current.session` (an `ActiveSupport::CurrentAttributes`) are how views read the signed-in user; `authenticated?` is the exposed helper, and the layouts branch on it.
- `start_new_session_for(user, remember: true)` backs the "remember me" checkbox — `remember: false` gives a session cookie instead of a permanent one.
- Sign-in, sign-up and password-reset `create` actions are each `rate_limit to: 10, within: 3.minutes`.
- `SessionsController#create` authenticates with `User.authenticate_by(params.permit(:student_id, :password))`.
- `PasswordsController#create` checks `params[:email_address].present?` before looking up — without it, a blank submission would match `email_address IS NULL` and reach one of the many accounts with no address. It always redirects to the same confirmation, so the screen never reveals whether an address has an account.
- `RegistrationsController#user_params` permits `:name, :student_id, :password, :password_confirmation`. **Do not add `:role`** — `test/controllers/registrations_controller_test.rb` fails if you do.

Authorization is a separate concern, included *after* `Authentication` so a signed-out visitor lands on `/login` rather than the catalog:

```ruby
def allow_only(*roles, **options)      # mirrors allow_unauthenticated_access:
  before_action(**options) { authorize_role(roles) }   # it names who is let in
end
```

Any `User` predicate works — `allow_only :staff` on `InstructorController` (staff is `instructor? || admin?`), `allow_only :admin` on `AdminController`. Denial is a redirect to `root_path` with a flash, matching how `CoursesController#show` handles an unknown course code.

`ApplicationHelper#app_nav_items` is built from the role, so a missing gate shows up as a link nobody can use. An admin gets a **different list entirely** (`admin_nav_items`) rather than the learner nav with staff entries bolted on. The desktop rail and the burger drawer both read that one list.

## Routing

Auth URLs read as plain English rather than as REST resources, and each screen has **one** helper covering both its GET and its POST — `login_path` is the form action as well as the link to it.

```ruby
get/post "login"                 → sessions#new/create        # login_path
delete   "logout"                → sessions#destroy
get/post "register"              → registrations#new/create   # register_path
get/post "forgot-password"       → passwords#new/create
get/put  "reset-password/:token" → passwords#edit/update

post "language/:locale" => "languages#update", constraints: { locale: /th|en/ }

resources :courses, only: :show, param: :code   # /courses/AI1101
get  "lesson"          => "lessons#show"        # ?step=theory|exercise|code|summary
post "lesson/complete" => "lessons#complete"
get   "my-learning"    => "my_learning#show"    # ?tab=progress|done
get   "map"            => "knowledge_maps#show" # ?topic=<node id>&mode=course|project
get   "progress"       => "progress#show"
get   "leaderboard"    => "leaderboards#show"   # ?tab=week|semester|university
get   "instructor"     => "instructor#show"
get   "admin"          => "admin#show"          # ?tab=features|overview|users|courses|queue|audit
patch "admin/users/:id" => "admin#update"
get   "up"             => "rails/health#show"
root "home#index"                               # catalog / admin / landing
```

The generator's old auth URLs (`/session/new`, `/passwords/:token/edit`, …) survive only as `redirect()`s so reset links already in inboxes still resolve; nothing in the app links to them.

## Views and layouts

Two layouts, sharing `shared/_head`:

- **`layouts/application`** — renders `shared/_app_header` (dark chrome: nav, language toggle, gems and streak counters, notifications, account menu) when signed in, `shared/_header` (marketing) when not. `shared/_footer` closes **every** screen either way; only its first two link columns branch on the session (`ApplicationHelper#footer_columns` — landing anchors signed out, app routes signed in, since `#learn` would scroll nowhere on `/progress`). Its copy lives under `chrome.footer.*`, not `landing.*`, because it is shared chrome.
- **`layouts/auth`** — used by `SessionsController#new`, `RegistrationsController#new` and `PasswordsController#new/edit` via `layout "auth", only: …`. No app chrome; a split screen with `shared/_auth_hero` on the left.

## Frontend

Add JS dependencies with `bin/importmap pin <pkg>` — never npm or yarn. It writes `config/importmap.rb` and vendors into `vendor/javascript`. Stimulus controllers are auto-registered by `pin_all_from`, and **the filename determines the identifier**.

| Controller | What it does |
| --- | --- |
| `header` | sticky header, mobile drawer |
| `dropdown` | notifications, account menu |
| `tabs` | segmented controls that navigate |
| `panels` | tabs whose panels are all already in the document — show/hide, optionally pushing a path and title |
| `quiz`, `code_task` | in-browser lesson grading |
| `rewards` | listens for the reward events those two emit, POSTs the completion |
| `proctor` | lesson integrity monitoring |
| `to_top` | back-to-top button |

Accordions are native `<details>` — no controller.

**State travels on `data-*` attributes and is read by Tailwind variants** (`data-[state=correct]:`, `data-[open=true]:`, `group-open:`, `aria-selected:`). Controllers set an attribute; they do not juggle class lists. Keep it that way when adding interaction. `header_controller` is the exception that proves the rule: it receives its pinned state as *several* utilities via `data-header-pinned-class`, so it uses `classList.add/remove(...this.pinnedClasses)` — `classList.toggle` takes only one class and will silently break if you switch back to it.

`proctor_controller` mounts only for `Current.user.student?`; staff get the same bar with the controls inert. Like the quiz and the coding task it runs entirely in the browser and persists nothing, so the integrity score resets on reload. The log row is a `<template>` in the view, cloned per incident, so no markup lives in JS.

**Lesson grading runs in the browser**, so the answer key (`LessonContent::CORRECT_OPTION`) and the passing regexes (`LessonContent::CHECKS`, compiled to `RegExp` in `code_task_controller`) are public. That is intentional for a teaching exercise; real grading belongs on the server once submissions persist.

## Internationalisation

```ruby
config.i18n.default_locale = :th
config.i18n.available_locales = %i[ th en ]
config.i18n.fallbacks = [ :en ]        # a key missing from th.yml renders English rather than raising
```

`ApplicationController#switch_locale` is an `around_action` reading `session[:locale]`; `LanguagesController#update` writes it. The route constraint `/th|en/` means an unsupported locale 404s at the router and never reaches `I18n`. The toggle partial takes a `dark:` local because it renders both on chrome and on light surfaces.

## Infrastructure

- In production the solid_* adapters live in **separate SQLite databases** (`storage/production_{queue,cache,cable}.sqlite3`), declared as extra entries under `production:` in `config/database.yml`, each with its own `migrations_paths`. Their schemas are `db/{queue,cache,cable}_schema.rb` — **do not fold these into `db/schema.rb`**.
- Development and test use a single `storage/development.sqlite3` / `storage/test.sqlite3`; the solid_* adapters are only wired up in `config/environments/production.rb`.
- Workers run **in-process**: `config/puma.rb` loads `plugin :solid_queue` when `SOLID_QUEUE_IN_PUMA` is set, which `config/deploy.yml` sets. `bin/jobs` runs the supervisor standalone; recurring jobs go in `config/recurring.yml`.
- `storage/` is a persistent Docker volume — that is where the production SQLite files live.
- `assets:precompile` builds Tailwind first, so the Dockerfile needs no extra step.
- `RAILS_MASTER_KEY` decrypts `config/credentials.yml.enc`. `config/deploy.yml` still carries the placeholder server `192.168.0.1` and registry `localhost:5555`.

## Tests and CI

Minitest, run in parallel (`parallelize(workers: :number_of_processors)`), loading all fixtures — keep tests isolated from shared mutable state. `test/test_helpers/session_test_helper.rb` provides `sign_in_as(user)` and `sign_out`, auto-included into integration tests.

| File | Covers |
| --- | --- |
| `controllers/app_screens_test.rb` | every signed-in screen renders, bad params fall back, every route redirects to login when signed out |
| `controllers/admin_test.rb` | the role gate and the only place a role is granted |
| `controllers/lesson_completion_test.rb` | the browser-to-record seam, and that a completion then shows on the screens that count it |
| `controllers/registrations_controller_test.rb` | sign-up, including that `:role` can never be mass-assigned |
| `controllers/languages_controller_test.rb` | the locale switch sticks across requests; an unroutable locale 404s |
| `models/placeholder_content_test.rb` | derived values and the positional locale wiring, in **both** locales |
| `models/learner_progress_test.rb`, `topic_completion_test.rb` | every counted figure, and what the table will and will not accept |
| `tasks/admin_task_test.rb` | `admin:create`, including promotion of an existing account |

Assertions compare against `I18n.t(...)` rather than literal strings, and are scoped (`assert_select "main h2"`) because the header nav links to AI1101 on every page — a copy change in a locale file should not break a test.

**`test/fixtures/topic_completions.yml` is deliberately empty and must stay present.** Tests that need progress record it themselves; the file exists so fixtures clear the table, because `bin/ci` seeds completions into the test database and those rows would otherwise outlive the users they point at.

`bin/ci` is the whole pipeline — there is no CI service and no GitHub workflow:

```
Setup → Style: Ruby → Gem audit → Importmap audit → Brakeman → Tests: Rails → Tests: Seeds
```

The seeds step runs `db:seed:replant` against the test database, so `db/seeds.rb` must stay runnable against a fresh one. **There are no system tests yet** — `test/system/` does not exist and that step stays commented out in `config/ci.rb` until it does.

---

## What is real, and what is not

**Users, sessions and progress are persisted; the learning material is not.**

A learner's progress is genuinely recorded — `topic_completions` holds one row per learner per topic, and the catalog, My Learning and the dashboard all count off it. Everything else is placeholder:

- **Courses, lessons and topics are not tables.** They are plain-Ruby modules of frozen constants in `app/models/`, which is why every course shares one syllabus and shows the same topic total.
- **A lesson's *content* is the same whichever topic you open.** `/lesson?course=AI1101&topic=2-3` is a real position in the syllabus: it decides what gets recorded, which module unlocks next, and where "continue" goes. But the prose, the quiz and the coding task behind it are one placeholder set — writing sixteen of them is a content job, not a modelling one.
- **Grading runs in the browser**, so the answer key is public and `POST /lesson/complete` trusts what it is told. A student can report a completion they did not earn — the same trust level as the answer key already being readable in the page. Server-side grading is the fix, and the completions table is the half of it that now exists.
- **The leaderboard and the instructor report are still frozen constants**, as are hearts, awards, badges, notifications and the "projects submitted" dashboard tile. The leaderboard in particular needs a section concept that `users` does not have.
- **`/admin` is the exception** — its Users tab is real records and the `role` column, and it is the only screen backed by the database rather than a module. Its other five tabs are placeholder.
- The landing page's content is still hardcoded in `HomeController#index`.

See `CLAUDE.md` for the conventions to follow when changing any of this, and `docs/process.md` for how the team works — sprints, roles, the four Scrum events, and what "done" means here.
