# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

A learning platform for UTCC students getting started with AI. Rails 8.1, Ruby 3.4.10, module `UtccAiFundamental`.

`/` is **two different pages**: a marketing landing page for signed-out visitors, and the course catalog for a signed-in student (`HomeController#index` branches on `authenticated?` and renders `home/catalog` or `home/index`). An **admin is redirected to `/admin`** — the admin screen is their index, so the logo and the first nav slot both lead there and the catalog is not part of their app. Behind the login there are eight screens — catalog, course, lesson, my learning, knowledge map, progress, leaderboard, instructor.

**Nothing is persisted except users and sessions.** There are no Course/Lesson/Topic tables. Every screen is driven by plain-Ruby placeholder modules in `app/models/` (see below), so the whole app UI is real markup over fake data.

Bilingual, Thai-first: `default_locale = :th`, English as fallback, a toggle in the header.

## Commands

```bash
bin/setup              # install gems, db:prepare, clear logs/tmp, then exec bin/dev
bin/setup --skip-server # same without booting the server
bin/dev                # foreman: rails server + tailwindcss:watch (Procfile.dev)
bin/ci                 # full local CI pipeline (steps defined in config/ci.rb)

bin/rails tailwindcss:build   # one-off CSS build into app/assets/builds/tailwind.css
bin/rails tailwindcss:watch   # rebuild on change (what bin/dev runs)

bin/rails admin:create        # create or promote an admin — the only way to get the first one
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

There is no CI workflow in this repo — `bin/ci` is the whole pipeline, run locally.

## Placeholder content: the app's central pattern

`app/models/` holds no Active Record classes for the learning material. It holds **modules of frozen constants plus `Data.define` value objects**: `CourseCatalog`, `Syllabus`, `LessonContent`, `LearnerProfile`, `KnowledgeMap`, `Leaderboard`, `InstructorReport`. Controllers are three or four lines each — read params, ask a module, assign.

The split is deliberate and consistent:

- **Ruby holds numbers, taxonomy and shape** — course codes, percentages, the tree structure, which module is locked.
- **`config/locales/{th,en}.yml` holds every word a human reads.** The `Data` objects reach copy through `I18n.t` in their own methods (`course.title` is `I18n.t("catalog.courses.#{code}.title")`).

**Several of these joins are positional, not keyed** — `Syllabus::ENTRIES[i]` lines up with `course.modules[i]` in the locale file, `InstructorReport::HARD_TOPIC_PERCENTS[i]` with `instructor.hard_topics[i]`, `LearnerProfile::AWARDS[i]` with `my_learning.awards[i]`, `Leaderboard::FIGURES[i]` with `leaderboard.leaders[i]`. Inserting a row in one place without the other silently shifts every label after it. `test/models/placeholder_content_test.rb` exists mainly to catch that, and asserts across **both** locales.

Replacing a placeholder with a real model means keeping the same reader methods; the views only ever call those.

## Internationalisation

- `config/application.rb`: `default_locale = :th`, `available_locales = %i[th en]`, `fallbacks = [:en]` — a key missing from `th.yml` renders the English rather than raising.
- `ApplicationController` has `around_action :switch_locale`, which reads `session[:locale]`. `LanguagesController#update` writes it.
- The route is **POST** `language/:locale` with a `/th|en/` constraint. It is POST on purpose: Turbo prefetches links on hover, and a GET would switch language just by pointing at the toggle. The constraint means an unsupported locale 404s at the router and never reaches `I18n`.
- `th.yml` and `en.yml` are 1:1 in structure — add a key to both. Some values are **arrays consumed by index** (see above); keep their length and order identical across the two files.
- The toggle partial (`shared/_language_toggle`) takes a `dark:` local because it renders on chrome (header, auth screens) and on light surfaces.

## Routing and layouts

```ruby
resources :courses, only: :show, param: :code   # /courses/AI1101
get "lesson"      => "lessons#show"             # ?step=theory|exercise|code|summary
get "my-learning" => "my_learning#show"         # ?tab=progress|done
get "map"         => "knowledge_maps#show"      # ?topic=<node id>&mode=course|project
get "progress"    => "progress#show"
get "leaderboard" => "leaderboards#show"        # ?tab=week|semester|university
get "instructor"  => "instructor#show"
root "home#index"                               # catalog signed in, /admin for an admin, landing when not
```

Screen state lives in the **query string**, not in client-side JS — filter chips, lesson steps, tabs and the map's selected node are all links. Controllers validate the param and fall back to a default rather than raising (`CourseCatalog::FILTERS.include?`, `LessonContent.step_for`, `Leaderboard.tab_for`). The knowledge map derives which groups are expanded from the path to the selected node, so the URL alone determines the tree's state.

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

