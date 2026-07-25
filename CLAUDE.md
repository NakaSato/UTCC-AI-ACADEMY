# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

A learning-and-sharing site for UTCC students getting started with AI: learning topics, levelled tracks, a student community feed, and events. Thai-first (`lang="th"`) — all UI copy, flash messages, and validation output are in Thai.

Rails 8.1, Ruby 3.4.10, module `UtccAiFundamental`. Currently: a themed public landing page (`home#index`) and full email/password authentication. The landing-page content is **hardcoded arrays in `HomeController#index`** — there are no Topic/Track/Post models yet, so that controller is the seam where real models will replace placeholders.

## Commands

```bash
bin/setup              # install gems, db:prepare, clear logs/tmp, then exec bin/dev
bin/setup --skip-server # same without booting the server
bin/dev                # foreman: rails server + tailwindcss:watch (Procfile.dev)
bin/ci                 # full local CI pipeline (steps defined in config/ci.rb)

bin/rails tailwindcss:build   # one-off CSS build into app/assets/builds/tailwind.css
bin/rails tailwindcss:watch   # rebuild on change (what bin/dev runs)
```

`bin/dev` is now required for CSS changes to take effect — `bin/rails server` alone
serves whatever `app/assets/builds/tailwind.css` was last built. `assets:precompile`
builds Tailwind first, so the Dockerfile needs no extra step.

Tests (Minitest, not RSpec):

```bash
bin/rails test                          # all tests except system tests
bin/rails test test/models/foo_test.rb  # single file
bin/rails test test/models/foo_test.rb:42  # single test by line number
bin/rails test:system                   # Capybara + Selenium, not run by bin/ci or bin/rails test
bin/rails db:test:prepare test          # what GitHub Actions runs
```

Lint and security (each is also a `bin/ci` step and a separate GitHub Actions job):

```bash
bin/rubocop            # rubocop-rails-omakase style; -a to autocorrect
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit      # gem CVEs; ignore entries go in config/bundler-audit.yml
bin/importmap audit    # JS dependency CVEs
```

`bin/ci` also runs `env RAILS_ENV=test bin/rails db:seed:replant`, so `db/seeds.rb` must stay runnable against a fresh test database. System tests are commented out in `config/ci.rb` but do run in GitHub Actions.

## Architecture notes

**All infrastructure is SQLite + database-backed.** There is no Redis, Memcached, or separate job runner:

- `solid_queue` for Active Job, `solid_cache` for `Rails.cache`, `solid_cable` for Action Cable.
- In production these live in *separate* SQLite databases (`storage/production_{queue,cache,cable}.sqlite3`) declared as extra entries under `production:` in `config/database.yml`, each with its own `migrations_paths` (`db/queue_migrate`, etc.). Their schemas are `db/{queue,cache,cable}_schema.rb` — do not fold these into `db/schema.rb`.
- Workers run in-process: `config/puma.rb` loads `plugin :solid_queue` when `SOLID_QUEUE_IN_PUMA` is set, which `config/deploy.yml` sets. `bin/jobs` runs the supervisor standalone. Recurring jobs go in `config/recurring.yml`.
- Development and test use a single `storage/development.sqlite3` / `storage/test.sqlite3`; the solid_* adapters are only wired up in `config/environments/production.rb`.

**Frontend is importmap + Hotwire, still no Node.** Add JS dependencies with `bin/importmap pin <pkg>` (writes to `config/importmap.rb`, vendors into `vendor/javascript`) — never npm/yarn. Stimulus controllers in `app/javascript/controllers/` are auto-registered via `pin_all_from`; the filename determines the identifier. Assets are served by Propshaft (no Sprockets manifest, no `app/assets/config/`). CSS is Tailwind v4 via `tailwindcss-rails`, which ships a standalone binary — there is still no npm, no `package.json`, and no PostCSS config.

