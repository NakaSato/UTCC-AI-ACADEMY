# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

A learning platform for UTCC students getting started with AI. Rails 8.1, Ruby 3.4.10, module `UtccAiFundamental`.

`/` is **two different pages**: a marketing landing page for signed-out visitors, and the course catalog for a signed-in student (`HomeController#index` branches on `authenticated?` and renders `home/catalog` or `home/index`). An **admin is redirected to `/admin`** — the admin screen is their index, so the logo and the first nav slot both lead there and the catalog is not part of their app. Behind the login there are eight screens — catalog, course, lesson, my learning, knowledge map, progress, leaderboard, instructor.

**Users, sessions, the course taxonomy, progress and submitted work are persisted; the learning material is not.** `courses`, `course_modules` and `topics` carry identity, taxonomy and numbers; `topic_completions` carries what a learner finished and `submissions` what they sent to get there. Everything a human *reads* — titles, prose, topic names — is still copy in the locale files, reached through the placeholder modules in `app/models/` (see below). See "Progress" and "Grading" below for what is real and what is not.

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

**System tests exist and run in `bin/ci`** — `test/system/learning_walk_test.rb` walks the definition-of-done path in a real browser: sign in through the form, fail then pass the graded exercise, and see the pass counted on My Learning. The driver is headless Edge, registered by hand in `test/application_system_test_case.rb` because Rails' shorthand knows Chrome and Firefox; it also pins the browser's language to Thai, since the assertions are the app's default copy. Swap the two `:edge` references there to run against another browser.

Lint and security (each is also a `bin/ci` step):

```bash
bin/rubocop            # rubocop-rails-omakase style; -a to autocorrect
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit      # gem CVEs; ignore entries go in config/bundler-audit.yml
bin/importmap audit    # JS dependency CVEs
```

