---
id: ADR-0006
type: adr
title: Define academic-post permissions and draft lifecycle
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-01
updated: 2026-08-02
review_by: 2026-08-15
supersedes: []
superseded_by: []
depends_on: []
implemented_by:
  - SPEC-0004
  - app/models/academic_post_membership.rb
  - app/models/academic_post_invitation.rb
  - app/controllers/academic_post_invitations_controller.rb
  - test/models/academic_post_permission_test.rb
  - test/controllers/academic_post_invitations_controller_test.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - db/migrate
  - test/models
  - test/controllers
  - test/system
enforced_by:
  - test/models/academic_post_permission_test.rb
  - test/controllers/academic_post_invitations_controller_test.rb
agent_writable: true
---

# Define Academic-Post Permissions and Draft Lifecycle

> [Decision Records](README.md) ·
> [Academic-post specification](../specs/spec-academic-post-permissions-and-lifecycle.md) ·
> [Academic writing roadmap](../roadmap.md#milestone-10--academic-writing) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted in the repository. Production email remains out
> of scope; the in-app invitation boundary is implemented under SPEC-0004.

## Context

Milestone 10 needs a durable academic-post boundary before implementation. The
current application has `student` and staff roles, but no academic-post model,
collaboration membership, invitation flow, revision policy, or publication
state. The roadmap also requires a safe first increment while production email
remains deferred.

The decisions are consequential because an incorrect ownership or publication
rule can expose unpublished student work, make revocation ineffective, or make
later collaboration and moderation migrations expensive.

## Decision

Record the following product decisions as the baseline for human acceptance:

- An academic post has one owner and an explicit lifecycle: `draft`, `review`,
  and `published`.
- `student` and `instructor` are the author roles. Administrators are not
  authors by default; any moderation authority must be specified separately.
- Authorization is checked on the server for every read and mutation. A
  signed-in student or instructor may create a post; anonymous users cannot
  create or mutate one.
- The owner is the authority for draft membership and may revoke a member. A
  collaborator's effective permission is explicit (`viewer` or `editor`) and
  is evaluated against the current post state, not only against an invitation
  record.
- A published post is immutable through the draft editor. Any later change
  must use a new revision or an explicitly accepted editorial workflow; the
  implementation must not silently mutate the published representation.
- Every saved mutation carries a revision/version check. The first increment
  uses saved revisions with a visible conflict response; it does not attempt
  real-time editing or automatic merging. A stale write must not silently
  overwrite a newer save.
- Invitations are represented as revocable, expiring records and are accepted
  through an in-app acceptance link. This does not add production email or
  credentials.
- The owner submits a post for review, and an instructor approves publication.
  The implementation must not treat submission as publication.
- HTML is the first export format; other formats are out of scope for this
  increment.

## Alternatives

### One owner with no collaboration

Smallest data model and safest access boundary, but it fails the roadmap goal
of invited co-authors and would require a second ownership model later.

### Real-time collaborative editing first

Provides the richest authoring experience, but introduces presence, ordering,
reconnect, conflict-resolution, and operational requirements before the
permission and lifecycle rules are proven.

### Saved revisions with optimistic concurrency first

Selected for the first increment. It keeps the work reversible and testable,
gives collaborators a clear conflict instead of silently losing work, and
defers real-time cursor and merge behavior.

### Trust client-supplied role and lifecycle fields

Rejected. It would make forged requests capable of publishing or editing work;
the server must derive effective permission from persisted ownership,
membership, role, and lifecycle state.

## Consequences

- The data model must separate post ownership, collaboration membership,
  invitation state, and post revision/version state.
- Controller and policy tests must cover direct forged requests, revoked
  members, stale writes, cross-user reads, and published-content mutation.
- A non-email invitation path is needed for local development and testing, but
  it must not be treated as production delivery.
- The initial experience is less fluid than real-time collaboration; that
  trade-off can be revisited after learner and teacher feedback.

## Fitness Functions

- `bin/docs` validates this ADR's frontmatter, links, and lifecycle headings.
- The accepted specification maps each permission and lifecycle invariant to a
  focused test before implementation begins.
- A forged request cannot read or mutate another user's private draft.
- A revoked collaborator loses access on the next authorized request.
- A stale revision cannot overwrite a newer saved revision.
- A published representation cannot be changed through the draft mutation
  path.
