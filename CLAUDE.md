# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

A learning platform for UTCC students getting started with AI. Rails 8.1, Ruby 3.4.10, module `UtccAiFundamental`.

`/` is **two different pages**: a marketing landing page for signed-out visitors, and the course catalog for a signed-in student (`HomeController#index` branches on `authenticated?` and renders `home/catalog` or `home/index`). An **admin is redirected to `/admin`** — the admin screen is their index, so the logo and the first nav slot both lead there and the catalog is not part of their app. Behind the login there are eight screens — catalog, course, lesson, my learning, knowledge map, progress, leaderboard, instructor.

**Users, sessions and topic completions are persisted; nothing else is.** There are still no Course/Lesson/Topic tables — every screen's *content* comes from plain-Ruby placeholder modules in `app/models/` (see below) — but a learner's **progress is real**, counted off `topic_completions`. See "Progress" below for what that covers and what it does not.

Bilingual, Thai-first: `default_locale = :th`, English as fallback, a toggle in the app header and on the auth screens — **not** on the marketing header, so a signed-out visitor to `/` has no way to switch (see the landing-page exception below).

**Three names, all current, none a typo.** The product is *UTCC AI Academy by Upperclassman*, the Kamal service and image are `utcc_ai_academy`, and the Rails module is still `UtccAiFundamental` — the app was renamed and the constant was deliberately left alone, since renaming it touches every environment file and the encrypted credentials for no user-visible gain. Do not "fix" the module to match the repo.

## Other docs, and which one wins

- **`README.md`** is written for a human joining the project, and its second half ("Technical overview" onward) covers the same ground as this file — stack, layout, request path, data model, auth, routing, tests. **The two must not drift.** An architectural change here needs the matching README section updated in the same commit; that is where the eight screens and the setup path are explained for a person who has never run the app.
- **`docs/process.md`** — the team's Scrum process: two-week sprints, the four events, and a definition of done that points back at the invariants in this file. Read it before proposing what to build next; it also fixes the dependency order of the remaining work.
- **`docs/design-system.md`** — background on the reference site, **not** the current tokens. See "Design system" below; the CSS wins.
- **`.claude/skills/`** — four project skills (`explore-codebase`, `debug-issue`, `refactor-safely`, `review-changes`) that drive the code-review-graph MCP tools. Prefer them over hand-rolling a search.

## Commands

```bash
bin/setup              # install gems, db:prepare, clear logs/tmp, then exec bin/dev
bin/setup --skip-server # same without booting the server
bin/dev                # foreman: rails server + tailwindcss:watch (Procfile.dev)
bin/ci                 # full local CI pipeline (steps defined in config/ci.rb)

bin/rails tailwindcss:build   # one-off CSS build into app/assets/builds/tailwind.css
bin/rails tailwindcss:watch   # rebuild on change (what bin/dev runs)

bin/rails admin:create        # create or promote an admin — the only way to get the first one
bin/rails instructor:create   # create or promote an instructor — never demotes an admin
```

`bin/dev` is required for CSS changes to take effect — `bin/rails server` alone serves whatever `app/assets/builds/tailwind.css` was last built. `assets:precompile` builds Tailwind first, so the Dockerfile needs no extra step.

Tests (Minitest, not RSpec):

```bash
bin/rails test                          # all tests except system tests
bin/rails test test/models/foo_test.rb  # single file
bin/rails test test/models/foo_test.rb:42  # single test by line number
bin/rails db:test:prepare test          # from a clean test database
```

**There are no system tests yet** — `test/system/` does not exist, so `bin/rails test:system` has nothing to run. Capybara and `selenium-webdriver` are in the Gemfile's `:test` group ready for the first one; add it there and uncomment the step in `config/ci.rb`.

Lint and security (each is also a `bin/ci` step):

```bash
bin/rubocop            # rubocop-rails-omakase style; -a to autocorrect
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit      # gem CVEs; ignore entries go in config/bundler-audit.yml
bin/importmap audit    # JS dependency CVEs
```

`bin/ci` also runs `env RAILS_ENV=test bin/rails db:seed:replant`, so `db/seeds.rb` must stay runnable against a fresh test database. The system-test step is commented out in `config/ci.rb` — leave it that way until `test/system/` actually has something in it.

There is no CI service and no GitHub Actions workflow — `.github/` holds only `dependabot.yml`, and `bin/ci` is the whole pipeline, run locally. `docs/process.md` makes "`bin/ci` passes on your machine" the definition of done, so treat a green run as the shipping gate rather than a formality.

## Software system design

