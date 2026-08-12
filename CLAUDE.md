# Repository Instructions

Follow the [System Development Flow Master](docs/system-development-flow-master.md).

[Workflow Guide for All Roles](docs/system-development-flow-role-guide.md) ·
[Documentation Templates](docs/templates/README.md) ·
[Skill Library](docs/skills-library-README.md) ·
[Project Skill Router](.agents/skills/use-project-skill-library/SKILL.md)

## Stack

Rails 8.1 · PostgreSQL · Hotwire (Turbo + Stimulus, import maps, Propshaft) · Tailwind CSS 4 · Minitest/Capybara.

## Commands

- `bin/setup` — install dependencies and prepare the database
- `bin/dev` — run the app (Rails server + Tailwind watcher)
- `bin/rails test` — unit and integration tests; `bin/rails test:system` for system tests
- `bin/verify` — the full local CI gate (docs freshness, RuboCop, bundler-audit, importmap audit, Brakeman, all tests, seed replant). Run it before pushing.

## Architecture

- Standard Rails MVC plus `app/services/` for domain services (`observability/`, `quality/`, `recovery/`, `recruitment/`).
- Two domains share the app: the **academy** (courses, enrollments, lessons, certificates, proctoring) and the **recruitment platform** (`Recruitment::` namespace across models, controllers, and services).
- The UI is bilingual: `config/locales/en.yml` and `config/locales/th.yml` must stay in sync. PDF generation (Prawn) bundles Noto Sans Thai for Thai text.

## Invariants

- Every phase of work produces a Markdown artifact in `docs/` — `decisions/adr-*.md`, `specs/spec-*.md`, `releases/`, `runbooks/`, `postmortems/`. Before changing existing behavior, find the governing spec in `docs/specs/` and ADR in `docs/decisions/` and keep them consistent with the code.
- CI (`config/ci.rb`) treats security scans as gates, not advice: Brakeman, bundler-audit, and importmap audit failures block the build.
- Every route leads somewhere: a route's action must exist, and a GET that renders no template must be listed with its reason in `test/operations/route_reachability_test.rb`. A screen nothing links to is still a screen someone can reach.
