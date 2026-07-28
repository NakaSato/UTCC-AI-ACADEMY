# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

A learning platform for UTCC students getting started with AI. Rails 8.1, Ruby 3.4.10, module `UtccAiFundamental`.

`/` is **two different pages**: a marketing landing page for signed-out visitors, and the course catalog for a signed-in student (`HomeController#index` branches on `authenticated?` and renders `home/catalog` or `home/index`). An **admin is redirected to `/admin`** — the admin screen is their index, so the logo and the first nav slot both lead there and the catalog is not part of their app. Behind the login there are nine screens — catalog, course, lesson, my learning, profile, knowledge map, progress, leaderboard, instructor.

**Users, sessions, the course taxonomy, progress and submitted work are persisted; the learning material is not.** `courses`, `course_modules` and `topics` carry identity, taxonomy and numbers; `topic_completions` carries what a learner finished and `submissions` what they sent to get there. Everything a human *reads* — titles, prose, topic names — is still copy in the locale files, reached through the placeholder modules in `app/models/` (see below). The one place that is now a default rather than the last word is the marketing landing page: `landing_texts` holds whatever an admin has rewritten from `/admin?tab=landing`, and an empty table is the app as shipped. See "Progress" and "Grading" below for what is real and what is not.

Bilingual, Thai-first: `default_locale = :th`, English as fallback, a toggle in the app header and on the auth screens — **not** on the marketing header, so a signed-out visitor to `/` has no way to switch (see the landing-page exception below).

**Three names, all current, none a typo.** The product is *UTCC AI Academy by Upperclassman*, the Kamal service and image are `utcc_ai_academy`, and the Rails module is still `UtccAiFundamental` — the app was renamed and the constant was deliberately left alone, since renaming it touches every environment file and the encrypted credentials for no user-visible gain. Do not "fix" the module to match the repo.

## Other docs, and which one wins

- **`README.md`** is written for a human joining the project, and its second half ("Technical overview" onward) covers the same ground as this file — stack, layout, request path, data model, auth, routing, tests. **The two must not drift.** An architectural change here needs the matching README section updated in the same commit; that is where the nine screens and the setup path are explained for a person who has never run the app.
- **`docs/process.md`** — the team's Scrum process: two-week sprints, the four events, and a definition of done that points back at the invariants in this file. Read it before proposing what to build next; it also fixes the dependency order of the remaining work.
- **`docs/design-system.md`** — the current tokens and conventions explained in prose, with the earlier eng.utcc.ac.th port kept as a history section. The `@theme` block is still the source of truth; the CSS wins where they disagree.
- **`.claude/skills/`** — five project skills. Four of them (`explore-codebase`, `debug-issue`, `refactor-safely`, `review-changes`) drive the code-review-graph MCP tools; prefer them over hand-rolling a search. The fifth, **`run-app`**, is the cold-started path to seeing a change work in a real browser — the server, the headless-Edge driver, the seeded accounts, and the gotchas already paid for. Reach for it whenever a change needs to be *seen* rather than only tested.

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

**System tests exist and run in `bin/ci`**, and there are two. `test/system/learning_walk_test.rb` walks the definition-of-done path in a real browser: sign in through the form, fail then pass the graded exercise, and see the pass counted on My Learning. `test/system/frame_recovery_test.rb` covers the one failure mode only a browser can show — a frame fetched after its page has been signed out from, which without `frame_recovery.js` renders "Content missing" into the header. **Both need a synchronisation point after `sign_in_through_the_form`**: `visit` does not queue behind a form submission, so a navigation issued straight after sign-in goes out cookieless and the test fails on a landing page rather than on what it is about. The driver is headless Edge, registered by hand in `test/application_system_test_case.rb` because Rails' shorthand knows Chrome and Firefox; it also pins the browser's language to Thai, since the assertions are the app's default copy. Swap the two `:edge` references there to run against another browser.

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

A server-rendered monolith: one Puma process, one SQLite file, no API layer, no client-side router, no external service **the app talks to** — the browser fetches webfonts from Google (`shared/_fonts`), which is the one origin other than our own that any page depends on, and the two `fonts.*` allowances in the CSP are there to say so. Every screen is a full HTML response that Turbo Drive swaps in, and **one of them arrives in two** — see the lazy frame on the leaderboard below. There is exactly one WebSocket, to our own `/cable`, and it carries the notification bell and nothing else. Hold that shape — most of the decisions below only make sense because nothing is distributed.

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
| Who you are | signed `httponly` cookie holding a `sessions` row id, `same_site: :lax` | 30 days with "remember me", the browser session otherwise — never longer, either way |
| Language | `session[:locale]`, or `?lang=` for one request, or `Accept-Language` | the session; `?lang=` survives nothing on purpose |
| Learning progress | `topic_completions` | forever |
| Identity and role | `users` | forever |
| Cohort membership — who is in which section, who teaches it | `sections`, `enrollments` | forever |
| Quiz answers and coding-task attempts | `submissions` | forever — every attempt, passed or not |
| Which cards the landing page has, and in what order | `landing_cards` | forever |
| Landing-page copy an admin rewrote | `landing_texts` | forever; deleting the row restores the shipped copy |
| What an admin did on `/admin` | `audit_events` | forever — nothing deletes or prunes them |
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

**One thing on every signed-in screen is also pushed to.** `shared/_app_header` renders `turbo_stream_from notification_bell.stream`, so each page holds one Action Cable subscription for the length of its visit — the first thing in the app to open a channel. `NotificationBell` owns that channel, the DOM id it replaces and the path it is re-read from; `Notification.notify` and `NotificationsController#read_all` are the only two callers of `broadcast_refresh!`. See "The notification bell" below for why what travels over that socket is a frame rather than a rendered bell.