A server-rendered monolith: one Puma process, one SQLite file, no API layer, no client-side router, no external service. Every screen is a full HTML response that Turbo Drive swaps in. Hold that shape — most of the decisions below only make sense because nothing is distributed.

### Layers, and which way the arrows point

```
browser ──▶ routes ──▶ controller ──▶ ┌─ content module ─┐ ──▶ I18n (th/en)
                          │           └─ Active Record ──┘
                          └──▶ view ──▶ reader methods on the object it was handed
```

- **Views call reader methods and nothing else.** No queries, no `I18n.t` for content (they ask `course.title`, which does the lookup). A view that reaches past its assigned object is the smell that a module is missing a method.
- **Controllers hold no domain logic.** Read a param, validate it against a whitelist, ask a module, assign. If a controller grows a calculation, it belongs on the `Data` object or in `LearnerProgress`. **`HomeController#landing` is the one exception** — see "The landing page is the exception to both rules" below before touching it.
- **`Data` objects are the presenters.** There is no presenter/serializer/service-object layer, and adding one would duplicate what `Data.define … do … end` already does.
- **The dependency arrow runs from the persisted side to the placeholder side, not the other way.** `TopicCompletion` validates `course_code` against `CourseCatalog.codes` and `topic_key` against `Syllabus.topic_keys`. That inversion is the whole trick: a real table can reference a taxonomy that has no tables yet, and the strings stay honest until they do.
- **`LearnerProgress` is the only bridge.** It is the one object that reads records and returns placeholder value objects (`CourseCatalog::Course` with the counts filled in). Keep it the only one — if a second class starts joining the two sides, the seam stops being replaceable.

### Where state lives

| State | Home | Survives |
| --- | --- | --- |
| Screen state — filter, lesson step, tab, selected map node | the **query string** | reload, bookmark, sharing |
| Who you are | signed `httponly` cookie holding a `sessions` row id, `same_site: :lax` | permanent when "remember me", browser session otherwise |
| Language | `session[:locale]` | the session |
| Learning progress | `topic_completions` | forever |
| Identity and role | `users` | forever |
| Quiz answers, coding-task attempts, proctor score, the optimistic gem counter | **browser memory only** | nothing — reload resets them |

The rule that follows: **nothing that must survive a reload may live only in JS**, and nothing that must be shareable may live only in the session. A new piece of screen state goes in the URL by default.

### Request lifecycle of one signed-in screen

1. Thruster → Puma → Rails.
2. `require_authentication` resolves `Current.session` from the signed cookie, or stashes `return_to_after_authenticating` and redirects to `/` with `flash.sign_in_required`.
3. `allow_only` runs next where a controller declares it — after authentication, so a signed-out visitor gets the "sign in" flash rather than the "staff only" one.
4. `switch_locale` wraps the action in `I18n.with_locale`.
5. The action validates its params against a whitelist and assigns from a module.
6. The view renders; the `progress` helper loads the learner's completions **once** (memoised on the `User`) and every counter, bar and tile folds off that one array.
7. Turbo Drive swaps the body on the next navigation; no JSON crosses the wire.

### Trust boundaries

The browser is untrusted, with one deliberate, documented exception.

- **Lesson grading is on the client**, so the answer key and the passing regexes are public and `POST /lesson/complete` believes what it is told. Accepted for a teaching exercise; mitigated only by `rate_limit to: 30, within: 3.minutes` and by `TopicCompletion.record` being idempotent, so the worst case is a student marking their own topics done. Server-side grading is the fix and the table is the half of it that exists.
- **Every param is whitelist-or-default.** `AdminConsole.tab_for` is the one where it is a security control rather than a nicety — the tab name is interpolated into a `render` path.
- **`role` is never mass-assignable.** Sign-up permits four attributes and `:role` is not among them; the only grant is `AdminController#update`, behind `allow_only :admin`.
- **No user enumeration on password reset** — `PasswordsController#create` redirects identically whether or not the address exists, and checks `present?` first so a blank submission cannot match the many accounts with a null email.
- **Rate limits** on sign-in, sign-up, password reset (10/3min) and lesson completion (30/3min).
- Password max length is 72 because that is bcrypt's ceiling — anything longer is silently ignored, so accepting it would be a lie.
- Brakeman, bundler-audit and `importmap audit` are `bin/ci` steps, not optional extras.

### Invariants

Break one of these and something rots quietly rather than failing loudly:

