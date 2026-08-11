---
id: ADR-0047
type: adr
title: Ship dark mode by overriding tokens, and split crimson into a fill and an ink
status: accepted
owners: ["@tech-lead", "@product-owner", "@design-owner"]
created: 2026-08-11
updated: 2026-08-11
review_by: 2026-08-25
supersedes: []
superseded_by: []
depends_on: [ADR-0023, ADR-0046]
implemented_by:
  - SPEC-0047
touches:
  - app/assets/tailwind/application.css
  - app/controllers/themes_controller.rb
  - app/controllers/concerns/localization.rb
  - app/views/shared/_theme_toggle.html.erb
  - app/views/layouts/application.html.erb
  - app/views/layouts/auth.html.erb
  - app/views/layouts/error.html.erb
  - lib/templates/error_page.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - docs/design-system.md
enforced_by:
  - test/assets/dark_palette_test.rb
  - test/controllers/themes_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Ship Dark Mode by Overriding Tokens, and Split Crimson Into a Fill and an Ink

> **Decision state:** Accepted by the user on 2026-08-11. Dark mode redefines the
> `--color-*` variables rather than adding `dark:` utilities, the preference is
> session-backed like the language toggle, and `brand` becomes two tokens
> because one crimson cannot meet AA in both of its jobs.

> [Decision Records](README.md) ·
> [Dark mode specification](../specs/spec-dark-mode.md) ·
> [Quality budgets decision](adr-0023-curriculum-quality-budgets.md) ·
> [Server-raised toasts decision](adr-0046-server-raised-toasts.md)

## Context

The app shipped one palette: crimson on cream, with a near-black chrome field
under the header and footer. Every colour in it is a token — `docs/design-system.md`
makes "never hardcode a hex outside `@theme`" a rule, and an audit found it
held: of thirty inline `style` attributes across the views, **none** carries a
colour, and the only hex outside the stylesheet is the `theme-color` meta tag.

That is the whole reason dark mode is a small change rather than a large one.

The usual recipe — the one the Rails Blocks switcher documents — is a `dark`
class plus `dark:` variants in the markup and a pre-paint `<script>` reading
`localStorage`. Two parts of that do not fit here.

## Decision

1. **Redefine the tokens, do not add variants.** `bg-canvas` compiles to
   `background-color: var(--color-canvas)`, so a block that gives that variable
   a new value repaints the product. No template carries a `dark:` utility.
2. **The chrome family does not change.** Dark mode is "the rest of the app
   joins the chrome": the header and footer are identical in both palettes, the
   canvas sits *below* chrome so the header still lifts off the page, and cards
   lift above both.
3. **The preference is `session[:theme]`, rendered as a class on `<html>`** —
   the language toggle's twin, POST for the same reason (Turbo prefetches links
   on hover). "System" is stored as *no* preference, which hands the answer to
   `@media (prefers-color-scheme: dark)`, exactly as an unset locale falls
   through to `Accept-Language`. An explicit "light" is its own class because it
   has to beat a dark system setting.
4. **No pre-paint script.** The server knows the answer when it renders, so
   there is no flash of the wrong theme to prevent. This also sidesteps the CSP
   question entirely (ADR-0046 is the case where an injected script could not be
   nonced).
5. **`brand` splits into a fill and an ink.** `bg-brand` stays crimson in both
   palettes; `text-brand-ink` and `border-brand-ink` lift to `#E4798D` in dark.
   289 utility occurrences were renamed. `text-brand` no longer exists.
6. **The theme toggle submits with `data-turbo: false`.** Measured, not assumed:
   Turbo copies `lang` and `dir` off the incoming page's `<html>` and nothing
   else, so a Turbo visit leaves `class` stale and the palette unchanged until a
   reload. The language toggle beside it needs no such treatment, because `lang`
   *is* copied.
7. **The flat error pages get a dark palette too**, via `prefers-color-scheme`
   only — they are served when there is no app to read a session.

## Alternatives

