---
id: SPEC-0007
type: spec
title: Academic-post authoring and reader tools
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-10-31
supersedes: []
superseded_by: []
depends_on: [SPEC-0004, SPEC-0005, SPEC-0006]
implemented_by:
  - app/models/academic_post.rb
  - app/controllers/academic_posts_controller.rb
  - app/services/academic_post_content_sanitizer.rb
  - app/views/academic_posts
  - app/javascript/controllers
  - config/locales/en.yml
  - config/locales/th.yml
touches:
  - app/models/academic_post.rb
  - app/controllers/academic_posts_controller.rb
  - app/views/academic_posts
  - app/javascript/controllers
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
  - test/system
enforced_by:
  - test/models/academic_post_content_safety_test.rb
  - test/controllers/academic_posts_controller_test.rb
  - test/system/academic_post_walk_test.rb
agent_writable: true
---

# Academic-Post Authoring and Reader Tools

> [Executable Specifications](README.md) ·
> [Academic-post permissions and lifecycle](spec-academic-post-permissions-and-lifecycle.md) ·
> [Tiptap editor integration](spec-academic-post-tiptap-editor.md) ·
> [Preview-page editing](spec-academic-post-preview-editing.md) ·
> [Academic writing roadmap](../roadmap.md#milestone-10--academic-writing) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted in the repository. The bounded first increment is
> implemented and ready for human verification: one sanitized Tiptap document,
> section navigation, reading width, font size, theme controls, structured
> author-entered references and citations, HTML-only export, and a WCAG 2.2 AA
> accessibility baseline. Comments, translation, search/library, social tools,
> and other export formats remain deferred. Full completion still requires
> acceptance of the structured-content and browser criteria below.

## Problem

Academic posts currently support title, body, basic formatting, mathematics,
and preview-shell editing. The roadmap calls for a useful academic workspace
with structured sections, references, citations, figures, tables, code, and
reader controls. Those capabilities affect storage, sanitization, accessibility,
localization, and export behavior, so they must be bounded before implementation.

## Scope

### Included

- Structured academic sections and subsections within the existing Tiptap
  document model or an explicitly accepted extension of it.
- References and citation markers with a server-safe reader representation.
- Figures with captions and accessible alternative text using the existing
  server-owned picture boundary.
- Tables, code blocks, links, lists, quotations, and notes within the accepted
  sanitizer allowlist.
- Reader controls for section navigation, reading width, font size, and theme
  where the accessibility and persistence behavior is accepted.
- Thai and English labels, empty states, validation errors, and reader controls.
- Focused model, controller, content-safety, accessibility, and browser tests.

### Excluded

- Real-time collaboration, presence, automatic merge, or new permission rules.
- Production email, external asset hosting, arbitrary embeds, or executable
  content.
- Machine translation or claims of translation quality without a separate
  accepted content and privacy decision.
- Comments, highlights, library search, or social features unless individually
  accepted below.
- PDF, Markdown, DOCX, or citation-manager export until an export contract is
  accepted.

## Resolved Product Decisions

1. The first increment keeps structured academic content in one sanitized Tiptap
   document rather than introducing first-class rows for each content element.
2. The first reader controls are section navigation, reading width, font size,
   and theme.
3. References and citations are structured, author-entered content owned by the
   post document and rendered through a server-safe reader representation.
4. Comments, highlights, translation, search/library views, and social tools are
   deferred to separate backlog decisions.
5. HTML is the only export format in this increment.
6. The reader and controls follow a WCAG 2.2 AA accessibility baseline.

## Invariants

1. Existing server-side ownership, membership, role, lifecycle, revision, and
   conflict checks remain authoritative for all authoring actions.
2. Reader output and exports contain only sanitized, approved HTML and
   server-owned attachment references.
3. Structured content cannot create executable markup, unsafe URLs, arbitrary
   embeds, or unapproved remote assets.
4. A viewer can read only content they are currently authorized to access, and a
   revoked collaborator loses access on the next request.
5. Figures require validated attachments and accessible alternative text; tables,
   code, links, lists, quotations, notes, and equations preserve safe semantics.
6. Thai and English translations for the same control, state, error, and empty
   case remain structurally aligned.
7. Reader controls do not mutate saved academic content unless an explicit,
   separately authorized preference path is accepted.
8. Any export uses the same authorization and sanitization boundary as the reader.

## Acceptance Criteria

- [ ] An authorized author creates a structured post containing the accepted
      section, reference, figure, table, code, link, list, quotation, note, and
      mathematics elements (`test/controllers/academic_posts_controller_test.rb`).
- [ ] The reader renders the accepted structured content with safe HTML and
      accessible figure, table, code, link, and equation semantics
      (`test/models/academic_post_content_safety_test.rb`).
- [ ] An unauthorized or revoked user cannot read structured content, attachments,
      references, or exports (`test/controllers/academic_posts_controller_test.rb`).
- [ ] Accepted reader controls work at supported responsive widths without
      changing the saved post (`test/system/academic_post_walk_test.rb`).
- [ ] Thai and English labels, errors, empty states, and accessibility names are
      aligned (`test/models/academic_post_locale_test.rb`).
- [ ] Any accepted export produces only authorized, sanitized content and has a
      focused contract test (`test/controllers/academic_posts_controller_test.rb`).

## Error and Boundary Cases

- Unsupported structured nodes fail visibly or degrade to safe text without
  dropping unrelated content.
- A malformed citation or reference cannot inject HTML, unsafe URLs, or script.
- A figure with invalid bytes, dimensions, type, size, or missing alt text is
  rejected according to the accepted accessibility policy.
- A table or code block that exceeds content limits is rejected without partial
  persistence.
- Reader preferences survive navigation only if the accepted persistence scope
  permits it and never override authorization.
- A stale save preserves the newest revision and returns the existing conflict
  behavior.
- Export requested for an inaccessible or unpublished private post is denied
  without revealing its existence.

## Verification

```bash
bin/docs
bin/rails test test/models/academic_post_content_safety_test.rb test/controllers/academic_posts_controller_test.rb
bin/rails test:system test/system/academic_post_walk_test.rb
bin/verify
```