1. One `topic_completions` row per learner per topic, and `record` never moves a timestamp already set.
2. Every row names a course and topic that exist — enforced by validation, not by convention.
3. `th.yml` and `en.yml` stay 1:1 in structure, and every positionally-indexed array keeps the same length **and order** in both.
4. At least one admin always exists — guaranteed solely by an admin being unable to change their own role.
5. Sign-up only ever produces a student.
6. `test/fixtures/topic_completions.yml` stays present and empty.
7. Denominators come from `Syllabus`, so a course's stat tile and its progress bar can never disagree.
8. Reader-method names are the public interface of a content module. Renaming one is a view change; keeping one is what makes the module replaceable.

### Performance and scale

Sized for a classroom, not a public site, and the design leans on that.

- **The N+1 that isn't:** `LearnerProgress` issues one query for a learner's rows and folds them in Ruby for six different cuts. Adding a per-course query to a view would undo it.
- **The known hotspot is `LearnerProgress.standings`** — two grouped counts over the *entire* `topic_completions` table, run on every render that shows a rank. Correct and cheap at a few thousand rows; it is the first thing to cache or denormalise when it is not.
- Nothing uses `Rails.cache` yet. `stale_when_importmap_changes` gives HTML responses an etag; Thruster handles asset caching and compression.
- One writer: SQLite, single process, workers in-process under Puma. Horizontal scale is not available without changing the database, so do not design as if it were.
- The only enqueued work in the whole app is the password-reset email (`deliver_later`). Solid Queue is wired up for it in production and nothing else uses it.

### Evolving a placeholder into a real model

`LearnerProgress` is the worked example; the recipe generalises:

1. **Keep the reader names.** The views only ever call those, which is why they did not change when progress became real.
2. Add the table and the migration; leave the module's public methods alone.
3. Point the module's `all` (or `for(user)`) at the records. The `Data` object can stay — it makes a fine read model over a row.
4. Move copy out of the locale files last, or not at all. Instructor-authored text wants columns; UI chrome wants locales.
5. Turn the string validations in `TopicCompletion` into foreign keys once Course and Topic tables exist.
6. Update `placeholder_content_test.rb` — it is the test that knows about the positional locale joins.

Dependency order for the remaining work, because each unlocks the next: **Course/Topic tables** (they anchor the strings everything else references) → **submissions** (which is what makes server-side grading possible) → **sections/cohorts** (which the leaderboard and `InstructorReport` are both waiting on) → **projects, awards, notifications**.

### What this design deliberately lacks

No API layer, no service objects, no presenters, no form objects, no Redis, no Node, no client-side router, no state manager, no component CSS classes. Each absence is a decision, not an oversight. Reach for one only when a concrete problem in this codebase demands it — the app is small enough that the abstraction usually costs more than the duplication it removes.

## Placeholder content: the app's central pattern

`app/models/` holds no Active Record classes for the learning material. It holds **modules of frozen constants plus `Data.define` value objects**: `CourseCatalog`, `Syllabus`, `LessonContent`, `LearnerProfile`, `KnowledgeMap`, `Leaderboard`, `InstructorReport`, `Proctoring`, `AdminConsole`. Controllers are three or four lines each — read params, ask a module, assign.

`AdminConsole` is the one with a real neighbour: the console's **Users** tab is genuinely persisted (the `role` column, `AdminController#update`), while its other five tabs are placeholder like everything else. Do not fold the roster into the module.

`LearnerProfile` used to hold a learner's whole state and now holds only what nothing records yet — hearts, awards, badges, notifications. Its counted half moved to `LearnerProgress`, which is an ordinary class over `topic_completions`.

The split is deliberate and consistent:

- **Ruby holds numbers, taxonomy and shape** — course codes, percentages, the tree structure, which module is locked.
- **`config/locales/{th,en}.yml` holds every word a human reads** — everywhere behind the login. The `Data` objects reach copy through `I18n.t` in their own methods (`course.title` is `I18n.t("catalog.courses.#{code}.title")`).

### The landing page is the exception to both rules

`app/views/home/index.html.erb` and `HomeController#landing` break the pattern the rest of the app follows, and they are the likeliest place to waste time looking for a module or a locale key that does not exist:

- **Its copy is hardcoded Thai, not I18n.** The view calls `t` for none of its own text — two dozen-odd lines of Thai sit inline in the ERB, and five more arrays of it (`@topics`, `@tracks`, `@shares`, `@events`, `@faqs`) are literals in the controller's private `landing` method. **The landing page body is therefore Thai-only**, which is why `shared/_header` carries no language toggle — it would offer a switch that changes almost nothing on the page. The `landing.*` namespace in the locale files covers only that marketing header and the footer chrome.
- **It is the only controller holding content.** Nothing in `app/models/` describes the landing page, so "add a section to the landing page" means editing the controller and the view, not a placeholder module.

