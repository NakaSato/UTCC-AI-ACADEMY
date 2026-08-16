---
id: ADR-0011
type: adr
title: Define course-completion certificate policy
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-02
updated: 2026-08-08
review_by: 2026-10-31
supersedes: []
superseded_by: []
depends_on: [SPEC-0003]
implemented_by: []
touches:
  - app/models/learner_progress.rb
  - app/models/course.rb
  - app/views/my_learning/show.html.erb
  - config/routes.rb
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define course-completion certificate policy

> **Decision state:** Accepted by the user on 2026-08-08 as a deferral. M6 will
> not generate, issue, download, verify, or revoke certificate artifacts. The
> existing completion counter remains truthful progress telemetry, not proof of
> an institutional credential.

> [Decision Records](README.md) ·
> [M6 certificate specification](../specs/spec-m6-course-completion-certificates.md) ·
> [Roadmap Milestone 6](../roadmap.md#milestone-6--institutional-access-and-documents) ·
> [M4 curriculum boundary](../specs/spec-m4-course-specific-curricula.md)

## Context

Courses have a `certificate` catalog flag and `LearnerProgress` already counts
fully completed certificate courses, but the application does not generate,
store, issue, revoke, or verify a certificate. A gold “Certificate” label is a
catalog attribute, not proof that an academic credential has been awarded.

Generating a document that looks official could create an institutional claim
without an academic owner, identity assurance, completion policy, or revocation
path. The next decision must separate course completion telemetry from a
credential that employers or universities may rely on.

## Decision boundary

1. Completion eligibility remains derived from the selected course's current
   curriculum and recorded assessment evidence.
2. Certificate issuance, identity shown on the document, issuer authority,
   revocation, and external verification are explicit policy boundaries.
3. No certificate is generated from the catalog flag alone.
4. A certificate artifact must not expose learner data beyond the approved
   identity, course, issue date, and verification fields.
5. If the policy is not approved, the interface may show course completion but
   must not present it as a downloadable or verifiable certificate.

The user approved the deferral alternative on 2026-08-08. A future certificate
policy requires a new accepted decision covering academic meaning, issuer,
evidence, identity disclosure, verification, revocation, privacy, retention,
and operational ownership before any artifact work resumes.

## Alternatives

### Completion letter without verification

Generates a learner-facing PDF with course and completion details. It is simpler,
but can be mistaken for an official credential and offers no revocation or
third-party trust mechanism.

### Signed/verifiable certificate

Generates a document with a stable verification identifier and a public or
authenticated verification response. It supports trust and revocation, but
requires issuer authority, identity proof, privacy policy, key custody,
verification availability, and a lifecycle for corrections and withdrawal.

### Selected for M6 — do not generate a certificate

Keeps the current completion count honest and avoids an institutional claim until
academic policy exists. It delays the learner-facing document but is the safest
default when ownership is unresolved.

## Human decisions required

- Whether the `certificate` flag means an official credential, a completion
  record, or only catalog marketing metadata.
- Required completion evidence: all topics, all graded activities, projects,
  instructor review, attendance, or another rule.
- Identity and name source printed on the document, including corrections.
- Issuer authority, academic approver, issue date, and time-zone convention.
- Downloadability, public verification, revocation, expiry, replacement, and
  correction behavior.
- Signing key owner, rotation, compromise response, and verification uptime.
- Privacy, retention, data-residency, accessibility, and filename policy.

## Consequences

- `LearnerProgress#certificates_earned` cannot be treated as proof of issuance
  without the accepted policy and artifact state.
- A signed certificate creates a long-lived institutional record and should not
  depend only on mutable current curriculum rows.
- Public verification can reveal course completion and personal identity; its
  minimum disclosure must be reviewed before implementation.
- Deferring issuance preserves truthful UI and leaves the existing progress
  counter available for discovery and policy discussion.

## Fitness Functions

- `bin/docs` validates the decision record and its human-review metadata.
- The accepted M6 deferral keeps completion counts truthful and exposes no
  certificate download or verification claim.
- Future tests must prove certificate eligibility, identity disclosure,
  revocation/correction behavior, and that non-certificate courses cannot issue
  an artifact.
- A system walkthrough must show the approved completed-course state and the
  approved certificate/deferral behavior in Thai and English.
