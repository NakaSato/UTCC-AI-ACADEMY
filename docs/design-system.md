# UTCC Engineering — UI Design System

Extracted from <https://eng.utcc.ac.th> (fetched 2026-07-25) by reading the served HTML and its compiled `/_astro/*.css` bundles. Values below are the real ones in the shipped CSS, not approximations.

## Stack the reference site uses

| Layer | What it is |
|---|---|
| Framework | Astro (static, `/_astro/` hashed assets) with Vue islands (`astro-island`, `data-v-*` scoped styles) for interactive parts (e.g. `FooterList`) |
| CSS | Tailwind CSS with a custom color token layer, plus **daisyUI** component classes (`btn`, `btn-primary`, `btn-ghost`, `navbar`, `collapse`, `bg-base-100`) |
| Carousel | Swiper |
| Font loading | Google Fonts — Noto Sans Thai Looped, weights 100–900, `display=swap` |

daisyUI ships its own default theme variables (`--fallback-p: #491eff` etc.). The site **does not** use them for brand color — it overrides on the element with its own utility tokens. Don't mistake daisyUI defaults for UTCC brand colors.

## Color

The brand is **UTCC maroon**. Tokens are named `{utility}-a-{family}-{hex}`.

### Brand / primary

| Token | Hex | RGB | Used for |
|---|---|---|---|
| `a-red-8c1c36` | `#8C1C36` | `140 28 54` | **Primary.** Header bar background, primary borders |
| `a-red-622432` | `#622432` | `98 36 50` | Deep maroon — primary CTA label color, dark fills |
| `a-red-851614` | `#851614` | `133 22 20` | Text accent |
| `a-red-ff0038` | `#FF0038` | `255 0 56` | Bright alert/highlight red — sparing use |

### Footer maroons (darker end of the ramp)

| Value | Hex | Used for |
|---|---|---|
| Footer top | `#4F0018` | `.footer-body-top` background |
| Footer bottom | `#2D000E` | `.footer-body-bottom` background |

So the full brand ramp, light → dark: `#FF0038` → `#8C1C36` → `#622432` → `#4F0018` → `#2D000E`.

### Neutrals

| Token | Hex | RGB | Used for |
|---|---|---|---|
| `a-black-0B0B0B` | `#0B0B0B` | `11 11 11` | Body text, dark surfaces |
| `a-black-0B0B0B/70` | `#0B0B0BB3` | — | Image/hero scrim overlay |
| `a-black-1D1D1E` | `#1D1D1E` | `29 29 30` | Secondary dark surface |
| `a-black-001C0B` | `#001C0B` | `0 28 11` | Near-black with green cast |
| `a-gray-696F6F` | `#696F6F` | `105 111 111` | Body/muted text |
| `a-gray-86868B` | `#86868B` | `134 134 139` | Caption/tertiary text |

Plus stock Tailwind neutrals for section backgrounds: `bg-slate-100`, `bg-slate-200`, `bg-gray-100`, `text-gray-400`, `text-gray-500`.

### On-maroon link color

Nav links on the maroon header are **not** white by default — they're a soft pink `#FFC9C9`, going to `#FFFFFF` on hover. See `.cool-link` below.

## Typography

**Display/UI face:** `DB Heavent` / `DB Heavent Regular`, falling back to `sans-serif` — a Thai typeface, loaded locally (not from Google). **Web font:** `Noto Sans Thai Looped` from Google Fonts as the Thai text face. Monospace falls back to the Tailwind default `ui-monospace, SFMono-Regular, Menlo, …` stack.

### Type scale

Classes are named by their intended pixel size, but the rem values are the Tailwind scale — **`text-18` is `1rem` (16px), not 18px.** Read the rem column, not the class name.

| Class | rem | ≈px |
|---|---|---|
| `text-18` | 1rem | 16 |
| `text-20` | 1.25rem | 20 |
| `text-24` | 1.5rem | 24 |
| `text-30` | 1.875rem | 30 |
| `text-34` | 2.125rem | 34 |
| `text-36` | 2.25rem | 36 |
| `text-44` | 2.75rem | 44 |
| `text-54` | 3.375rem | 54 |
| `text-64` | 4rem | 64 |
| `text-80` | 5rem | 80 |

Most-used in practice: `text-20` and `text-24` for body/cards, `text-30` for footer column headings, `text-44`/`text-66` for section headings. Footer base font-size is `24px`; footer bottom bar is `1.25rem`.

### Line clamping

Custom utilities `text-1-line` and `text-2-line` truncate card titles to one or two lines — heavily used across news/blog cards.

## Layout

**Container:** Tailwind's `.container` with `mx-auto`, breakpoints at `576 / 640 / 768 / 1024 / 1280 / 1536px`. Note the non-standard **576px** breakpoint added to the default set.

**Grid:** `grid-cols-1` → `lg:grid-cols-3` / `grid-cols-4` is the dominant responsive pattern. Footer is `grid grid-cols-4 gap-4` with a `col-span-3` link area.