Both are the same debt as the rest of the placeholder content, just parked one layer higher. Moving that copy into locale files (and the arrays into a module, if it earns one) is the fix; until then do not read the "no copy in controllers" and "no words outside locales" rules as describing this file.

**Several of these joins are positional, not keyed** — `Syllabus::ENTRIES[i]` lines up with `course.modules[i]` in the locale file (and its topics with `course.modules[i][:topics][j]`, which is what a `"<module>-<position>"` topic key points into), `InstructorReport::HARD_TOPIC_PERCENTS[i]` with `instructor.hard_topics[i]`, `LearnerProfile::AWARDS[i]` with `my_learning.awards[i]`, `Leaderboard::FIGURES[i]` with `leaderboard.leaders[i]`, `LearnerProgress#dashboard_stats` with `progress.stats[i]`, `LessonContent::BLOCKS[i]` with `lesson.theory.blocks[i]`, and every `AdminConsole` array with its `admin.*` counterpart (`STATS`, `ADOPTION`, `HEALTH`, `COURSES`, `QUEUE_KINDS`, `AUDIT_LEVELS`, plus `FLAG_GROUPS` which nests one level deeper). Inserting a row in one place without the other silently shifts every label after it. `test/models/placeholder_content_test.rb` exists mainly to catch that, and asserts across **both** locales.

Replacing a placeholder with a real model means keeping the same reader methods; the views only ever call those. `LearnerProgress` is the worked example — see below.

## Progress: the one thing that is recorded

`topic_completions` is the only table about learning. **One row per learner per topic**, carrying `learned_at` and a nullable `applied_at` — learning a topic and applying it are one row, because a topic cannot be applied without first being learned, and the UI shows them as two bars over the same list.

A topic is named by strings, not foreign keys: `course_code` from `CourseCatalog` and a `"<module>-<position>"` `topic_key` from `Syllabus`. Both are validated against those modules in `TopicCompletion`, so a row can never name a course or topic that does not exist. That is the whole reason this works without Course/Topic tables.

- **`TopicCompletion.record` is idempotent** — it is a `find_or_initialize_by` that never moves a timestamp already set. The exercise and the coding task each report a pass on every run; re-running the lesson writes no second row and inflates no count.
- **`LearnerProgress` is where completions become figures.** XP and gems per topic, how long a level is, what counts as a streak day — all display conventions, all in that class rather than in the table. It loads a learner's rows once and folds them in Ruby (the date arithmetic wants `Time.zone`, and the screens ask for six different cuts of the same rows).
- **`ApplicationController#progress` is a `helper_method`**, so any view can ask; `User#progress` memoises it per instance.
- **`CourseCatalog.for(user)` / `LearnerProgress#courses`** return the ordinary `CourseCatalog::Course` values with `learned`, `applied` and `next_key` filled in, so the catalog, My Learning and the dashboard all render the same object and the views did not change when this landed.

Recording happens from the browser: `rewards_controller.js` POSTs to `POST /lesson/complete` when `quiz` or `code_task` announces a pass (`kind: "learned"` and `"applied"` respectively), sending the course and topic the lesson was about. **That means a student can post a completion they did not earn** — the same trust level as the answer key already being public. Server-side grading is the fix, and this table was the missing half of it.

### A lesson is a position in a syllabus

`/lesson?course=AI1101&topic=2-3&step=code`. Both params are optional and both resolve rather than raise:

- **no `course`** → `LessonContent::DEFAULT_COURSE`;
- **no `topic`** → the learner's first unfinished topic in that course (`course.next_key`), or the last one once they all are. "Continue" links across the app are therefore just `lesson_path(course:)`.

The **prose, the quiz and the coding task are the same whichever topic is open** — writing sixteen of each is a content job, not a modelling one. Only the identity is real, and it is what the completion is filed under.

**Links inside a lesson must use `lesson_step_path(step)`** (`ApplicationHelper`), not `lesson_path(step:)`. A bare `lesson_path` resolves to whatever topic the learner is next on, so stepping through a topic they went *back* to would silently jump forward.

### Locking is a real gate

`Syllabus` derives module status from what a learner has finished rather than storing it: **done** when every one of its topics is, **now** for the first that is not, **locked** after that. `Syllabus.unlocked?(key, done_keys)` is the one rule, and it is enforced in three places that must agree — the course page does not link a locked topic, `LessonsController#show` redirects to the course with `flash.topic_locked`, and `#complete` answers `403`. `#complete` checks it again on purpose: a POST does not have to come from that screen.

