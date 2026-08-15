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

Which palette a visitor gets is `session[:theme]`, rendered as a class on `<html>` and selected from `shared/_theme_toggle` — the language selector's dropdown twin, POST for the same reason. Both controls follow Sign up on the public header and move inside the profile dropdown during a signed-in session. No preference at all means no class, and the media query answers, exactly as an unset locale falls through to `Accept-Language`. There is **no pre-paint script**: the server knows the answer when it renders, so there is no flash to prevent. See SPEC-0047.

Two things to know before touching it:

- **The dark block is written twice** — once for `.dark`, once for the media query — because CSS cannot share a declaration block across the two. `test/assets/dark_palette_test.rb` fails if they drift, and also checks every text pair against WCAG AA in both palettes.
- **The theme toggle submits with `data-turbo: false`.** Turbo replaces `<body>`, merges `<head>`, and copies exactly two attributes off the incoming `<html>` — `lang` and `dir`. `class` is not one of them, so a Turbo visit would leave the palette class stale and the palette unchanged until a reload. (This is also why the *language* toggle needs no such treatment: `lang` is copied.)

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
| `muted-2` | `#746A62` | meta, captions, table cells — **do not lighten**, see below |
| `muted-3` | `#B6ACA5` | disabled text, empty counters |
| `muted-4` | `#C9C1BA` | locked badge hint, completed topic dot |

**`muted` and `muted-2` are nearly the same colour in light mode, and have to be.** `muted-2` was `#8B8179` until it was measured: 3.81:1 on a card and 3.48:1 on the page, against the 4.5:1 floor SPEC-0023 sets, on text carrying dates, counts and table cells. The lightest value that clears AA on every background it sits on — white, canvas, `surface-2`, `surface-4` — is `#746A62`, which is 1.06× off `muted`. To do better a colour would need a luminance at or below 0.1507 and `muted` is already 0.1373: **the light ramp has one more grey step than the contrast budget allows.** Lightening `muted-2` to make the step visible again re-introduces the failure, and `test/assets/dark_palette_test.rb` will say so.

The dark palette keeps a real step, because its surfaces leave room below `muted`. If the light hierarchy is wanted back, the move is to darken `muted` to make space — not to lighten `muted-2`.

`muted-3` and `muted-4` are below the floor and stay there: they mark disabled controls and inactive states, which WCAG 1.4.3 exempts.

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
- `nav:` — **1180px**. Named for the header rail it was cut for: below it the destinations no longer fitted beside the utility rail. The header now carries one dropdown at every width and no longer reads it, but the admin two-column screens fold here

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

Shared dropdown panels use the Web Animations API through `dropdown_controller`:
they enter over 170ms with a 6px rise and slight unscale, and leave over 120ms
with the inverse movement. Top-level panel blocks follow with a capped 22ms
stagger, and controls that carry a chevron rotate it toward the open panel.
Every direction uses the same entrance easing above. The controller checks
`prefers-reduced-motion` itself because the CSS duration clamp does not affect
JavaScript-created animations; reduced-motion readers get the same immediate
open/close state with no movement.

An unread notification gets one 620ms bell swing from
`notification_bell_controller`. The controller remembers the newest unread
notification id in tab-scoped session storage, so Turbo navigation does not
repeat the same attention cue; a later notification may ring once under its new
id. It never loops, an empty/read bell never moves, and reduced motion bypasses
the effect entirely.

Primary page content uses `page_motion_controller` at the application and
authentication layout boundary. On an initial render or ordinary Turbo advance,
`main#main` settles upward by 7px while moving from 88% to full opacity over
180ms. Cached previews do not animate, browser-history restoration puts content
back without movement, and reduced-motion readers bypass the effect. There is no
outgoing animation: navigation begins immediately rather than waiting on
decoration.

Redirect flash messages use `flash_motion_controller` once they arrive. Each
message settles downward by 6px while moving from 35% to full opacity over
220ms, with additional messages staggered by 35ms and capped at 105ms. The
controller does not dismiss feedback on a timer; it only removes consumed flash
markup before Turbo caches the page, preventing stale messages from returning
through browser history. Reduced-motion readers receive the message immediately
with no movement.