**Spacing rhythm:** `gap-4` (most common), `gap-1`/`gap-2` for tight groups; `px-4` for gutters, `px-16` for wide desktop insets; `py-24` for section vertical padding, `py-2`/`py-4` inside components.

**Radius & elevation:** `rounded-full` (pills/CTAs), `rounded-md` (cards/inputs), `rounded-box` (daisyUI). Shadows: `shadow-md` dominant, `shadow-lg` for raised cards, `shadow-2xl` for modals/overlays.

## Page structure

```
header  (sticky-on-scroll, bg #8C1C36, shadow-md, z-20)
  navbar container mx-auto
    navbar-start   → logo SVG (136×39)
    navbar-center  → hidden lg:flex, .cool-link nav items
    navbar-end     → CTA button + mobile hamburger (btn btn-ghost, flex lg:hidden)
hero      h1: คณะวิศวกรรมศาสตร์ มหาวิทยาลัยหอการค้าไทย
#aboutus  เกี่ยวกับคณะ
#course   หลักสูตรคณะวิศวกรรมศาสตร์   (degree-level filter tabs + program cards)
#faq      คำถามที่พบบ่อย              (daisyUI collapse accordion)
#partners พันธมิตร                    (logo grid)
#alumni   ศิษย์เก่า                    (testimonial cards)
#news     ข่าวและกิจกรรม               (Swiper carousel)
#blogs    Blog                        (Swiper carousel)
footer    .footer-body-top (#4F0018) → .footer-body-bottom (#2D000E)
sidemenu / menu-right / menu-close-side  (mobile drawer)
```

### Sticky header behavior

Inline module script on `#header`: on `scroll > initialOffset + 10`, swap `relative` → `fixed top-0 left-0 right-0` and pin `z-index: 20`; reverse below the threshold. Runs once on load to handle a pre-scrolled page.

## Components

### Primary CTA ("สมัครเรียน" / Apply)

```html
<button class="btn btn-primary rounded-full font-normal uppercase text-a-red-622432" lang="th">
  สมัครเรียน <svg …/>
</button>
```

Pill-shaped, **`font-normal`** (not bold), `uppercase`, maroon `#622432` label on the daisyUI primary fill, with a trailing arrow icon.

### Nav link (`.cool-link`) — animated underline

```css
.cool-link        { display:inline-block; color:#FFC9C9; text-decoration:none; position:relative }
.cool-link:hover  { color:#fff }
.cool-link:after  { position:absolute; bottom:0; content:""; display:block;
                    width:0; height:2px; background:#FFC9C9;
                    transition:width .3s; right:0; left:initial }
.cool-link:hover:after { width:100%; right:initial; left:0; transition:width .3s }
```

The underline grows left-on-hover and retracts rightward — the `right`/`left` swap is what makes enter and exit animate in opposite directions. Spacing between items is `mx-2`.

### Footer link list

Desktop: three columns (`Quick Links`, `คณะและวิทยาลัย`, `มหาวิทยาลัย`) at `text-30` headings. Mobile (`lg:hidden`): the same columns become daisyUI `collapse collapse-arrow` accordions with `border-b border-white`. Links are `color:#fff; opacity:.7`; list items are `font-weight:300`.

### Cards

Program cards carry degree-level badges (ปริญญาตรี, หลักสูตรนอกเวลา) and are filterable by level. News/blog cards use `text-1-line`/`text-2-line` clamping with `shadow-md` and `rounded-md`.

## Content & localization

Thai-first (`lang="th"`), audience is prospective Thai engineering students. Current content push is the **UTCC AI Institute** — AI/IoT/robotics partnerships, Humanoid network, data-center workforce. A language dropdown (`DropdownLang`) exists in the markup but is **commented out**, so the shipped site is Thai-only.

Nav: เกี่ยวกับคณะ · หลักสูตร · คำถามที่พบบ่อย · พันธมิตร · นักศึกษาปัจจุบัน · ศิษย์เก่า · ข่าวและกิจกรรม · Blog · **สมัครเรียน** (CTA → `admissions.utcc.ac.th`)

## How it was ported into this app

This repo runs **Tailwind v4 through `tailwindcss-rails`**, which ships a standalone binary — so the reference site's Tailwind half transfers directly, while its Node/daisyUI half does not. There is no `package.json`, no npm, and no PostCSS config. daisyUI's component classes are re-expressed as utility classes in the markup.

Everything lives in one file, `app/assets/tailwind/application.css`:

| Block | Holds |
|---|---|
| `@theme` | every value in this document, as `--color-*` / `--text-*` / `--radius-*` / `--breakpoint-*` / `--container-*` entries. **The only place a raw hex belongs.** |
| `@layer base` | `scroll-behavior` + header-clearing `scroll-padding-top`, the button cursor preflight restores to `default`, the `:focus-visible` ring, and the reduced-motion block |
| `@utility brand-field` | the maroon field behind the hero and auth screens — a 70% ink scrim over a 135° `brand → footer-btm` gradient. A utility rather than markup because the stacked `background-image` would otherwise inline two raw hexes. |
| `@utility marker-none` | `<details>` arrow suppression; no built-in utility covers `::-webkit-details-marker` |