**A frame fetch can be refused by a gate its page already passed**, and both frames in the app fetch after load. Leave a screen open past `Session::MAX_AGE` and the next fetch is redirected to the landing page; Turbo cannot find its frame in that response and its default is to write **"Content missing"** into the frame — two English words in the middle of the Thai header, where the bell was. `app/javascript/frame_recovery.js` is one document-level `turbo:frame-missing` listener that promotes a *redirected* frame response to the full-page visit it should have been, flash and all. It is guarded on `response.redirected` on purpose: a frame missing because a template stopped rendering it is a bug and must keep failing loudly. `test/system/frame_recovery_test.rb` is the only test that can see any of this, and it fails without the listener.

**One screen answers this twice.** `/leaderboard` renders a shell — heading, tabs, column header — around a `<turbo-frame loading="lazy">` whose `src` is the same URL, and the browser comes straight back for it with a `Turbo-Frame` header. `LeaderboardsController#show` branches on `turbo_frame_request?`: the shell is what a navigation gets, the board is what the frame gets, and turbo-rails swaps in its own minimal layout for the second one so the chrome is not rendered twice. **The frame's response must not carry `src` or `loading`** — a frame that names its own source on the way back fetches itself forever. `test/controllers/leaderboard_frame_test.rb` asserts both halves, since neither is visible from the other.

### Trust boundaries

The browser is untrusted, with one deliberate, documented exception.

- **Lesson grading is on the server.** `LessonContent::CORRECT_OPTION` and `CHECKS` are read by `grade_quiz` / `grade_code` and never rendered into the page, and `POST /lesson/submit` decides the verdict — a claimed pass is not a pass. Still rate-limited at 30 in 3 minutes, and `TopicCompletion.record` is still idempotent. The one thing that does come back is `correct_index`, so the page can mark the right option after a **graded, recorded** attempt; guessing works but leaves the failed `submissions` row that makes it visible.
- **Every param is whitelist-or-default.** `AdminConsole.tab_for` is the one where it is a security control rather than a nicety — the tab name is interpolated into a `render` path.
- **`role` is never mass-assignable.** Sign-up permits four attributes and `:role` is not among them; **`ProfilesController#profile_params` permits four and omits it too**, along with `:student_id`. The only grant is `AdminController#update`, behind `allow_only :admin`. Both whitelists have a test that fails if a role posted through the form sticks.
- **`/profile` edits `Current.user` and takes no id.** The path carries nothing to tamper with, so there is no object to authorize — which is why it needs no `allow_only`.
- **No user enumeration on password reset** — `PasswordsController#create` redirects identically whether or not the address exists, and checks `present?` first so a blank submission cannot match the many accounts with a null email.
- **Rate limits** on sign-in, sign-up, password reset (10/3min) and lesson completion (30/3min).
- Password max length is 72 because that is bcrypt's ceiling — anything longer is silently ignored, so accepting it would be a lie.
- **A Content-Security-Policy ships on every response**, and its whole value is `script-src 'self'` plus a per-request nonce: with no `unsafe-inline` and no remote origin, an injected `<script>` is a blocked resource rather than executing code. Three things about it are load-bearing and easy to undo by accident:
  - **The nonce is `SecureRandom`, not `request.session.id`.** The landing page is served to visitors with no session, for whom a session-derived nonce is the empty string — that would leave the inline importmap unsigned and break every screen for the audience least able to report it. The cost is that HTML bodies are no longer byte-identical between requests, so `Rack::ETag` stops answering 304 for them.
  - **`SchemaHelper#json_ld` passes the nonce by hand.** Browsers gate `<script type="application/ld+json">` under `script-src` even though it never executes, and `content_security_policy_nonce_auto` does not reach a `tag.script` built in a helper. Without it every JSON-LD document on the site is silently dropped — a security change turning into an SEO regression. importmap-rails already stamps its own two inline tags.
  - **`style-src` allows `unsafe-inline` deliberately.** Nineteen computed `style="width: …%"` attributes carry the progress bars and stagger delays, and CSP has no nonce for style *attributes* — only for `<style>` elements. The alternative is not a stricter policy but a broken layout.
  - `test/controllers/content_security_policy_test.rb` asserts both directions: that `script-src` never gains `unsafe-inline`, and that every inline `<script>` on a rendered page carries the nonce the header names.
- Brakeman, bundler-audit and `importmap audit` are `bin/ci` steps, not optional extras.

### Invariants

Break one of these and something rots quietly rather than failing loudly:

1. One `topic_completions` row per learner per topic, and `record` never moves a timestamp already set.
2. Every row names a course and topic that exist — enforced by validation, not by convention.
3. `th.yml` and `en.yml` stay 1:1 in structure, and every positionally-indexed array keeps the same length **and order** in both.
4. At least one admin always exists — guaranteed solely by an admin being unable to change their own role.
5. Sign-up only ever produces a student.
6. `test/fixtures/topic_completions.yml`, `submissions.yml`, `notifications.yml`, `landing_texts.yml` and `audit_events.yml` stay present and empty; `courses.yml`, `course_modules.yml`, `topics.yml` and `landing_cards.yml` stay in step with their migration and the seeds.
7. Denominators come from `Syllabus`, so a course's stat tile and its progress bar can never disagree.
8. Reader-method names are the public interface of a content module. Renaming one is a view change; keeping one is what makes the module replaceable.
9. A `landing_texts` row is a departure from the shipped copy, never a duplicate of it — `LandingText.write` deletes when a value matches the default, so the locale files stay the source of truth.
10. Destroying a `landing_cards` row destroys its copy with it, so a slug that comes back cannot inherit the words of the card that had it before.

### Performance and scale

Sized for a classroom, not a public site, and the design leans on that.

- **The N+1 that isn't:** `LearnerProgress` issues one query for a learner's rows and folds them in Ruby for six different cuts. Adding a per-course query to a view would undo it.
- **Every screen is constant-cost in the size of the data it folds**, and `test/models/query_budget_test.rb` is what keeps it that way — it grows a section and asserts the roster's query count does not move. Measured per render against the seeds: landing 2, map and profile 6, the leaderboard's shell 6 and its board frame 6 again (10 in one response before the frame), course/lesson/My Learning 12, catalog 13, progress 14, instructor 16, admin 12–20.
  - **A cohort is loaded once, never once per member.** `Leaderboard#completions` and `InstructorReport#done_keys` are the same move — one `where(user: …)` grouped by `user_id` in Ruby. `InstructorReport` used to build a `LearnerProgress` per roster row, which cost three queries a student and made `/instructor` **3n + 12**: 273 queries for an 87-student section. It reads one thing from that object, so it now reads one query for the section instead.
  - **A `LearnerProgress` per user per request, no more.** `User#progress` memoises one and `ApplicationController#progress` hands the view that same one, so `CourseCatalog.for` goes through `user.progress` rather than `LearnerProgress.new(user)` — building a second loaded the learner's completions twice on every course and lesson screen.
