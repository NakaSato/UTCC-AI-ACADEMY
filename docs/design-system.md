---
---

# UTCC AI Academy — UI Design System

**Tags:** [#design](tags.md#design) [#frontend](tags.md#frontend) [#accessibility](tags.md#accessibility)

The app UI's tokens were ported from the **"UTCC AI Fundamental App UI" design** (claude.ai/design project `7a17af7d`): crimson on cream, near-black chrome, IBM Plex Sans Thai. An earlier system, extracted from <https://eng.utcc.ac.th>, preceded it — see "History: the eng.utcc.ac.th port" at the end for what it was and what survives from it.

**The single source of truth is the `@theme` block in `app/assets/tailwind/application.css`.** This document explains the values and the conventions around them; where the two ever disagree, the CSS wins. Values below were read from that file (as of 2026-07-27).

## Stack

Tailwind v4 through `tailwindcss-rails`, which ships a standalone binary — **no Node, no npm, no `package.json`, no PostCSS config, no daisyUI**. `bin/rails tailwindcss:build` compiles to `app/assets/builds/tailwind.css`, which `stylesheet_link_tag :app` picks up through Propshaft. `bin/dev` runs `tailwindcss:watch` alongside the server (`Procfile.dev`); `assets:precompile` builds it for Docker, so the Dockerfile needs no extra step. A CSS change made under bare `bin/rails server` will not appear until something rebuilds.

Everything lives in one file, `app/assets/tailwind/application.css`. There is no `app/assets/stylesheets/` directory. The file is:

| Block | Holds |
|---|---|
| `@custom-variant dark` | one line, so a `dark:` utility is available if a screen ever needs one. Almost nothing does — see below |
| `@theme` | every token — `--color-*`, `--text-*`, `--radius-*`, `--shadow-*`, `--breakpoint-*`, `--container-*`, `--animate-*` and their keyframes. **The light palette, and the only place a raw hex belongs apart from the dark block below.** |
| `@layer theme` | the dark palette: the same `--color-*` names with dark values, twice — once under `.dark`, once under `@media (prefers-color-scheme: dark)` |
| `@layer base` | page defaults: smooth scrolling with header-clearing `scroll-padding-top`, the button-cursor preflight restore, the `:focus-visible` ring, the reduced-motion block |
| `@utility` × 8 | escape hatches for multi-stop gradients and clip-paths — see below |

The one hex outside the file is the `theme-color` meta tag in `shared/_head`, which mirrors `--color-chrome` (`#17120F`) because a meta tag cannot read a CSS variable. Chrome is the same value in both palettes, so one tag still answers for both.

### Dark mode

**No template carries a `dark:` utility, and none should.** Every colour in the app is a token, so dark mode redefines the tokens and the whole product repaints. `bg-canvas` compiles to `background-color: var(--color-canvas)`, and `.dark` gives that variable a different value.

The design is *the rest of the app joins the chrome*. The chrome family and the `on-chrome-*` ramp are the one part that does not change — they were drawn for a near-black field already — so the header and footer look identical in both palettes. The canvas goes **below** chrome (`#0F0C0B` against `#17120F`) so the header still lifts off the page, and cards lift above both.

Which palette a visitor gets is `session[:theme]`, rendered as a class on `<html>` and toggled by `shared/_theme_toggle` — the language toggle's twin, POST for the same reason. No preference at all means no class, and the media query answers, exactly as an unset locale falls through to `Accept-Language`. There is **no pre-paint script**: the server knows the answer when it renders, so there is no flash to prevent. See SPEC-0047.

Two things to know before touching it:

- **The dark block is written twice** — once for `.dark`, once for the media query — because CSS cannot share a declaration block across the two. `test/assets/dark_palette_test.rb` fails if they drift, and also checks every text pair against WCAG AA in both palettes.
- **The theme toggle submits with `data-turbo: false`.** Turbo replaces `<body>` and merges `<head>` but never touches attributes on `<html>`, so a Turbo visit would leave the class stale and the palette unchanged until a reload.

## Color

Tokens are grouped by **role**, and the names say where a colour goes — not what it looks like. A view never needs to know a hex; it asks for `bg-brand`, `text-muted`, `border-hairline-2`.

### Brand — the crimson ramp

| Token | Hex | Used for |
|---|---|---|
| `brand` | `#A81E32` | primary **fills**, active state, progress — the same in both palettes |
| `brand-deep` | `#7F1526` | hover on brand fills |
| `brand-ink` | `#A81E32` → `#E4798D` | crimson as **text and borders**; lifts in dark mode |
| `brand-ink-deep` | `#7F1526` → `#F0A3AE` | its hover |
| `brand-tint` | `#FDF6F6` | selected row, soft panel |
| `brand-line` | `#F0DCDD` | hairline on a tint panel |
| `brand-soft` | `#E79AA4` | the "learned" pill border |
| `brand-accent` | `#8F2130` | error text |
| `brand-alert` | `#C4566A` | error border, wrong-answer state |

### Chrome — the near-black field the header and dark panels sit on

| Token | Hex | Used for |
|---|---|---|
| `chrome` | `#17120F` | the header field itself |
| `chrome-deep` | `#0F0C0A` | the gamification strip, code console |
| `chrome-2` | `#221B17` | control fill inside the header |
| `chrome-3` | `#2B231E` | editor chrome, XP track |
| `chrome-hover` | `#251E1A` | nav item hover |
| `chrome-line` | `#302722` | border on chrome-2 controls |
| `chrome-line-2` | `#241D19` | the strip's top hairline |
| `chrome-edge` | `#4A3D36` | control border on hover/focus |
| `chrome-edge-2` | `#3A2F29` | muted button border in the editor |

Text sitting on chrome has its own ramp, brightest to dimmest: `on-chrome-bright` `#F2ECE7` → `on-chrome` `#CFC6BF` → `on-chrome-2` `#B6ACA5` → `on-chrome-soft` `#A29892` → `on-chrome-muted` `#8F857E` → `on-chrome-dim` `#6C625B`.

### Surfaces and hairlines

| Token | Hex | Used for |
|---|---|---|
| `canvas` | `#F7F4F1` | the page itself |
| `surface` | `#FFFFFF` | every card |
| `surface-2` | `#F2EDE9` | segmented-control track, avatar plate |
| `surface-3` | `#EFEAE5` | progress-bar track, card divider |
| `surface-4` | `#FAF8F6` | table header, locked module badge |
| `surface-5` | `#F4F0EC` | list-row divider |
| `hairline` | `#E7E1DB` | the default 1px card border |
| `hairline-2` | `#E0D9D2` | input + outline-button border |
| `hairline-3` | `#D6CEC7` | unchecked checkbox, locked badge clasp |

### Text

| Token | Hex | Used for |
|---|---|---|
| `ink` | `#191512` | headings and primary body |
| `ink-2` | `#332D29` | long-form body |
| `ink-3` | `#2F2925` | list-row label |
| `ink-4` | `#4A423C` | secondary body, form labels |
| `muted` | `#6F6660` | supporting copy |
| `muted-2` | `#8B8179` | meta, captions, table cells |
| `muted-3` | `#B6ACA5` | disabled text, empty counters |
| `muted-4` | `#C9C1BA` | locked badge hint, completed topic dot |

### Accents

- **Gold** (gems, ratings, the "in project" tag): `gold` `#C99A2E`, `gold-tint` `#F6E4B8` (certificate tag plate), `gold-ink` `#6B4D0C` (text on gold-tint), `gold-deep` `#2C2007` (text on gold).
- **Success** (correct answer, passed check): `success` `#4F8A5F`, `success-deep` `#2F6640`, `success-tint` `#F2F8F3`, `success-line` `#CFE3D5`, `success-ink` `#1F3D27`, `success-bright` `#8FD6A4` (passing console output).
- **Danger** (the failure states beyond `brand-alert`): `danger-tint` `#FDF3F3`, `danger-line` `#F0D6D9`, `danger-bright` `#F0A3AE` (failing console output), `danger-soft` `#F0B8C0` (outline button on chrome).
- **Heat ramp** (the contribution grid, coldest to hottest): `heat-0` `#F2EDE9` → `heat-1` `#F4D6DA` → `heat-2` `#E79AA4` → `heat-3` `#C4566A` → `heat-4` `#A81E32`.
- **Code** (static syntax colouring in samples): `code` `#E8E2DC`, `code-keyword` `#C58CE0`, `code-number` `#E5B567`, `code-comment` `#6C625B`.

## Typography

**Faces:** `IBM Plex Sans Thai` carries the UI, `IBM Plex Sans` is the Latin fallback, `JetBrains Mono` sets every code sample and student ID. All three load from Google Fonts in `shared/_fonts` (weights 400–700 for the sans faces, 400/500 for mono, `display=swap`, with preconnects).

**The scale is literal: `text-14` is 14px**, expressed in rem so it still responds to the user's root font size. Half steps carry the design's fine-tuning and are spelled with a trailing `-5` — `text-13-5` is 13.5px, because a dot is not usable in a Tailwind theme key. The scale **replaces** Tailwind's named sizes: use `text-16`/`text-24`/`text-46`, never `text-base`/`text-2xl`/`text-4xl`.

Available sizes: `9-5`, `10`, `10-5`, `11`, `11-5`, `12`, `12-5`, `13`, `13-5`, `14`, `14-5`, `15`, `15-5`, `16`, `16-5`, `17`, `18`, `18-5`, `19`, `20`, `21`, `22`, `23`, `24`, `26`, `27`, `28`, `30`, `32`, `34`, `38`, `40`, `44` (the admin console's two dark counter panels), `46` — plus the display sizes `54`/`64`/`80`, which exist **only** for the marketing landing page a signed-out visitor sees.

Line heights: `leading-tight` is `1.2` (overriding Tailwind's 1.25), `leading-body` is `1.6`.

## Radius, elevation, layout

Radii are named by role:

| Token | Value | Used for |
|---|---|---|
| `rounded-field` | 11px | inputs and primary buttons |
| `rounded-card` | 18px | the standard content card |
| `rounded-panel` | 20px | the largest cards on My Learning |
| `rounded-box` | 16px | the landing page's panels |

Shadows: `shadow-card` (resting card), `shadow-card-hover` (raised on hover), `shadow-menu` (dropdowns), `shadow-menu-dark` (menus on chrome).

Layout tokens:

- `max-w-page` — 1320px, every app screen but the leaderboard
- `max-w-narrow` — 1000px, the leaderboard
- `h-header` / `--spacing-header` — 64px
- `xs:` — a non-standard **576px** breakpoint (inherited from the earlier system; used by two-up form rows)
- `nav:` — **1180px**, below which the header's eight nav destinations no longer fit beside the utility rail and the nav collapses into the burger drawer

## Motion

All entrance animations share the easing `cubic-bezier(0.22, 0.9, 0.3, 1)` and are staggered by each consumer setting its own `animation-delay`:

| Token | What it does |
|---|---|
| `animate-row-in` | list rows slide in from the left, 0.3s |
| `animate-card-in` | cards rise and unscale, 0.34s |
| `animate-rise` | larger blocks rise, 0.42s |
| `animate-pop` | small elements scale in, 0.34s |
| `animate-bar` | the progress fill wipes in from its left edge, 0.6s — pair with `origin-left` |
| `animate-fade` | 0.2s opacity |
| `animate-shimmer` | the loading skeleton's sweep, 1.3s linear infinite |
| `animate-top-bar` | the indeterminate slider pinned to the top of the viewport, 1s infinite |

The `@layer base` reduced-motion block clamps every animation and transition to 0.01ms **and** forces `animation-iteration-count: 1` — without that the skeleton's infinite shimmer would restart every 0.01ms and repaint forever instead of settling.

The base layer also restores `cursor: pointer` on enabled buttons (Tailwind v4's preflight ships the default arrow), gives anchor targets `scroll-padding-top` that clears the sticky header, and draws the `:focus-visible` ring as a 2px `brand` outline offset by 2px.

## The `@utility` escape hatches

Eight exist, and each is there for the same reason: **a multi-stop gradient or clip-path that cannot be expressed as a utility without inlining a raw colour into the markup.** Adding a ninth needs that same justification.

| Utility | What it draws |
|---|---|
| `brand-field` | the landing/auth hero field — a 72% chrome scrim over a 135° `brand → chrome-deep` gradient |
| `marker-partial` | the knowledge map's half-filled square for a partly-learned group |
| `badge-ring` | the earned-badge hexagon's gradient ring |
| `badge-fill` | its gradient fill |
| `clip-hex` | the hexagon silhouette both badge sizes share |
| `skeleton` | the loading skeleton's shimmer gradient on light cards |
| `skeleton-on-chrome` | the same, recoloured for the chrome panel |
| `marker-none` | native `<details>` arrow suppression — no built-in utility covers `::-webkit-details-marker` |

## Conventions

- **There are no component classes** — no `.btn`, no `.card`. If a recipe repeats across views, repeat the utilities; that is the trade Tailwind asks for, and it keeps the cascade flat.
- **Never hardcode a hex outside the `@theme` block and its dark counterpart** (the `theme-color` meta tag is the lone exception, above).
- **Crimson as a fill and crimson as ink are different tokens.** `bg-brand` is the fill; `text-brand-ink` and `border-brand-ink` are the ink, with `-deep` for the hover on each. They are the same colour in light mode and deliberately different in dark, because no single crimson can carry white text *and* be readable on a near-black canvas — white on a fill needs a luminance at or below 0.183, ink on the canvas needs 0.210 or above, and that range is empty. `gold-ink` and `success-ink` already named the same distinction. There is no `text-brand`.
- **`text-white` means white.** Use it for text on a brand fill or on the chrome field; do not reach for `text-surface`, which is a *surface* colour and goes dark with the palette.
- **State travels on `data-*` attributes and is read by Tailwind variants** (`data-[state=correct]:`, `data-[open=true]:`, `group-open:`, `aria-selected:`). Stimulus controllers set an attribute; they do not juggle class lists. Accordions are native `<details class="group">` with `group-open:` styling — no controller.
- The one controller that does touch classes, `header_controller`, receives its pinned state as **several** utilities via `data-header-pinned-class` and so calls `classList.add/remove(...this.pinnedClasses)` — `classList.toggle` accepts only one class and will silently drop the rest.
- **A skeleton repeats the grid of what it stands in for, and lives beside it.** `skeleton`/`skeleton-on-chrome` and `animate-shimmer` are the tokens; the markup is per-screen, because a placeholder whose rows do not line up with the real ones shifts the layout the moment they land. `leaderboards/_skeleton` is the working example — it sits inside that screen's lazy Turbo frame, repeats the board row's `grid-cols` so both fall under one column header, staggers its shimmer by 90ms a row, and is `aria-hidden` inside a `role="status"` wrapper whose only readable text is `chrome.loading`. Decoration announces itself once, not eight times.
  **Match the height through the type scale, not with a number.** A row's height is the sum of the line-heights of the text stacked in it, so the placeholder wraps each bar in the same `text-*` class as the line it stands in for and makes the bar `inline-block` — a block child would give the wrapper the bar's height instead of the text's. Two bars stacked with a `gap` measured 65px against the real row's 73.375, an 8px jump per row the moment the frame answered; mirroring the wrappers matched it exactly. A hardcoded `h-[73.375px]` would have matched too, and drifted the next time the type scale moved. (`shared/_loading_skeleton` is a whole-page version of the same idea that nothing currently renders — a spare part, not a shared partial.)
- **Light-on-dark rule:** anything placed on the chrome field — header, hero, mobile drawer, auth screens — needs a light variant. A `border-brand text-brand` outline button all but vanishes on near-black; the chrome-side alternatives are the `on-chrome-*` text ramp, `chrome-edge` borders and `danger-soft` for a destructive outline.

## History: the eng.utcc.ac.th port

The first system was extracted from <https://eng.utcc.ac.th> (fetched 2026-07-25) by reading the served HTML and its compiled `/_astro/*.css` bundles: UTCC maroon (`#8C1C36` primary, a ramp down to the `#2D000E` footer), Noto Sans Thai Looped, and daisyUI component anatomy re-expressed as utilities — the reference site is Astro + Vue islands with Tailwind and daisyUI. Its type scale was named misleadingly (`text-18` was 1rem), its nav links were soft pink `#FFC9C9` with an animated underline, and its hand-written component classes (`.btn--primary`, `.card`, `.section__title`) were mapped one-by-one into utility recipes.

That system has been fully replaced by the tokens above. What survives from it:

- the **576px `xs` breakpoint**, non-standard in Tailwind's default set, which the reference site added
- the **`54`/`64`/`80` display sizes** on the marketing landing page
- `--leading-tight: 1.2` (upstream's value, overriding Tailwind's 1.25)
- the **`brand-field`** idea — a scrim over a diagonal brand gradient behind the hero and auth screens, since recoloured from maroon to crimson-on-chrome
- the **SEO and social metadata** in `shared/_meta`, which was ported from the reference site's head and still says so in its comment

The literal type scale also descends from that port's lesson: upstream's class names lied about their sizes, so when the scale was rebuilt the names were made honest instead.
