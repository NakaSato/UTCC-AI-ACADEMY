---
id: SPEC-0052
type: spec
title: Vue islands — the mount contract, the registry, and what an island may not do
status: accepted
owners: ["@tech-lead", "@security-owner", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-11-10
supersedes: []
superseded_by: []
depends_on: [ADR-0051, ADR-0007]
implemented_by:
  - config/importmap.rb
  - vendor/javascript/vue.js
  - app/javascript/controllers/vue_island_controller.js
  - app/javascript/islands/registry.js
  - app/javascript/islands/character_counter.js
  - app/views/admin/_proposals.html.erb
enforced_by:
  - test/operations/vue_build_test.rb
  - test/controllers/admin_proposals_test.rb
  - test/system/vue_island_walk_test.rb
  - test/operations/locale_parity_test.rb
touches:
  - app/javascript
  - app/views
  - config/importmap.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - vendor/javascript
  - test
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-ARCH-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002]
---

# Vue Islands — the Mount Contract, the Registry, and What an Island May Not Do

> **Review state:** Accepted on 2026-08-12 on the authority of
> [ADR-0051](../decisions/adr-0051-vue-islands.md), which the user accepted the
> same day. This adds no product decision: it is the contract the decision
> implies, written down so the second island does not have to guess.

> [Executable Specifications](README.md) ·
> [Vue islands decision](../decisions/adr-0051-vue-islands.md) ·
> [Tiptap bridge](../decisions/adr-0007-integrate-tiptap-with-stimulus-importmap.md) ·
> [Design system](../design-system.md)

## Problem

Vue is now available (ADR-0051) to an application whose CSP forbids the build
most Vue documentation assumes, whose asset pipeline has no compiler, and whose
DOM is replaced under it by Turbo. Each of those is a way to write Vue that
works locally and fails in production — a `template:` string that renders in a
test and is blocked by the header, an app mounted on a node Turbo later swaps, a
translated word typed into JavaScript.

The library is one line of `importmap.rb`. The contract is this document.

## The build

Vite builds one entrypoint, `app/frontend/entrypoints/islands.js`, into
`public/vite` through `assets:precompile`. Vue comes from npm and is bundled;
nothing is vendored and the import map pins no `vue`.

**The property everything rests on:** a `.vue` file is compiled at build time,
so the browser receives render code and the Vue runtime alone. Vue's template
compiler would need `Function(…)` at runtime, which this application's CSP
blocks, and `test/operations/vue_build_test.rb` builds the bundle and asserts
the compiler is not in it. The two ways to break that are an alias to
`vue/dist/vue.esm-bundler` in `vite.config.mts`, and an island written with a
runtime `template:` string; both fail that test.

**Two directories, two toolchains.** `app/javascript` belongs to the import map,
`app/frontend` to Vite, and neither imports from the other — a shared module
would ship twice.

## The mount contract

| Rule | Why |
| --- | --- |
| `createApp` is called in `entrypoints/islands.js` and nowhere else | An app mounted outside the bridge is one nothing unmounts |
| A `MutationObserver` mounts an island when its element appears and unmounts it when the element leaves | Turbo Drive replaces the body and a Stream replaces one node with no page event at all; this is the rule Stimulus used to apply for us |
| `turbo:before-cache` unmounts everything | So the snapshot Turbo caches holds the server's markup, not Vue's output |
| The element is a `div` the server rendered, and the island replaces its contents | The island has a home in the layout before it exists |
| An island is named by `data-vue-island` | Markup selects from an allow-list; it does not import code |
| Props arrive as JSON in `data-vue-island-props` | One place, escaped by ERB, parsed once |

## The registry

The entrypoint imports each island and maps a name to it. A name the registry
does not answer to warns in the console and mounts nothing; the screen is
unchanged, because of the next section.

Registered today:

| Name | Island | Used on |
| --- | --- | --- |
| `character-counter` | How much of a limited field is left, as somebody types | The proposal decision reason (`/admin?tab=proposals`) |

## What an island may not do

1. **Own a page or a route.** No router, no client-side navigation, no view that
   is the whole screen.
2. **Fetch the data a page is made of.** The server renders the page. An island
   may react to what is already on it.
3. **Be the only way something works.** Every island enhances markup that
   already functions with JavaScript off. The counter's limit is `maxlength` and
   the model's validation; the island only says how much is left.
4. **Carry a runtime `template:` string, or any in-DOM template.** A single-file
   component's `<template>` is compiled at build time and is the way to write
   markup; a `template:` option is compiled in the browser, which the CSP blocks.
5. **Hold translated copy.** Words come from `config/locales` as props, already
   translated, with only computed values left to interpolate.
6. **Carry appearance of its own.** Classes come from the Tailwind token system,
   like every other template — the same rule that took Tiptap for behavior and
   refused its styling.
7. **Duplicate a Stimulus controller.** Stimulus stays the default for behavior
   attached to markup; Vue is for state-shaped UI. Neither is rewritten into the
   other for its own sake.

## Invariants

1. The built island bundle contains no template compiler.
2. `createApp` appears in exactly one file across `app/frontend` and
   `app/javascript`.
3. Every name in the registry resolves to a file, and that directory is pinned.
4. An island's props name a field that exists on the same page, and any limit it
   displays equals the limit that field actually enforces.
5. Island copy exists in both locale files.
6. A screen renders and functions with every island removed.

## Acceptance Criteria

- The bundle Vite builds matches neither `new Function(` nor `compileToFunction`
  nor `@vue/compiler-dom`.
- `config/importmap.rb` pins no `vue`, and `vendor/javascript/vue.js` is gone.
- Exactly one file across the two source directories calls `createApp`, and
  exactly one Vite entrypoint exists.
- On `/admin?tab=proposals`, the reason field has the id the island's `fieldId`
  prop names, the island's `max` equals the field's `maxlength`, and its
  `template` is `forms.characters_left` with `%{count}` still unresolved.
- `forms.characters_left` exists in `en.yml` and `th.yml`.

## Verification

- `test/operations/vue_build_test.rb` — builds the bundle, then asserts the
  compiler is absent, the registry resolves, `createApp` has one caller, the
  import map carries no Vue, and there is one entrypoint.
- `test/controllers/admin_proposals_test.rb` — the island's props against the
  field they describe.
- `test/operations/locale_parity_test.rb` — the copy exists in both languages.
- `test/system/vue_island_walk_test.rb` — the half no other test can see: that
  the island mounts at all, counts down as somebody types, changes tone near the
  limit, and that the form still records a decision with the island on the page.
  Three failures are only visible here — a CSP that blocks the build, a bridge or
  registry that never mounts, and an island bound to the wrong field.

## Consequences

- One dependency, one bridge, one registry, and a list of what islands may not
  do that is shorter to read than the first island.
- The second island costs a file and a registry line. The first cost this
  document, which is the point at which the boundary is cheapest to set.
- If SFCs are ever needed, this specification is what the bundler ADR argues
  against, with a real island to measure the argument on.