Transient toast rows use `toast_controller` for both directions instead of CSS
transition timing. A new row travels from the stack's configured 6px top or
bottom offset while fading in over 200ms. Dismissal measures any unfinished
entrance, cancels it, and continues toward that anchor over 160ms before removing
the row. Reduced-motion readers receive immediate reveal and removal. Motion
does not alter live-region urgency, timers, hover/focus pause, actions, ordering,
or the three-row cap defined by SPEC-0046.

The signed-out mobile navigation drawer also uses the Web Animations API through
`header_controller`. Its backdrop fades in over 180ms while the panel travels
from the right over 240ms. Dismissal measures any unfinished entrance, then
continues the backdrop and panel toward their closed positions over 140ms and
180ms respectively; reopening during that interval continues from the visible
position. Open state, initial focus, and body scroll lock are applied before
decoration, while dismissal updates the toggle and releases scroll immediately.
Reduced-motion readers receive immediate open and close state with no animation.

The public learning-track filter commits its selected tab and card `hidden`
states through `tabs_controller` before the matching cards settle upward by 6px
and unscale over 220ms. Visible results are staggered by 35ms and capped at
105ms. A newer filter cancels the older card sequence, selecting the active
filter again remains still, and reduced-motion readers receive the filtered
result without a Web Animations API call. Track level, order, copy, and links do
not depend on the decoration.

Each public FAQ keeps native `details`/`summary` semantics and uses
`disclosure_motion_controller` only after an answer is open. The answer settles
4px downward while fading to rest over 190ms. Closing remains immediate and
cancels unfinished movement; reopening may start a new acknowledgement, while
reduced-motion readers use the native disclosure without a Web Animations API
call. Question and answer copy, structured data, focus, and toggle behavior stay
independent of decoration.

Learner syllabus modules reuse that native disclosure controller for their
topic area. The server-selected current module stays open without replaying
motion on initial render. Opening another module settles its content 4px
downward over 190ms; closing cancels immediately, and reduced-motion readers
receive the same native disclosure state without animation. Module ordering,
current/done/locked state, topic links, and progress remain server-owned.

Expandable course rows on My Learning use the same native disclosure motion.
The server-selected first row in each in-progress or completed list stays open
and still on render. A learner-opened row settles its progress and action area
4px downward over 190ms; closing cancels immediately, and reduced-motion readers
receive native state without animation. Tab selection, course classification,
completion counts, progress values, and destinations remain server-owned.

Administrator landing-content sections reuse the native disclosure motion for
their editor body. The `?group=`-selected section stays open and still on
render. Manually opening another section settles its fields and card controls
4px downward over 190ms; closing cancels immediately, and reduced motion uses
native state without animation. Form ownership, bilingual copy, save/add/delete
and reorder actions, card attributes, and the group return URL are unchanged.

The shared back-to-top control uses `to_top_controller` to acknowledge threshold
crossings without changing the 400px threshold or its smooth-scroll action. It
rises 8px and unscales over 200ms when shown, then reverses over 150ms before
becoming invisible. A newer crossing cancels and continues from the computed
visual state; initial page position is committed without movement, and reduced
motion changes visibility immediately without calling the Web Animations API.

The signed-out sticky header uses `header_controller` to soften its existing
shadow change after the 10px pin threshold. The class-backed pinned state is
committed immediately, while its computed shadow interpolates over 200ms when
pinned and 150ms when released. A newer crossing cancels and continues from the
rendered shadow; initial/restored scroll position remains still, and reduced
motion commits the same pinned state without calling the Web Animations API.
Sticky positioning, drawer behavior, section spy, and navigation are unchanged.

That header's section spy also acknowledges a newly current visible navigation
link after committing `data-active` and `aria-current`. The rendered desktop or
drawer link settles upward by 2px and unscales over 180ms; superseded movement
is cancelled, the observer's initial pass remains still, and reduced motion
bypasses the Web Animations API. Section visibility, ordering, translated copy,
anchors, and the active-state decision remain owned by the existing observer.

Academic-post reader preference changes use `reader_controller` to acknowledge
the already-applied width, font-size, or theme setting on the reading surface.
The surface settles upward by 3px and unscales over 180ms; a newer preference
continues from the rendered position, while restored settings, repeated no-op
choices, and reduced motion remain still. Local-storage scope, sanitized post
content, server authorization, export, translated controls, and saved academic
content are unchanged under SPEC-0007.