A consequence worth knowing: **a brand-new account can only open module 1.** That is correct behaviour, not a bug in the seeds.

Denominators come from `Syllabus`, not from per-course numbers: `Syllabus.topic_count` and `applied_topic_count` are counted off `ENTRIES`, and every course reuses the one placeholder syllabus. That is why every course shows the same total — and it is deliberate, because a course whose stat tile and progress bar disagreed could never be finished.

**Still placeholder, and waiting on something to record them:** hearts/lives, the award shelf and badge row (`LearnerProfile`), notifications, the "projects submitted" dashboard tile, the whole `Leaderboard` (it needs a section concept that `users` does not have) and `InstructorReport`.

## Internationalisation

- `config/application.rb`: `default_locale = :th`, `available_locales = %i[th en]`, `fallbacks = [:en]` — a key missing from `th.yml` renders the English rather than raising.
- `ApplicationController` has `around_action :switch_locale`, which reads `session[:locale]`. `LanguagesController#update` writes it.
- The route is **POST** `language/:locale` with a `/th|en/` constraint. It is POST on purpose: Turbo prefetches links on hover, and a GET would switch language just by pointing at the toggle. The constraint means an unsupported locale 404s at the router and never reaches `I18n`.
- `th.yml` and `en.yml` are 1:1 in structure — add a key to both. Some values are **arrays consumed by index** (see above); keep their length and order identical across the two files.
- The toggle partial (`shared/_language_toggle`) has exactly two render sites — `shared/_app_header` (signed in) and `shared/_auth_hero` (the auth screens, which pass `dark: true`). It takes that `dark:` local because it sits on the chrome field in one place and on a light surface in the other. The marketing header does not render it at all.

## Routing and layouts

```ruby
resources :courses, only: :show, param: :code   # /courses/AI1101
get  "lesson"          => "lessons#show"        # ?course=AI1101&topic=2-3&step=theory|exercise|code|summary
post "lesson/complete" => "lessons#complete"    # the browser reporting a passed step
get "my-learning" => "my_learning#show"         # ?tab=progress|done
get "map"         => "knowledge_maps#show"      # ?topic=<node id>&mode=course|project
get "progress"    => "progress#show"
get "leaderboard" => "leaderboards#show"        # ?tab=week|semester|university
get "instructor"  => "instructor#show"
get "privacy"     => "policies#privacy"         # public — the PDPA notice
get "terms"       => "policies#terms"           # public — terms of use
get "admin"       => "admin#show"               # ?tab=features|overview|users|courses|queue|audit
patch "admin/users/:id" => "admin#update"       # admin_user_path — the only role grant in the app
root "home#index"                               # catalog signed in, /admin for an admin, landing when not
```

Screen state lives in the **query string**, not in client-side JS — filter chips, lesson steps, tabs and the map's selected node are all links. Controllers validate the param and fall back to a default rather than raising (`CourseCatalog::FILTERS.include?`, `LessonContent.step_for`, `Leaderboard.tab_for`, `AdminConsole.tab_for`). `AdminConsole.tab_for` matters twice over: the tab name is interpolated into a `render` path, so anything but a whitelisted value would be a template-injection foothold. The knowledge map derives which groups are expanded from the path to the selected node, so the URL alone determines the tree's state.

Two layouts:

- `layouts/application` — renders `shared/_app_header` (dark app chrome: nav, language toggle, gems/streak counters, notifications, account menu) when signed in, `shared/_header` (marketing) when not. `shared/_footer` closes **every** screen either way; only its first two link columns branch on the session (`ApplicationHelper#footer_columns` — landing anchors signed out, app routes signed in, since `#learn` would scroll nowhere on `/progress`). Its copy lives under `chrome.footer.*`, not `landing.*`, because it is shared chrome.
- `layouts/auth` — used by `SessionsController#new`, `RegistrationsController#new`, `PasswordsController#new/edit` via `layout "auth", only: …`. No app chrome; a split screen with `shared/_auth_hero` on the left.

`shared/_head` is shared by both layouts — the layouts differ only in what wraps `<body>`.

## Architecture notes

**All infrastructure is SQLite + database-backed.** There is no Redis, Memcached, or separate job runner:

