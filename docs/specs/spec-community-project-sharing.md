---
id: SPEC-0056
type: spec
title: Public community project sharing, collaboration, and moderation
status: draft
owners: ["@product-owner", "@academic-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@admin-owner", "@qa-owner"]
created: 2026-08-20
updated: 2026-08-21
review_by: 2026-11-18
supersedes: []
superseded_by: []
depends_on: [ADR-0056, ADR-0017, ADR-0044]
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001]
---

# Public Community Project Sharing, Collaboration, and Moderation

> **Review state:** Draft from ADR-0056. The requester has decided that a
> student or instructor owner publishes directly, the owner decides join
> requests, and administrators alone moderate. This specification is not ready
> for Code until the named human owners resolve the remaining audience,
> collaborator-permission, academic-integrity, privacy/retention, success, and
> moderation-service-level decisions.

> [Executable Specifications](README.md) ·
> [Community Projects ADR](../decisions/adr-0056-community-project-sharing.md) ·
> [Existing community boundary](spec-m8-helping-hand-community.md) ·
> [Project Development Flow](../development-flow.md)

## Problem

Students and instructors have no academy-owned way to share project work,
assemble a team through owner-controlled invitations or join requests, or make
their work discoverable under an administrator-only moderation boundary. The
existing academic-post and company-business-case domains cannot be widened to
do this safely because they carry different approval, audience, and
confidentiality rules.

## Scope

### Included after human review

- A separate project owned by one eligible student or instructor.
- Private-by-default, owner-managed private/public visibility and an
  administrator-controlled hidden moderation state.
- Owner-to-eligible-user, in-app invitations with expiry, revocation, and
  authenticated acceptance.
- A join request from an eligible user to a discoverable public project, with
  owner-only acceptance or rejection.
- Plain-text comments on a project, scoped to the current project audience.
- One like or dislike reaction per eligible user on a visible project comment.
- An administrator list of all projects, including private and hidden projects,
  for approved oversight.
- A report path and administrator-only moderation actions with privacy-safe
  audit records.
- Thai and English copy for project, visibility, invitation, membership, join,
  report, and moderation states.

### Excluded

- Chat, direct messages, replies, ratings, following, search ranking,
  recommendations, or a forum.
- File, image, source-code, or executable uploads; external repository or
  portfolio integration.
- Peer review, grades, certificates, course progress, award credit, or any
  change to the Helping Hand award.
- Production email, push notifications, external APIs, or automatic moderation.
- Company business-case access, recruitment data, academic-post publication,
  and cross-domain membership reuse.

## Proposed domain contract

```text
User
├── CommunityProject (owner)
│   ├── CommunityProjectMembership
│   ├── CommunityProjectInvitation
│   ├── CommunityProjectJoinRequest
│   └── CommunityProjectComment
│       └── CommunityProjectCommentReaction
│   └── CommunityProjectReport / moderation audit
└── administrator oversight of every CommunityProject
```

`User` remains the sole identity and role authority. Community Projects own
their content, audience, membership, invitation, request, comment, reaction,
report, and moderation records. An invitation or request has no access effect
until its server-authorized acceptance transaction creates an active membership.

## Invariants

The following proposed invariants require human Spec Owner and QA acceptance.

1. Every project has exactly one owner who is a current `student` or
   `instructor`; no request parameter can substitute the owner or role. Every
   new project starts private.
2. A project visibility is exactly `private` or `public`; its moderation state
   is exactly `visible` or `hidden`. A hidden project is never in public
   discovery and is unreadable and immutable to every ordinary user, including
   its owner and collaborators, until an administrator restores it.
3. A private project and its content, membership, invitations, requests, and
   reports are readable only by the owner, active collaborators, and an
   authorized administrator. An unauthorized request safely discloses neither
   its existence nor title.
4. A public project is discoverable and readable only by authenticated student
   and instructor academy users. It is not discoverable by an unauthenticated
   visitor or company account, and never grants write access, invitation
   authority, membership visibility, join-request decisions, or moderation
   authority to an ordinary reader.
5. A collaborator's access derives only from an active editor membership. An
   active collaborator may update the project title and description, but cannot
   change ownership, visibility, invitations, join requests, reports, or
   moderation. An invitation, a submitted join request, a revoked membership,
   or an old URL grants no access.
6. An invitation targets one eligible non-owner user, is single-use, expiry
   bound, revocable, and cannot be accepted by another account. At most one
   actionable invitation for a project/user pair exists at a time.
7. A join request belongs to one eligible non-member user and one discoverable
   public project. A user cannot request their own project or hold more than
   one pending request for the same project. Only that project's owner can
   accept or reject it, and acceptance atomically creates or restores one
   active membership.