- **The known hotspot is `LearnerProgress.standings`** — two grouped counts over the *entire* `topic_completions` table. It is memoised on `Current.standings` for the length of a request, because `/progress` asks for a rank more than once and used to pay for all of it twice; `TopicCompletion.record` calls `LearnerProgress.forget_standings`, the same contract `LandingText.forget` carries. Correct and cheap at a few thousand rows, and the per-request memo is what buys time before it has to be cached or denormalised. `Leaderboard`'s university tab does the same shape of work — every student's rows, folded per learner — so the two share that fate.
  - **Which is why the board is deferred rather than optimised.** `/leaderboard`'s shell no longer folds the cohort at all: the four queries behind `Leaderboard#entries` moved into the lazy frame, so the screen paints on the viewer's own rows and the whole-table fold happens behind a skeleton. It buys perceived latency, not queries — the total is unchanged and the frame costs a second round trip. Nothing else on the app is split this way, and a screen should only be split when the deferred half is genuinely the expensive half.
- **The bell's socket is one subscription per open page, and one poller per process.** `solid_cable` polls its own SQLite file every 100ms for new messages — once per Puma process, not once per subscriber, so a section of ninety students is ninety in-memory fan-outs off the same poll rather than ninety pollers. It is a different database file from the one that takes writes, which is why constant reads on it do not compete with the single writer. The broadcast itself is **synchronous** rather than `_later`: it renders nothing (the payload is a constant frame), so there is no rendering cost to move off the request, and enqueuing it would make the admin path the second thing in the app to need Solid Queue.
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

`app/models/` holds **modules plus `Data.define` value objects** in front of the records: `CourseCatalog`, `Syllabus`, `LessonContent`, `Landing`, `Policy`, `KnowledgeMap`, `Proctoring`, `AdminConsole`. Controllers are three or four lines each — read params, ask a module, assign. (`Leaderboard` and `InstructorReport` have left this list — ordinary classes over the tables now — and `LearnerProfile` is gone entirely; see below.)

`CourseCatalog` and `Syllabus` are no longer frozen constants: they read `courses`, `course_modules` and `topics` and hand back the same `Data` objects they always did, which is why no view changed when the tables landed. The rest still are.

`AdminConsole` has real neighbours: five of the console's tabs are backed by records rather than by the module — **Users** (the `role` column, `AdminController#update`), **Sections** (`sections`/`enrollments`), **Integrity** (`proctor_events`, through `Proctoring`), **Landing** (`landing_cards` and `landing_texts`, over `Landing`) and **Audit** (`audit_events`) — while the remaining five are placeholder like everything else. Do not fold any of them into the module.

**The Audit tab is the console reporting on itself.** Every mutating action in `AdminController` calls `AuditEvent.record` on its success path, and the tab reads those rows. Three things about it are deliberate:

- **The actor is `Current.user`, not an argument** — unlike `Notification.notify`, whose subject is somebody other than whoever is acting. An audit entry's subject never is.
- **The level is derived from the action, not stored.** `AuditEvent::WARN` names the entries worth a second look — a privilege change, or something that cannot be undone from the screen that did it — so reclassifying one is a deploy rather than a backfill. `at_level` filters in SQL for the same reason `RECENT` exists: the cap has to apply to what survives the filter, not to what went into it.
- **Two actions deliberately record nothing**, and both say so in a comment: `show`, because reading is not an event, and `move_card`, because reordering the landing page changes neither what exists nor who can do what and would bury the role grants. `test/controllers/admin_audit_test.rb` drives every endpoint, so an action that stops recording — or a new one that never starts — fails a test rather than going quiet.

Like `Notification`, the row carries the action and its interpolations and never a sentence, so a line reads in whichever language it is *read* in. A stored `role` or landing `group` is a key that gets translated on the way out; a person's name and a card's title are not keys and are stored as written. There is no way to delete a row and nothing prunes them — an audit log you can clear is not one.

`LearnerProfile` is deleted — the worked example of a placeholder module finishing its life. The counting moved to `LearnerProgress` when `topic_completions` landed; the awards followed as **derived rules** once `submissions` existed; notifications left for their own table; and hearts became a derived display too — `LearnerProgress#hearts` is `5` minus the failed attempts of the last four hours, with the refill time derived from when the oldest counted failure ages out. **Hearts gate nothing at zero**: whether an empty set should block an attempt is a pedagogy decision nobody has made, and the display does not sneak it in.

The split is deliberate and consistent:

- **Ruby holds numbers, taxonomy and shape** — course codes, percentages, the tree structure, which module is locked.
- **`config/locales/{th,en}.yml` holds every word a human reads** — everywhere behind the login. The `Data` objects reach copy through `I18n.t` in their own methods (`course.title` is `I18n.t("catalog.courses.#{code}.title")`).

### The notification bell

The one component in the app that updates itself. `NotificationBell` is a plain class in `app/models/` — not a component object, because there is no component layer here and adding one would be the presenter this design refuses — and it owns four things that would otherwise be scattered as matching strings: the DOM id it replaces (`ID`), the channel it is replaced over (`stream`), the path it is re-read from, and the two figures the panel shows. A caller writes `NotificationBell.new(user).broadcast_refresh!` and knows none of them. `Notification.notify` is one such caller and `NotificationsController#read_all` is the other, which is the whole list.

**The broadcast pushes an empty frame, never a rendered bell**, and that is the load-bearing decision. Both reasons are the same reason — **a broadcast has no session**:

