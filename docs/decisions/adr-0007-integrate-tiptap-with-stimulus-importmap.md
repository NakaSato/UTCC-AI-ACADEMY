---
id: ADR-0007
type: adr
title: Integrate Tiptap with a native Stimulus and Importmap bridge
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-16
supersedes: []
superseded_by: []
depends_on: [ADR-0006]
implemented_by:
  - config/importmap.rb
  - app/javascript/controllers/tiptap_controller.js
  - app/services/academic_post_content_sanitizer.rb
  - app/services/academic_post_picture_validator.rb
  - app/controllers/academic_posts_controller.rb
  - test/system/academic_post_tiptap_walk_test.rb
touches:
  - config/importmap.rb
  - app/javascript/controllers
  - app/models/academic_post.rb
  - app/controllers/academic_posts_controller.rb
  - app/views/academic_posts
  - test/controllers
  - test/system
enforced_by:
  - bin/docs
agent_writable: true
---

# Integrate Tiptap with a Native Stimulus and Importmap Bridge

> [Decision Records](README.md) ·
> [Academic-post lifecycle ADR](adr-0006-academic-post-permissions-and-lifecycle.md) ·
> [Academic writing roadmap](../roadmap.md#milestone-10--academic-writing) ·
> [Tiptap upstream project](https://github.com/ueberdosis/tiptap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted in the repository and implemented in the current
> academic-post slice. Production release remains subject to the release gate.

## Context

The first academic-post slice currently uses a plain Rails text area. The
roadmap calls for an editor inside the preview experience, while the accepted
academic-post lifecycle already defines saved revisions, visible stale-write
conflicts, owner submission, instructor publication approval, and HTML-first
export.

The repository already uses Rails Importmap, Hotwire Stimulus, and Tailwind.
Tiptap is headless and therefore provides editor behavior without imposing a
visual design system. That fits the supplied Medium-like direction, but adding
an editor dependency affects the asset supply chain, content trust boundary,
rendering safety, and future choices about attachments and collaboration.

## Decision

For the first academic-post rich-text editor, use a small, native Stimulus
controller around version-pinned Tiptap packages delivered through the existing
Importmap setup:

- Use Tiptap core and StarterKit for the initial document model.
- Add Bubble Menu and Floating Menu extensions only when the corresponding
  controls are implemented and covered by the editor contract.
- Initialize the editor from the persisted academic-post body and synchronize
  its serialized HTML into the existing Rails form field on update.
- Keep the existing `AcademicPost` save path, `lock_version`, and revision
  snapshots as the authority for persistence and conflict detection. The
  editor must not invent client-side merge behavior.
- Render persisted content through an explicit server-side sanitizer before it
  is placed in the reader or HTML export. Browser-provided HTML is untrusted,
  including content submitted by an authenticated author.
- Use the existing Tailwind design tokens and editor classes for typography,
  spacing, focus states, menus, and empty-block affordances. Tiptap supplies
  behavior, not application styling.
- Preserve a real form input and a usable error path when JavaScript is
  unavailable or the editor fails to initialize.

The baseline does not add ActionText integration, a community Rails wrapper
gem, React or Vue mounting, remote embeds, or real-time collaboration. Picture
import is implemented as a separately bounded capability under SPEC-0005
because it changes the storage, authorization, upload-validation, and
rendering model. The implementation does not authorize remote imports, SVG, or
unbounded attachment processing.

## Alternatives

### Use a community Rails wrapper such as RicherText or Rhino Editor

These may shorten initial integration and provide ActionText-oriented features,
but they add a wrapper's lifecycle and upgrade policy to the application. They
also assume or encourage an ActionText storage and attachment model that the
current academic-post body and revision design does not use.

### Mount a React or Vue Tiptap component

A framework component can provide a rich ecosystem of UI primitives, but this
repository has no React or Vue application boundary. Introducing one for a
single editor would add a second frontend runtime and build path without a
known product requirement.

### Move the application to Vite, esbuild, or Bun

A bundler would make package management and tree-shaking familiar to many
frontend teams, but it would expand the change beyond the editor and replace a
working Importmap path. The migration can be considered if several features
need a bundler, not as a prerequisite for this editor increment.

### Keep the plain text area or adopt Trix/ActionText

The plain text area has the smallest risk but cannot deliver the requested
structured, Medium-like editing experience. Trix/ActionText may reduce custom
code, but its storage and extension model would conflict with the current
explicit HTML body, saved revision, and future export boundary.

## Consequences

### Benefits

- Fits the current Rails asset architecture without introducing a second
  frontend framework.
- Keeps visual ownership in the application and supports the supplied
  Medium-like layout direction.
- Reuses the existing revision and optimistic-concurrency boundary.
- Keeps uploads, embeds, and collaborative editing out of the first security
  and data-model increment.

### Costs and constraints

- The application owns the Stimulus lifecycle, toolbar behavior, accessibility,
  and compatibility work.
- HTML sanitization becomes a mandatory server-side boundary for display and
  export; raw submitted content must never be marked safe.
- Importmap pins, package versions, and transitive assets require review and
  recurring audit attention.
- The initial editor must be intentionally small. Adding extensions later can
  change the persisted document shape and needs a migration or compatibility
  plan.

## Threat Model

| Boundary or asset | Threat | Required control |
| --- | --- | --- |
| Author browser → Rails form | Forged fields, oversized payloads, or unsafe HTML | Keep server authorization and model limits; sanitize and validate on the server |
| Persisted body → reader/export | Stored XSS through tags, attributes, URLs, or embeds | Allowlist the document shape and protocols; sanitize immediately before rendering/export |
| Importmap → browser | Tampered or unexpectedly changed package asset | Pin package versions and URLs; run the repository's importmap audit and review updates |
| Menu/editor DOM → application | Focus, keyboard, and selection failures | Add system coverage for initialization, keyboard access, and form synchronization |
| Stale editor session → save endpoint | Lost update or accidental overwrite | Preserve `lock_version`, visible conflict response, and saved revision snapshot |

The accepted baseline restricts links to safe protocols, keeps remote embeds
out of scope, and limits picture import to validated local Active Storage
attachments. Future changes to those boundaries require a specification and
security review.

## Fitness Functions

- `bin/docs` validates the ADR frontmatter, links, and lifecycle structure.
- `bin/importmap audit` and `bin/verify` pass after the pinned packages are
  added.
- A controller or model test proves that persisted HTML is sanitized before
  reader/export rendering and that authorization remains server-side.
- A system test proves editor initialization, existing-body loading, form
  synchronization, keyboard-accessible menus, and the visible stale-write
  conflict path.
- The Product Owner and Tech Lead acceptance is recorded in this ADR; release
  still requires the repository verification gate and human review of the
  resulting diff.
