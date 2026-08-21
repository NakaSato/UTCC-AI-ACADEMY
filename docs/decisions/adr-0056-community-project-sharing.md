---
id: ADR-0056
type: adr
title: Define public community project sharing and collaboration boundary
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@admin-owner"]
created: 2026-08-20
updated: 2026-08-21
review_by: 2026-11-18
supersedes: []
superseded_by: []
depends_on: [ADR-0017, ADR-0006, ADR-0044]
implemented_by: []
touches:
  - app/models
  - app/controllers
  - app/views
  - app/services
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test/models
  - test/controllers
  - test/system
enforced_by: []
agent_writable: true
requires_skills: [SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004]
---

# Define Public Community Project Sharing and Collaboration Boundary

> **Decision state:** Draft. The requester has set the initial policy: students
> and instructors may create projects; an owner publishes directly; the owner
> decides join requests; and administrators alone moderate public projects.
> WiT (`@product-owner`) completed Plan triage on 2026-08-21: priority is High;
> the baseline is no community-project, team, comment, or moderation workflow;
> the one-semester target is 30 public projects, 15 approved collaborator joins,
> and no report older than 48 hours; and tags, ranking, attachments, chat, and
> ownership transfer are deferred until after the pilot. This is recorded in
> [UTCC M11](../roadmap.md#milestone-11--community-project-sharing) and
> [`COMM-001`](../backlog.json). The ADR remains draft pending its accountable
> design, privacy, security, academic, and administration reviews.

> [Decision Records](README.md) ·
> [Community-boundary decision](adr-0017-helping-hand-community-boundary.md) ·
> [Academic-post collaboration decision](adr-0006-academic-post-permissions-and-lifecycle.md) ·
> [Project Development Flow](../development-flow.md)

## Context

The academy has no learner project-sharing community. Its landing-page
“community” content is marketing copy. Academic posts support private,
invitation-only collaboration and instructor-approved publication, while
company business cases belong to an organization and have a separate,
confidential participation boundary. Neither implements a student or instructor
project that its owner can make publicly discoverable, invite collaborators to,
or accept interested members into.

ADR-0017 deliberately deferred all learner-generated community interaction
until a moderated policy existed. This proposal is that policy for one narrow
project-sharing slice; it does **not** make the Helping Hand award earnable or
 introduce a forum, ratings, direct messages, peer grading, or production
 email. Project comments are the one approved interaction mechanism.

## Problem frame

- **Affected users:** Students and instructors who need a durable place to
  present work and form a project team; administrators responsible for public
  content and safety.
- **Current behavior:** A user cannot create a community project, set a
  project-wide audience, invite collaborators, request to join another
  project, or administratively review all project posts.
- **Failure risk:** A private work-in-progress leaks publicly; an owner or role
  is forged through request parameters; spam or inappropriate work is publicly
  displayed without an accountable moderation path; or an old invitation or
  join request grants access after it should not.
- **Proposed outcome:** An eligible user creates one project, keeps it private
  or publishes it deliberately, collaborates through owner-approved membership,
  and can rely on an administrator-only moderation path for public content.

## Decision

Create a separate **Community Projects** domain. Do not extend
`AcademicPost`, `BusinessCase`, recruitment profiles, or course curriculum
tables: their lifecycle, audience, authorization, and retention purposes are
different.

The proposed first increment has these boundaries:

1. A student or instructor can own a project. Every project has exactly one
   owner, a title, a short description, a visibility state, and a moderation
   state. Every new project defaults to private.
2. The owner may directly switch a project between private and public unless an
   administrator has hidden it. “Public” means discoverable and readable by
   authenticated student and instructor academy users only; it is not visible
   to unauthenticated visitors or company accounts. Private projects appear
   only to their owner and active collaborators. A hidden project is not
   deleted and is unavailable to every ordinary user, including its owner and
   collaborators, until an administrator restores it.
3. An owner can issue a revocable, expiring in-app invitation to an existing
   eligible user. Acceptance creates an active project membership. No
   production-email dependency is introduced.
4. An eligible user can submit one pending join request for a discoverable
   public project. Only the owner can accept or reject it; acceptance creates
   one active editor membership. An active collaborator may edit the shared
   project title and description, but cannot change ownership, visibility,
   invitations, join requests, or moderation. Whether a private project exposes
   a non-content join-request path remains a Product and Academic Owner
   decision for the specification.
5. Administrators can list and read every project, including private and
   hidden ones, solely for the approved oversight purpose. An eligible viewer
   can report visible project or comment content as `safety_or_harassment`,
   `personal_data_or_privacy`, `plagiarism_or_copyright`, `spam`, or `other`,
   with optional plain-text context. Administrators alone can view reporter
   identity, review a report, dismiss it, or hide and restore the reported
   project or comment. The reported author is notified of a hide and can appeal
   within 14 calendar days. An administrator records an uphold or restore
   decision within seven calendar days of the appeal; neither the author nor
   other users can identify the reporter.
   Moderation actions require an actor, reason, timestamp, and audit record;
   they do not change project ownership or grant collaboration access.
6. A visible project can own plain-text comments. An authenticated student or
   instructor can comment only on a public project they may read, while its
   owner and active collaborators can comment on their private project. A
   comment inherits the project's current audience; it has no replies,
   direct-message behavior, attachments, or executable content. Its author can
   soft-delete it; it disappears from ordinary views while a minimal
   author/project/timestamp audit record remains for administrators. An owner
   cannot delete another user's comment, while an administrator can hide it
   through moderation.
7. An eligible reader can give a visible comment one like or one dislike. A
   reaction belongs to one comment and one user; it does not convey membership
   or any other project permission. Selecting the same reaction removes it;
   selecting the opposite reaction replaces it.
8. Project and comment text are learner-generated content shared inside the
   authenticated academy audience. The first increment requires a report path,
   an administrator-owned queue, an appeal path, safe denial behavior, and a
   48-hour target for administrators to review a new report before public
   discovery is enabled. Reports of urgent threats or personal data follow the
   existing safety escalation process immediately.
   Attachments, source-code execution, messaging, ratings, and project
   assessment are excluded.
9. A project reader may see its owner and active collaborators' display names
   and optional public avatars. Email addresses, student identifiers, phone
   numbers, and private profile fields are never exposed through Community
   Projects. This team display inherits project audience: it is available to
   authorized readers of a visible project and to administrators for oversight.

## Alternatives

### Extend academic posts

Academic posts already have owner, membership, invitation, revision, and
publication concepts. Reusing them would conflate instructor-approved academic
publication with owner-controlled project visibility, couple project work to a
rich-text/revision model it does not require, and risk widening academic-post
access. Rejected.

### Extend company business cases

Business cases already model collaborative project work. They are
organization-scoped, confidential, and governed by recruitment participation;
using them would expose company boundaries to the academy community. Rejected.

### Make every project public and let anyone join

This minimizes workflow steps but exposes unfinished student work and lets
unwanted users enter a team. It has no owner-controlled access boundary.
Rejected.

### Keep projects private and invitation-only

This reuses a familiar safety boundary and minimizes moderation, but does not
meet the requested public sharing and owner-approved join flow. Rejected.

### Reopen the Helping Hand award with project activity

Publishing or joining a project is not evidence of useful peer help and would
create an incentive to spam. The award remains unavailable under ADR-0017.
Rejected.

## Consequences

- The implementation introduces new project, membership, invitation, join
  request, comment, comment-reaction, and report/moderation records. It must
  not repurpose or migrate academic-post or business-case data.
- Project membership becomes a collaboration authorization boundary, distinct
  from visibility. A public project is readable by its approved audience but
  not writable by a visitor; an active collaborator may edit only the approved
  shared project fields.
- Direct owner publication is faster, but requires an operational moderation
  commitment before enabling public discovery.
- Admin visibility is a high-privilege privacy boundary. Admin read and
  moderation actions must be audited and must not expose project data in
  notifications, logs, or public error pages.
- The community scope remains intentionally small: comments and like/dislike
  reactions only, with no chat, applicant ranking, peer review, grades, award
  credit, uploads, or external integrations.

## Threats and controls

| Threat | Control to specify and test |
| --- | --- |
| Private-project enumeration or insecure direct object reference | Server-side audience policy on every read and mutation; safe 404/denial behavior; no client-supplied owner, role, or visibility authority. Public visibility grants authenticated student/instructor read access only. |
| Forged publication, join approval, or moderation | Derive actor from the authenticated session; authorize owner and administrator transitions separately; record moderation audit events. |
| Duplicate, replayed, or self-serving membership flow | Database foreign keys, check constraints, partial unique indexes for open invitations and pending requests, single-use/expiring invitations, and transactionally created memberships. |
| Comment spam, script injection, or private-comment leakage | Plain-text length-limited storage; audience authorization is rechecked on every read/write; no attachments, replies, or rendered HTML; administrators moderate reported comments. |
| Deleted-comment disclosure | Self-deletion removes comment content from ordinary views and retains only the approved minimal audit record; retention duration and any report-evidence exception require privacy review. |
| Forged, duplicate, or brigaded reactions | Server-side audience authorization; a database unique index on comment/user; an allowed `like`/`dislike` value; aggregate counts that do not expose reacting identities. |
| Contributor identity disclosure | Show only display names and optional public avatars to authorized project readers; never expose email, student ID, phone number, or private profile fields. |
| Public abuse, plagiarism, harassment, or personal data | Eligible-viewer reporting route with an allowed, auditable category and optional plain-text context; administrator-only queue and reporter identity; hide/restore rather than destructive deletion; author notification and appeal; and documented escalation/retention policy. |
| Administrator overreach or disclosure | Limit admin actions to the console role, audit every privileged read/action as approved by policy, and prohibit project text in Slack or telemetry. |

## Fitness Functions

- A database constraint and server-side policy make it impossible for a project
  to have no owner, more than one owner, or a visibility/moderation state
  outside the approved enumeration.
- Private project content, membership, invitations, and join-request details
  are unreadable to a user who is neither the owner, an active collaborator,
  nor an administrator. A hidden project is unreadable to every ordinary user,
  including its owner and active collaborators.
- Only an owner can create/revoke invitations and accept/reject join requests;
  only an administrator can view a reporter identity, review/dismiss a report,
  or hide/restore reported project or comment content. A reported author can
  appeal a hide within 14 calendar days without seeing the reporter identity;
  an administrator records an uphold or restore decision within seven calendar
  days of the appeal.
- A join request or invitation cannot create duplicate active membership, grant
  access after revocation, or be accepted by a different account.
- Every comment belongs to exactly one project and author, is visible only to
  that project's approved audience, and cannot create collaboration access.
- A user can contribute at most one like/dislike reaction per visible comment;
  reaction identity remains private from ordinary readers.
- Project team displays disclose only each contributor's display name and
  optional public avatar, and never disclose email, student ID, phone number,
  or private profile fields.
- Public discovery is limited to authenticated student/instructor academy users
  and excludes private and hidden projects. Hiding preserves the owner,
  membership, moderation, and audit history.
- Every new report has a recorded review timestamp within 48 hours, except that
  urgent-threat and personal-data reports trigger the existing immediate safety
  escalation process.
- English and Thai copy for visibility, membership, request, report, and
  moderation states stays structurally aligned.
- The Helping Hand award remains unearnable until a separate accepted policy
  changes ADR-0017 and SPEC-0017.

## Human design review record

| Review point | Required owner | State |
| --- | --- | --- |
| Plan owner, priority, baseline, success target, and opportunity cost | Product Owner | Pending |
| Eligible roles, project-member permission, and academic-integrity policy | Academic Owner | Pending |
| Private default, public visibility, reporting, retention, and audit scope | Privacy and Security Owners | Pending |
| Moderation queue, hide/restore authority, escalation, and response target | Admin Owner | Pending |
| Domain boundary, schema constraints, and migration fitness functions | Tech Lead | Pending |