- **The panel contains the one form this menu has**, and a form rendered outside a session gets no CSRF token at all. That is measured, not assumed: with forgery protection on, `button_to` in an out-of-band render emits no `authenticity_token`, so "mark all read" clicked on a pushed bell would be refused — and would look identical to one that worked.
- **A reader's language lives in `session[:locale]`**, so a bell rendered by whoever *triggered* the notification would be written in their language. `Notification` stores a kind rather than a sentence precisely to stop that happening.

So `shared/_app_notifications_refetch` — an empty `<turbo-frame>` naming its own `src` — is what crosses the wire, and the browser fetches the bell back from `GET /notifications` over an ordinary authenticated request that carries the reader's cookies, and therefore their token and their language. One extra round trip on an event that happens a handful of times a term. `test/models/notification_bell_test.rb` asserts that no copy and no token ever appear in a broadcast payload, and `notification_broadcast_test.rb` asserts the refetched bell has both.

Three smaller things are easy to undo by accident:

- **The frame a request renders must have no `src`**, or every screen in the app fetches the bell a second time on load. `_app_notifications` is the version without one; `_app_notifications_refetch` is the version with. Both name the same id, which is what makes them two shapes of one frame rather than two frames.
- **The pushed frame is not empty** — it holds a wordless 38px `skeleton-on-chrome` square. Without it the frame collapses for the length of the fetch and the header's whole right-hand rail slides sideways. Wordless because a broadcast has no language to write words in.
- **`turbo_stream_from` lives in `shared/_app_header`, outside the frame**, so a replacement cannot tear down the subscription that delivered it. The channel name is still in one place: the header asks the bell for it.

### The landing page

`app/views/home/index.html.erb` used to be the exception to both rules above — two dozen lines of hardcoded Thai in the ERB and five arrays of it in a private `HomeController#landing`. It is not any more, and it is now the one screen an admin can edit without a deploy. **It is also the only content in the app that is fully a CMS**: not just reworded but added to, reordered and deleted from, at `/admin?tab=landing`.

`Landing` is a read model, not a placeholder module. It holds no taxonomy of its own any more — the five card collections that used to be `TOPICS`/`TRACKS`/`SHARES`/`EVENTS`/`FAQS` are `landing_cards` rows. `TRACK_FILTERS` is the one constant left, because it is the three shared `levels.*` and not a collection.

**Two halves, in two places:**

| | Home | Editable how |
| --- | --- | --- |
| Which cards exist, in what order, a track's level and weeks, an event's date | `landing_cards` | add / reorder / delete, and the attributes ride on the copy form |
| Every word a card shows | `landing.*` in both locale files, with `landing_texts` in front | the bilingual editor |

**Its joins are by key, not by position.** A card looks up its own copy by its own slug (`LandingCard#prefix` — note `tracks` and `events` nest under `items.` in the locale files, which is the one thing that map exists for), so adding a card never shifts the copy of the card below it.

**The locale files are the default, not the last word — and for a card an admin created, there is no default at all.** `Landing.copy(key)` is the three-step ladder that reconciles those two cases:

```ruby
LandingText.for(key) || default(key).presence || LandingText.any(key).to_s
```

Every reader on every `Data` object goes through it, and so does the view — which is why the section headings in `home/index.html.erb` are `Landing.copy("tracks.title")` rather than `t()`. The steps matter in that order:

1. **What an admin wrote in this language.**
2. **What ships in this language** — `Landing.default` is `I18n.t(…, default: nil)`, and the explicit `nil` is load-bearing: without it a card an admin added renders `translation missing`. Because this beats step 3, a Thai-only rewrite still never displaces the English the repo ships.
3. **What an admin wrote in the other language.** This is what keeps an admin-made card visible on both pages rather than blank in one — and keeps a blank `name` out of the `Course`/`Event` JSON-LD.

Then:

- **A row is a departure from the default, never a copy of it.** `LandingText.write` deletes rather than stores when a box is cleared or retyped to match what ships, so the editor needs no reset control and the locale files can never be shadowed by a stale duplicate of themselves. That is invariant 9. For an admin-made card the default is nothing, so clearing simply removes the copy.
- **The editable surface is derived, not listed.** `Landing.groups` is built from the rows, so a card an admin adds arrives in the editor with copy fields of its own; `editable_keys` is the whitelist `LandingText` validates against and `AdminController#update_landing` reads params through. Chrome is deliberately outside it — `landing.brand_*`, `landing.nav.*` and `hero.logo_alt` belong to `shared/_header`, and `levels.*`/`units.*` are shared with the catalog, so the landing editor cannot reword another screen.
- **A track's level and an event's date are on the card, not in the copy.** They are one fact in both languages, so they are columns; they are edited on the same form as the copy because they are the same card. An event's `starts_on` is a real `date`, so an unparseable one casts to "undated" rather than shipping an invalid `startDate`.
- **Deleting a card deletes its copy** — `LandingCard`'s `after_destroy`. That is invariant 10; without it a slug that came back would silently inherit someone else's words.
- A card's slug is **generated, never typed** (`LandingCard.key_for`): an admin should not have to invent a stable identifier. `parameterize` strips non-ASCII, so a Thai-only title falls back to `"card"` plus a numeric suffix.
- `LandingText.overrides` and `Landing.cards` each read their whole table once per request and memoise on `Current`, for the same reason `Current.syllabus` exists. Anything that writes must call `LandingText.forget` / `Landing.forget_cards`.
- The taxonomy is **three copies that must agree** — the `CreateLandingCards` migration, `db/seeds.rb` above the `Rails.env.local?` fence, and `test/fixtures/landing_cards.yml`. `landing_card_test.rb` asserts the shape all three have to produce, exactly as `taxonomy_test.rb` does for the catalog.

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

**Failures are kept on purpose.** They are what `InstructorReport`'s "share failing on first attempt" is counted from, and half of what its average score is a mean of.

