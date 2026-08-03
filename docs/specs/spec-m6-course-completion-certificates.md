---
id: SPEC-0011
type: spec
title: Course-completion certificate policy and artifact
status: draft
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-09
supersedes: []
superseded_by: []
depends_on: [ADR-0011, SPEC-0003]
implemented_by: []
touches:
  - app/models/learner_progress.rb
  - app/models/course.rb
  - app/views/my_learning/show.html.erb
  - config/routes.rb
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Course-completion certificate policy and artifact

> **Review state:** Draft and blocked on academic/institutional policy. This
> specification does not authorize certificate issuance merely because a course
> row has `certificate: true`.

> [Executable Specifications](README.md) ·
> [M6 certificate architecture decision](../decisions/adr-0011-course-completion-certificates.md) ·
> [Roadmap Milestone 6](../roadmap.md#milestone-6--institutional-access-and-documents) ·
> [M6 syllabus PDF](spec-m6-course-syllabus-pdf.md)

## Problem

The academy can count completed certificate-marked courses, but it has no
approved rule or artifact for issuing a certificate. Showing a downloadable
document without an issuer, identity, evidence, and revocation policy could
misrepresent learner progress as an institutional credential.

## Scope after policy approval

### Included

- Define and enforce the approved completion-evidence rule.
- Show certificate state only for courses whose policy permits it.
- Generate the approved localized artifact, if issuance is approved.
- Preserve a stable certificate identity and the approved verification or
  authenticated-view boundary.
- Support correction, revocation, replacement, and audit behavior required by
  the accepted policy.

### Excluded

- Inferring eligibility from the catalog certificate flag alone.
- Claiming university accreditation or external recognition without an issuer
  decision.
- Including student identifiers, grades, attendance, or personal data not
  explicitly approved for the artifact.
- Public verification, cryptographic signing, or QR codes unless selected in
  ADR-0011.
- Changing course completion or progress semantics without a separate spec.

## Invariants

1. A non-certificate course can never issue a certificate artifact.
2. An artifact is issued only when all approved completion evidence is present.
3. The identity and course data on an artifact come from approved authoritative
   records, not request parameters or browser-submitted values.
4. A revoked, corrected, or replaced artifact cannot continue to present as
   valid under the approved verification policy.
5. Certificate issuance is idempotent for the same learner, course, and approved
   completion event.
6. Certificate views and verification endpoints disclose only the approved
   minimum data and never expose raw progress or private learner records.
7. A policy-deferred course shows truthful completion state without implying a
   certificate was issued.

## Acceptance Criteria

- [ ] The approved eligibility rule distinguishes complete certificate courses
      from incomplete and non-certificate courses (`test/models/certificate_policy_test.rb`).
- [ ] A certificate artifact is generated only after approved evidence exists
      and is idempotent (`test/models/certificate_test.rb`, `test/controllers/certificates_test.rb`).
- [ ] The artifact uses approved localized identity, course, issue-date, and
      issuer fields (`test/controllers/certificates_test.rb`).
- [ ] Revocation, correction, replacement, and verification follow the accepted
      policy without exposing private learner data (`test/models/certificate_test.rb`,
      `test/controllers/certificates_test.rb`).
- [ ] A course without certificate authority cannot expose a download or
      verification claim (`test/controllers/certificates_test.rb`).
- [ ] A browser walkthrough demonstrates the approved completed-course and
      deferred/non-eligible states (`test/system/certificate_walk_test.rb`).

## Boundary cases and unresolved policy

- A course marked for certificates but lacking an approved issuer must remain
  policy-deferred.
- A learner completion after a curriculum revision must use the approved
  versioning rule rather than silently changing a previously issued artifact.
- Name changes, duplicate identities, account deletion, and support corrections
  require explicit retention and replacement behavior.
- A verification lookup for an unknown, revoked, or private identifier must not
  reveal whether a different certificate exists.

## Human Academic Review Handoff

Implementation is held until the Product Owner and Academic Owner decide what
the credential means and the Tech Lead records a safe technical boundary. The
agent can expose options and testable controls, but cannot declare academic
authority or decide what employers and students may rely on.

| Review point | Evidence | Decision required |
| --- | --- | --- |
| Meaning of the catalog `certificate` flag | [ADR-0011 context](../decisions/adr-0011-course-completion-certificates.md#context) | Choose official credential, completion record, or informational metadata. |
| Completion evidence and curriculum version | [Certificate invariants](#invariants) | Define the exact evidence and how curriculum revisions affect eligibility. |
| Issuer, identity, and displayed fields | [ADR-0011 decision boundary](../decisions/adr-0011-course-completion-certificates.md#decision-boundary) | Name issuer authority and approve identity, date, course, and disclosure fields. |
| Verification, revocation, correction, and replacement | [ADR-0011 alternatives](../decisions/adr-0011-course-completion-certificates.md#alternatives) | Choose authenticated-only, public verification, or defer issuance. |
| Signing, privacy, retention, and operations | [ADR-0011 human decisions](../decisions/adr-0011-course-completion-certificates.md#human-decisions-required) | Name key, privacy, retention, support, and incident owners. |

Until these choices are recorded, the application must keep the existing
completion count truthful and must not expose a certificate download or
verification claim.

## Rollback and observability

- Keep certificate links hidden or policy-deferred until issuer and artifact
  rules are accepted; rollback must not delete historical issuance records.
- Audit issuance, revocation, correction, replacement, and verification outcomes
  without logging unnecessary learner identifiers or document contents.
- Monitor artifact-generation failures and verification availability before any
  public release.

## Verification

```bash
bin/docs
bin/rails test test/models/certificate_policy_test.rb test/models/certificate_test.rb
bin/rails test test/controllers/certificates_test.rb
bin/rails test:system test/system/certificate_walk_test.rb
bin/verify
```
