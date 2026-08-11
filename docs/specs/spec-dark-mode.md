---
id: SPEC-0047
type: spec
title: Dark mode, the palette toggle, and the fill/ink split
status: accepted
owners: ["@tech-lead", "@product-owner", "@design-owner"]
created: 2026-08-11
updated: 2026-08-11
review_by: 2026-08-25
supersedes: []
superseded_by: []
depends_on: [ADR-0047, ADR-0023, SPEC-0045]
implemented_by:
  - app/assets/tailwind/application.css
  - app/controllers/themes_controller.rb
  - app/controllers/concerns/localization.rb
  - app/views/shared/_theme_toggle.html.erb
  - app/views/layouts/application.html.erb
  - app/views/layouts/auth.html.erb
  - app/views/layouts/error.html.erb
  - lib/templates/error_page.html.erb
  - config/routes.rb
touches:
  - app/assets/tailwind/application.css
  - app/controllers
  - app/views
  - lib/templates
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - docs/design-system.md
enforced_by:
  - test/assets/dark_palette_test.rb
  - test/controllers/themes_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-PROD-001]
min_reviewer_skills: [SKILL-SPEC-002]
---

# Dark Mode, the Palette Toggle, and the Fill/Ink Split

> [Specifications](README.md) ·
> [Dark mode decision](../decisions/adr-0047-dark-mode-by-token-override.md) ·
> [Design system](../design-system.md) ·
> [Quality budgets specification](spec-m9-curriculum-quality-budgets.md)

## Problem

The app had one palette. A student reading a lesson at night got cream at full
brightness, and the only dark surface in the product was the header they were
trying to read past.

The obvious cost of adding a second palette is touching every screen. It is not
the cost here: every colour in this app is a token, no inline style carries one,
and the only hex outside the stylesheet is a meta tag. The real costs are two
different ones. First, a preference has to be answered *before the first paint*
or the visitor sees the wrong palette flash. Second, one of the tokens cannot be
flipped at all — crimson does two jobs, and no single value does both at AA.

## Invariants

### The palette

1. Dark mode is a redefinition of `--color-*` variables. No template carries a
   `dark:` utility.
2. The dark values live in two blocks with identical token sets: `.dark`, and
   `@media (prefers-color-scheme: dark) { :root:not(.light) }`.
3. Neither block redefines a `chrome-*` or `on-chrome-*` token. The header and
   footer are the same in both palettes.
4. Neither block defines a token the `@theme` block does not.
5. `--color-canvas` in dark is darker than `--color-chrome`, so the header lifts
   off the page; `--color-surface` is lighter than both.
6. Every text pair in `DarkPaletteTest::PAIRS` clears WCAG 2.2 AA — 4.5:1 for
   body text, 3.0:1 for large text and non-text UI — in **both** palettes.
7. White on a `bg-brand` fill clears 4.5:1 in both palettes.

### The fill/ink split

8. `brand` is a fill colour and is the same value in both palettes.
9. `brand-ink` and `brand-ink-deep` are crimson as text and as borders, and lift
   in dark mode. `text-brand` and `border-brand` do not exist.
10. `text-surface` does not exist. Text on a brand fill or on the chrome field
    is `text-white`.

### The preference

11. The preference is `session[:theme]`, one of `"light"`, `"dark"`, or absent.
12. Absent means the media query answers. Choosing "system" deletes the key
    rather than storing a third value.
13. `<html>` carries `class="dark"`, `class="light"`, or no class, on all three
    layouts — application, auth, and error.
14. `POST /theme/:theme` is the only way to set it, constrained to
    `light|dark|system`. There is no GET route: Turbo prefetches links on hover.
15. The toggle renders on the marketing header, the app header, and the auth
    hero, beside the language toggle, and marks the current choice with
    `aria-current`.
16. Its labels are bilingual and its buttons carry an accessible name.
17. The toggle's form submits with `data-turbo: false`. Turbo never updates
    attributes on `<html>`, so a Turbo visit would leave the palette stale.
18. There is no pre-paint script, and no client-side storage of the preference.

### The flat error pages

19. `public/*.html` carry both palettes, switched by `prefers-color-scheme`
    alone: they are served when there is no app to read a session.
20. Their dark values match the `.dark` block.

## Acceptance Criteria

- A visitor whose system is light and who has chosen nothing gets the light
  palette and no class on `<html>`.
- Choosing dark gives `html.dark` and the dark canvas.
- Choosing light while the system is dark gives `html.light` and the light
  canvas — the explicit choice wins.
- Choosing system while the system is dark gives no class and the dark canvas.
- `GET /theme/dark` is a 404 and leaves the session untouched.
- `POST /theme/sepia` is a 404 and leaves the session untouched.
- The toggle appears on `/`, `/login`, and a signed-in screen, with three
  buttons and `aria-current` on the chosen one.
- The two dark blocks in the stylesheet define exactly the same tokens.
- Every pair in `PAIRS` clears its floor in both palettes.

## Verification

- `test/assets/dark_palette_test.rb` parses the stylesheet and checks invariants
  1–7 as arithmetic, including that the two blocks agree and that the chrome
  family is untouched.
- `test/controllers/themes_test.rb` covers the class on `<html>` for each
  choice, the three layouts, `aria-current`, the Thai labels, the refused GET,
  and the refused unknown palette.
- The four-way preference matrix (system light/dark × chosen light/dark/system)
  was driven in a real browser with an emulated `prefers-color-scheme` on
  2026-08-11 and screenshotted in both palettes. Not automated: the system
  tests drive one browser with one fixed preference, and emulating the media
  feature needs CDP.
- `bin/verify` runs the whole gate.

## Out of scope

**The light palette's own AA gaps.** `muted-2` is 3.81:1 on a card and 3.48:1 on
the page against a 4.5:1 floor, and it carries meta text, captions and table
cells. It predates this work and fixing it moves a shipped colour, which is a
design decision rather than a dark-mode one. It is recorded as
`DarkPaletteTest::LIGHT_BELOW_AA` and the dark palette's equivalents pass.

**The stale `lang` attribute.** The language toggle has the same Turbo
limitation this spec fixes for the theme — `<html lang>` is not updated on a
Turbo visit, so after switching language the document's declared language is
stale until a reload. It is a pre-existing accessibility bug with the same
one-line fix, and it belongs to whoever owns the language toggle.

**Per-user persistence.** The preference is a session, so it does not follow an
account to another browser. Matching the language toggle was the point; a column
on `users` is a later decision if it is wanted.
