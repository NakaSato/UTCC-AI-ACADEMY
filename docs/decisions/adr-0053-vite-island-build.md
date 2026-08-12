---
id: ADR-0053
type: adr
title: Build the island layer with Vite, and leave the rest on import maps
status: accepted
owners: ["@tech-lead", "@security-owner", "@platform-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0051, ADR-0007]
implemented_by:
  - SPEC-0052
touches:
  - Gemfile
  - package.json
  - vite.config.mts
  - config/vite.json
  - config/importmap.rb
  - config/initializers/content_security_policy.rb
  - config/ci.rb
  - Dockerfile
  - bin/setup
  - app/frontend/entrypoints/islands.js
  - app/frontend/islands/CharacterCounter.vue
  - app/views/layouts/application.html.erb
enforced_by:
  - test/operations/vue_build_test.rb
  - test/controllers/admin_proposals_test.rb
  - test/system/vue_island_walk_test.rb
agent_writable: true
requires_skills: [SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Build the Island Layer with Vite, and Leave the Rest on Import Maps

> **Decision state:** **Accepted by the user on 2026-08-12**, who asked for Vite
> after being shown what it costs — a Node build step in CI and in the image, a
> weaker development CSP, and a second toolchain to maintain. This amends
> [ADR-0051](adr-0051-vue-islands.md) decisions 1 and 3 and leaves the rest of
> it standing.

> [Decision Records](README.md) ·
> [Vue islands](adr-0051-vue-islands.md) ·
> [Vue islands specification](../specs/spec-vue-islands.md) ·
> [Tiptap bridge](adr-0007-integrate-tiptap-with-stimulus-importmap.md) ·
> [Coding standard — dependencies](../coding-standard.md)

## Context

ADR-0051 took Vue with no build step, and paid for it in one place: **the CSP.**
`script-src 'self'` with no `unsafe-eval` blocks Vue's template compiler, so the
runtime-only build was vendored and an island had to be a hand-written `h()`
render function. That is Vue at its least pleasant, and it was recorded at the
time as the reason a bundler would be the next decision if single-file
components turned out to matter.

They do. An island whose markup is a nested `h()` call is unreadable at the size
where an island stops being trivial, which is the size the next one will be — a
board, a filter panel, a canvas.

Vite resolves this without touching the policy, because **the compiler moves to
the toolchain**. A `.vue` file is compiled at build time and the browser
receives render code and the Vue runtime alone. The property the CSP cares about
is unchanged; what changes is who does the compiling and when.

## Decision

1. **Vite builds the Vue island layer, and only that.** `vite_rails`, one
   entrypoint, output under `public/vite`, hooked into `assets:precompile`.
   Turbo, Stimulus, Tiptap and the thirteen controllers stay exactly where they
   are, on import maps and Propshaft.

2. **Two directories, two toolchains, no file in both.** `app/javascript` is the
   import map's; `app/frontend` is Vite's. `sourceCodeDir` says so, and the two
   never import from each other — a shared module would mean two copies of the
   same code in two bundles.

3. **Vue leaves the import map.** The pin and `vendor/javascript/vue.js` are
   deleted. Vue in both toolchains is two Vues, and the vendored one exists only
   because there was no compiler; there is one now.

4. **Islands are single-file components.** The counter is rewritten as a `.vue`
   file with the same behavior, which is the whole point of the change and the
   proof it works.

5. **The bridge moves into the Vite entrypoint, and keeps its contract.**
   `createApp` is called in exactly one file, as before. Stimulus can no longer
   host it — its bundle cannot import Vite's — so the entrypoint owns the
   lifecycle with a `MutationObserver` over the document plus a
   `turbo:before-cache` unmount. That covers what Stimulus covered: Drive
   replacing the body, and a Stream replacing one node with no page event at
   all. The markup contract becomes `data-vue-island` and
   `data-vue-island-props`, still a name in a registry rather than an import.

6. **The CSP is unchanged in production and test, and weaker in development
   only.** Vite's HMR client loads from its dev server and evaluates what it
   pushes, so development gains `unsafe_eval` and that origin in `script-src`,
   and the dev server plus its websocket in `connect-src`. Nothing else, and
   nowhere else. A developer running a weaker policy than production is a real
   cost; it is bounded to the one environment that serves nobody.

7. **Node is a build dependency and never a runtime one.** The Dockerfile
   installs it in the build stage, runs `npm ci` and `assets:precompile`, and
   deletes `node_modules` before the final image. The image that runs in
   production has no Node, no npm, and no package tree.

8. **`npm audit` joins the security gate.** `bundler-audit` covers gems and
   `importmap audit` covers pins; a Vite dependency tree is a third supply chain
   and was the one nothing watched. It runs at `--audit-level=high --omit=dev`
   in `config/ci.rb`, beside the other two.

## Alternatives

### Stay on import maps and write `h()` by hand

What ADR-0051 chose, and correct until components stopped being trivial. It
costs nothing to run and gets steadily worse to read. Rejected because the next
island is the reason this decision exists.

### Vite for everything, retiring import maps

The tidier end state: one toolchain, no vendored ProseMirror, no sixty-line
importmap file. Rejected as a much larger change with no benefit to show for it
today — sixty-three pins and thirteen controllers work, are tested, and would
all be touched. It stays available, and this decision does not block it.

### Inertia.js, and a JavaScript view layer

Rejected, and worth writing down because it is the option most often meant by
"add Vite". It replaces the view layer: server-rendered HTML becomes components,
Turbo and Inertia do not coexist, copy moves out of the locale files or is
duplicated, and a screen with JavaScript off is blank. That is a different
application, and it would supersede ADR-0044, ADR-0046 and ADR-0050's reasoning
rather than extend it. If it is ever wanted, it is a rewrite with its own ADR.

### jsbundling-rails with esbuild

Comparable, smaller, and already a Rails default. Rejected because Vue's SFC
support is a first-class Vite plugin and an afterthought elsewhere, and because
the dev-server ergonomics are the thing being bought.

## Consequences

- **A Node toolchain now exists in CI and in the image build.** `bin/setup`
  installs it, `config/ci.rb` builds the bundle and audits the tree, and the
  Dockerfile carries a pinned Node version. That is the cost, and it is paid on
  every build.
- The island bundle is 61KB (24KB gzipped), against 110KB for the vendored
  runtime build it replaces — Vite tree-shakes what the islands do not use.
- **No source map in production.** The first build shipped one: 535KB beside a
  61KB bundle, served publicly, holding the island sources. The argument for it
  was that a bundle nobody can read cannot be reviewed after an incident, and
  that argument needs somewhere for the map to go. There is nowhere — no error
  tracker, no upload step, and no other bundle ships a map, because Propshaft
  serves the import map’s files as they were written. Maps stay on in every
  other mode. If an error tracker arrives, it should be given the map rather
  than the origin serving it.
- Two toolchains is a real maintenance surface: two lockfiles, two audits, two
  upgrade paths. The boundary in decision 2 is what keeps it from becoming
  worse than one.
- `bin/dev` gains a `vite` process, and `autoBuild` covers a developer who does
  not run it. **Test does not use `autoBuild`**: eight parallel workers all
  discovering a stale bundle at once is a race, one reading `public/vite-test`
  while another rewrites it, so `test_helper` builds once in the parent before
  it forks. That cost a green run and two red ones to find.
- The vendored-bytes test that guarded the runtime build is replaced by one that
  builds the bundle and asserts the compiler is not in it — the same invariant,
  one step later in the pipeline.
- A development-only CSP relaxation exists for the first time. It is written as
  a conditional in the policy rather than a comment, so it cannot silently apply
  anywhere else.

## Fitness Functions

- The built island bundle contains no `Function(` compiler call, no
  `compileToFunction`, and no `@vue/compiler-dom`.
- `createApp` appears in exactly one file across both source directories.
- `config/importmap.rb` pins no `vue`, and `vendor/javascript/vue.js` does not
  exist.
- Exactly one Vite entrypoint exists; a second is a decision, not a file.
- The production image contains no `node_modules`.

## Decision owner

Tech Lead, with the Security owner for the CSP and supply-chain gate and the
Platform owner for the image build. **Accepted by the user on 2026-08-12.**
