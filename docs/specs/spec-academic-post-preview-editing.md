---
id: SPEC-0006
type: spec
title: Academic-post preview-page editing
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-16
supersedes: []
superseded_by: []
depends_on: [SPEC-0004, SPEC-0005]
implemented_by:
  - app/views/academic_posts/edit.html.erb
  - test/controllers/academic_posts_controller_test.rb
touches:
  - app/controllers/academic_posts_controller.rb
  - app/views/academic_posts
  - config/routes.rb
  - test/controllers/academic_posts_controller_test.rb
  - test/system/academic_post_walk_test.rb
enforced_by:
  - test/controllers/academic_posts_controller_test.rb
  - test/system/academic_post_walk_test.rb
agent_writable: true
---

# Academic-Post Preview-Page Editing

> [Executable Specifications](README.md) ·
> [Academic-post permissions and lifecycle](spec-academic-post-permissions-and-lifecycle.md) ·
> [Tiptap editor integration](spec-academic-post-tiptap-editor.md) ·
> [Academic writing roadmap](../roadmap.md#milestone-10--academic-writing) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted in the repository. The existing edit route is rendered
> in the preview shell, successful saves return to read-only preview, stale saves
> use the existing visible conflict page, and the baseline keyboard/focus rules
> apply to all preview editor controls.

## Problem

The current academic-post experience separates the reader preview from the
editor. Authors lose reading context when moving between those surfaces, and
the roadmap calls for editing from the post preview page. The preview editor
must reuse the accepted server-side lifecycle, Tiptap integration, sanitization,
revision, and authorization boundaries rather than introducing a second save
path.

## Scope

### Included

- An authorized owner or active editor can enter an edit state from the post
  preview without losing the post context.
- The existing Tiptap editor and Rails draft update path are reused.
- The preview shows the same sanitized saved representation that the editor
  edits.
- Draft save, validation errors, stale-write conflicts, and locale behavior
  remain visible on the preview surface.
- Published and review-state posts retain their existing read-only behavior.
- The edit affordance and keyboard/focus behavior are covered in controller and
  browser tests.

### Excluded

- A second persistence endpoint or client-authoritative authorization path.
- Real-time collaboration, presence, automatic merge, or new revision rules.
- New academic content types, citations, comments, export formats, or reader
  tools.
- Changes to the accepted owner, membership, submission, approval, or publish
  lifecycle.
- A decision about whether edit mode is represented by a query parameter,
  nested route, or an in-place Turbo state until human review accepts one.

## Resolved Product Decisions

1. Edit mode uses the existing `/academic_posts/:id/edit` route rendered in the
   preview shell.
2. A successful save returns to the read-only preview.
3. A stale save uses the existing visible conflict page.
4. Preview editor controls use the standard keyboard navigation, visible focus,
   semantic labels, and responsive layout baseline.

## Invariants

1. Every preview read and edit transition is authorized server-side using the
   existing owner, active-membership, role, and lifecycle checks.
2. Only an owner or active editor of a draft can submit changes; viewers cannot
   obtain an editor by forging a preview or form parameter.
3. The preview renders server-sanitized content and never trusts editor HTML,
   status, owner, role, or lock-version fields from the client.
4. Saves use the existing optimistic lock and revision path. A stale save is
   visible and cannot overwrite newer content.
5. Review and published posts remain read-only through every preview URL and
   form variant.
6. Removing or failing to initialize JavaScript does not create a second
   persistence path or silently submit stale content.
7. Thai and English labels, errors, conflict messages, and edit controls remain
   structurally aligned.

## Acceptance Criteria

- [ ] An authorized owner opens a draft preview and enters the accepted edit
      state without exposing another user's post (`test/controllers/academic_posts_controller_test.rb`).
- [ ] An active editor can edit and save from the preview surface, while a
      viewer is denied without changing the post (`test/controllers/academic_posts_controller_test.rb`).
- [ ] A successful save returns to the accepted preview/edit state and displays
      the sanitized saved body (`test/system/academic_post_walk_test.rb`).
- [ ] A stale preview save shows the accepted conflict behavior and preserves
      the newer revision (`test/controllers/academic_posts_controller_test.rb`).
- [ ] Review and published posts do not expose an editable preview form and
      reject forged update requests (`test/controllers/academic_posts_controller_test.rb`).
- [ ] The preview editor's controls, focus order, validation errors, and Thai or
      English labels are covered at supported responsive widths
      (`test/system/academic_post_walk_test.rb`).

## Error and Boundary Cases

- A revoked collaborator follows an old preview or edit URL and is denied.
- A malformed post ID or edit state returns the existing safe not-found or
  forbidden response without revealing private content.
- Tiptap fails to initialize and the form does not submit stale hidden content
  silently.
- A draft becomes review or published between preview and save and the update
  is rejected without a partial write.
- A stale lock version does not discard the latest saved title or body.
- A locale switch does not change stored HTML or bypass authorization.

## Verification

```bash
bin/docs
bin/rails test test/controllers/academic_posts_controller_test.rb
bin/rails test:system test/system/academic_post_walk_test.rb
bin/verify
```
