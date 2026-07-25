# UTCC AI Fundamental

A place for UTCC students to learn about AI and share what they build with each other — learning topics, levelled tracks, a community feed, and events. Thai-first interface.

Rails 8.1 · Ruby 3.4.10 · SQLite · Hotwire (importmap, no Node)

![The course catalog — the first screen a signed-in student sees](docs/screenshots/catalog.png)

## Getting started

```bash
bin/setup      # install gems, prepare the database, then start the server
bin/dev        # start the server on http://localhost:3000
```

Use `bin/dev` rather than `bin/rails server` — it runs the Tailwind watcher alongside Puma, so CSS changes actually rebuild.

## Everyday commands

```bash
bin/rails test                             # run the tests
bin/rails test test/models/user_test.rb:12 # run one test
bin/ci                                     # the full pipeline: lint, security scans, tests (run locally — there is no CI service)
bin/rubocop -a                             # autocorrect style
```

## Accounts

Email and password, built on Rails 8's built-in authentication:

- `/register` — sign up (display name, email, password; faculty and year optional)
- `/login` — sign in
- `/forgot-password` — request a reset link
- `/reset-password/:token` — set a new password (the link in the email)

Passwords must be at least 8 characters. The landing page is public; everything else requires an account, because `ApplicationController` applies `require_authentication` globally — new public actions must opt out with `allow_unauthenticated_access`.

No mail delivery is configured in development (`raise_delivery_errors = false`), so reset emails go nowhere. Preview the template at `/rails/mailers`, or grab the reset URL from `log/development.log`.

## Design

The visual system is ported from [eng.utcc.ac.th](https://eng.utcc.ac.th) — brand maroon `#8C1C36`, DB Heavent with Noto Sans Thai Looped as fallback, Tailwind v4 through `tailwindcss-rails` (still no Node, no npm).

**`docs/design-system.md` documents every colour, the type scale, and each component**, including which values came from the reference site and where this app deliberately diverges. Read it before making visual changes.

`app/assets/tailwind/application.css` is the entire stylesheet: the `@theme` token block, a small `@layer base`, and two `@utility` escape hatches. There are no component classes — recipes are repeated as utilities in the markup — and no hex value belongs anywhere but that `@theme` block.

## Next steps

The landing page content is still hardcoded in `HomeController#index`. Turning it into a real community site means replacing those arrays with models — topics and tracks for the learning material, and user-authored posts for the community feed.
