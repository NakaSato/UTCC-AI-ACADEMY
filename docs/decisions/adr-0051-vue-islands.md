---
id: ADR-0051
type: adr
title: Take Vue for islands, on the runtime build, behind one Stimulus bridge
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0007, ADR-0046]
implemented_by:
  - SPEC-0052
touches:
  - config/importmap.rb
  - vendor/javascript/vue.js
  - app/javascript/controllers/vue_island_controller.js
  - app/javascript/islands/registry.js
  - app/javascript/islands/character_counter.js
  - app/views/admin/_proposals.html.erb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/operations/vue_build_test.rb
  - test/controllers/admin_proposals_test.rb
agent_writable: true
requires_skills: [SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Take Vue for Islands, on the Runtime Build, Behind One Stimulus Bridge

> **Decision state:** Accepted by the user on 2026-08-12, who asked for Vue to
> be available to the frontend for some code after being shown the constraints
> below and reaffirming. The capability is what was asked for; this document is
> the boundary that comes with it.

> [Decision Records](README.md) ·
> [Vue islands specification](../specs/spec-vue-islands.md) ·
> [Tiptap bridge](adr-0007-integrate-tiptap-with-stimulus-importmap.md) ·
> [Server-raised toasts](adr-0046-server-raised-toasts.md) ·
> [Coding standard — dependencies](../coding-standard.md)

## Context

The application renders HTML on the server and enhances it with Stimulus over
import maps: seventeen controllers, a thousand lines between them, and no build
step. `docs/coding-standard.md` says a JavaScript package arrives only behind an
accepted ADR naming the capability, the alternatives *including no dependency*,
maintenance and security ownership, failure and removal paths, and the licence
and supply-chain position. This is that document.

**The capability asked for:** a declarative way to build a piece of UI whose
state changes as somebody interacts with it, without hand-writing the DOM
updates. Stimulus is a good way to attach behavior to server-rendered markup and
a poor way to keep a tree in sync with state — the two `innerHTML` assemblies in
`toast_controller.js` and the manual class toggling in `quiz_controller.js` are
what that costs today, and they are the small end of it.

Three facts about this application decide the shape of the answer.

**The CSP has no `unsafe-eval`.** `script_src :self` plus a per-request nonce is
the directive that turns an injected string into a blocked resource. Vue's full
build compiles `template:` strings and in-DOM templates into render functions
with `Function(…)`, which that policy blocks — in production, silently, on a
screen that worked in every test that never loaded the header.

**There is no JavaScript build step.** Propshaft and import maps, and the only
`package.json` script builds the documentation site's CSS. Single-file
components need a bundler, and a bundler is a larger decision than this one.

**Turbo owns the DOM.** Drive replaces the body on navigation and a Stream can
replace any node. An app mounted and forgotten is a detached tree with live
listeners.

## Decision

1. **Vue 3 is available, as the runtime-only build.** `vue.runtime.esm-browser.prod.js`
   is vendored and pinned; `bin/importmap pin vue` fetches the full build and is
   the way this regresses, so `test/operations/vue_build_test.rb` asserts the
   vendored bytes contain no compiler. An island is a render function — `h` —
   never a template string.

2. **Vue is for islands, not for pages.** A screen is server-rendered HTML that
   works with JavaScript off; an island is a small piece of it whose state
   changes under the reader's hands. Vue may not own a route, fetch a page's
   data, own navigation, or replace what a Turbo Frame does. The moment a
   proposal needs `<router-view>`, this decision is the wrong one and the
   replacement is an ADR, not a pull request.

3. **One bridge, and it is Stimulus.** `vue_island_controller.js` is the only
   place that calls `createApp`, asserted by test. Mounting is tied to
   `connect`/`disconnect`, which Turbo already drives for both navigation and
   Streams, so an island cannot outlive the element it was mounted on.

4. **An island is named, never imported by a template.** `islands/registry.js`
   is the list of what may mount; a `data-vue-island-island-value` names an
   entry in it. Markup selects from an allow-list rather than reaching arbitrary
   code, which is the same rule `FeatureSetting`, `AdminConsole.tab_for` and
   every other whitelist in this application already follow.

5. **Copy comes from the server, already translated.** An island takes its words
   as props from `config/locales`, with only the values it computes left to
   interpolate. Translation does not move into JavaScript, and the bilingual
   invariant keeps one home.

6. **An island enhances markup that already works.** The field, the form and the
   limit exist in HTML; the island adds the count. With JavaScript off nothing
   is lost but the enhancement. This is what keeps Vue from becoming load-bearing
   by accident.

7. **Stimulus stays the default.** Vue is the exception for genuinely stateful
   UI, and the existing seventeen controllers are not rewritten. A rewrite for
   its own sake is churn on working, spec-governed screens.

8. **The first island is the character counter** on the proposal decision
   reason: how much of a limited field is left, as somebody types. It is small,
   real, reversible, and it exercises the whole path — pin, registry, bridge,
   mount and unmount, props, both locales, and the CSP.

## Alternatives

### No dependency: keep writing Stimulus

The honest default, and it stays the default for everything that is not
state-shaped (decision 7). It was not chosen as the *only* answer because the
cost lands exactly where it is hardest to see: a controller that assembles
`innerHTML` is one interpolation away from an injection, and one refactor away
from a state the DOM no longer agrees with. What Vue supplies is that the tree
is a function of the state rather than a sequence of edits.

### Alpine.js

Smaller and importmap-friendly, and the closest competitor. Rejected for the CSP:
Alpine's expressions live in `x-` attributes and are evaluated at runtime, which
needs `unsafe-eval` or the CSP build with a different authoring style. Trading
`script-src` for terser markup is not a trade this application makes.

### React with `htm`, or Preact

Comparable capability. Rejected because Vue's reactivity needs no compiler for
the parts this application would use, the runtime build is ~110KB, and the team
question ("what do people here already read?") has no evidence either way. This
is the weakest of the three rejections and would be the first to revisit.

### Add a bundler and take single-file components

The version of this that most people mean by "add Vue". Rejected here as a
different and much larger decision: it changes the asset pipeline, the CI shape,
the deploy artifact, and the reason import maps were chosen. If SFCs turn out to
be the thing that matters, that is the ADR to write — and this one is a
prerequisite for knowing.

## Consequences

- One dependency, MIT-licensed, ~110KB vendored, no transitive packages, no
  build step, and `bin/importmap audit` covers it because the pin carries its
  version.
- **Maintenance and security ownership:** Tech Lead, with the Security owner for
  the CSP boundary. Upgrades are `bin/importmap pin vue` **followed by
  re-vendoring the runtime build** — the pin command alone reintroduces the
  compiler, and the test fails loudly when it does.
- **Failure path:** an island that fails to mount leaves the server's markup on
  screen, because every island enhances something that already renders. A name
  the registry does not answer to warns in the console and changes nothing.
- **Removal path:** delete `app/javascript/islands`, the bridge controller, the
  two pins and the vendored file, and revert the island's markup to its
  server-rendered form. Nothing else imports Vue, which decision 3 exists to
  keep true.
- Islands are verifiable only in a browser, so `bin/rails test:system` is where
  their behavior is proven. What the server owns — that the island names a field
  that exists, with the limit that field enforces, and the copy from both locale
  files — is asserted without one.
- This is the second JavaScript dependency taken for behavior and refused for
  styling, after Tiptap. The token system stays the only source of appearance.

## Fitness Functions

- `vendor/javascript/vue.js` contains no `Function(` call and no
  `compileToFunction`, whatever an upgrade did.
- `createApp` appears in exactly one file.
- Every name in the registry resolves to a file, and the islands directory is
  pinned.
- An island's props name a field that exists on the same page, with the same
  limit that field enforces.
- No island carries a `template:` string.

## Decision owner

Tech Lead, with the Security owner for the CSP boundary and the Product Owner
for where islands may be used. **Accepted by the user on 2026-08-12.**