8. An eligible viewer can report a visible project or comment. An administrator
   alone can read the oversight list, see reporter identity, dismiss a report,
   or hide/restore the reported project or comment. A reported author is
   notified of a hide and can appeal within 14 calendar days, but cannot see
   the reporter identity. An administrator records an uphold or restore
   decision within seven calendar days of the appeal. Every privileged action
   records actor, action, reason, and timestamp without copying project or
   comment text into a notification or telemetry event.
9. A comment belongs to exactly one project and one author. It is plain text,
   length limited, has no attachment/reply capability, and inherits its
   project's current audience. Its author may soft-delete it; it disappears from
   ordinary views while a minimal author/project/timestamp audit record remains
   for administrators. A project owner cannot delete another author's comment,
   and an administrator can hide it only through the approved moderation path.
   A comment never grants membership, editor, owner, invitation, request, or
   moderation authority.
10. A reaction belongs to exactly one visible comment and one eligible user and
    has exactly one value, `like` or `dislike`. A database unique constraint
    prevents more than one reaction per comment/user pair. Selecting the same
    reaction removes it; selecting the opposite reaction replaces it. Reaction
    counts may be shown, but reacting identities are not exposed to ordinary
    readers.
11. A hide/restore action preserves project, owner, membership, invitation,
   request, report, and audit history. The first slice contains no destructive
   project deletion.
12. Community Project records cannot mutate academic posts, business cases,
    course progress, grades, certificates, awards, recruitment applications,
    or candidate profiles.
13. English and Thai labels for the same state, permission, denial, and action
   are structurally aligned.
14. An administrator records review of every new report within 48 hours. A
    report concerning an urgent threat or personal data triggers the existing
    immediate safety escalation process; this community feature does not
    replace that process.
15. An authorized reader can see a visible project's owner and active
    collaborators' display names and optional public avatars. Community
    Projects never disclose their email addresses, student identifiers, phone
    numbers, or private profile fields.
16. A report has exactly one category:
    `safety_or_harassment`, `personal_data_or_privacy`,
    `plagiarism_or_copyright`, `spam`, or `other`. It may carry optional
    length-limited plain-text context and is readable only through the
    administrator oversight path.

## Role and access matrix

| Actor | Read | Create / update | Membership and moderation boundary |
| --- | --- | --- | --- |
| Student or instructor owner | Own visible project, active collaborators, and all discoverable public projects | Create, edit, directly publish/unpublish, invite, decide their project's join requests, comment and react on readable projects | Cannot moderate; cannot decide another project's requests or delete others' comments; cannot read or act on a hidden project |
| Student or instructor collaborator | Visible active projects and all discoverable public projects | Edit active project's title and description; comment and react on readable projects | Cannot change owner, visibility, invitation, request, report, or moderation state; cannot read or act on a hidden project |
| Eligible non-member | Discoverable public projects | Submit one join request where allowed; accept their own invitation; comment and react on a discoverable public project | Cannot read private project content or infer a private project's existence |
| Administrator | All projects, comments, reports, and reporter identities for documented oversight | Review/dismiss project/comment reports; hide/restore reported content; decide appeals; read approved audit context | Cannot silently become an owner or collaborator; every privileged action is audited |
| Unauthenticated visitor or company account | None | None | Cannot discover public projects or obtain collaboration, invitation, request, or moderation authority |

## Acceptance Criteria

Human QA owns the acceptance intent. Once reviewed, the implementation must add
the named test files and connect them under `enforced_by` before this spec can
move to Code.

- [ ] An eligible student or instructor creates a private project with exactly
      one owner; ineligible roles and forged owner/visibility parameters are
      denied (`test/models/community_project_test.rb`,
      `test/controllers/community_projects_controller_test.rb`).
- [ ] The owner can directly publish and return their visible project to private;
      discovery is limited to authenticated student/instructor academy users and
      excludes unauthenticated visitors, company accounts, and hidden projects
      (`test/models/community_project_test.rb`,
      `test/controllers/community_projects_controller_test.rb`).
- [ ] An in-app invitation expires, is revocable and single-use, matches its
      authenticated target, and creates one active membership only after
      acceptance (`test/models/community_project_invitation_test.rb`,
      `test/controllers/community_project_invitations_controller_test.rb`).
- [ ] An eligible user can submit one join request to an eligible public
      project; only its owner accepts or rejects, duplicate/self/hidden/private
      cases are safely denied, and acceptance creates membership atomically
      (`test/models/community_project_join_request_test.rb`,
      `test/controllers/community_project_join_requests_controller_test.rb`).