- `solid_queue` for Active Job, `solid_cache` for `Rails.cache`, `solid_cable` for Action Cable.
- In production these live in *separate* SQLite databases (`storage/production_{queue,cache,cable}.sqlite3`) declared as extra entries under `production:` in `config/database.yml`, each with its own `migrations_paths` (`db/queue_migrate`, etc.). Their schemas are `db/{queue,cache,cable}_schema.rb` — do not fold these into `db/schema.rb`.
- Workers run in-process: `config/puma.rb` loads `plugin :solid_queue` when `SOLID_QUEUE_IN_PUMA` is set, which `config/deploy.yml` sets. `bin/jobs` runs the supervisor standalone. Recurring jobs go in `config/recurring.yml`.
- Development and test use a single `storage/development.sqlite3` / `storage/test.sqlite3`; the solid_* adapters are only wired up in `config/environments/production.rb`.

**Frontend is importmap + Hotwire, still no Node.** Add JS dependencies with `bin/importmap pin <pkg>` (writes to `config/importmap.rb`, vendors into `vendor/javascript`) — never npm/yarn. Stimulus controllers in `app/javascript/controllers/` are auto-registered via `pin_all_from`; the filename determines the identifier. Assets are served by Propshaft (no Sprockets manifest, no `app/assets/config/`). CSS is Tailwind v4 via `tailwindcss-rails`, which ships a standalone binary — no npm, no `package.json`, no PostCSS config.

**Deployment is Kamal + Docker**, configured in `config/deploy.yml` (currently placeholder server `192.168.0.1` and registry `localhost:5555`). `storage/` is a persistent Docker volume — that's where the production SQLite files live. Thruster fronts Puma in the container. `RAILS_MASTER_KEY` decrypts `config/credentials.yml.enc`.

Ruby style is modern and terse throughout — `Data.define` with endless methods, `class << self`, `it` as the implicit block parameter, pattern matching in `case/in`. Match it.

## Authentication

Built on Rails 8's `bin/rails generate authentication` (cookie sessions in a `sessions` table, no Devise), plus a hand-written `RegistrationsController` since the generator omits sign-up.

- **Everything requires login by default.** `ApplicationController` includes `Authentication`, whose `included do` block adds a global `before_action :require_authentication`. Any publicly reachable action must opt out with `allow_unauthenticated_access` — only `HomeController#index`, `LanguagesController` and `PoliciesController` do. Forgetting it is the usual cause of an unexpected redirect to the landing page carrying `flash.sign_in_required`.
- `Current.user` / `Current.session` (an `ActiveSupport::CurrentAttributes`) are how views read the signed-in user; `authenticated?` is the exposed helper method, and layouts branch on it.
- **Authorization is a separate concern from authentication.** `users.role` is a string column defaulting to `"student"`, declared on `User` as `enum :role, ROLES.index_by(&:itself), default: "student", validate: true`. `validate: true` is deliberate: the admin form posts a role from params, and without it an unknown value raises `ArgumentError` instead of failing validation.
  - **admin is a superset of instructor.** `User#staff?` is `instructor? || admin?`, so a staff-wide gate needs no second rule for admins.
  - `Authorization` (`app/controllers/concerns/authorization.rb`) is included in `ApplicationController` **after** `Authentication`. Both denials now redirect to `root_path` with a flash, so the ordering is what decides *which* flash: a signed-out visitor gets `flash.sign_in_required` from `require_authentication` rather than the misleading `flash.forbidden`. Its `allow_only` macro mirrors `allow_unauthenticated_access` — it names who is let in, and any `User` predicate works: `allow_only :staff` on `InstructorController`, `allow_only :admin` on `AdminController`. Denial is a redirect to `root_path` with `flash[:alert]`, matching `CoursesController#show`'s handling of an unknown course code.
  - **`ApplicationHelper#app_nav_items` is built from the role** — the instructor entry is appended only for the roles that can open it, so a gate that is missing shows up as a link nobody can use. An admin gets a **different list entirely** (`admin_nav_items`: admin, then instructor) rather than the learner nav with staff entries bolted on — `/` only redirects them back to `/admin`, so the catalog, the AI1101 shortcuts and the learner screens are not part of their app. The desktop rail and the burger drawer both read that one list.
  - `/admin` (`AdminController`) is the **only** screen backed by real records rather than a placeholder module, and the only place a role is granted — sign-up always produces a student, and `RegistrationsController#user_params` never whitelists `role`. **Do not add `:role` to that list**; `test/controllers/registrations_controller_test.rb` fails if you do. An admin cannot change their own role; since only an admin reaches the action, that single rule is what guarantees at least one admin always survives.
  - **The first admin comes from `bin/rails admin:create`** (`lib/tasks/roles.rake`) — /admin cannot grant it, since opening /admin already requires the role, and `db/seeds.rb` is fenced to `Rails.env.local?`. The task prompts when attached to a terminal and reads `ADMIN_STUDENT_ID` / `ADMIN_NAME` / `ADMIN_PASSWORD` when not, so it also works over `kamal app exec`. An existing account with that student ID is promoted rather than duplicated.
  - **`bin/rails instructor:create`** sits beside it in the same file and behaves identically, reading `INSTRUCTOR_STUDENT_ID` / `INSTRUCTOR_NAME` / `INSTRUCTOR_PASSWORD`. Both go through `RoleTask.grant`, which takes the predicate that counts as already holding the role. For admin that is `admin?`; for instructor it is **`staff?`, not `instructor?`** — admin is a superset, so writing the role onto an admin would demote them, and demoting the only admin is the one way around invariant 4. An admin is therefore reported and left alone.
