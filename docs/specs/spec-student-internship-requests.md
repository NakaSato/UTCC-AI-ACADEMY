---
id: SPEC-0041
type: spec
title: Student-initiated internship requests, placements, and progress reporting
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@academic-owner", "@recruitment-domain-owner", "@qa-owner"]
created: 2026-08-09
updated: 2026-08-09
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0041, ADR-0024, ADR-0028, ADR-0040, SPEC-0024, SPEC-0028]
implemented_by:
  - app/models/internship_request.rb
  - app/controllers/internship_requests_controller.rb
  - app/controllers/internship_request_decisions_controller.rb
  - app/controllers/organization_internship_settings_controller.rb
  - db/migrate/20260809160000_create_internship_requests.rb
enforced_by:
  - test/models/internship_request_test.rb
  - test/controllers/internship_requests_controller_test.rb
  - test/controllers/internship_request_decisions_controller_test.rb
  - test/operations/internship_request_boundary_test.rb
  - test/system/internship_request_walk_test.rb
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

> **Review state:** Accepted by the user on 2026-08-09. ADR-0041 decision 1 was
> answered yes, so increment 1 is authorized and implemented: student-initiated,
> strictly position-less internship requests to companies that have opted in,
> and a recorded company decision. Placements, progress reports, faculty
> oversight, document uploads, interviews, rubric evaluation, email, REST APIs,
> and any academic-credit field remain unauthorized and are enforced absent by
> `test/operations/internship_request_boundary_test.rb`.

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

### Included in increment 1 (implemented)

- A student-initiated internship request addressed to an organization, carrying
  a motivation statement and learning goals as structured text.
- Strictly position-less requests: a request holds no reference to a
  `Recruitment::InternshipProgram`, which is what keeps it from becoming a
  second application model.
- An organization opt-in switch; a company is targetable only after an
  accountable member turns acceptance on.
- A request lifecycle of draft, submitted, under review, approved, rejected, and
  withdrawn, with guarded transitions and a rejection reason.
- One open request per student per organization, with re-approach allowed after
  a decision or withdrawal.
- In-app notification to the company's deciders on submission and to the student
  on a decision.
- Privacy-safe audit events for submission, review, decisions, withdrawal, and
  the opt-in switch.
- Bilingual English/Thai copy.

### Deferred to later increments (unauthorized, enforced absent)

- A placement record and its planned/active/completed lifecycle. Approval in
  increment 1 records a decision and nothing more; an approved request is
  explicitly not an internship, and not a finished one.
- Periodic progress reports, hours, and supervisor acknowledgement.
- A faculty assignment and academic review record; the `instructor` role
  continues to grant nothing in this context.

### Excluded

- Position publication, program browsing, program applications, capacity rules,
  and the per-application evaluation — SPEC-0028 owns all of these and this
  specification adds no second model for any of them.
- Résumé, portfolio, deliverable, and any other file or document upload, until
  ADR-0041 decision 5 records the document contract. Requests carry structured
  text only, and the interface states this.
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

- [x] ADR-0041 records the boundary against SPEC-0028, the trust boundaries,
      alternatives, consequences, fitness functions, and human decisions.
- [x] The specification states which capabilities remain owned by SPEC-0028 and
      adds no second position, application, or capacity model
      (`test/operations/internship_request_boundary_test.rb`).
- [x] ADR-0041 decision 1 is answered — yes — so the request layer is built and
      is strictly position-less (`test/models/internship_request_test.rb`).
- [x] The request lifecycle defines draft, submitted, under-review, decided, and
      withdrawn behavior, including the duplicate and re-approach rules
      (`test/models/internship_request_test.rb`).
- [x] A company is targetable only after opting in
      (`test/controllers/internship_requests_controller_test.rb`).
- [x] Approval records a decision only; no placement exists and no record
      implies a started or finished internship
      (`test/operations/internship_request_boundary_test.rb`).
- [ ] The placement lifecycle defines planned, active, and completed behavior
      and proves an approved request is not a completed internship — increment 2.
- [ ] Progress reporting defines cadence, required fields, append-only
      behavior, acknowledgement authority, and missed-report handling —
      increment 2.
- [ ] Faculty assignment, academic review authority, and visibility per role are
      recorded by the academic and privacy owners — deferred.
- [ ] The document contract for résumés, portfolios, and deliverables is
      recorded before any upload route is designed — deferred.
- [x] The audit and privacy contract covers redaction and cross-domain
      non-mutation for increment 1; retention is append-only with export and
      deletion routed to the policy owner
      (`test/controllers/internship_request_decisions_controller_test.rb`).
- [x] `bin/docs` validates this specification's metadata, links, and skill
      references.

### Implementation evidence

| Contract | Evidence |
| --- | --- |
| Domain separation | `test/operations/internship_request_boundary_test.rb` — no second position or application model, no program association on a request, and the shipped internship domain intact |
| Request scope and isolation | `test/controllers/internship_requests_controller_test.rb`, `test/controllers/internship_request_decisions_controller_test.rb` |
| Request lifecycle | `test/models/internship_request_test.rb` |
| Opt-in targeting | `test/controllers/internship_requests_controller_test.rb` |
| Academic and cross-domain non-mutation | `test/controllers/internship_request_decisions_controller_test.rb` |
| Deferred-increment absence | `test/operations/internship_request_boundary_test.rb` — no placement, progress-report, faculty, upload, mailer, API, or credit surface |
| Audit and privacy | Audit assertions across the model and controller tests |
| Browser workflow | `test/system/internship_request_walk_test.rb` |
| Placement lifecycle · progress reporting · faculty authority · document contract | Increment 2 and beyond; not yet authorized |

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

ADR-0041 carries the recorded decisions. Decision 1 was answered yes on
2026-08-09, authorizing increment 1; decisions 2 through 11 remain open and each
gates its own increment. The decisions that shape what shipped are: requests are
strictly position-less, a company must opt in before it can be targeted, a
student may hold one open request per organization and may re-approach after a
decision, faculty oversight is deferred, and placements and progress reports are
deferred so approval records a decision and nothing more.

## Rollback and observability

Increment 1 adds the `internship_requests` table and one organization column
through a reversible migration, with no external dependency. To stop the
capability without losing evidence, switch off acceptance on each organization —
no company becomes targetable and existing requests stay readable and auditable.
Removing the routes makes every path unreachable while records remain. Dropping
the table destroys evidence and needs the release owner's explicit approval.
Later increments must extend this plan to cover freezing placements and
reconciling partial reports.

Future operations must measure privacy-safe counts and latency for request
submissions, decisions, placement transitions, report submissions and misses,
acknowledgements, authorization failures, faculty actions, and export or
deletion requests. Metrics must exclude student free text, document content,
company-confidential data, and any personal identifier beyond an internal id.

## Verification

```bash
bin/rails test test/models/internship_request_test.rb \
  test/controllers/internship_requests_controller_test.rb \
  test/controllers/internship_request_decisions_controller_test.rb \
  test/operations/internship_request_boundary_test.rb
bin/rails test:system TEST=test/system/internship_request_walk_test.rb
bin/docs
git diff --check
```