**Deployment is Kamal + Docker**, configured in `config/deploy.yml` (currently placeholder server `192.168.0.1` and registry `localhost:5555`). `storage/` is a persistent Docker volume — that's where the production SQLite files live. Thruster fronts Puma in the container. `RAILS_MASTER_KEY` decrypts `config/credentials.yml.enc`.

Tests run in parallel by default (`parallelize(workers: :number_of_processors)` in `test/test_helper.rb`) and load all fixtures — keep tests isolated from shared mutable state.

## Authentication

Built on Rails 8's `bin/rails generate authentication` (cookie sessions in a `sessions` table, no Devise), plus a hand-written `RegistrationsController` since the generator omits sign-up.

- **Everything requires login by default.** `ApplicationController` includes `Authentication`, whose `included do` block adds a global `before_action :require_authentication`. Any publicly reachable action must opt out with `allow_unauthenticated_access` — `HomeController` does this for `:index`. Forgetting it is the usual cause of an unexpected redirect to `/session/new`.
- `Current.user` / `Current.session` (an `ActiveSupport::CurrentAttributes`) are how views read the signed-in user; `authenticated?` is the exposed helper method.
- `User` validates a minimum password length of 8. The generator's fixtures and password-reset test predate that rule — a password shorter than 8 characters in a test will fail validation rather than the assertion you intended.
- Routes: `resource :session` (login), `resource :registration` (sign-up), `resources :passwords` (reset). `/login` and `/register` are `redirect()` aliases, deliberately not route names, so there's one canonical path each.

## Design system

The visual language is ported from <https://eng.utcc.ac.th> — **`docs/design-system.md` records every colour, the type scale, and the component anatomy, with provenance.** Read it before changing anything visual.

- **Tailwind v4, no daisyUI, no Node.** The reference site uses Tailwind + daisyUI; this app takes the Tailwind half (through `tailwindcss-rails`' standalone binary) and expresses the daisyUI components it needs as utility classes in the markup. There are **no component CSS classes** — no `.btn`, no `.card`. If a recipe repeats, repeat the utilities.
- **`app/assets/tailwind/application.css` is the whole stylesheet.** There is no `app/assets/stylesheets/` directory any more. The file is `@import "tailwindcss"` plus one `@theme` block (the tokens), one `@layer base` block (page defaults, focus ring, reduced motion), and exactly two `@utility` escape hatches: `brand-field` (the scrim-over-gradient maroon field) and `marker-none` (`<details>` arrow suppression). Adding a third needs a reason that utilities genuinely cannot express.
- Brand primary is maroon `#8C1C36`; the full ramp and neutrals are `--color-*` entries in that `@theme` block. **Never hardcode a hex anywhere else** — that block is the only place one belongs.
- The type scale is **named by intended px but valued in rem** (`text-18` is 1rem), ported 1:1 from upstream. Use `text-18`/`text-24`/`text-44`, not `text-base`/`text-2xl`/`text-4xl`.
- `stylesheet_link_tag :app` resolves to the single build at `app/assets/builds/tailwind.css` (Propshaft picks it up from the builds directory). Cascade order no longer matters — Tailwind sorts its own layers.
- Interactivity is Stimulus: `header` (sticky-on-scroll + mobile drawer), `tabs` (filter by level), `to-top`. Accordions are native `<details>` — no controller. State that CSS reacts to is carried on `data-*` attributes and read with Tailwind variants (`data-[open=true]:`, `group-data-[open=true]:`, `group-open:`, `aria-selected:`).
- `header_controller` receives its pinned state as **several** utilities via `data-header-pinned-class`, so it uses `classList.add/remove(...this.pinnedClasses)` — `classList.toggle` only accepts one class and will silently break if you switch back to it.
- Anything placed on the maroon field (header, hero, drawer, auth screens) needs a light-on-dark variant; the default outline button (`border-brand text-brand`) renders maroon-on-maroon there and disappears. Use `border-surface text-surface hover:bg-surface hover:text-brand-deep` instead.

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