**`score` is what the server made of the attempt beyond whether it passed** — an integer percentage, the share of the step's criteria that matched. `grade_code` was always computing one boolean per `LessonContent::CHECKS` entry so the page could light its list, and throwing them away; this keeps them. A quiz is one right answer, so its score is honestly 0 or 100. Partial credit is given even on a fail, and a leftover `___` still fails outright — how close the source got and whether the attempt counts are two different questions.

Two things about it are load-bearing:

- **Stored, not derived.** Re-running `CHECKS` over a stored `answer` would re-mark old work under criteria that did not exist when it was submitted. A grade is a fact about a moment — the mirror of `Notification`, which stores a kind precisely so the *reader's* present wins.
- **NULL is not zero.** Rows written before the column existed were graded pass/fail and nothing more; they do not vote in the average. Counting them as zero would invent the measured-looking number the change removed.

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

**Still placeholder, and what it is waiting for:** the lesson's prose, quiz and coding task are the same for every topic — a content job, not a modelling one. That is now the only one. **Nothing on a staff-facing screen is invented any more**: the Teaching console's average exercise score was the last, and `submissions.score` retired it. Everything a learner sees is counted — the leaderboard, the Teaching console, awards, projects, hearts, notifications — off `sections`, `enrollments`, `topic_completions`, `submissions`, `proctor_events` and `notifications`.

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
post "lesson/incident" => "lessons#incident"    # the proctor reporting what it saw — the one post the lock does not guard
get  "notifications"      => "notifications#show"      # the bell alone, for the frame a
                                                       # broadcast pushes to come back to
post "notifications/read" => "notifications#read_all"  # the bell's "mark all read"
get "my-learning" => "my_learning#show"         # ?tab=progress|done
get   "profile"   => "profiles#edit"            # profile_path — the account's own details
patch "profile"   => "profiles#update"          # the only place an email address is ever set
patch "profile/password" => "profiles#update_password"  # changing it while signed in
get "map"         => "knowledge_maps#show"      # ?topic=<node id>&mode=course|project
get "progress"    => "progress#show"
get "leaderboard" => "leaderboards#show"        # ?tab=week|semester|university — shell, or the
                                                # board when the Turbo-Frame header asks for it
get "instructor"  => "instructor#show"
get "instructor/grades" => "instructor#grades"  # the roster as CSV; same staff gate as the screen
get "privacy"     => "policies#privacy"         # public — the PDPA notice
get "terms"       => "policies#terms"           # public — terms of use
get "robots.txt"  => "crawlers#robots"          # public — rendered, not a file in public/
get "sitemap.xml" => "crawlers#sitemap"         # public — the three readable pages
get "llms.txt"    => "crawlers#llms"            # public — the site in English, for a model
# ?tab= must match AdminConsole::TABS exactly — see the note below on why that
# whitelist is a security control and not a nicety.
get "admin"       => "admin#show"               # ?tab=features|overview|users|courses|landing|sections|queue|integrity|perms|audit
patch "admin/users/:id" => "admin#update"       # admin_user_path — the only role grant in the app
post "admin/integrity/:user_id/close"    => "admin#close_case"     # stamps a learner's unreviewed proctor events
post "admin/integrity/:user_id/notify"   => "admin#notify_case"
post "admin/integrity/:user_id/escalate" => "admin#escalate_case"
post   "admin/sections"                  => "admin#create_section"
patch  "admin/sections/:id"              => "admin#update_section"
post   "admin/sections/:id/enrol"        => "admin#enrol"
delete "admin/sections/:id/enrol/:user_id" => "admin#unenrol"
patch  "admin/landing"                   => "admin#update_landing"  # the copy, both languages at once
post   "admin/landing/cards"             => "admin#create_card"     # a card is created with its title, never nameless
patch  "admin/landing/cards/:id/move"    => "admin#move_card"       # ?dir=up|down
delete "admin/landing/cards/:id"         => "admin#destroy_card"    # takes the card's copy with it
root "home#index"                               # catalog signed in, /admin for an admin, landing when not
```

Screen state lives in the **query string**, not in client-side JS — filter chips, lesson steps, tabs and the map's selected node are all links. **The leaderboard's tabs are the reason that rule is worth stating twice:** they were links intercepted by the `panels` controller, which had no panel to show on that screen, so the switch replayed the rows it already had and picking "semester" changed the URL while the data stayed on "week". Each tab is a real cut of the data, so it has to reach the server; the interception is gone and the lazy frame is what makes the round trip read as a load rather than a stall. Controllers validate the param and fall back to a default rather than raising (`CourseCatalog::FILTERS.include?`, `LessonContent.step_for`, `Leaderboard.tab_for`, `AdminConsole.tab_for`). `AdminConsole.tab_for` matters twice over: the tab name is interpolated into a `render` path, so anything but a whitelisted value would be a template-injection foothold. The knowledge map derives which groups are expanded from the path to the selected node, so the URL alone determines the tree's state.

Two layouts:

- `layouts/application` — renders `shared/_app_header` (dark app chrome: nav, language toggle, gems/streak counters, notifications, account menu) when signed in, `shared/_header` (marketing) when not. `shared/_footer` closes **every** screen either way; only its first two link columns branch on the session (`ApplicationHelper#footer_columns` — landing anchors signed out, app routes signed in, since `#learn` would scroll nowhere on `/progress`). Its copy lives under `chrome.footer.*`, not `landing.*`, because it is shared chrome.
- `layouts/auth` — used by `SessionsController#new`, `RegistrationsController#new/create`, `PasswordsController#new/edit` via `layout "auth", only: …`. No app chrome; a split screen with `shared/_auth_hero` on the left.
  - **`only:` filters by action, not by template**, so an action that re-renders someone else's template needs to be named too. `RegistrationsController#create` renders `:new` when validation fails and was missing from the list — the rejected sign-up came back on `layouts/application`, marketing header and all. Sign-in and password reset redirect on failure, which is why only registration was affected. Add `create` to the list of any auth action that grows a re-render.

`shared/_head` is shared by both layouts — the layouts differ only in what wraps `<body>`.

### What a crawler reads

