---
id: ADR-0040
type: adr
title: Define an invitation-only company business-case collaboration boundary
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@academic-owner", "@recruitment-domain-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0025, ADR-0026, ADR-0028, ADR-0033, ADR-0038]
implemented_by:
  - SPEC-0040
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
enforced_by: []
agent_writable: true
requires_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-SPEC-001, SKILL-SPEC-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define an Invitation-Only Company Business-Case Collaboration Boundary

> **Decision state:** Accepted by the user on 2026-08-09 as the governing
> collaboration boundary. No company business-case, project, invitation,
> attachment, source-code, milestone, or submission workflow is authorized by
> this record. Product, Security, Privacy, Academic, Recruitment Domain, and QA
> owners must still approve the confidentiality, consent, intellectual-property,
> retention, and participant rules before implementation.

> [Decision Records](README.md) ·
> [Company business-case specification](../specs/spec-company-business-case-collaboration.md) ·
> [Company Business Case Platform Roadmap](../roadmap.md#company-business-case-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Context

The Company Business Case Platform proposal describes an industry–university
ecosystem where a company submits a real challenge, invites selected students,
and collaborates through milestones, deliverables, feedback, and completion.
The current application already has one User identity and organization-scoped
recruitment memberships, but it has no business-case aggregate, project
participant boundary, student invitation flow for cases, milestone model,
submission model, or policy for company-confidential data and student work.

This feature crosses two trust domains. A company may share commercially
sensitive requirements, data, attachments, or source code; students and faculty
may contribute personal data, academic work, and intellectual property. A
public marketplace or organization-wide read permission would expose data
before the university and company agree on purpose, participants, retention,
and ownership.

## Problem frame

- **Affected users:** Company owners and reviewers, invited students, faculty
  mentors, university administrators, and the operators responsible for
  confidentiality and academic safety.
- **Current behavior:** No company business-case records or routes exist; the
  proposal is documentation only.
- **Failure risk:** A leaked invitation exposes a confidential case, an
  organization member reads a case they do not review, a student work product
  is reused without an approved IP policy, an attachment becomes public, or a
  milestone/submission is altered without evidence.
- **Design outcome:** A case-level, invitation-only collaboration boundary that
  reuses the existing User and Organization identity seams while keeping
  company, student, faculty, and administrator permissions explicit.

## Decision

The platform will model each business case as an organization-owned,
case-scoped collaboration aggregate. Access to a case is granted by explicit
company authorization, accepted student invitation, approved faculty
assignment, or administrator support access; it is never inferred from a public
URL or from general student enrollment.

1. Reuse the existing `User`, `Organization`, and active membership boundaries.
   Do not create a second authentication system, global company role, or
   separate company identity store.
2. A business case belongs to exactly one organization and owns its invitations,
   participant assignments, milestones, submissions, comments/feedback,
   attachment references, and audit history. A case cannot be moved between
   organizations after publication without an explicitly approved migration
   policy.
3. Keep business-case access case-scoped. Company owners/reviewers may manage
   cases within their organization according to an approved role matrix;
   invited students may access only cases with an accepted invitation; faculty
   may access only cases to which they are explicitly assigned; administrators
   receive support access through an auditable, least-privilege path.
4. The first access path is invite-only. A published case is not publicly
   searchable, and a non-participant cannot infer its existence, requirements,
   attachments, milestones, submissions, or comments from an identifier.
5. Invitation acceptance binds an authenticated existing student to one case
   invitation. Invitation tokens are single-use, expiring, stored as a
   non-reversible reference or digest, and never grant organization-wide access.
   Email delivery remains disabled until the transactional-email provider,
   consent, template, and delivery-failure policy are approved; the in-app
   invitation record remains the source of truth.
6. Milestones and submissions are separate from recruitment applications and
   academic course submissions. They have explicit case ownership, participant
   authorization, lifecycle transitions, timestamps, and audit events.
7. Attachments and source-code deliverables are private case assets accessed
   through authorization-checked, expiring URLs. The first implementation must
   define file type/size limits, malware handling, retention, deletion, export,
   and ownership terms before accepting company or student uploads.
8. The platform records feedback and progress as collaboration evidence, not as
   an automated hiring decision. AI requirement generation, solution
   recommendation, ranking, evaluation, or recruitment actions are out of
   scope until separate policy, evaluation, and human-review decisions exist.
9. Business-case completion does not transfer intellectual property, create an
   employment relationship, or authorize recruitment use. The case cannot be
   enabled for production until company, university, student, privacy, and IP
   terms are recorded.

## Proposed bounded context

| Context | Owns | Must not own |
| --- | --- | --- |
| Organization identity | Users, organization memberships, company roles | Case-specific student access or deliverable rights |
| Business-case collaboration | Cases, invitations, participants, milestones, submissions, comments, attachments, feedback, case audit | Passwords, global roles, recruitment application stages, course grades |
| Recruitment platform | Jobs, applications, candidate-controlled recruitment records | Business-case source code, case IP terms, academic grades |
| Academic platform | Courses, enrolments, learning progress, faculty role | Company confidential case content unless explicitly assigned |
| Platform administration | Support access, configuration, reports, security evidence | Unbounded reading or changing of case content without an audit reason |

## Trust boundaries and minimum controls

| Boundary | Valuable assets | Minimum control | Failure behavior |
| --- | --- | --- | --- |
| Company organization → case | Confidential requirements, data, attachments | Organization membership plus case-role authorization | Return safe not-found; do not disclose case existence |
| Invitation → student participant | Token, identity, consent, case access | Authenticated student, single-use expiry, explicit accept/decline, audit | Reject replayed/expired/mismatched invitation |
| Faculty → case | Student work, company data, mentoring notes | Explicit case assignment and academic-owner review | No access from instructor role alone |
| Case → file storage | Attachments, source code, personal data | Private storage, authorization-checked signed URL, limits, malware process | Do not expose or persist an unauthorized file |
| Student submission → company reviewer | Portfolio/source code, academic work | Case participant scope, submission versioning, IP/retention notice | Preserve prior evidence; reject unauthorized overwrite |
| Administrator → case | All case data | Least privilege, reason/audit event, support expiry | No silent or unbounded administrative browsing |

## Alternatives

### Create a separate company authentication platform

This would duplicate identity, recovery, sessions, and role controls and would
make student/company collaboration harder to audit. It is rejected.

### Make cases public and let students self-enroll

This could increase participation, but it conflicts with real-company
confidentiality, invitation-only requirements, and controlled access to data and
attachments. It is rejected for the first slice.

### Give every active organization member access to every case

This is simple to implement, but it cannot express confidential case teams,
student participants, or faculty assignments. It is rejected in favor of
case-level authorization.

### Reuse recruitment applications or academic submissions

Both records have different ownership, retention, evaluation, and access
semantics. Reusing them would couple employment decisions or course grades to
company project work. It is rejected.

### Implement email invitations and file uploads first

This produces visible functionality quickly, but it would commit the system to
an unapproved email provider, personal-data delivery, file-security process,
and IP/retention policy. It is deferred until those human decisions exist.

## Consequences

- The first slice has more explicit participant and asset records than a simple
  shared project page, but it prevents organization-wide and public leakage.
- Company, university, and student policy decisions become release gates rather
  than copy or checkbox behavior.
- A case can evolve through milestones without changing recruitment application
  or academic course semantics.
- The platform must operate invitation expiry, private storage, malware
  handling, audit review, retention/deletion, and support access controls.
- Until the human decisions below are accepted, the safe state is no runtime
  business-case capability and no external company data.

## Fitness Functions

- `bin/docs` validates this record's lifecycle metadata, skill references, and
  links.
- A future business-case request cannot read a case through an organization,
  student, faculty, or administrator path without the corresponding scope and
  audit reason.
- A case, invitation, participant, milestone, submission, comment, and
  attachment always resolves to exactly one case and organization.
- A replayed, expired, declined, or mismatched invitation cannot create case
  access or a participant assignment.
- Private assets cannot be fetched through a public URL; signed access is
  short-lived and rechecks authorization.
- A submission or milestone transition is append-audited and cannot mutate
  recruitment application stages or academic course grades.
- Delete/export/retention and IP/ownership evidence exists before production
  data or source code is accepted.

## Human decisions required

The agent can expose options and draft controls but cannot decide these matters:

1. Company, university, student, and faculty legal roles; confidentiality and
   acceptable-use terms; student compensation; and intellectual-property,
   licensing, attribution, and recruitment-use policy.
2. Which company data may enter the platform, whether real customer/employee
   data is prohibited, data residency, PDPA/legal basis, retention, deletion,
   export, and incident-notification obligations.
3. The case-role matrix, faculty assignment authority, administrator support
   access, conflict-of-interest handling, and separation of company reviewers.
4. Invitation delivery channel, provider, token support process, consent,
   expiration, notification frequency, and bounce/failure handling.
5. Attachment and source-code policy: allowed formats, scanning, size limits,
   repository integration, secret detection, malware response, versioning,
   ownership, and post-project access.
6. Milestone/submission acceptance, grading versus feedback semantics,
   completion criteria, dispute handling, and academic-credit treatment.
7. Revenue, premium support, recruitment conversion, reporting, and AI
   features, each with its own product, privacy, and human-review boundary.
