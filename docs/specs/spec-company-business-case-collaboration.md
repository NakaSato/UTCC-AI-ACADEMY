---
id: SPEC-0040
type: spec
title: Invitation-only company business-case collaboration and project workspace boundary
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@academic-owner", "@recruitment-domain-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0040, ADR-0024, ADR-0025, ADR-0033, ADR-0038]
implemented_by:
  - app/models/business_case.rb
  - app/models/business_case_invitation.rb
  - app/models/business_case_participant.rb
  - app/models/business_case_milestone.rb
  - app/models/business_case_submission.rb
  - app/models/business_case_comment.rb
  - app/controllers/business_cases_controller.rb
  - app/controllers/business_case_invitations_controller.rb
  - app/controllers/business_case_participants_controller.rb
  - app/controllers/business_case_milestones_controller.rb
  - app/controllers/business_case_submissions_controller.rb
  - app/controllers/business_case_comments_controller.rb
  - db/migrate/20260809100000_create_business_case_collaboration.rb
enforced_by:
  - test/models/business_case_test.rb
  - test/models/business_case_invitation_test.rb
  - test/models/business_case_participant_test.rb
  - test/models/business_case_milestone_test.rb
  - test/models/business_case_submission_test.rb
  - test/models/business_case_comment_test.rb
  - test/controllers/business_cases_controller_test.rb
  - test/controllers/business_case_invitations_controller_test.rb
  - test/controllers/business_case_workspace_test.rb
  - test/operations/business_case_boundary_test.rb
  - test/system/business_case_walk_test.rb
touches:
  - app/models
  - app/services
  - app/controllers
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test
  - docs/runbooks
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004]
---

# Invitation-Only Company Business-Case Collaboration and Project Workspace

> **Review state:** Accepted by the user on 2026-08-09 as the governing design
> gate. On the same date the user recorded the Phase 1 review-handoff decisions
> below and authorized the invitation-only, text-only collaboration slice:
> cases, invitations, participants, lifecycle, milestones, submissions,
> comments, and audit events. File and source-code uploads, email delivery,
> administrator support and reporting surfaces, recruitment conversion, and
> REST APIs remain unauthorized until their own review decisions are recorded.

