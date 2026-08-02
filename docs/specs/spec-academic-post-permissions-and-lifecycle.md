---
id: SPEC-0004
type: spec
title: Academic-post permissions and draft lifecycle
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-01
updated: 2026-08-02
review_by: 2026-08-15
supersedes: []
superseded_by: []
depends_on: [ADR-0006]
implemented_by:
  - app/models/academic_post_membership.rb
  - app/models/academic_post_invitation.rb
  - app/controllers/academic_post_invitations_controller.rb
  - db/migrate/20260802020000_create_academic_post_collaboration.rb
  - test/models/academic_post_permission_test.rb
  - test/controllers/academic_post_invitations_controller_test.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - db/migrate
  - config/locales/en.yml
  - config/locales/th.yml
  - test/models
  - test/controllers
  - test/system
enforced_by:
  - test/models/academic_post_lifecycle_test.rb
  - test/controllers/academic_posts_controller_test.rb
  - test/models/academic_post_permission_test.rb
  - test/controllers/academic_post_invitations_controller_test.rb
  - test/system/academic_post_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-001, SKILL-ARCH-004, SKILL-HUM-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-001, SKILL-ARCH-004]
---

# Academic-Post Permissions and Draft Lifecycle

> [Executable Specifications](README.md) ·
> [ADR-0006 permissions and lifecycle decision](../decisions/adr-0006-academic-post-permissions-and-lifecycle.md) ·
> [Academic writing roadmap](../roadmap.md#milestone-10--academic-writing) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted in the repository. Implementation follows the
> recorded server-side authorization, invitation, and revision invariants.

## Problem

Academic Writing needs a clear authorization and lifecycle contract before
students and teachers can create, collaborate on, review, or publish posts.
Without that contract, an implementation could expose private drafts, allow a
revoked collaborator to continue editing, or let a client forge publication.

## Scope

### Included

- The ownership, membership, invitation, and lifecycle concepts required by
  the first academic-post increment.
- Server-side authorization rules for private drafts, collaborators, review,
  and published content.
- A visible stale-write/conflict rule for saved revisions.
- Thai and English user-facing states and error messages.
- Focused model, controller, and browser acceptance-test seams.

### Excluded

- The complete academic editor and structured content renderer.
- Real-time presence, cursors, or automatic merge unless separately accepted.
- Production email delivery or credentials; production email remains governed by
  ADR-0004.
- Export formats, comments, translation, KaTeX rendering, and reader tools.
- Automatic publication or permission inference from client-supplied fields.

## Resolved Product Decisions

The Product Owner's requested baseline is:

1. `student` and `instructor` are the author roles; administrators are not
   authors by default.
2. The first increment uses saved revisions with visible conflicts, not
   real-time editing or automatic merging.
3. Invitations are accepted through an in-app acceptance link; production email
   remains out of scope.
4. The owner submits a post for review and an instructor approves publication.
5. HTML is the first export format.

## Invariants

1. Every post has exactly one owner and one lifecycle state from `draft`,
   `review`, or `published`.
2. A request must be authenticated before it can create, read, or mutate a
   private post.
3. Effective permission is computed server-side from owner, active membership,
   account role, and post state; request parameters cannot grant permission.
4. A user without active access cannot read post content, revisions, or
   invitation details.
5. Revoking membership prevents subsequent reads and writes, even if the user
   retains an old URL or invitation token.
6. Only an authorized transition actor can change lifecycle state, and invalid
   transitions are rejected without changing the post.
7. The draft mutation path cannot alter a published representation.
8. A save with a stale revision/version is rejected visibly and leaves the
   newest saved content unchanged.
9. Invitation tokens are single-purpose, revocable, and expire; their raw
   values are never rendered into unrelated pages or logs.
10. Thai and English labels for the same permission and lifecycle state remain
    structurally aligned.

## Acceptance Criteria

- [ ] An authorized role can create and reopen a private draft; an unauthorized
      role cannot (`test/controllers/academic_posts_controller_test.rb`).
- [ ] The owner can grant and revoke explicit collaborator permissions, and a
      revoked collaborator is denied on the next request
      (`test/models/academic_post_permission_test.rb`).
- [ ] Reads and writes derive authorization on the server and reject forged
      owner, role, lifecycle, or membership parameters
      (`test/controllers/academic_posts_controller_test.rb`).
- [ ] Allowed lifecycle transitions succeed, invalid transitions fail without a
      partial write, and publication requires the accepted approval rule
      (`test/models/academic_post_lifecycle_test.rb`).
- [ ] A published post cannot be changed through the draft editor path
      (`test/controllers/academic_posts_controller_test.rb`).
- [ ] A stale save returns a visible conflict and preserves the newer revision
      (`test/models/academic_post_lifecycle_test.rb`).
- [ ] Invitation acceptance follows the accepted non-production delivery rule;
      expired or revoked invitations cannot grant access
      (`test/models/academic_post_permission_test.rb`).
- [ ] Thai and English permission, lifecycle, denial, and conflict messages are
      aligned (`test/models/academic_post_locale_test.rb`).
- [ ] A browser walkthrough demonstrates create → save → reopen → review or
      publish for the accepted role set
      (`test/system/academic_post_walk_test.rb`).

## Error and Boundary Cases

- Missing or suspended accounts cannot use an invitation.
- A duplicate membership grant is idempotent and does not widen permission.
- A user cannot invite themselves or exceed the accepted collaborator limit.
- A malformed, expired, or revoked token returns a safe denial without
  revealing whether the post exists.
- Concurrent saves never silently discard the newer revision.
- A post with missing required title or body cannot enter `review` or
  `published`.
- A locale missing a permission or lifecycle translation fails validation rather
  than falling back silently.

## Verification

```bash
bin/docs
bin/rails test test/models/academic_post_permission_test.rb test/models/academic_post_lifecycle_test.rb test/controllers/academic_posts_controller_test.rb
bin/rails test:system test/system/academic_post_walk_test.rb
bin/verify
```