- [ ] A revoked collaborator immediately loses every project read/write path;
      public visibility does not restore collaboration access
      (`test/models/community_project_membership_test.rb`,
      `test/controllers/community_projects_controller_test.rb`).
- [ ] An eligible user can add a plain-text comment only to a project they may
      read; private, hidden, company, unauthenticated, forged, reply, and
      attachment paths are denied (`test/models/community_project_comment_test.rb`,
      `test/controllers/community_project_comments_controller_test.rb`).
- [ ] A comment author can delete only their own comment; an eligible reader can
      record at most one `like` or `dislike` reaction per visible comment, while
      selecting the same reaction removes it and selecting the opposite one
      replaces it. Forged, duplicate, private, hidden, ineligible, and
      identity-disclosure paths are denied (`test/models/community_project_comment_test.rb`,
      `test/models/community_project_comment_reaction_test.rb`,
      `test/controllers/community_project_comment_reactions_controller_test.rb`).
- [ ] Self-deletion removes a comment from ordinary project views while retaining
      only the approved minimal audit record; an owner cannot delete another
      author's comment (`test/models/community_project_comment_test.rb`,
      `test/controllers/community_project_comments_controller_test.rb`).
- [ ] An eligible viewer can report visible project or comment content. Only an
      administrator can list all projects, see reporter identity, dismiss a
      project or comment report, or hide/restore reported content; a hidden
      author is notified, can appeal within 14 calendar days without seeing
      reporter identity, and receives an uphold/restore decision within seven
      calendar days. Owner and collaborator attempts are denied and each
      administrative action produces privacy-safe audit evidence
      (`test/controllers/admin/community_projects_controller_test.rb`,
      `test/models/community_project_report_test.rb`).
- [ ] New reports receive an administrative review within 48 hours, while
      urgent-threat and personal-data reports trigger the existing immediate
      safety escalation (`test/models/community_project_report_test.rb`,
      `test/jobs/community_project_report_escalation_test.rb`).
- [ ] An eligible viewer can submit a visible project or comment report with one
      approved category and optional plain-text context; forged categories,
      private/hidden/ineligible targets, and ordinary-user report reads are
      denied (`test/models/community_project_report_test.rb`,
      `test/controllers/community_project_reports_controller_test.rb`).
- [ ] An authorized reader sees only owner and active collaborator display names
      and optional public avatars for a visible project; email addresses,
      student identifiers, phone numbers, and private profile fields never
      appear (`test/controllers/community_projects_controller_test.rb`,
      `test/system/community_project_walk_test.rb`).
- [ ] Hidden projects are absent from every ordinary-user path, including owner
      and collaborator paths, without deleting their data; restoration returns
      only the approved visibility
      (`test/models/community_project_test.rb`,
      `test/system/community_project_walk_test.rb`).
- [ ] Thai and English project, visibility, invitation, join, report, and
      moderation copy are structurally aligned
      (`test/models/community_project_locale_test.rb`).
- [ ] A browser walkthrough proves owner create → direct publish → request →
      owner approval → collaboration → report → admin hide/restore
      (`test/system/community_project_walk_test.rb`).

## Error and boundary cases

- A suspended, missing, or ineligible account attempts to create, invite, join,
  accept, or moderate.
- The owner and requester make concurrent accept/revoke, accept/reject, or
  duplicate-request attempts.
- A public project becomes private or hidden while a request or invitation is
  pending; the authoritative state controls the next action.
- A project is hidden while its owner or collaborator has an open page or edit
  form; subsequent read and mutation attempts are denied until an administrator
  restores it.
- A project membership changes while its team display is requested; the result
  reflects only active contributors authorized by the project's current
  visibility and never leaks a private profile field.
- A project changes visibility or is hidden while a comment is being submitted;
  authorization is checked transactionally against the authoritative project
  state and no stale client state publishes a comment into a new audience.
- A comment author deletes a comment that has reactions or an existing report;
  ordinary readers cannot retrieve its deleted text and any retention exception
  is handled only by the approved privacy/moderation policy.
- Two requests attempt to create or change a reaction for the same comment/user
  at once; the database preserves one allowed reaction state.
- An old invitation, request URL, or direct project URL is reused after expiry,
  revocation, rejection, hiding, or role change.
- A report contains personal data, threats, plagiarism concerns, or a bad-faith
  allegation; its visibility, retention, escalation, and reporter protection
  follow the human-approved policy rather than public project rules.
- A report uses an unknown category or excessive context, or targets content
  that is not visible to its author; model constraints and server-side audience
  checks deny it without revealing private content.
