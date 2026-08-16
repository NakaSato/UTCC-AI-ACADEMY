---
id: SPEC-0005
type: spec
title: Academic-post Tiptap editor integration
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-10-31
supersedes: []
superseded_by: []
depends_on: [ADR-0006, ADR-0007]
implemented_by:
  - config/importmap.rb
  - app/javascript/controllers/tiptap_controller.js
  - app/services/academic_post_content_sanitizer.rb
  - app/services/academic_post_picture_validator.rb
  - app/controllers/academic_posts_controller.rb
  - test/models/academic_post_content_safety_test.rb
  - test/models/academic_post_picture_test.rb
  - test/controllers/academic_posts_controller_test.rb
  - test/system/academic_post_walk_test.rb
  - test/system/academic_post_tiptap_walk_test.rb
touches:
  - config/importmap.rb
  - app/javascript/controllers
  - app/models/academic_post.rb
  - app/controllers/academic_posts_controller.rb
  - app/views/academic_posts
  - test/models
  - test/controllers
  - test/system
enforced_by:
  - bin/docs
  - test/models/academic_post_content_safety_test.rb
  - test/models/academic_post_picture_test.rb
  - test/controllers/academic_posts_controller_test.rb
  - test/system/academic_post_walk_test.rb
  - test/system/academic_post_tiptap_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-001, SKILL-ARCH-004, SKILL-HUM-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-001, SKILL-ARCH-004]
---

# Academic-Post Tiptap Editor Integration