> [Executable Specifications](README.md) ·
> [Company business-case ADR](../decisions/adr-0040-company-business-case-collaboration-boundary.md) ·
> [Company Business Case Platform Roadmap](../roadmap.md#company-business-case-platform-roadmap)

## Problem

Companies need a secure way to bring authentic business challenges into an
industry–university collaboration, while students and faculty need a bounded
workspace for requirements, milestones, deliverables, feedback, and learning.
The repository currently has organization membership and recruitment data, but
not a case-level collaboration domain. The first step is to define the data,
authorization, privacy, academic, and IP contract before building the workflow.

## Scope

### Included

- Organization-owned business cases with draft, published, and closed states.
- Case-level participant and reviewer authorization.
- Invite-only access for selected authenticated students with acceptance,
  decline, expiry, and replay protection.
- Faculty assignment and bounded mentoring access.
- Structured milestones, submissions, comments/feedback, and completion
  evidence as separate business-case records.
- Private attachment/source-code asset boundary with an approved storage,
  scanning, retention, export, and deletion contract required before upload.
- Audit events for case, invitation, participant, milestone, submission,
  feedback, asset, and access-control changes.
- English/Thai product copy and an administrative/reporting boundary subject to
  privacy review.

### Excluded

- Public case discovery, open enrollment, or anonymous access.
- Company self-registration or a second authentication system.
- Email delivery until provider, consent, template, and failure policy are
  approved; an in-app invitation record is the source of truth.
- Source-code repository integration, arbitrary executable files, or unscanned
  uploads.
- Automatic AI requirement generation, solution recommendation, grading,
  ranking, hiring decisions, or candidate matching.
- Academic course grades, credits, learner progress, or recruitment application
  stage changes.
- Payments, revenue plans, employment contracts, recruitment conversion, or IP
  transfer by implication.
- REST APIs or external integrations in the first collaboration slice.

## Domain model boundary

The proposed aggregate is:

```text
Organization
└── BusinessCase
    ├── Invitations → ParticipantAssignments
    ├── Milestones → Submissions
    ├── Comments / Feedback
    ├── Private Asset References
    └── Audit Events
```

`Organization` and `User` remain the identity and membership authorities.
`BusinessCase` owns case content and lifecycle. `Invitation` grants no access
until an authenticated student accepts it. `ParticipantAssignment` records the
case-specific role and active state. `Milestone`, `Submission`, `Comment`, and
`AssetReference` must all carry an unambiguous case scope and cannot be reused
as recruitment application, course submission, or general academic records.

## Role and access contract

| Actor | Case access | Write access | Explicit boundary |
| --- | --- | --- | --- |
| Company owner/reviewer | Cases in the organization allowed by case role | Create/manage cases, invite students, review work according to approved matrix | Organization membership alone must not expose restricted case assets if the case matrix says otherwise |
| Invited student | Accepted invitations only | Accept/decline invitation, submit own work, ask questions, view permitted feedback | Cannot discover or access another case or student submission |
| Faculty mentor | Explicitly assigned cases only | Mentor feedback and progress support according to academic policy | Instructor role alone grants no case access |
| Administrator | Support/reporting scope only | Configuration or documented support actions | Every content access requires reason, least privilege, and audit evidence |
| Unauthenticated or non-participant | None | None | Safe not-found response; no case existence, title, or attachment disclosure |

The final role matrix is human-owned. The table is a proposed minimum boundary,
not approval to grant access.

## Invariants

1. Every business case belongs to exactly one organization and has one owner;
   it cannot silently move across organizations.
2. A case has only the approved lifecycle states, and a closed case cannot
   accept new invitations, submissions, or ordinary edits.
3. A case is not publicly discoverable; every read requires an authorized case
   scope, and unauthorized identifiers disclose no case existence.
4. An invitation belongs to one case and one target student, has a single-use
   expiry-bound acceptance state, and cannot be replayed or accepted by another
   user.
5. A student receives case access only after authenticated acceptance and only
   while the participant assignment is active.
6. Faculty access requires an explicit active assignment; global instructor
   status alone never grants access.
7. Every milestone, submission, comment, feedback record, and asset reference
   belongs to exactly one case and cannot cross organization boundaries.
8. A student can create or replace only their own permitted submission version;
   company review cannot rewrite the student's original evidence.
9. Private asset access rechecks authorization at fetch time, uses expiring
   access, and never exposes a public storage URL.
10. Case collaboration cannot mutate recruitment application stages, candidate
    profile ownership, course progress, grades, or awards.
11. Consequential case, access, milestone, submission, feedback, asset, and
    support actions create privacy-safe audit evidence without storing raw
    secrets or unnecessary content.
12. Retention, deletion, export, confidentiality, and intellectual-property
    terms are known before the platform accepts company data or student source
    code.

## Acceptance Criteria

The design-gate criteria below are satisfied by the Phase 1 implementation and
its enforcing tests.

- [x] ADR-0040 records the organization/case boundary, alternatives, trust
      boundaries, consequences, fitness functions, and human decisions.
- [x] The model and access contract separates company organization membership,
      case participants, faculty assignments, and administrator support access
      (`test/controllers/business_cases_controller_test.rb`).
- [x] Invite-only behavior includes authenticated target matching, single-use
      acceptance, expiry, decline, replay rejection, and safe unauthorized
      responses (`test/models/business_case_invitation_test.rb`,
      `test/controllers/business_case_invitations_controller_test.rb`).
- [x] The case workflow defines draft, published, and closed behavior for
      invitations, edits, milestones, submissions, and completion
      (`test/models/business_case_test.rb`,
      `test/controllers/business_case_workspace_test.rb`).
- [x] Milestones, submissions, feedback, and asset references are explicitly
      separate from recruitment applications and academic course submissions
      (`test/models/business_case_submission_test.rb`).
- [x] The asset boundary states private storage, authorization-checked access,
      scanning, size/type limits, retention, export, deletion, and ownership
      decisions required before uploads; Phase 1 accepts no uploads
      (`test/operations/business_case_boundary_test.rb`).
- [x] The human review handoff records confidentiality, consent, IP, academic,
      role, notification, support, and data-governance decisions
      (see the recorded decisions below).
- [x] `bin/docs` validates this specification's metadata, links, and skill
      references.

### Implementation evidence

| Contract | Evidence |
| --- | --- |
| Case and organization isolation | `test/models/business_case_test.rb`, `test/controllers/business_cases_controller_test.rb` |
| Invitation security | `test/models/business_case_invitation_test.rb`, `test/controllers/business_case_invitations_controller_test.rb` |
| Role matrix | `test/controllers/business_cases_controller_test.rb`, `test/models/business_case_participant_test.rb` |
| Lifecycle transitions | `test/models/business_case_test.rb`, `test/models/business_case_milestone_test.rb`, `test/controllers/business_case_workspace_test.rb` |
| Submission ownership | `test/models/business_case_submission_test.rb` |
| Private assets | Phase 1 accepts no assets; `test/operations/business_case_boundary_test.rb` proves the absence of any upload, attachment, mailer, or API surface |
| Audit and privacy | Audit assertions across the model and controller tests; cross-domain non-mutation in `test/controllers/business_cases_controller_test.rb` |
| Browser workflow | `test/system/business_case_walk_test.rb` |

## Error and boundary cases

- An invitation link is expired, replayed, declined, or opened by a different
  authenticated student: show a safe outcome and create no assignment.
- A company member loses membership during an open case: new reads and writes
  fail closed; existing evidence remains auditable.
- A faculty assignment is removed: the mentor loses access without deleting
  feedback or student submissions.
- A case is closed while a submission is in progress: preserve the draft or
  reject the write according to the approved closure policy; never partially
  mutate it.
- A file fails type, size, malware, secret, or policy scanning: do not expose it
  to participants and record only the approved safe failure evidence.
- A duplicate milestone or submission request is retried: idempotency or a
  concurrency-safe conflict preserves one valid record and the original audit.
- A participant requests export or deletion while company retention applies:
  route to the approved policy owner rather than silently deleting or exporting
  confidential content.
- A company attempts to use a case as an employment or recruitment decision
  channel: keep recruitment stage and candidate data unchanged and surface the
  policy boundary.

## Human review handoff

The Product Owner, Tech Lead, Security Owner, Privacy Owner, Academic Owner,
Recruitment Domain Owner, and QA Owner must record:

1. Confidentiality, acceptable-use, data classification, legal basis, consent,
   residency, retention, deletion, export, and incident-notification policy.
2. Intellectual-property, licensing, attribution, source-code ownership,
   portfolio use, student compensation, and recruitment-conversion terms.
3. Company reviewer, student, faculty, and administrator role matrix,
   assignment authority, support access, conflict-of-interest, and dispute
   handling rules.
4. Invitation channel, email provider, token support, notification frequency,
   expiry, bounce/failure, and consent behavior.
5. File and source-code formats, scanning, secret detection, repository policy,
   size limits, versioning, quarantine, and post-project access.
6. Milestone acceptance, feedback versus grading, academic-credit treatment,
   completion, cancellation, and closure behavior.

### Recorded decisions (2026-08-09, Phase 1)

The user, acting as the accountable owners, recorded these decisions for the
Phase 1 slice. Each later phase must reopen the corresponding decision before
widening the boundary.

1. **Data governance:** the platform accepts text-only case content. Company
   confidential files, source code, and real customer/employee personal data
   are prohibited; the case and invitation screens state this notice. Records
   are append-only; deletion and export requests are routed to the policy
   owner rather than executed in-app.
2. **Intellectual property:** students retain ownership of their own
   submissions. Portfolio use of case material requires company consent.
   Case participation creates no compensation, employment, or
   recruitment-conversion terms.
3. **Role matrix:** active organization owners create, edit, publish, and
   close cases, manage milestones, invite students, assign and revoke
   mentors, and read all case content. Other organization roles have no case
   access. Students gain access only through an accepted invitation and only
   while their participant assignment is active. Mentors must hold the
   instructor account role and an explicit owner-made assignment.
   Administrators have no case-content access in Phase 1; reason-gated
   support access requires a future review. All other requests fail closed
   with a safe not-found response.
4. **Invitation channel:** in-app notification records only, with a 7-day
   expiry, single-use digest-stored tokens, and no email delivery while
   ADR-0004 defers the production email provider.
5. **Files:** no upload surface exists in Phase 1;
   `test/operations/business_case_boundary_test.rb` enforces the absence.
6. **Academic treatment:** company and mentor feedback is mentoring evidence,
   not grading; case work carries no academic credit and cannot change course
   progress, grades, or recruitment application stages.

## Rollback and observability

Phase 1 adds the `business_case_*` tables through a reversible migration and no
external dependency. To disable the capability, remove the business-case routes
(every controller path becomes unreachable while models, data, and audit
evidence remain intact); participant access is revoked per case through the
existing revocation action. There are no assets to quarantine in Phase 1.
Submissions are append-only versions, so a partial write leaves prior evidence
untouched. Dropping the tables is a data-destroying rollback and requires the
release owner's explicit approval.

Future operations must measure privacy-safe counts and latency for case creation,
invitation acceptance/expiry, authorization failures, milestone transitions,
submission failures, asset quarantine, feedback, support access, export/delete
requests, and closure. Metrics must avoid company-confidential text, student
identifiers, source code, attachment content, and invitation tokens.

## Verification

```bash
bin/rails test test/models/business_case_test.rb \
  test/models/business_case_invitation_test.rb \
  test/models/business_case_participant_test.rb \
  test/models/business_case_milestone_test.rb \
  test/models/business_case_submission_test.rb \
  test/models/business_case_comment_test.rb \
  test/controllers/business_cases_controller_test.rb \
  test/controllers/business_case_invitations_controller_test.rb \
  test/controllers/business_case_workspace_test.rb \
  test/operations/business_case_boundary_test.rb
bin/rails test:system TEST=test/system/business_case_walk_test.rb
bin/docs
git diff --check
```