- A report is dismissed, content is hidden, or an appeal is decided while the
  related project, comment, or account changes state; the administrator's
  action is authorized against current records and preserves the required audit
  history without disclosing reporter identity.
- An appeal is received after 14 calendar days, or no decision is recorded
  within seven calendar days; the system safely denies an expired appeal and
  produces the approved operational escalation signal for a late decision.
- An administrator account is revoked or loses its console role during a
  moderation action.
- The user switches locale while seeing a visibility, join, or moderation
  message; state does not change and copy remains aligned.

## Human specification handoff

| Decision needed before acceptance | Required owner | Status |
| --- | --- | --- |
| Plan: WiT (`@product-owner`); High priority; no existing community-project/team/comment/moderation workflow; one-semester target of 30 public projects, 15 approved joins, and no report older than 48 hours; defer tags, ranking, attachments, chat, and ownership transfer | WiT (`@product-owner`) | Approved 2026-08-21; `COMM-001` is blocked on this draft's required reviews |
| “Public” audience: authenticated student/instructor academy users only; never unauthenticated visitors or company accounts | Requester; Privacy Owner reviews | Recorded 2026-08-20; privacy review pending |
| Private-by-default | Requester; Product and Academic Owners review | Recorded 2026-08-20; review pending |
| Collaborator edit permission: title and description only; no access-control or moderation action | Requester; Product and Academic Owners review | Recorded 2026-08-20; review pending |
| Interaction type: plain-text project comments and one like/dislike reaction per eligible user; no replies, chat, attachments, or executable content | Requester; Product, Academic, Privacy, and Security Owners review | Recorded 2026-08-20; review pending |
| Comment author soft-deletion only; project owners cannot delete others' comments | Requester; Product, Academic, Privacy, Security, and Admin Owners review | Recorded 2026-08-20; review pending |
| Self-deletion hides a comment from ordinary views while retaining a minimal author/project/timestamp audit record | Requester; Privacy and Admin Owners review | Recorded 2026-08-21; review pending |
| Same reaction removes it; opposite reaction replaces it | Requester; Product, Academic, Privacy, Security, and Admin Owners review | Recorded 2026-08-21; review pending |
| Visible projects show owner/collaborator display names and optional public avatars only; never email, student ID, phone number, or private profile fields | Requester; Privacy and Academic Owners review | Recorded 2026-08-21; review pending |
| Eligible viewers may report visible project/comment content; only administrators see reporter identity | Requester; Privacy, Security, and Admin Owners review | Recorded 2026-08-21; review pending |
| Report categories: safety/harassment, personal data/privacy, plagiarism/copyright, spam, and other; optional plain-text context | Requester; Privacy, Security, and Admin Owners review | Recorded 2026-08-21; review pending |
| Administrators dismiss reports or hide/restore reported content; hidden authors are notified and can appeal without learning reporter identity | Requester; Product, Academic, Privacy, Security, and Admin Owners review | Recorded 2026-08-21; review pending |
| Appeal window: author has 14 calendar days; administrator records uphold or restore within seven calendar days | Requester; Product, Privacy, and Admin Owners review | Recorded 2026-08-21; review pending |
| Retention duration/report-evidence exception | Product, Academic, Privacy, Security, and Admin Owners | Pending |
| Hidden projects are unreadable and immutable for all ordinary users, including owner and collaborators, until administrator restoration | Requester; Admin, Privacy, and Academic Owners review | Recorded 2026-08-21; review pending |
| Hidden-project owner notification/appeal rule | Admin, Privacy, and Academic Owners | Pending |
| New reports are reviewed by an administrator within 48 hours; urgent threats and personal-data reports use the existing immediate safety escalation process | Requester; Admin, Privacy, Security, and On-call Owners review | Recorded 2026-08-21; review pending |
| Retention, escalation evidence, and audit-readable fields | Admin, Privacy, Security, and On-call Owners | Pending |
| Human acceptance tests and independent reviewer assignment | QA Owner | Pending |

## Rollback and observability

- Before public discovery is enabled, the rollback control is to leave every
  project private. After launch, administrators can hide a project and disable
  discovery while preserving records for policy review; no rollback deletes
  learner work or moderation history.
- Measure only approved aggregate signals: projects created, projects directly
  published, join requests submitted/decided, active collaborations, comments
  and reactions created, reports opened/reviewed/resolved, moderation latency,
  and reviews outside the 48-hour target. Do not emit project descriptions,
  comment text, reacting or reporter identity, invitation tokens, or
  private-project identifiers in logs, metrics, or Slack.

## Verification

```bash
bin/docs
# After the human specification review, add and run the focused model,
# controller, authorization, locale, and system tests named above.
bin/verify
```
