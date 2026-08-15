---
id: SPEC-0047
type: spec
title: Dark mode, the palette toggle, and the fill/ink split
status: accepted
owners: ["@tech-lead", "@product-owner", "@design-owner"]
created: 2026-08-11
updated: 2026-08-15
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
6a. `muted-2` clears 4.5:1 on every background it sits on: `surface`, `canvas`,
    `surface-2` and `surface-4`. It may not be lightened to restore a visible
    step below `muted`; `muted-3` and `muted-4` are exempt as inactive states.
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
15. The theme selector renders on the marketing header and in the signed-in
    account menu, beside the language selector, but not on authentication
    screens. Its button names the current choice; its dropdown lists light,
    dark, and system, with `aria-current` on the selected option. The language
    selector uses the same dropdown shape. On the public navbar, both selectors
    follow the sign-up action; in a signed-in session, both are removed from the
    header rail and nested in the profile dropdown.
16. Its labels are bilingual and its buttons carry an accessible name.
17. The toggle's form submits with `data-turbo: false`. Turbo copies only `lang`
    and `dir` from the incoming page's `<html>`, so a Turbo visit would leave
    the palette class stale and the palette unchanged until a reload.
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
- The selector appears on `/` and inside the profile dropdown on a signed-in
  screen, while `/login` shows neither preference selector. The signed-in
  header rail carries no standalone preference controls. Its dropdown contains
  three theme buttons and `aria-current` marks the chosen one.
- The language selector's dropdown contains every available locale and names
  each language in that language.
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

**Restoring the light palette's grey hierarchy.** `muted-2` was 3.81:1 on a card
and 3.48:1 on the page and is now `#746A62`, which clears AA everywhere it sits
(invariant 6a). The cost is that it lands 1.06× from `muted` and the two read as
one weight in light mode — a compliant value needs a luminance at or below
0.1507 and `muted` is 0.1373, so the ramp has one step more than the budget
allows. Getting the hierarchy back means darkening `muted` to make room, which
moves supporting copy across 515 more occurrences and belongs to the design
owner. See the amendment in ADR-0047.

**The language selector's submission behavior.** An earlier draft of this spec
claimed it had the same staleness — it does not. Turbo copies exactly two
attributes from the incoming page's `<html>`, `lang` and `dir`, and nothing
else; verified in `turbo.min.js` and in a browser, where switching language over
a Turbo visit updates `lang` correctly. That is precisely why the theme needs
invariant 17: `class` is not in the copied set. The two selectors now share a
dropdown presentation, while only the theme form opts out of Turbo.

**Per-user persistence.** The preference is a session, so it does not follow an
account to another browser. Matching the language toggle was the point; a column
on `users` is a later decision if it is wanted.