`bin/rails tailwindcss:build` compiles to `app/assets/builds/tailwind.css`, which `stylesheet_link_tag :app` picks up through Propshaft. `bin/dev` runs `tailwindcss:watch` alongside the server via `Procfile.dev`; `assets:precompile` builds it for Docker.

### Where the old class names went

The hand-written CSS (`00_tokens` → `30_forms`) is gone. Its component classes map to these utility recipes:

| Was | Now |
|---|---|
| `.container` | `mx-auto w-full max-w-page px-4 xl:px-8` |
| `.section` / `.section--muted` | `py-16 lg:py-24` / `+ bg-surface-2` |
| `.section__title` | `text-36 leading-tight font-bold text-balance text-brand-deep lg:text-44` |
| `.grid--3` | `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3` |
| `.btn` (base) | `inline-flex items-center gap-2 rounded-full px-6 py-2.5 text-18 leading-tight font-normal whitespace-nowrap uppercase transition duration-300 active:scale-97` |
| `.btn--primary` | `+ bg-surface text-brand-deep shadow-md hover:bg-brand-tint hover:shadow-lg` |
| `.btn--solid` | `+ bg-brand text-surface hover:bg-brand-deep` |
| `.btn--outline` | `+ border border-brand text-brand hover:bg-brand hover:text-surface` |
| `.card` | `flex h-full flex-col gap-2 rounded-md bg-surface p-4 shadow-md transition duration-300` (+ `hover:-translate-y-0.5 hover:shadow-lg` when it links) |
| `.badge` | `inline-flex items-center rounded-full bg-surface-2 px-3 py-0.5 text-18 font-medium text-brand-deep` |
| `.tab` | `rounded-full border border-hairline px-4 py-1.5 text-18 text-muted … aria-selected:bg-brand aria-selected:text-surface` |
| `.input` | `w-full rounded-md border border-hairline bg-surface px-3.5 py-2.5 text-18 … focus:border-brand focus:ring-3 focus:ring-brand/15 focus:outline-none aria-[invalid=true]:border-brand-alert` |
| `.text-2-line` | `line-clamp-2` |
| `.visually-hidden` | `sr-only` |
| `.auth` | `brand-field grid min-h-[calc(100vh_-_var(--spacing-header))] place-items-center px-4 py-8` |

**There are no component classes.** If a recipe repeats across views, repeat the utilities — that is the trade Tailwind asks for, and it keeps the cascade flat.

### State is data-attributes + variants

CSS reacts to state through `data-*` attributes the Stimulus controllers already set, read with Tailwind variants:

- drawer: `data-[open=true]:visible` on the drawer, `group-data-[open=true]:translate-x-0` / `:opacity-100` on the panel and scrim
- back-to-top: `data-[visible=true]:visible data-[visible=true]:opacity-100`
- filter tabs: `aria-selected:bg-brand aria-selected:border-brand aria-selected:text-surface`
- accordions: `<details class="group">` + `group-open:after:rotate-[-135deg]` on the summary

`header_controller` is the one controller the migration changed: its pinned state is now **several** utilities (`fixed top-0 right-0 left-0`), so it calls `classList.add/remove(...this.pinnedClasses)`. `classList.toggle` takes only one class and would silently drop the rest.

Deliberate departures from the reference:

- **daisyUI `btn-primary` was not reproduced literally.** Upstream sets a maroon *label* (`text-a-red-622432`) on daisyUI's primary fill, whose colour comes from a Tailwind theme config that isn't published. The primary button here is a cream pill with a `#622432` label, which is what that combination is clearly reaching for and reads correctly on the maroon header.
- The type scale keeps upstream's misleading names (`--text-18` = `1rem`) so values port 1:1 — which is why it **replaces** Tailwind's `text-base`/`text-xl`/`text-2xl` names rather than reusing them. Read the rem, not the name.
- `--leading-tight` overrides Tailwind's `1.25` with upstream's `1.2`. `--radius-md` needed no override — Tailwind's default already matches upstream's `0.375rem`.
- The non-standard **576px** breakpoint is `--breakpoint-xs`, used by the two-up rows on the sign-up form.
- `DB Heavent` is licensed and not bundled; it stays first in the stack, with Google-hosted **Noto Sans Thai Looped** as the shipping face.

**Light-on-dark rule:** anything placed on the maroon field — header, hero, mobile drawer, auth screens — needs a light variant. The default outline button (`border-brand text-brand`) is maroon-on-maroon there and vanishes; use `border-surface text-surface hover:bg-surface hover:text-brand-deep` instead.

### The hero lockup

`app/assets/images/hero-eng-utcc.webp` is the site's `2-ENG-UTCC-1-min` asset (1650×650): a **white logo lockup on a transparent background**, not a photograph. It therefore sits *on* the maroon hero rather than behind it as a background image, and needs no plate or scrim of its own.