- **Everything requires login by default.** `ApplicationController` includes `Authentication`, whose `included do` block adds a global `before_action :require_authentication`. Any publicly reachable action must opt out with `allow_unauthenticated_access` — only `HomeController#index` and `LanguagesController` do. Forgetting it is the usual cause of an unexpected redirect to `/login`.
- `Current.user` / `Current.session` (an `ActiveSupport::CurrentAttributes`) are how views read the signed-in user; `authenticated?` is the exposed helper method, and layouts branch on it.
- **Authorization is a separate concern from authentication.** `users.role` is a string column defaulting to `"student"`, declared on `User` as `enum :role, ROLES.index_by(&:itself), default: "student", validate: true`. `validate: true` is deliberate: the admin form posts a role from params, and without it an unknown value raises `ArgumentError` instead of failing validation.
  - **admin is a superset of instructor.** `User#staff?` is `instructor? || admin?`, so a staff-wide gate needs no second rule for admins.
  - `Authorization` (`app/controllers/concerns/authorization.rb`) is included in `ApplicationController` **after** `Authentication`, so `require_authentication` runs first and a signed-out visitor still lands on `/login` rather than the catalog. Its `allow_only` macro mirrors `allow_unauthenticated_access` — it names who is let in, and any `User` predicate works: `allow_only :staff` on `InstructorController`, `allow_only :admin` on `AdminController`. Denial is a redirect to `root_path` with `flash[:alert]`, matching `CoursesController#show`'s handling of an unknown course code.
  - **`ApplicationHelper#app_nav_items` is built from the role** — the instructor entry is appended only for the roles that can open it, so a gate that is missing shows up as a link nobody can use. For an admin the **admin entry replaces the catalog entry** in the first slot, since `/` only redirects them back to `/admin`. The desktop rail and the burger drawer both read that one list.
  - `/admin` (`AdminController`) is the **only** screen backed by real records rather than a placeholder module, and the only place a role is granted — sign-up always produces a student, and `RegistrationsController#user_params` never whitelists `role`. **Do not add `:role` to that list**; `test/controllers/registrations_controller_test.rb` fails if you do. An admin cannot change their own role; since only an admin reaches the action, that single rule is what guarantees at least one admin always survives.
  - **The first admin comes from `bin/rails admin:create`** (`lib/tasks/admin.rake`) — /admin cannot grant it, since opening /admin already requires the role, and `db/seeds.rb` is fenced to `Rails.env.local?`. The task prompts when attached to a terminal and reads `ADMIN_STUDENT_ID` / `ADMIN_NAME` / `ADMIN_PASSWORD` when not, so it also works over `kamal app exec`. An existing account with that student ID is promoted rather than duplicated.
- `start_new_session_for(user, remember: true)` backs the "remember me" checkbox — `remember: false` gives a session cookie instead of a permanent one.
- `User` validates a minimum password length of 8. A password shorter than 8 characters in a test will fail validation rather than the assertion you intended.
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
- `test/controllers/languages_controller_test.rb` — the locale switch, that it sticks across requests, and that an unroutable locale 404s.

Assertions compare against `I18n.t(...)` rather than literal strings; a copy change in the locale file should not break a test.

## Design system

**The single source of truth for the app UI's visual tokens is the `@theme` block in `app/assets/tailwind/application.css`.** Read it before changing anything visual.

`docs/design-system.md` documents the **earlier** port from <https://eng.utcc.ac.th> (maroon `#8C1C36`, Noto Sans Thai Looped, daisyUI component anatomy). The app UI has since moved to a different system — crimson `#A81E32` on cream, IBM Plex Sans Thai — so treat that document as background on the reference site, not as a description of the current tokens. The CSS wins where they disagree.

- **Tailwind v4, no daisyUI, no Node.** There are **no component CSS classes** — no `.btn`, no `.card`. If a recipe repeats, repeat the utilities.
- **`app/assets/tailwind/application.css` is the whole stylesheet.** There is no `app/assets/stylesheets/` directory. It is `@import "tailwindcss"`, one `@theme` block (tokens), one `@layer base` block (page defaults, focus ring, reduced motion), and a small set of `@utility` escape hatches — `brand-field`, `marker-partial`, `badge-ring`, `badge-fill`, `clip-hex`, `marker-none`. Every one exists because a multi-stop gradient or a clip-path cannot be expressed as a utility without inlining a raw colour into the markup. Adding another needs that same justification.
- **Never hardcode a hex anywhere else.** The `@theme` block is the only place one belongs. (The lone exception is the `theme-color` meta tag in `shared/_head`, which mirrors `--color-chrome`.)
- The palette is grouped by role, and the names say where a colour goes: `brand-*` (crimson ramp), `chrome-*` (the near-black header field), `on-chrome-*` (text sitting on it, brightest to dimmest), `surface-*`/`canvas`/`hairline-*` (light surfaces), `ink-*`/`muted-*` (text), plus `gold`, `success`, `danger`, `heat-0…4` (the contribution grid) and `code-*` (static syntax colouring).
- The type scale is **literal**: `text-14` is 14px expressed in rem. Half steps carry the design's fine-tuning and are spelled with a trailing `-5` — `text-13-5` is 13.5px, because a dot is not usable in a Tailwind theme key. Use `text-16`/`text-24`/`text-46`, never `text-base`/`text-2xl`/`text-4xl`. `text-54`/`64`/`80` exist only for the marketing landing page.
- Layout tokens: `max-w-page` (1320px, every app screen but the leaderboard), `max-w-narrow` (1000px, the leaderboard), `h-header` (64px). Radii are named by role — `rounded-field`, `rounded-card`, `rounded-panel`, `rounded-box`.
- **State travels on `data-*` attributes and is read by Tailwind variants** (`data-[state=correct]:`, `data-[open=true]:`, `group-open:`, `aria-selected:`). Stimulus controllers set an attribute; they do not juggle class lists. Keep it that way when adding interaction.
- Stimulus controllers: `header` (sticky + mobile drawer), `dropdown` (notifications, account menu), `tabs`, `to_top`, `quiz` and `code_task` (in-browser lesson grading), `rewards` (listens for `quiz`/`code_task` reward events). Accordions are native `<details>` — no controller.
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