> [Executable Specifications](README.md) ·
> [Tiptap integration ADR](../decisions/adr-0007-integrate-tiptap-with-stimulus-importmap.md) ·
> [Academic-post lifecycle specification](spec-academic-post-permissions-and-lifecycle.md) ·
> [Academic writing roadmap](../roadmap.md#milestone-10--academic-writing) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted in the repository. JavaScript dependencies and
> implementation may proceed under the recorded invariants; picture import
> retains its explicit storage, validation, and security constraints.

## Problem

Academic posts currently use a plain text area. Authors need a structured,
Medium-like editing surface with application-owned styling, while the existing
Rails lifecycle must continue to own authorization, saved revisions, stale-write
conflicts, submission, and publication approval.

## Scope

### Included

- A Stimulus controller that initializes Tiptap from the academic-post form.
- Importmap delivery of the approved, version-pinned Tiptap packages.
- StarterKit content with the explicitly approved Bubble Menu and Floating Menu
  behavior.
- LaTeX inline and block mathematics through the official
  `@tiptap/extension-mathematics` extension and KaTeX rendering.
- Picture import through an approved server-owned upload path, with an image
  reference represented in the Tiptap document only after validation.
- Synchronization of serialized editor HTML into the Rails form field before
  save.
- Tailwind-compatible editor, focus, menu, empty-state, and validation styles.
- KaTeX CSS delivered through an approved Rails asset path or the selected
  bundler; it must not depend on an unreviewed runtime CDN.
- Server-side content sanitization before reader rendering or HTML export.
- Tests for initialization, existing-body loading, synchronization, mathematics,
  malformed or unsafe content, authorization, and visible stale-write conflicts.

### Excluded

- ActionText storage or a community Rails wrapper gem.
- React, Vue, Vite, esbuild, or Bun migration.
- Real-time collaboration, cursors, presence, or automatic conflict merging.
- Remote embeds, arbitrary HTML, and unapproved attachment processing.
- Citation, comments, translation, and non-HTML export tools.
- Changes to the accepted owner, submission, instructor-approval, or revision
  lifecycle rules.

## Invariants

These invariants are accepted for this implementation slice. Changes to the
content allowlist, fallback behavior, or attachment boundary require a new
review rather than an implicit extension of the editor.

1. The editor must initialize with the persisted academic-post body for the
   authorized owner and must not load another user's draft.
2. Before a form submission reaches Rails, the current editor document must be
   serialized into the submitted body field; an old hidden value must not win.
3. The server must remain authoritative for owner, role, lifecycle, and
   `lock_version`; Tiptap data cannot grant access or publish a post.
4. Submitted HTML must be bounded and sanitized on the server before it is
   rendered in a reader or used for HTML export.
5. The sanitizer must remove executable elements, event-handler attributes,
   unsafe URL protocols, and unapproved embeds without silently widening the
   allowlist when a new extension is added.
6. A stale `lock_version` must preserve the newer saved content and return the
   existing visible conflict response; editor initialization must not hide the
   conflict.
7. A draft with empty title or body may remain a draft, but it cannot be
   submitted for review or published under the existing lifecycle contract.
8. Removing or failing to initialize JavaScript must not create a second
   persistence path or bypass server validation; the form must show a safe
   failure or usable fallback.
9. Mathematical content must be represented by the approved Tiptap mathematics
   nodes, not arbitrary HTML or executable attributes.
10. KaTeX rendering must use the approved package and stylesheet version; a
    missing stylesheet or invalid expression must fail visibly without
    exposing raw unsafe markup.
11. Author-provided LaTeX macros and expressions must not widen the HTML,
   URL, embed, or script allowlists.
12. An imported picture must be authorized for the current post, validated from
    its decoded bytes, and referenced only through a server-approved attachment
    URL; a client-supplied URL or filename cannot attach arbitrary content.
13. Picture rendering must use an approved image format and bounded dimensions
    and size, with alt text handled according to the accepted accessibility
    policy.

## Acceptance Criteria

- [ ] An authorized student or instructor opens the new/edit form and the
      editor loads the current title and body without exposing another user's
      draft (`test/system/academic_post_tiptap_walk_test.rb`).
- [ ] Typing, selecting a heading/list/quote, and using the approved Bubble or
      Floating Menu updates the Rails body field before submit
      (`test/system/academic_post_tiptap_walk_test.rb`).
- [ ] An author can create approved inline and block mathematics using the
      accepted LaTeX interaction, and the saved document renders it through
      KaTeX in the editor and reader (`test/system/academic_post_tiptap_walk_test.rb`).
- [ ] A saved post renders only sanitized, approved HTML; script elements,
      event handlers, unsafe links, unapproved embeds, and unsafe mathematical
      markup are not rendered (`test/models/academic_post_content_safety_test.rb`).
- [ ] Invalid or unsupported LaTeX produces the accepted visible error or
      fallback behavior without breaking the rest of the document
      (`test/models/academic_post_math_test.rb`).
- [ ] An author can import a picture through the approved file, paste, or drop
      interaction, and the editor saves only the validated attachment reference
      (`test/system/academic_post_tiptap_walk_test.rb`).
- [ ] An unauthorized user cannot attach, read, replace, or delete a picture
      belonging to another post, and invalid type, size, dimension, or content
      is rejected (`test/controllers/academic_post_picture_test.rb`).
- [ ] Reader and HTML export output contains only approved picture URLs and
      accessible alternative text; unsafe `data:`, `javascript:`, SVG, or
      unapproved remote URLs are not rendered
      (`test/models/academic_post_content_safety_test.rb`).
- [ ] Forged owner, role, status, or HTML-only client fields cannot bypass the
      existing server-side authorization and lifecycle rules
      (`test/controllers/academic_posts_controller_test.rb`).
- [ ] Two editor sessions preserve the newer save and show the existing
      visible stale-write conflict when the older lock version submits
      (`test/controllers/academic_posts_controller_test.rb`).
- [ ] The form remains bounded and displays validation errors for oversized or
      malformed content (`test/controllers/academic_posts_controller_test.rb`).
- [ ] The editor has keyboard-accessible focus, menu controls, and a visible
      validation/failure state at the supported responsive widths
      (`test/system/academic_post_tiptap_walk_test.rb`).
- [ ] The approved package pins pass Importmap and full repository verification
      (`bin/importmap audit`, `bin/verify`).

## Error and Boundary Cases

- Tiptap fails to load: do not submit stale or empty editor content silently;
  show the form error and preserve the server-rendered value.
- The stored body contains legacy plain text: load it without interpreting
  user text as markup and preserve a deliberate migration or escaping rule.
- The sanitizer removes content: save the sanitized result only if the product
  decision permits loss, otherwise return a validation error explaining what
  was rejected.
- A link has a relative, `http`, `https`, or unsafe protocol: apply the accepted
  protocol policy consistently in reader and export output.
- Content reaches the size limit through nested markup: enforce the limit on
  the submitted representation and reject excessive nesting or payload size.
- A browser submits directly without the Stimulus controller: server-side
  validation and authorization still apply, and no client field is trusted.
- A user switches locale while editing: labels and errors remain available in
  the selected locale without changing the stored document.
- KaTeX CSS is unavailable: the editor and reader show a visible degraded
  state or safe fallback defined by the accepted UI decision; they do not load
  styles from an unapproved external CDN.
- A mathematical expression contains unsupported commands or malformed
  delimiters: apply the accepted KaTeX error policy and preserve surrounding
  document content.
- A macro attempts to produce HTML, a link, an embed, or executable content:
  reject or neutralize it according to the sanitizer policy.
- A picture upload has a misleading extension or MIME type: inspect the file
  bytes, reject unsupported formats, and do not trust the browser's metadata.
- A picture exceeds the accepted byte or dimension limit: reject it before it
  becomes part of the saved document.
- A picture is uploaded but the post save fails: apply the accepted orphaned
  attachment cleanup policy without exposing the temporary object.
- A picture is removed from a draft: apply the accepted retention and deletion
  policy without deleting an attachment still referenced by another revision.

## Follow-up Decisions After Acceptance

1. Which exact Tiptap and KaTeX package versions and Importmap URLs are
   approved, and where will KaTeX CSS be served?
2. Which block and inline nodes, including inline and block mathematics, are in
   the first allowlist beyond StarterKit's
   defaults?
3. Which math input affordances and delimiters are supported: `$...$`,
   `$$...$$`, a menu action, or another explicit interaction?
4. Which KaTeX macros and strictness/error policy are allowed for author input?
5. Which storage and authorization boundary will picture import use: Rails
   Active Storage, a dedicated upload endpoint, or another approved service?
6. Which picture formats, maximum byte size, dimensions, metadata policy, and
   alt-text requirement apply? Is SVG permanently excluded?
7. Are pictures imported from local files only, or are paste/drop and approved
   remote imports also supported?
8. How are temporary or orphaned uploads cleaned up, and are pictures retained
   across saved revisions?
9. Are author-submitted links allowed, and if so, which URL protocols and
   target/rel policy apply?
10. Should sanitizer removal reject the save or persist the sanitized result?
11. What is the required no-JavaScript behavior for the authoring form?
12. Should the editor's HTML be canonicalized on save, or only sanitized at
   render/export boundaries?

## Verification

```bash
bin/docs
bin/importmap audit
bin/rails test test/models/academic_post_content_safety_test.rb test/models/academic_post_math_test.rb test/controllers/academic_posts_controller_test.rb
bin/rails test:system test/system/academic_post_tiptap_walk_test.rb
bin/verify
```