The academic reader table of contents acknowledges a newly selected section link
with a cancellable 160ms horizontal nudge after native anchor navigation begins.
Repeated selection of the same link, initial rendering, and reduced-motion
preferences remain still; heading IDs, browser scrolling, and content semantics
remain native.

The shared sign-in/sign-up switch keeps both compact auth panels still and uses
an opt-in `panels_controller` cue only on the newly selected tab. After the
panel, `aria-selected`, focus, URL, and document title are committed, the tab
settles from 0.96 scale through a 1.03 overshoot over 200ms. Initial and repeated
selection remain still, a newer selection cancels the older cue, and reduced
motion switches immediately without calling the Web Animations API. Form
actions, validation, authentication, registration, and browser history remain
unchanged.

Lesson content panels opt into the shared `panels_controller` movement with
`data-motion`. Moving forward through Theory, Exercise, Coding Task, and Summary
brings the next panel 12px from the right; moving backward brings it from the
left. Both directions settle over 220ms with the shared entrance easing. Other
consumers of `panels_controller` do not move, selecting the current step again
does not replay movement, and reduced-motion readers switch immediately.

The lesson progress fill uses the same controller instead of a CSS width
transition. It measures its visible percentage before cancelling superseded
movement, commits the new step percentage underneath, and interpolates to it
over 300ms. This lets rapid forward or backward selections continue without a
jump. Direct or repeated selections remain still, and reduced-motion readers
receive the destination width immediately without a Web Animations API call.

Each newly selected lesson-step circle confirms its already-applied current
state with one 240ms scale settle: 0.84 to a 1.10 overshoot at 62%, then back to
rest. A newer selection cancels the previous circle movement. Opening a step
directly, selecting the current step again, and reduced-motion preferences all
leave the semantic `aria-selected` and current/done states immediate and still.

The compact translated step label beside the progress bar enters after its
hidden state switches. Forward navigation brings it 4px from below; backward
navigation brings it 4px from above, both fading to rest over 180ms. A newer
selection cancels the older label entrance. Direct or repeated selections and
reduced-motion preferences show the correct label immediately without movement.

Assessment results use `assessment_motion_controller` after the quiz or coding
controller has already rendered its semantic status. The feedback plate or
console settles upward by 6px from 45% to full opacity over 240ms. A newer
result cancels movement on the same surface, resetting the coding task cancels
its console movement, and reduced-motion readers receive the updated status
without a Web Animations API call. Grading never waits for decoration.

The coding-task console also acknowledges a submitted run after its running
state is committed with a cancellable 160ms horizontal nudge. A newer run or
the graded result cancels the prior cue; reset, failed transport recovery, and
reduced-motion readers keep the console state immediate without movement.

The exercise check control uses the same 160ms acknowledgement after its
disabled, submitted state commits and before server grading returns. A result or
transport recovery supersedes the cue; answer selection, retry behavior, result
feedback, and reduced-motion readers remain immediate and unchanged.

Academic-post editor toolbar buttons acknowledge an executed Tiptap command with
a cancellable 160ms scale settle. The command, prompt result, editor HTML sync,
save behavior, and reduced-motion readers remain immediate; repeated presses on
one button cancel and restart only its decorative cue.

Academic-editor status messages acknowledge a changed validation or picture
import result with a cancellable 180ms upward settle. The message text, error
state, live-region announcement, and reduced-motion behavior remain immediate;
repeating the same status does not replay movement.

My Learning progress/completed tabs opt into the shared 200ms selection
acknowledgement after their panel, URL, and aria state commit. The panels and
course disclosures stay still; repeated selections and reduced-motion readers
receive the same immediate tab state without movement.

The newly selected My Learning panel also settles from the direction of the tab
change over 220ms after its hidden state commits. Repeated selections, initial
rendering, course disclosures, and reduced-motion readers remain still.

The continuation link revealed by a passing exercise or coding task uses that
controller only after server grading has made the action visible. It settles
upward by 5px with a slight 0.98 unscale over 220ms. A newer pass replaces any
movement on the same link, Coding Task Reset cancels its pending movement, and
reduced-motion readers receive the immediately usable action without animation.
The link destination and completion rules remain independent of decoration.