`robots.txt`, `sitemap.xml` and `llms.txt` are **rendered by `CrawlersController`, not checked into `public/`** — all three have to name absolute URLs and the app has no configured host (`config/deploy.yml` is still a placeholder), so the only thing that knows where the site lives is the request. A static `public/robots.txt` would be served first and the action would never run, which is why it was deleted rather than kept as a fallback.

- **`DISALLOWED` is the private half of the app spelled out**, and `test/controllers/crawlers_test.rb` asserts the sitemap against it — a path cannot be advertised and closed at the same time. robots.txt stops the crawl and `layouts/auth` adds `noindex, nofollow` to stop the indexing, since a disallowed path linked from elsewhere can still be listed as a bare URL.
- **The sitemap lists every page once per language**, each entry naming the whole hreflang set including itself — a cluster that does not name itself is discarded rather than read partially. `shared/_meta` publishes the same set as `<link rel=alternate>` plus an `x-default` pointing at Thai, and the canonical is the URL of *that translation* rather than of the path.
- **`AI_AGENTS` names the model crawlers** and gives them the wildcard group's rules verbatim; both groups render the same `_rules` partial. A group written by name *replaces* the wildcard rather than adding to it, so repeating the rules is the only way to keep the two equal.
- **`llms.txt` is the one page with a single language.** `#llms` forces `I18n.with_locale(:en)` whatever the session says, because the file is read by models rather than by students, and it says so in its own first paragraph. Everything it lists comes from `Landing`, so a card added to the landing page shows up there without a second edit.

Structured data is `SchemaHelper` plus `yield :schema` in `shared/_meta`. Every page carries the `EducationalOrganization`; a template adds its own documents with `content_for :schema` — the landing page publishes an `ItemList` of `Course`, a `FAQPage` and an `ItemList` of `Event`, all built from `Landing` and so all translated with the page. Two `ItemList`s on one page are told apart by `name`, which is the heading of the section they came from. Only the events whose `landing_cards` row carries a `starts_on` are published: `Event` without a `startDate` is invalid rather than vague, and "every Wednesday" is not a date. A collection an admin has emptied publishes no list at all, rather than an `ItemList` of nothing. Templates render before their layout, which is what lets a `content_for` in the body land in `<head>`. Each course names its provider as an `@id` reference to the organization rather than repeating the address, and carries no `offers`: the tracks have no price in this codebase, and inventing a free one to earn a richer search result would be a claim nothing here backs.

## Architecture notes

**All infrastructure is SQLite + database-backed.** There is no Redis, Memcached, or separate job runner:

- `solid_queue` for Active Job, `solid_cache` for `Rails.cache`, `solid_cable` for Action Cable — and Action Cable is now in use, so `solid_cable` is no longer dead weight in production. Development uses the `async` adapter and test the `test` one, which is why the bell can be driven locally at all; note that `async` is per-process, so a broadcast from `bin/rails runner` reaches no browser.
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
- `start_new_session_for(user, remember: true)` backs the "remember me" checkbox — `remember: false` gives a browser-session cookie instead of a dated one.
- **A session dies 30 days after it was created** (`Session::MAX_AGE`), and the cookie carries the same expiry so the browser stops sending a dead id. The cap is **absolute, not idle**, and that is a deliberate trade: an idle timeout has to touch the row on every authenticated request, and this is one Puma process over one SQLite file with a single writer — a write per page view is the cost every other decision here refuses. Thirty days is invisible to a student who signs in weekly through a semester, and it is what bounds a cookie lifted from a shared campus machine.
  - **Look a session up through `Session.live`, never a bare `find_by`.** Two places resolve that cookie — `Authentication#find_session_by_cookie` and `ApplicationCable::Connection#set_current_user` — and an expiry enforced in only one of them is an expiry that can be walked around. **This is no longer hypothetical** — the notification bell subscribes on every signed-in page, so a dead session's cookie is offered to the second one constantly.
  - `Session.expired` is the other half, swept nightly by `clear_expired_sessions` in `config/recurring.yml`. That also bounds how long the `ip_address` and `user_agent` on those rows are kept.
  - Revocation is still thin: `PATCH /profile/password` clears every other session and password reset clears all of them, but **reset needs a working mailer and SMTP is not configured**, so for an account with no email the 30-day cap is the only thing that ends a stolen session.