- `start_new_session_for(user, remember: true)` backs the "remember me" checkbox — `remember: false` gives a session cookie instead of a permanent one.
- `User` validates a password of 8–72 characters (`PASSWORD_LENGTH`) that contains a letter and a digit, is not in `COMMON_PASSWORDS`, and does not contain the student's own ID. A weak password in a test will fail validation rather than the assertion you intended — `"password"` and `"12345678"` are both rejected now.
- Sign-in, sign-up and password-reset `create` actions are all `rate_limit to: 10, within: 3.minutes`.
- Routes are spelled out one line per verb rather than declared as REST resources, so the URL a student sees is the plain English word for the screen:

  ```ruby
  get/post "login"  → sessions#new/create      # login_path
  delete   "logout" → sessions#destroy         # logout_path
  get/post "register" → registrations#new/create  # register_path
  get/post "forgot-password" → passwords#new/create        # forgot_password_path
  get/put  "reset-password/:token" → passwords#edit/update # reset_password_path(token)
  ```

  Each screen has **one** helper covering both its GET and its POST — `login_path` is the form action as well as the link to it. The generator's old URLs (`/session/new`, `/registration/new`, `/passwords/new`, `/passwords/:token/edit`) survive only as `redirect()`s so reset links already sitting in inboxes still resolve; nothing in the app links to them.

## Tests

Tests run in parallel (`parallelize(workers: :number_of_processors)`) and load all fixtures — keep tests isolated from shared mutable state.

`test/test_helpers/session_test_helper.rb` provides `sign_in_as(user)` and `sign_out`, auto-included into integration tests.

- `test/controllers/app_screens_test.rb` — every signed-in screen: it renders, bad params fall back, and every route redirects to login when signed out. Assertions are scoped (`assert_select "main h2"`) because the header nav links to AI1101 on every page.
- `test/models/placeholder_content_test.rb` — derived values and locale wiring for the placeholder modules, checked in both locales.
- `test/models/learner_progress_test.rb` and `topic_completion_test.rb` — every counted figure, and what the table will and will not accept.
- `test/controllers/lesson_completion_test.rb` — the browser-to-record seam, and that a completion then shows up on the screens that count it.
- **`test/fixtures/topic_completions.yml` is deliberately empty and must stay present.** Tests that need progress record it themselves; the file exists so fixtures clear the table, because `bin/ci` seeds completions into the test database and those rows would otherwise outlive the users they point at.
- `test/controllers/languages_controller_test.rb` — the locale switch, that it sticks across requests, and that an unroutable locale 404s.
- The auth and role suites: `admin_test.rb` (the roster and the one place a role is granted), `user_test.rb` (the password rules and the `role` enum), `sessions_`/`registrations_`/`passwords_controller_test.rb`, `auth_switch_test.rb`, `legacy_auth_routes_test.rb` (the `redirect()`s above still resolve), `footer_test.rb` (the columns branch on the session), `test/tasks/admin_task_test.rb` (`admin:create` promotes rather than duplicates) and `test/tasks/instructor_task_test.rb` (`instructor:create` leaves an admin alone rather than demoting one).

Assertions compare against `I18n.t(...)` rather than literal strings; a copy change in the locale file should not break a test.

## Design system

**The single source of truth for the app UI's visual tokens is the `@theme` block in `app/assets/tailwind/application.css`.** Read it before changing anything visual.

`docs/design-system.md` documents the **earlier** port from <https://eng.utcc.ac.th> (maroon `#8C1C36`, Noto Sans Thai Looped, daisyUI component anatomy). The app UI has since moved to a different system — crimson `#A81E32` on cream, IBM Plex Sans Thai — so treat that document as background on the reference site, not as a description of the current tokens. The CSS wins where they disagree.