Selecting a new exercise answer applies its `aria-checked` and visual picked
state before the answer marker settles from 0.86 scale through a 1.12 overshoot
and back to rest over 200ms. Selecting a different answer cancels superseded
marker movement; selecting the current answer again remains still. Reduced-
motion readers receive the same radio state immediately without animation, and
the selection cue has no knowledge of the server-held answer key.

When a new integrity incident is recorded on Exercise or Coding Task, the
numeric score and its derived band update before the score settles from 2px
above at 1.12 scale over 240ms. A newer incident cancels superseded score
movement. Initial page loads, restored scores after refresh or language change,
Theory and Summary interactions, and reduced-motion preferences remain still.
Incident weights, persistence, the integrity meter, and log-row behavior are
independent of this acknowledgement.

The integrity meter uses the same controller instead of its former CSS width
transition. After an assessed-step incident, it measures the currently visible
percentage before cancelling superseded movement, commits the new score width,
and interpolates to it over 300ms. Rapid incidents therefore continue without
jumping to an older destination. Initial and restored widths, inactive lesson
steps, an unchanged zero score, and reduced-motion preferences receive the
committed width immediately without a Web Animations API call.

The translated integrity verdict moves only when a new assessed-step incident
crosses the clean, review, or risk score boundary. Its new copy, color band, and
score are applied first; the label then settles 3px upward from 45% opacity over
220ms. Deductions within one band remain still, and a newer boundary change
cancels superseded verdict movement. Initial/restored state, inactive steps,
and reduced-motion preferences receive the translated verdict immediately.

The integrity log rebuilds its translated rows immediately after an assessed-
step incident, then moves only the new first row 6px from the left over 260ms.
Restored rows and older rows remain still instead of replaying when the list is
rebuilt. A newer incident cancels superseded row movement; inactive steps and
reduced-motion preferences update no row or show the new row without animation.

The integrity guard is visible and blocks the assessed step before its backdrop
fades in over 180ms and its dialog settles upward by 8px from 0.98 scale over
260ms. A guarded incident while the guard is already open does not replay either
layer. The resume button keeps blocking and focus state committed immediately,
then the backdrop and dialog settle out over 150ms and 170ms; restored focus,
superseding incidents, and reduced-motion preferences hide it immediately.
Initial state and inactive steps receive no Web Animations API call. The guard's
incident recording and resume behavior do not depend on this decoration.

Coding Task criterion rows use the same controller after their server-returned
states are applied. Each row settles 6px from the left over 260ms, staggered by
45ms and capped at 135ms. A newer run or Reset cancels every remaining row
animation. Reduced-motion readers receive all criterion states immediately,
and the browser still never receives the grading patterns.

The lesson's earned-gems counter responds only after the existing
`quiz:reward` or `code-task:reward` event has updated its number. It rises 2px,
scales to 1.16, and settles over 320ms. A newer reward cancels the older bump,
disconnect cancels remaining movement, and reduced-motion readers receive the
same cumulative number without animation. The counter remains optimistic
browser state; persisted progress still comes exclusively from completions.

Arriving at the lesson Summary schedules its reward cards together through
`panels_controller`. Each card settles upward by 8px and unscales from 0.985
over 280ms, with a 45ms stagger capped at 135ms. Leaving or selecting another
step cancels every remaining card animation; opening directly on Summary and
selecting the current step do not replay it. Reduced-motion readers receive all
cards immediately without a Web Animations API call. The sequence is decorative
and does not alter reward values, completion state, or destination links.

The Summary completion mark starts with that arrival sequence and settles once
over 360ms: it scales from 0.78 with a 5-degree counterclockwise turn, reaches
1.08 at 68%, then returns to its resting size. Leaving the step cancels any
unfinished mark movement. Opening Summary directly, selecting it again, and
reduced-motion preferences all render the same completed mark immediately with
no Web Animations API call; the icon remains decorative and `aria-hidden`.

The two Summary action links follow the earlier completion cues while remaining
usable throughout. They settle upward by 6px over 260ms, starting after 180ms
and 220ms respectively. Leaving Summary cancels unfinished action movement;
opening the step directly, selecting it again, or requesting reduced motion
renders both links immediately without a Web Animations API call. Their hrefs,
labels, focus behavior, and primary/secondary hierarchy do not change.

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