**`dark:` variants in the markup.** The documented approach, and it would mean
touching every view that names a colour — hundreds of files — to say twice what
the token already says once. It also puts the palette in the templates, where
`docs/design-system.md` has spent the whole project keeping it out.

**A pre-paint script with `localStorage`.** Standard, and necessary when the
server cannot know the preference. Here the server can, so the script would add
an inline `<script>` (noncing it correctly on every render), a second source of
truth the server cannot see, and a preference that does not follow an account
between browsers — to solve a flash that does not occur.

**Keep `brand` as one token.** This is the alternative that is not merely
unattractive but arithmetically impossible, which is why the rename happened.
For white text on a brand fill to reach 4.5:1 the fill's relative luminance must
be **≤ 0.183**; for that same crimson to reach 4.5:1 as text on the dark canvas
it must be **≥ 0.210**. The range is empty. Keeping one token means shipping a
WCAG failure on either 96 buttons or 200 links, and SPEC-0023 sets WCAG 2.2 AA
as the target. `gold-ink` and `success-ink` already named this distinction, so
`brand-ink` follows the vocabulary rather than inventing one.

**Put the class on `<body>` instead of `<html>`.** Would survive Turbo without
the full reload, but `color-scheme` belongs on the root — it is what themes the
scrollbar and form controls — and a body-scoped palette leaves the overscroll
area unthemed.

**Adopt the Rails Blocks switcher.** Same two blockers as its toast component
(ADR-0046): the files are a download rather than a dependency, and its
`theme_controller.js` would collide. Its preference contract — `data-theme`, a
`dark` class, `color-scheme` — is good, and the class and `color-scheme` parts
are what this implements.

## Consequences

- A screen written today is already dark-mode correct if it uses tokens, which
  the conventions already require. Nothing needs revisiting per screen.
- The dark palette is written twice, once per selector, because CSS cannot share
  a declaration block across a media query. A test fails when they drift.
- `text-brand` is gone; `text-brand-ink` replaces it. Anything merged from an
  older branch will need the same rename.
- `text-surface` is gone too — all 38 uses meant "white on a dark field", and a
  surface colour that goes dark with the palette is the wrong token for that.
  They are `text-white` now.
- **A pre-existing accessibility defect surfaced and was then fixed** (see the
  amendment below): `muted-2` — meta text, captions, table cells — was 3.81:1
  on a card and 3.48:1 on the page in the *light* palette, below the 4.5:1 AA
  floor. It predated this work; measuring the palette for dark mode is what
  found it.

## Amendment, 2026-08-11: the light palette's grey ramp

`muted-2` is now `#746A62`, the lightest value that clears 4.5:1 on every
background it sits on — white, canvas, `surface-2`, `surface-4`, worst case
4.54 on `surface-2`. It was `#8B8179`.

The consequence is worth recording, because it is not a preference. A compliant
`muted-2` needs a relative luminance at or below **0.1507**, and `muted` above
it is already **0.1373**; the two therefore sit 1.06× apart and read as one
weight in light mode. **The light ramp has one more grey step than the contrast
budget allows.** Dark mode keeps a real step, because its surfaces leave room
below `muted`.

The alternative, not taken, is to darken `muted` (`#6F6660` → roughly `#5B534E`)
to make room, which restores a visible hierarchy and keeps both compliant. It
was rejected for scope rather than for merit: it moves supporting copy across
515 more occurrences and is a visible change to shipped design that belongs to
the design owner rather than to a dark-mode slice.

`muted-3` and `muted-4` stay below the floor: they carry disabled text and
inactive states, which WCAG 1.4.3 exempts.

## Fitness Functions

- `test/assets/dark_palette_test.rb` — the two dark blocks are identical, define
  no chrome token, define nothing the light theme lacks, and every text pair
  clears its WCAG floor in both palettes, including white on a brand fill.
- `test/controllers/themes_test.rb` — the class on `<html>` for each of the
  three choices, the toggle on all three layouts, `aria-current`, the Thai
  labels, and that the route refuses GET and an unknown palette.
- `bin/verify` runs the whole gate.
