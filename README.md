# UTCC AI Fundamental

A place for UTCC students to learn about AI and share what they build with each other — learning topics, levelled tracks, a community feed, and events. Thai-first interface.

Rails 8.1 · Ruby 3.4.10 · SQLite · Hotwire (importmap, no Node)

## Getting started

```bash
bin/setup      # install gems, prepare the database, then start the server
bin/dev        # start the server on http://localhost:3000
```

## Everyday commands

```bash
bin/rails test                             # run the tests
bin/rails test test/models/user_test.rb:12 # run one test
bin/ci                                     # the full pipeline: lint, security scans, tests
bin/rubocop -a                             # autocorrect style
```

## Accounts

Email and password, built on Rails 8's built-in authentication:

- `/register` — sign up (display name, email, password; faculty and year optional)
- `/login` — sign in
- `/passwords/new` — request a reset link

Passwords must be at least 8 characters. The landing page is public; everything else requires an account, because `ApplicationController` applies `require_authentication` globally — new public actions must opt out with `allow_unauthenticated_access`.

No mail delivery is configured in development (`raise_delivery_errors = false`), so reset emails go nowhere. Preview the template at `/rails/mailers`, or grab the reset URL from `log/development.log`.

## Design

The visual system is ported from [eng.utcc.ac.th](https://eng.utcc.ac.th) — brand maroon `#8C1C36`, Noto Sans Thai Looped, hand-written CSS components against custom properties (no Tailwind, no Node build).

**`docs/design-system.md` documents every colour, the type scale, and each component**, including which values came from the reference site and where this app deliberately diverges. Read it before making visual changes. Tokens live in `app/assets/stylesheets/00_tokens.css`; don't hardcode hex values anywhere else.

## Next steps

The landing page content is still hardcoded in `HomeController#index`. Turning it into a real community site means replacing those arrays with models — topics and tracks for the learning material, and user-authored posts for the community feed.