`bin/ci` also runs `env RAILS_ENV=test bin/rails db:seed:replant`, so `db/seeds.rb` must stay runnable against a fresh test database. The system-test step runs `bin/rails test:system` as part of the pipeline.

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
- **Controllers hold no domain logic.** Read a param, validate it against a whitelist, ask a module, assign. If a controller grows a calculation, it belongs on the `Data` object or in `LearnerProgress`.
- **`Data` objects are the presenters.** There is no presenter/serializer/service-object layer, and adding one would duplicate what `Data.define … do … end` already does.
- **The taxonomy is a table, and the modules read it.** `CourseCatalog` and `Syllabus` fold `courses`, `course_modules` and `topics` into the same `Data` objects they used to build from constants, so the views never learned the difference. `TopicCompletion` and `Submission` point at those rows with foreign keys, which is what the string validations became.
- **The bridges are few and named.** `LearnerProgress` (a learner's rows → every figure a learner screen shows), `InstructorReport` (a section's rows → the Teaching console) and `Leaderboard` (a scope's rows → ranked entries) are the only classes that read records and return value objects. Each folds one query set in Ruby. Keep the list this short — a new screen belongs behind one of them, not behind a fourth.

### Where state lives

| State | Home | Survives |
| --- | --- | --- |
| Screen state — filter, lesson step, tab, selected map node | the **query string** | reload, bookmark, sharing |
| Who you are | signed `httponly` cookie holding a `sessions` row id, `same_site: :lax` | permanent when "remember me", browser session otherwise |
| Language | `session[:locale]`, or `?lang=` for one request, or `Accept-Language` | the session; `?lang=` survives nothing on purpose |
| Learning progress | `topic_completions` | forever |
| Identity and role | `users` | forever |
| Cohort membership — who is in which section, who teaches it | `sections`, `enrollments` | forever |
| Quiz answers and coding-task attempts | `submissions` | forever — every attempt, passed or not |
| Proctor score, the optimistic gem counter | **browser memory only** | nothing — reload resets them |

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

- **Lesson grading is on the server.** `LessonContent::CORRECT_OPTION` and `CHECKS` are read by `grade_quiz` / `grade_code` and never rendered into the page, and `POST /lesson/submit` decides the verdict — a claimed pass is not a pass. Still rate-limited at 30 in 3 minutes, and `TopicCompletion.record` is still idempotent. The one thing that does come back is `correct_index`, so the page can mark the right option after a **graded, recorded** attempt; guessing works but leaves the failed `submissions` row that makes it visible.
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
6. `test/fixtures/topic_completions.yml` and `submissions.yml` stay present and empty; `courses.yml`, `course_modules.yml` and `topics.yml` stay in step with the migration and the seeds.
7. Denominators come from `Syllabus`, so a course's stat tile and its progress bar can never disagree.
8. Reader-method names are the public interface of a content module. Renaming one is a view change; keeping one is what makes the module replaceable.

### Performance and scale

Sized for a classroom, not a public site, and the design leans on that.

- **The N+1 that isn't:** `LearnerProgress` issues one query for a learner's rows and folds them in Ruby for six different cuts. Adding a per-course query to a view would undo it.
- **The known hotspot is `LearnerProgress.standings`** — two grouped counts over the *entire* `topic_completions` table, run on every render that shows a rank. Correct and cheap at a few thousand rows; it is the first thing to cache or denormalise when it is not. `Leaderboard`'s university tab does the same shape of work — every student's rows, folded per learner — so the two share that fate.
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

The dependency order is complete: ~~Course/Topic tables~~ (`1aa05c2`) → ~~submissions~~ (`e898a9b`) → ~~sections/cohorts~~ (`d2c3ca1`, `cf58c60`) → ~~projects and awards~~ (`20803ed`). What is still placeholder is listed under "Progress" below, each item with the reason it still is.

### What this design deliberately lacks

No API layer, no service objects, no presenters, no form objects, no Redis, no Node, no client-side router, no state manager, no component CSS classes. Each absence is a decision, not an oversight. Reach for one only when a concrete problem in this codebase demands it — the app is small enough that the abstraction usually costs more than the duplication it removes.

## Placeholder content: the app's central pattern

`app/models/` holds **modules plus `Data.define` value objects** in front of the records: `CourseCatalog`, `Syllabus`, `LessonContent`, `Landing`, `Policy`, `LearnerProfile`, `KnowledgeMap`, `Proctoring`, `AdminConsole`. Controllers are three or four lines each — read params, ask a module, assign. (`Leaderboard` and `InstructorReport` have left this list: they are ordinary classes over the tables now, the same shape as `LearnerProgress`.)

`CourseCatalog` and `Syllabus` are no longer frozen constants: they read `courses`, `course_modules` and `topics` and hand back the same `Data` objects they always did, which is why no view changed when the tables landed. The rest still are.

`AdminConsole` is the one with a real neighbour: the console's **Users** tab is genuinely persisted (the `role` column, `AdminController#update`), while its other five tabs are placeholder like everything else. Do not fold the roster into the module.

`LearnerProfile` has shrunk twice and now holds only what nothing records yet — hearts and notifications. The counting moved to `LearnerProgress` when `topic_completions` landed, and the award shelf followed once `submissions` gave its rules something to check: an award is a **derived rule**, one per medal, never stored.

The split is deliberate and consistent:

- **Ruby holds numbers, taxonomy and shape** — course codes, percentages, the tree structure, which module is locked.
- **`config/locales/{th,en}.yml` holds every word a human reads** — everywhere behind the login. The `Data` objects reach copy through `I18n.t` in their own methods (`course.title` is `I18n.t("catalog.courses.#{code}.title")`).

### The landing page

`app/views/home/index.html.erb` used to be the exception to both rules above — two dozen lines of hardcoded Thai in the ERB and five arrays of it in a private `HomeController#landing`. It is not any more. `Landing` holds the taxonomy, `landing.*` in both locale files holds every word, and the view reads `Landing` directly rather than through assigns, the same way the header reads `LearnerProfile`. `HomeController#index` therefore assigns nothing when it renders it.

**Its joins are by key, not by position** — unlike every module listed below. A card looks up its own copy by name, so adding one to `Landing::TOPICS` without writing its copy renders a missing translation instead of silently shifting the card after it.

The one thing still held in Ruby beyond the taxonomy is `Landing::EVENTS`, which maps each event to a calendar date or `nil`. The copy says when an event happens in words, and in two calendars; the date is the same fact in the form the structured data can use. See "What a crawler reads".

**Several of these joins are positional, not keyed** — `Syllabus::ENTRIES[i]` lines up with `course.modules[i]` in the locale file (and its topics with `course.modules[i][:topics][j]`, which is what a `"<module>-<position>"` topic key points into), `LearnerProgress::AWARDS[i]` with `my_learning.awards[i]` (rule and glyph on one side, name and hint on the other), `LearnerProgress#dashboard_stats` with `progress.stats[i]`, `LessonContent::BLOCKS[i]` with `lesson.theory.blocks[i]`, and every `AdminConsole` array with its `admin.*` counterpart (`STATS`, `ADOPTION`, `HEALTH`, `COURSES`, `QUEUE_KINDS`, `AUDIT_LEVELS`, plus `FLAG_GROUPS` which nests one level deeper). Inserting a row in one place without the other silently shifts every label after it. `test/models/placeholder_content_test.rb` exists mainly to catch that, and asserts across **both** locales.

Replacing a placeholder with a real model means keeping the same reader methods; the views only ever call those. `LearnerProgress` is the worked example — see below.

## Progress: the one thing that is recorded

`topic_completions` is the only table about learning. **One row per learner per topic**, carrying `learned_at` and a nullable `applied_at` — learning a topic and applying it are one row, because a topic cannot be applied without first being learned, and the UI shows them as two bars over the same list.

A topic is named by **foreign keys** — `course_id` and `topic_id`. It used to be a pair of strings validated against the placeholder modules, because nothing else could enforce them; now the database does, so "every row names a course and topic that exist" is true by construction. The strings survive as association readers (`course_code`, `topic_key`): they are what the browser posts, what the URL carries and what `LearnerProgress` folds on. Completions load with `includes(:course, :topic)`.

- **`TopicCompletion.record` is idempotent** — it is a `find_or_initialize_by` that never moves a timestamp already set. The exercise and the coding task each report a pass on every run; re-running the lesson writes no second row and inflates no count.
- **`LearnerProgress` is where completions become figures.** XP and gems per topic, how long a level is, what counts as a streak day — all display conventions, all in that class rather than in the table. It loads a learner's rows once and folds them in Ruby (the date arithmetic wants `Time.zone`, and the screens ask for six different cuts of the same rows).
- **`ApplicationController#progress` is a `helper_method`**, so any view can ask; `User#progress` memoises it per instance.
- **`CourseCatalog.for(user)` / `LearnerProgress#courses`** return the ordinary `CourseCatalog::Course` values with `learned`, `applied` and `next_key` filled in, so the catalog, My Learning and the dashboard all render the same object and the views did not change when this landed.

Recording is a consequence of grading, not a report of it. `quiz` and `code_task` POST what the student did to `POST /lesson/submit`; the server grades it, writes a `submissions` row for the attempt, and writes the completion **only on a pass** — `quiz` fills the learned half, `code` the applied one. `rewards_controller.js` is a counter again and posts nothing.

### Submissions: the attempt, as opposed to the outcome

`submissions` holds one row per **attempt** — `user`, `course`, `topic`, `kind` (`quiz` | `code`), `answer` (the option index, or the source), `passed`. A completion is the outcome and there is exactly one per learner per topic; a submission is the trying and there are as many as it took.

**Failures are kept on purpose.** They are what `InstructorReport`'s "share failing on first attempt" — still the fabricated figure on the Teaching console — will be counted from.

Grading lives in `LessonContent`: `grade_quiz` compares against `CORRECT_OPTION`, `grade_code` matches `CHECKS` and rejects any leftover `___` however well the rest matches. Neither the key nor the patterns are rendered. The cost, accepted deliberately: the coding task's criteria no longer tick as you type — they light up when the run answers, because live ticking needs the patterns in the page.

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

**Still placeholder, and what each is waiting for:** hearts/lives (no wrong answer costs a life), notifications (no deadline, grade or approval exists to notify about), the instructor's average exercise score (a submission is passed or not — nothing scores one out of ten), and the lesson's prose, quiz and coding task being the same for every topic (a content job). The leaderboard, the Teaching console, the award shelf and the projects tile are **counted now**, off `sections`, `enrollments`, `topic_completions` and `submissions`.

## Internationalisation

- `config/application.rb`: `default_locale = :th`, `available_locales = %i[th en]`, `fallbacks = [:en]` — a key missing from `th.yml` renders the English rather than raising.
- `ApplicationController` has `around_action :switch_locale`, and **three sources decide, most specific first: `?lang=`, then `session[:locale]`, then `Accept-Language`.** Thai is only the answer when none of them match. `LanguagesController#update` writes the session one.
- The route is **POST** `language/:locale` with a `/th|en/` constraint. It is POST on purpose: Turbo prefetches links on hover, and a GET would switch language just by pointing at the toggle. The constraint means an unsupported locale 404s at the router and never reaches `I18n`.
- **`?lang=` deliberately does not persist.** It exists so each translation has a URL that can be linked, canonicalised and paired in an hreflang — `ApplicationHelper#locale_url` is the one place that builds them, and the default locale keeps the bare path, so `/` stays Thai and `/?lang=en` is the English page. A param that wrote the session would reintroduce exactly the prefetch problem the POST route avoids.
- **`Accept-Language` is parsed in quality order** and matched on the primary subtag, so `th-TH` answers Thai and `en-GB` English. This is what a crawler gets, since it has no session and never sees the toggle.
- `th.yml` and `en.yml` are 1:1 in structure — add a key to both. Some values are **arrays consumed by index** (see above); keep their length and order identical across the two files.
- The toggle partial (`shared/_language_toggle`) has three render sites — `shared/_app_header` (signed in), `shared/_auth_hero` and `shared/_header` (the marketing chrome), the last two passing `dark: true`. It takes that local because it sits on the chrome field in two places and on a light surface in the other.

## Routing and layouts

```ruby
resources :courses, only: :show, param: :code   # /courses/AI1101
get  "lesson"          => "lessons#show"        # ?course=AI1101&topic=2-3&step=theory|exercise|code|summary
post "lesson/submit"   => "lessons#submit"      # an answer sent to be graded; replaced lesson/complete
get "my-learning" => "my_learning#show"         # ?tab=progress|done
get "map"         => "knowledge_maps#show"      # ?topic=<node id>&mode=course|project
get "progress"    => "progress#show"
get "leaderboard" => "leaderboards#show"        # ?tab=week|semester|university
get "instructor"  => "instructor#show"
get "privacy"     => "policies#privacy"         # public — the PDPA notice
get "terms"       => "policies#terms"           # public — terms of use
get "robots.txt"  => "crawlers#robots"          # public — rendered, not a file in public/
get "sitemap.xml" => "crawlers#sitemap"         # public — the three readable pages
get "llms.txt"    => "crawlers#llms"            # public — the site in English, for a model
get "admin"       => "admin#show"               # ?tab=features|overview|users|courses|queue|audit
patch "admin/users/:id" => "admin#update"       # admin_user_path — the only role grant in the app
root "home#index"                               # catalog signed in, /admin for an admin, landing when not
```

Screen state lives in the **query string**, not in client-side JS — filter chips, lesson steps, tabs and the map's selected node are all links. Controllers validate the param and fall back to a default rather than raising (`CourseCatalog::FILTERS.include?`, `LessonContent.step_for`, `Leaderboard.tab_for`, `AdminConsole.tab_for`). `AdminConsole.tab_for` matters twice over: the tab name is interpolated into a `render` path, so anything but a whitelisted value would be a template-injection foothold. The knowledge map derives which groups are expanded from the path to the selected node, so the URL alone determines the tree's state.

Two layouts:

- `layouts/application` — renders `shared/_app_header` (dark app chrome: nav, language toggle, gems/streak counters, notifications, account menu) when signed in, `shared/_header` (marketing) when not. `shared/_footer` closes **every** screen either way; only its first two link columns branch on the session (`ApplicationHelper#footer_columns` — landing anchors signed out, app routes signed in, since `#learn` would scroll nowhere on `/progress`). Its copy lives under `chrome.footer.*`, not `landing.*`, because it is shared chrome.
- `layouts/auth` — used by `SessionsController#new`, `RegistrationsController#new`, `PasswordsController#new/edit` via `layout "auth", only: …`. No app chrome; a split screen with `shared/_auth_hero` on the left.

`shared/_head` is shared by both layouts — the layouts differ only in what wraps `<body>`.

### What a crawler reads

`robots.txt`, `sitemap.xml` and `llms.txt` are **rendered by `CrawlersController`, not checked into `public/`** — all three have to name absolute URLs and the app has no configured host (`config/deploy.yml` is still a placeholder), so the only thing that knows where the site lives is the request. A static `public/robots.txt` would be served first and the action would never run, which is why it was deleted rather than kept as a fallback.

- **`DISALLOWED` is the private half of the app spelled out**, and `test/controllers/crawlers_test.rb` asserts the sitemap against it — a path cannot be advertised and closed at the same time. robots.txt stops the crawl and `layouts/auth` adds `noindex, nofollow` to stop the indexing, since a disallowed path linked from elsewhere can still be listed as a bare URL.
- **The sitemap lists every page once per language**, each entry naming the whole hreflang set including itself — a cluster that does not name itself is discarded rather than read partially. `shared/_meta` publishes the same set as `<link rel=alternate>` plus an `x-default` pointing at Thai, and the canonical is the URL of *that translation* rather than of the path.
- **`AI_AGENTS` names the model crawlers** and gives them the wildcard group's rules verbatim; both groups render the same `_rules` partial. A group written by name *replaces* the wildcard rather than adding to it, so repeating the rules is the only way to keep the two equal.
- **`llms.txt` is the one page with a single language.** `#llms` forces `I18n.with_locale(:en)` whatever the session says, because the file is read by models rather than by students, and it says so in its own first paragraph. Everything it lists comes from `Landing`, so a card added to the landing page shows up there without a second edit.

Structured data is `SchemaHelper` plus `yield :schema` in `shared/_meta`. Every page carries the `EducationalOrganization`; a template adds its own documents with `content_for :schema` — the landing page publishes an `ItemList` of `Course`, a `FAQPage` and an `ItemList` of `Event`, all built from `Landing` and so all translated with the page. Two `ItemList`s on one page are told apart by `name`, which is the heading of the section they came from. Only the events with a `Landing::EVENTS` date are published: `Event` without a `startDate` is invalid rather than vague, and "every Wednesday" is not a date. Templates render before their layout, which is what lets a `content_for` in the body land in `<head>`. Each course names its provider as an `@id` reference to the organization rather than repeating the address, and carries no `offers`: the tracks have no price in this codebase, and inventing a free one to earn a richer search result would be a claim nothing here backs.

## Architecture notes

**All infrastructure is SQLite + database-backed.** There is no Redis, Memcached, or separate job runner:

- `solid_queue` for Active Job, `solid_cache` for `Rails.cache`, `solid_cable` for Action Cable.
- In production these live in *separate* SQLite databases (`storage/production_{queue,cache,cable}.sqlite3`) declared as extra entries under `production:` in `config/database.yml`, each with its own `migrations_paths` (`db/queue_migrate`, etc.). Their schemas are `db/{queue,cache,cable}_schema.rb` — do not fold these into `db/schema.rb`.
- Workers run in-process: `config/puma.rb` loads `plugin :solid_queue` when `SOLID_QUEUE_IN_PUMA` is set, which `config/deploy.yml` sets. `bin/jobs` runs the supervisor standalone. Recurring jobs go in `config/recurring.yml`.
- Development and test use a single `storage/development.sqlite3` / `storage/test.sqlite3`; the solid_* adapters are only wired up in `config/environments/production.rb`.

**Frontend is importmap + Hotwire, still no Node.** Add JS dependencies with `bin/importmap pin <pkg>` (writes to `config/importmap.rb`, vendors into `vendor/javascript`) — never npm/yarn. Stimulus controllers in `app/javascript/controllers/` are auto-registered via `pin_all_from`; the filename determines the identifier. Assets are served by Propshaft (no Sprockets manifest, no `app/assets/config/`). CSS is Tailwind v4 via `tailwindcss-rails`, which ships a standalone binary — no npm, no `package.json`, no PostCSS config.

**Deployment is Kamal + Docker**, configured in `config/deploy.yml` (currently placeholder server `192.168.0.1` and registry `localhost:5555`). **`config.assume_ssl` and `config.force_ssl` are on**, so `proxy: ssl: true` in `deploy.yml` is not optional — the two are one decision. Without the proxy Rails sees plain http and `request.base_url` starts publishing `http://` canonicals, hreflangs and `<loc>`s for pages served over https. `/up` is excluded from the redirect, since the proxy and any uptime monitor reach it from inside the network. `storage/` is a persistent Docker volume — that's where the production SQLite files live. Thruster fronts Puma in the container. `RAILS_MASTER_KEY` decrypts `config/credentials.yml.enc` — and `secret_key_base` lives in there, so a target that does not set the variable fails in `bin/docker-entrypoint`'s `db:prepare` before the server starts, not later at a request.

**There is a second target: `render.yaml`**, a blueprint over the same Dockerfile. It exists so three things stay in the repo rather than in a dashboard — the disk mounted at `/rails/storage` (paid instance types only; without it `db:prepare` recreates an empty database on every deploy), `numInstances: 1` (SQLite takes one writer), and the `HTTP_PORT`/`PORT` pair, which must agree because `HTTP_PORT` is Thruster's listening port and `PORT` is what tells Render where to route. Kamal and Render are alternatives, not layers: `config/deploy.yml` is untouched by a Render deploy and vice versa, and both rely on the same `assume_ssl` decision above.

**The site is `https://academy.boring9.dev`**, and the name appears in exactly three places that must agree — `config.hosts`, `config.action_mailer.default_url_options` and `domains:` in `render.yaml`. `config.hosts` is a publishing control as much as a security one: `request.base_url` builds every canonical, hreflang and `<loc>`, so any name the app answers to is a name it can publish itself under. `/up` is excluded from host authorization as well as from the https redirect, since the platform health-checks it under an internal name. The mailer host is spelled out with `protocol: "https"` because there is no request to infer it from and `force_ssl` does not reach into a mailer. **SMTP is still not configured**, so the password-reset mail is enqueued and never delivered — the one broken user-facing path in production.

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
- **`test/fixtures/topic_completions.yml` and `submissions.yml` are deliberately empty and must stay present.** Tests that need progress or an attempt make one; the files exist so fixtures clear the tables, because `bin/ci` seeds into the test database and those rows would otherwise outlive the users and topics they point at.
- **`courses.yml`, `course_modules.yml` and `topics.yml` are the opposite** — they carry the taxonomy, because `db:test:prepare` loads the schema and a schema holds no data. That is three copies of the same rows that must agree: the `CreateCourses` migration (what production has), `db/seeds.rb` (what restores them after `db:seed:replant`) and these. `taxonomy_test.rb` asserts the shape all three have to produce.
- `test/controllers/languages_controller_test.rb` — the locale switch, that it sticks across requests, and that an unroutable locale 404s. `locale_negotiation_test.rb` covers the rest of the rule: which of `?lang=`, the session and `Accept-Language` wins, and that `?lang=` never persists.
- The three that nothing on screen would catch — `crawlers_test.rb` (robots.txt, the sitemap and llms.txt agreeing about what is public), `indexing_test.rb` (canonicals, the hreflang set, and which pages ask not to be indexed) and `structured_data_test.rb` (the JSON-LD each page publishes, in both locales).
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

**Lesson grading runs on the server** — `POST /lesson/submit`, graded in `LessonContent`, recorded in `submissions`. The `quiz` and `code_task` controllers send what the student did and render the verdict they get back; neither knows the answer key. They share the posting helper in `app/javascript/grading.js`, which is outside `controllers/` because `pin_all_from` would otherwise register it as a Stimulus controller.

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