- **Tailwind v4, no daisyUI, no Node.** There are **no component CSS classes** — no `.btn`, no `.card`. If a recipe repeats, repeat the utilities.
- **`app/assets/tailwind/application.css` is the whole stylesheet.** There is no `app/assets/stylesheets/` directory. It is `@import "tailwindcss"`, one `@theme` block (tokens), one `@layer base` block (page defaults, focus ring, reduced motion), and a small set of `@utility` escape hatches — `brand-field`, `marker-partial`, `badge-ring`, `badge-fill`, `clip-hex`, `marker-none`, `skeleton`, `skeleton-on-chrome`. Every one exists because a multi-stop gradient or a clip-path cannot be expressed as a utility without inlining a raw colour into the markup. Adding another needs that same justification.
- **Never hardcode a hex anywhere else.** The `@theme` block is the only place one belongs. (The lone exception is the `theme-color` meta tag in `shared/_head`, which mirrors `--color-chrome`.)
- The palette is grouped by role, and the names say where a colour goes: `brand-*` (crimson ramp), `chrome-*` (the near-black header field), `on-chrome-*` (text sitting on it, brightest to dimmest), `surface-*`/`canvas`/`hairline-*` (light surfaces), `ink-*`/`muted-*` (text), plus `gold`, `success`, `danger`, `heat-0…4` (the contribution grid) and `code-*` (static syntax colouring).
- The type scale is **literal**: `text-14` is 14px expressed in rem. Half steps carry the design's fine-tuning and are spelled with a trailing `-5` — `text-13-5` is 13.5px, because a dot is not usable in a Tailwind theme key. Use `text-16`/`text-24`/`text-46`, never `text-base`/`text-2xl`/`text-4xl`. `text-54`/`64`/`80` exist only for the marketing landing page.
- Layout tokens: `max-w-page` (1320px, every app screen but the leaderboard), `max-w-narrow` (1000px, the leaderboard), `h-header` (64px). Radii are named by role — `rounded-field`, `rounded-card`, `rounded-panel`, `rounded-box`.
- **State travels on `data-*` attributes and is read by Tailwind variants** (`data-[state=correct]:`, `data-[open=true]:`, `group-open:`, `aria-selected:`). Stimulus controllers set an attribute; they do not juggle class lists. Keep it that way when adding interaction.
- Stimulus controllers: `header` (sticky + mobile drawer), `dropdown` (notifications, account menu), `tabs` (segmented controls that navigate), `panels` (tabs whose panels are all already in the document — a show/hide that can optionally push a path and title), `to_top`, `quiz` and `code_task` (in-browser lesson grading), `rewards` (listens for `quiz`/`code_task` reward events), `proctor` (lesson integrity monitoring). Accordions are native `<details>` — no controller.
- `proctor_controller` mounts only for `Current.user.student?` — staff get the same bar with the controls inert. Like the quiz and the coding task it runs entirely in the browser and persists nothing, so the integrity score resets on reload. `Proctoring` hands it the weights and `lesson.proctor.*` hands it the sentences; the log row is a `<template>` in the view, cloned per incident, so no markup lives in JS.
- `header_controller` receives its pinned state as **several** utilities via `data-header-pinned-class`, so it uses `classList.add/remove(...this.pinnedClasses)` — `classList.toggle` accepts only one class and will silently break if you switch back to it.
- Anything on the chrome field (header, hero, drawer, auth screens) needs a light-on-dark variant; a `border-brand text-brand` outline button renders invisibly there.

**Lesson grading runs in the browser**, so the answer key (`LessonContent::CORRECT_OPTION`) and the passing regexes (`LessonContent::CHECKS`, compiled to `RegExp` in `code_task_controller`) are public. That is intentional for a teaching exercise; real grading belongs on the server once submissions persist.

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool` instead of Grep
- **Understanding impact**: `get_impact_radius_tool` instead of manually tracing imports
- **Code review**: `detect_changes_tool` + `get_review_context_tool` instead of reading entire files
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes_tool` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context_tool` | Need source snippets for review — token-efficient |
| `get_impact_radius_tool` | Understanding blast radius of a change |
| `get_affected_flows_tool` | Finding which execution paths are impacted |
| `query_graph_tool` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes_tool` | Finding functions/classes by name or keyword |
| `get_architecture_overview_tool` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes_tool` for code review.
3. Use `get_affected_flows_tool` to understand impact.
4. Use `query_graph_tool` pattern="tests_for" to check coverage.