- **Sign-in is rate-limited twice, and the two keys stop different attacks.** `rate_limit … name: "ip"` is the default `by: request.remote_ip` and slows one machine working through a list of accounts; `name: "account"`, keyed on the posted `student_id`, slows one account being guessed at from many addresses. `name:` is what lets them coexist — without it the second declaration would replace the first. Both are backed by `solid_cache_store` in production, so neither is a no-op there; in test the cache is a `:null_store` and both are inert, which is why `sessions_controller_test.rb` lends the captured store a real `MemoryStore#increment` for the length of a block rather than changing `config.cache_store` for the whole suite.
- **A student signs in with a 13-digit student ID, and most accounts have no email at all.** Sign-up does not ask for one; `/profile` ("Edit info", `ProfilesController`) is the only place an account ever gets one, and the same screen is the only place `name`, `faculty` and `study_year` can be changed after sign-up. This is load-bearing rather than cosmetic: `PasswordsController#create` finds a user **by email and by nothing else**, so an account that has never opened that screen cannot recover a forgotten password. The account menu's "My profile" and the card on My Learning both link there.
- **There are two ways to change a password, and they answer different questions.** `/reset-password/:token` is for someone locked *out* — it needs an address and a working mailer. `PATCH /profile/password` is for someone signed *in* and needs neither, which is why it exists: with SMTP unconfigured, the reset flow reaches nobody, and without this a student had no route to a new password at all. It asks for the current one (`User#authenticate`) because the session cookie alone should not be enough, rate-limits at 10 in 3 minutes like the other password paths, and on success destroys every session **except the current one** — `sessions.destroy_all` would sign the student out of the device they are standing at.
- **`User#current_password` is an `attr_accessor`, not a column.** `errors.add(:current_password, …)` makes Active Model call `read_attribute_for_validation`, which is `send(:current_password)` — without the accessor the error raises `NoMethodError` instead of reporting anything. Any virtual field a form validates needs the same.
- **Two forms share `/profile`, so each render says which one the errors belong to.** `@errors_on` is `:profile` or `:password`, and `profiles/edit` renders `shared/_form_errors` only in the matching form; both actions edit the same `Current.user`, so without it a rejected password reports itself above the name and email fields.
- **A blank email must normalise to `nil`, not `""`.** The column is uniquely indexed and its uniqueness validation is `allow_blank`, so two accounts each storing `""` would raise `RecordNotUnique` from the database with nothing catching it first. `User`'s `normalizes :email_address` ends in `.presence` for exactly that reason, and `:faculty` does the same.
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
- `test/models/notification_bell_test.rb` and `test/controllers/notification_broadcast_test.rb` — the bell that redraws itself. The model side asserts what a broadcast may contain: a replace of the bell's own id, a frame naming a src, a placeholder to hold the header open, and **no copy and no CSRF token in either language** — both of which would be a bell nobody can read or use. The controller side asserts the other half: every signed-in page subscribes and a signed-out one does not, the frame a page renders has no `src` of its own, an admin acting on a case reaches that student's bell, and the refetched bell comes back in the *reader's* language carrying a token they can actually submit (with forgery protection turned on for the length of the exchange, the way `sessions_controller_test` lends the rate limiter a real cache store).
- `test/controllers/leaderboard_frame_test.rb` — the one screen that answers twice: that the shell ships a lazy frame and none of the rows behind it, that the frame comes back with the rows and without the `src` that would make it fetch itself forever, that the tab in the URL is the tab the frame counts, and that the frame is refused without a session exactly as the page is.
- **`test/fixtures/topic_completions.yml`, `submissions.yml`, `notifications.yml`, `landing_texts.yml` and `audit_events.yml` are deliberately empty and must stay present.** Tests that need progress, an attempt or an override make one; the files exist so fixtures clear the tables, because `bin/ci` seeds into the test database and those rows would otherwise outlive the users and topics they point at. `landing_texts.yml` is load-bearing beyond that: an empty table *is* the app as shipped, which is what lets `landing_test.rb`, `structured_data_test.rb` and `crawlers_test.rb` go on asserting against the locale files.
- **`courses.yml`, `course_modules.yml`, `topics.yml` and `landing_cards.yml` are the opposite** — they carry taxonomy, because `db:test:prepare` loads the schema and a schema holds no data. Each is one of three copies of the same rows that must agree: the migration (what production has), `db/seeds.rb` (what restores them after `db:seed:replant`) and the fixture. `taxonomy_test.rb` and `landing_card_test.rb` assert the shape all three have to produce.
- `test/controllers/languages_controller_test.rb` — the locale switch, that it sticks across requests, and that an unroutable locale 404s. `locale_negotiation_test.rb` covers the rest of the rule: which of `?lang=`, the session and `Accept-Language` wins, and that `?lang=` never persists.
- The three that nothing on screen would catch — `crawlers_test.rb` (robots.txt, the sitemap and llms.txt agreeing about what is public), `indexing_test.rb` (canonicals, the hreflang set, and which pages ask not to be indexed) and `structured_data_test.rb` (the JSON-LD each page publishes, in both locales).
- `test/controllers/profiles_controller_test.rb` — the account's own details: that an address saved there is the one password reset then finds, that clearing a field stores `NULL` rather than `""`, that a posted `student_id` or `role` is dropped, and, for the password half, that a wrong current password changes nothing, that the new one is what signs in afterwards, and that the change signs out other devices but not this one.
- `test/models/landing_card_test.rb`, `landing_text_test.rb` and `test/controllers/admin_landing_test.rb` — the landing CMS: the taxonomy's three copies agreeing, slugs generated rather than typed, a card moving and a card's deletion taking its copy; then that a copy row is only ever a departure from what ships, that a key the page does not render cannot be written, that a card written in one language shows that language in the other, and that adding, reordering and deleting all reach the page a stranger reads.
- `test/models/audit_event_test.rb` and `test/controllers/admin_audit_test.rb` — the console reporting on itself: that the actor is whoever is signed in, that the level is derived rather than stored, that a line reads in the reader's language, and — driven through every endpoint, so it cannot drift from the controller — that each action logs exactly once, that a failed one logs nothing, and that a reorder deliberately logs nothing at all.
- The three that guard what a session is worth: `test/models/session_test.rb` (`live` and `expired` partition the table, and the boundary belongs to the living), `test/controllers/session_expiry_test.rb` (a backdated row stops opening a gated screen, is refused exactly as a signed-out visitor is, and the cookie's own expiry matches `MAX_AGE`) and `test/controllers/log_filtering_test.rb` (the student ID and the profile PII never reach a log line — nothing on screen would ever show a regression here).
- The auth and role suites: `admin_test.rb` (the roster and the one place a role is granted), `user_test.rb` (the password rules and the `role` enum), `sessions_controller_test.rb` (including both sign-in rate limits, each proven not to trip the other), `registrations_`/`passwords_controller_test.rb`, `auth_switch_test.rb`, `legacy_auth_routes_test.rb` (the `redirect()`s above still resolve), `footer_test.rb` (the columns branch on the session), `test/tasks/admin_task_test.rb` (`admin:create` promotes rather than duplicates) and `test/tasks/instructor_task_test.rb` (`instructor:create` leaves an admin alone rather than demoting one).

Assertions compare against `I18n.t(...)` rather than literal strings; a copy change in the locale file should not break a test.

## Design system

**The single source of truth for the app UI's visual tokens is the `@theme` block in `app/assets/tailwind/application.css`.** Read it before changing anything visual.

`docs/design-system.md` documents the **current** system — crimson `#A81E32` on cream, IBM Plex Sans Thai — token by token, and keeps the **earlier** port from <https://eng.utcc.ac.th> (maroon `#8C1C36`, Noto Sans Thai Looped, daisyUI component anatomy) as a history section. The CSS wins where they disagree.

- **Tailwind v4, no daisyUI, no Node.** There are **no component CSS classes** — no `.btn`, no `.card`. If a recipe repeats, repeat the utilities.
- **`app/assets/tailwind/application.css` is the whole stylesheet.** There is no `app/assets/stylesheets/` directory. It is `@import "tailwindcss"`, one `@theme` block (tokens), one `@layer base` block (page defaults, focus ring, reduced motion), and a small set of `@utility` escape hatches — `brand-field`, `marker-partial`, `badge-ring`, `badge-fill`, `clip-hex`, `marker-none`, `skeleton`, `skeleton-on-chrome`. Every one exists because a multi-stop gradient or a clip-path cannot be expressed as a utility without inlining a raw colour into the markup. Adding another needs that same justification.
- **Never hardcode a hex anywhere else.** The `@theme` block is the only place one belongs. (The lone exception is the `theme-color` meta tag in `shared/_head`, which mirrors `--color-chrome`.)
- The palette is grouped by role, and the names say where a colour goes: `brand-*` (crimson ramp), `chrome-*` (the near-black header field), `on-chrome-*` (text sitting on it, brightest to dimmest), `surface-*`/`canvas`/`hairline-*` (light surfaces), `ink-*`/`muted-*` (text), plus `gold`, `success`, `danger`, `heat-0…4` (the contribution grid) and `code-*` (static syntax colouring).
- The type scale is **literal**: `text-14` is 14px expressed in rem. Half steps carry the design's fine-tuning and are spelled with a trailing `-5` — `text-13-5` is 13.5px, because a dot is not usable in a Tailwind theme key. Use `text-16`/`text-24`/`text-46`, never `text-base`/`text-2xl`/`text-4xl`. `text-54`/`64`/`80` exist only for the marketing landing page.
- Layout tokens: `max-w-page` (1320px, every app screen but the leaderboard), `max-w-narrow` (1000px, the leaderboard), `h-header` (64px). Radii are named by role — `rounded-field`, `rounded-card`, `rounded-panel`, `rounded-box`.
- **State travels on `data-*` attributes and is read by Tailwind variants** (`data-[state=correct]:`, `data-[open=true]:`, `group-open:`, `aria-selected:`). Stimulus controllers set an attribute; they do not juggle class lists. Keep it that way when adding interaction.
- Stimulus controllers: `header` (sticky + mobile drawer), `dropdown` (notifications, account menu), `tabs` (segmented controls that navigate), `panels` (tabs whose panels are all already in the document — a show/hide that can optionally push a path and title; it needs a `data-panels-target="panel"` to show, and the leaderboard's tabs were wired to it with none, which is why they are plain links now), `to_top`, `quiz` and `code_task` (in-browser lesson grading), `rewards` (listens for `quiz`/`code_task` reward events), `proctor` (lesson integrity monitoring), `toast` (transient messages). Accordions are native `<details>` — no controller.
- **Toasts are for feedback with no page load behind it**, and `shared/_flashes` is for everything that survives a redirect. `shared/_toasts` ships the host on both layouts that have chrome — not on `layouts/auth` — and anything raises one by dispatching, so a new caller wires nothing:

  ```js
  this.dispatch("show", { prefix: "toast", detail: { message, kind } })  // info | success | error
  ```

  The row is a `<template>` cloned per message, so no markup lives in JS, and **every string comes out of a `data-*` attribute the view rendered** — a message written in JS would be copy outside the locale files. The current callers are `quiz` and `code_task` on the one path with no other surface: a grade that never reached the server, where re-enabling the button or resetting the console looks identical to the click not registering. A *passed* grade deliberately raises none — the feedback panel and the console already say so and stay on screen. `test/controllers/toasts_test.rb` asserts the host, its targets and the callers' copy, because all of it is read out of the DOM by name and a rename fails silently.
- **A skeleton is a placeholder with a shape, and it belongs to the thing it stands in for.** `skeleton`/`skeleton-on-chrome` plus `animate-shimmer` are the tokens; the markup is per-screen, because a placeholder that does not repeat the real row's grid shifts the layout the moment the content lands. `leaderboards/_skeleton` is the worked one — it sits inside the lazy frame, repeats the board row's grid so it lines up under the one column header, matches its height through the type scale rather than a pixel count, and is `aria-hidden` behind a `role="status"` wrapper whose only text is `chrome.loading`. `shared/_app_notifications_refetch` holds the other kind: a single wordless square, because what it is holding open is a 38px hole in the header rail and a broadcast has no language to label it in. `shared/_loading_skeleton` is a whole-page version of the same idea and **nothing renders it** — a spare part, not a shared partial.
- `proctor_controller` mounts only for `Current.user.student?` — staff get the same bar with the controls inert. The sidebar's score is still per-page theatre, but each incident is POSTed fire-and-forget to `lesson/incident` and kept in `proctor_events` — the admin Integrity tab derives its cases from those rows (`Proctoring.cases`: a case is a learner's unreviewed events, closing it stamps them). The browser reports evidence against itself, which is why that endpoint skips the lock check. `Proctoring` hands the controller its weights and `lesson.proctor.*` the sentences; the log row is a `<template>` in the view, cloned per incident, so no markup lives in JS.
- `header_controller` receives its pinned state as **several** utilities via `data-header-pinned-class`, so it uses `classList.add/remove(...this.pinnedClasses)` — `classList.toggle` accepts only one class and will silently break if you switch back to it.
- Anything on the chrome field (header, hero, drawer, auth screens) needs a light-on-dark variant; a `border-brand text-brand` outline button renders invisibly there.

**Lesson grading runs on the server** — `POST /lesson/submit`, graded in `LessonContent`, recorded in `submissions`. The `quiz` and `code_task` controllers send what the student did and render the verdict they get back; neither knows the answer key. They share the posting helper in `app/javascript/grading.js`, which is outside `controllers/` because `pin_all_from` would otherwise register it as a Stimulus controller. `app/javascript/frame_recovery.js` sits outside it for the same reason and is the only other one — a single document-level listener rather than a behaviour attached to an element. Both are pinned by name in `config/importmap.rb` and imported from `application.js`.

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
