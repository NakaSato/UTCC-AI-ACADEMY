---
id: SPEC-0041
type: spec
title: Student-initiated internship requests, placements, and progress reporting
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@academic-owner", "@recruitment-domain-owner", "@qa-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0041, ADR-0024, ADR-0028, ADR-0040, SPEC-0024, SPEC-0028]
implemented_by: []
enforced_by:
  - test/operations/internship_request_gate_test.rb
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
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-003]
---

# Student-Initiated Internship Requests, Placements, and Progress Reporting

> **Review state:** Draft for Product Owner, Tech Lead, Security Owner, Privacy
> Owner, Academic Owner, Recruitment Domain Owner, and QA Owner review. This
> specification authorizes no internship-request route, placement record,
> progress report, document upload, faculty workflow, notification, or academic
> decision. Human decision 1 in ADR-0041 decides whether the request layer is
> built at all.

> [Executable Specifications](README.md) ·
> [Student internship request ADR](../decisions/adr-0041-student-internship-request-boundary.md) ·
> [Existing internship management](spec-recruitment-internship-management.md) ·
> [Internship preparation assistance](spec-internship-application-assistance.md) ·
> [Student Internship Request Platform roadmap](../roadmap.md#milestone-m11--student-internship-request-platform)

## Problem

A student can only apply to an internship the catalogue already advertises.
SPEC-0028 ships company-published programs and one student application per
program, and SPEC-0036 adds advisory preparation guidance. Three things are
missing: a student cannot approach a company that has published nothing, the
platform keeps no record of the internship once an application is accepted, and
no faculty member participates in a path the university is accountable for.

The roadmap's stated baseline — that no internship position or evaluation
workflow exists — is inaccurate, and its recommended first slice is nearly all
shipped. This specification therefore defines only the genuine remainder, and
draws the line against SPEC-0028 explicitly so the repository does not grow two
internship request models.

## Scope

### Included

- A student-initiated internship request addressed to an organization, carrying
  a motivation statement and learning goals as structured text.
- Company-directed requests, where the target organization has published no
  position — subject to ADR-0041 human decision 1.
- A request lifecycle with an explicit draft state, submission, withdrawal,
  and a recorded company decision with an optional reason.
- A placement record created by approval, with a planned, active, and completed
  lifecycle that only authorized action advances.
- Periodic progress reports authored by the placed student, recording activity,
  outcomes, and blockers, with supervisor acknowledgement.
- A faculty assignment scoped to a request or placement, and an academic review
  record that is advisory evidence rather than a grade.
- Privacy-safe audit events for requests, decisions, placements, transitions,
  reports, acknowledgements, and faculty actions.
- Bilingual English/Thai copy.

### Excluded

- Position publication, program browsing, program applications, capacity rules,
  and the per-application evaluation — SPEC-0028 owns all of these and this
  specification adds no second model for any of them.
- Résumé, portfolio, deliverable, and any other file or document upload, until
  ADR-0041 decision 5 records the document contract.
- Academic credit, hours-to-credit conversion, grades, transcript entries, and
  any field that implies them.
- Interview scheduling and external calendar or meeting integration.
- Email delivery of any kind, and notification policy beyond the existing in-app
  bell; email remains deferred under ADR-0004.
- AI matching, ranking, screening, resume review, and evaluation assistance.
- REST API endpoints and external integrations.
- Company self-registration, a company or faculty identity store, and any new
  global account role.
- Payments, stipends, insurance, and contractual terms.

## Relationship to the shipped internship domain

| Capability | Owner | Note |
| --- | --- | --- |
| Company internship position with capacity and mentor | `Recruitment::InternshipProgram` (SPEC-0028) | Unchanged |
| Student application to a published position | `Recruitment::InternshipApplication` (SPEC-0028) | Unchanged; one per student per program |
| Advisory preparation guidance | `Recruitment::InternshipApplicationAssistant` (SPEC-0036) | Unchanged; computed, never stored |
| End-of-internship evaluation | `Recruitment::InternshipEvaluation` (SPEC-0028) | Unchanged in this slice; rubric dimensions are ADR-0041 decision 9 |
| Request to a company without a position | This specification | New, and gated on ADR-0041 decision 1 |
| The internship itself, after approval | This specification (placement) | New; today an accepted application is terminal |
| Periodic progress evidence | This specification | New |
| Faculty assignment and academic review | This specification | New; no faculty actor exists in the internship path today |

A request that targets a published position must not duplicate the application
record. Either the request references the existing application as its origin, or
positions are reached only through SPEC-0028 — the accepted design must state
which, and it cannot be both.

## Domain model boundary

```text
Organization                     User (student)
    │                                │
    └──── InternshipRequest ─────────┘
              │  ├── FacultyAssignment → AcademicReview
              │  └── Decision (approve / reject, with reason)
              ↓  (approval only)
          InternshipPlacement   (planned → active → completed)
              └── ProgressReport → SupervisorAcknowledgement
```

`User` and `Organization` remain the identity and membership authorities.
`InternshipRequest` owns the asking; `InternshipPlacement` owns the interning.
Every child record carries an unambiguous request or placement scope and cannot
be reused as a recruitment application, a course submission, or an academic
record.

Naming must not collide with the shipped domain. Every existing internship
model, table, controller, and locale key is prefixed `Recruitment::` /
`recruitment_internship_*` / `recruitment.internships.*`, and the `/internships`
route path is taken by program browsing. The new context uses its own top-level
namespace, its own table prefix, and its own route scope.

## Role and access contract

| Actor | Read | Write | Explicit boundary |
| --- | --- | --- | --- |
| Requesting student | Own requests, own placements, own reports | Draft, submit, withdraw a request; author reports on an active placement | Cannot see another student's request to the same company, nor the company's internal decision notes |
| Company supervisor/reviewer | Requests addressed to their organization; placements hosted by it | Record a decision with a reason; acknowledge reports; advance a placement per approved policy | Organization membership alone is not access to a request; no cross-organization read |
| Faculty reviewer | Only explicitly assigned requests and placements | Record academic review and oversight evidence | The `instructor` account role alone grants nothing |
| Administrator | Support and reporting scope only | Documented support actions | Every content access needs least privilege and audit evidence; no unbounded browsing of student documents |
| Unauthenticated or non-participant | None | None | Safe not-found; no disclosure of a request's existence, its company, or its student |

The final matrix is human-owned; this table is the proposed minimum, not
approval to grant access. Which membership roles count as company supervisor is
ADR-0041 decision 4, and the faculty role is decision 2.

## Invariants

1. A request belongs to exactly one student and exactly one organization and
   cannot be reassigned to a different student or company.
2. A request is visible only to its student, authorized members of its target
   organization, an assigned faculty reviewer, and audited support access.
3. A request has only the approved lifecycle states; a withdrawn or decided
   request accepts no further student edits.
4. A company decision is recorded once, by an authorized member, with the
   reason policy requires, and is never silently overwritten.
5. Approval creates at most one placement per request, in the `planned` state.
6. A placement reaches `active` and `completed` only through explicit
   authorized transitions. Neither approval nor any report marks a placement
   complete.
7. A progress report belongs to exactly one placement, is authored only by that
   placement's student while it is `active`, and is append-only once submitted.
8. A supervisor acknowledgement records who acknowledged and when, and never
   rewrites the student's report.
9. Faculty access requires an explicit active assignment; the `instructor`
   account role alone never grants it.
10. An academic review is advisory evidence. No request, decision, placement,
    report, acknowledgement, or review writes to course progress, grades,
    certificates, awards, or a recruitment application stage.
11. No record in this context holds academic credit or converts hours to
    credit until the institutional decision exists.
12. No document, résumé, portfolio, or deliverable is accepted, stored, or
    served until the document contract is recorded; no attachment or upload
    surface exists in this slice.
13. Consequential actions produce privacy-safe audit evidence with no document
    content, no free-text student data, and no identifiers beyond the acting
    user and the record.
14. Retention, export, deletion, and consent scope are known before the
    platform accepts production student or company data.

## Acceptance Criteria

Design-gate criteria for the current slice. Implementation must add real
enforcing tests and human-approved policy references before this specification
moves beyond draft.

- [ ] ADR-0041 records the boundary against SPEC-0028, the trust boundaries,
      alternatives, consequences, fitness functions, and human decisions.
- [ ] The specification states which capabilities remain owned by SPEC-0028 and
      adds no second position, application, or capacity model.
- [ ] ADR-0041 decision 1 is answered, and if a request must target a published
      position, the request layer is withdrawn and this specification is
      reduced to placements, progress reporting, and faculty oversight.
- [ ] The request lifecycle defines draft, submitted, decided, and withdrawn
      behavior, including duplicate, expiry, and re-approach rules.
- [ ] The placement lifecycle defines planned, active, and completed behavior
      and proves an approved request is not a completed internship.
- [ ] Progress reporting defines cadence, required fields, append-only
      behavior, acknowledgement authority, and missed-report handling.
- [ ] Faculty assignment, academic review authority, and visibility per role are
      recorded by the academic and privacy owners.
- [ ] The document contract for résumés, portfolios, and deliverables is
      recorded before any upload route is designed.
- [ ] The audit and privacy contract covers redaction, retention, export,
      deletion, and cross-domain non-mutation.
- [ ] `bin/docs` validates this specification's metadata, links, and skill
      references.

### Required future implementation evidence

Before implementation is accepted, the spec owner must add real test paths for
each contract:

| Contract | Required evidence |
| --- | --- |
| Domain separation | Tests proving no second position, application, or capacity model, and that a request cannot mutate a `Recruitment::InternshipApplication` |
| Request scope and isolation | Model and request tests for cross-student, cross-organization reads and identifier disclosure |
| Request lifecycle | Tests for draft, submission, withdrawal, single recorded decision, duplicate and expiry rules |
| Placement lifecycle | Tests proving approval yields exactly one `planned` placement and that completion requires an explicit authorized transition |
| Progress reporting | Tests for author scope on an active placement, append-only history, and acknowledgement authority |
| Faculty authority | Tests proving `instructor` alone grants nothing and that revoking an assignment removes access without deleting evidence |
| Academic non-mutation | Tests proving no course progress, grade, certificate, award, or recruitment stage changes |
| Document absence | A boundary test proving no upload route, no Active Storage attachment, and no mailer in this context |
| Audit and privacy | Tests for redaction, retention, export, deletion, and absence of document content in audit rows |
| Browser workflow | QA-owned system walkthrough for request submission, decision, placement activation, and a progress report |

## Error and boundary cases

- A student submits a request to a suspended, unverified, or non-participating
  organization: reject without creating a request and disclose nothing about the
  organization's status beyond the approved message.
- A student submits a second request to the same company while one is active:
  behave per the recorded duplicate policy; never create two competing requests
  silently.
- A request is withdrawn while a company is deciding: the decision fails
  closed and the withdrawal stands; existing evidence remains auditable.
- Two authorized company members decide the same request concurrently: one
  decision persists, the other reports a conflict, and the original audit
  survives.
- An approved request's company membership is revoked mid-placement: new reads
  and writes fail closed while placement evidence remains.
- A faculty assignment is removed: the reviewer loses access without deleting
  their recorded review.
- A placement is completed while a report is in progress: preserve the draft or
  reject the write per the approved closure policy; never partially mutate it.
- A report is submitted after the reporting window closes, or a required report
  is missed: record the truthful state and surface it; do not backdate.
- A student or company requests export or deletion while retention applies:
  route to the approved policy owner rather than silently deleting.
- A company attempts to use a request as an employment offer or a faculty
  reviewer as a grader: keep recruitment stages and academic records unchanged
  and surface the policy boundary.

## Human review handoff

The Product Owner, Tech Lead, Security Owner, Privacy Owner, Academic Owner,
Recruitment Domain Owner, and QA Owner must record the eleven decisions in
ADR-0041. Decision 1 is blocking: until it is answered, the central request
capability cannot be designed, because a request that must target a published
position is the shipped application.

## Rollback and observability

This design slice adds no runtime behavior to roll back. Before implementation,
the release plan must define how to stop new requests, freeze placements
without losing evidence, revoke faculty access, reconcile partial reports, and
return the platform to a no-internship-request state without deleting required
audit records.

Future operations must measure privacy-safe counts and latency for request
submissions, decisions, placement transitions, report submissions and misses,
acknowledgements, authorization failures, faculty actions, and export or
deletion requests. Metrics must exclude student free text, document content,
company-confidential data, and any personal identifier beyond an internal id.

## Verification

```bash
bin/rails test test/operations/internship_request_gate_test.rb
bin/docs
git diff --check
```
