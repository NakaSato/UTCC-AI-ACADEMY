---
id: SPEC-0041
type: spec
title: Student-initiated internship requests, placements, and progress reporting
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@academic-owner", "@recruitment-domain-owner", "@qa-owner"]
created: 2026-08-09
updated: 2026-08-16
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0041, ADR-0024, ADR-0028, ADR-0040, SPEC-0024, SPEC-0028]
implemented_by:
  - app/models/internship_request.rb
  - app/models/internship_placement.rb
  - app/models/internship_progress_report.rb
  - app/controllers/internship_requests_controller.rb
  - app/controllers/internship_request_decisions_controller.rb
  - app/controllers/organization_internship_settings_controller.rb
  - app/controllers/internship_placements_controller.rb
  - app/controllers/internship_progress_reports_controller.rb
  - app/models/internship_faculty_assignment.rb
  - app/models/internship_deliverable.rb
  - app/controllers/internship_faculty_assignments_controller.rb
  - app/controllers/internship_deliverables_controller.rb
  - app/controllers/internship_request_resumes_controller.rb
  - app/helpers/application_helper.rb
  - db/migrate/20260809160000_create_internship_requests.rb
  - db/migrate/20260809180000_create_internship_placements.rb
  - db/migrate/20260812210000_create_internship_faculty_assignments.rb
  - db/migrate/20260812220000_create_internship_deliverables.rb
enforced_by:
  - test/models/internship_request_test.rb
  - test/models/internship_placement_test.rb
  - test/models/internship_progress_report_test.rb
  - test/controllers/internship_placements_controller_test.rb
  - test/controllers/internship_requests_controller_test.rb
  - test/controllers/internship_request_decisions_controller_test.rb
  - test/operations/internship_request_boundary_test.rb
  - test/system/internship_request_walk_test.rb
  - test/system/internship_placement_walk_test.rb
  - test/controllers/student_internship_door_test.rb
  - test/models/internship_faculty_assignment_test.rb
  - test/controllers/internship_faculty_assignments_controller_test.rb
  - test/models/internship_document_test.rb
  - test/controllers/internship_documents_controller_test.rb
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
> `test/operations/internship_request_boundary_test.rb`. Increment 2 was
> recorded and implemented the same day: placements with a planned, active,
> completed, and cancelled lifecycle, originating from either an approved
> request or an accepted `Recruitment::InternshipApplication`, plus weekly
> progress reports with supervisor acknowledgement.
>
> **Increment 3 recorded and implemented 2026-08-12:** ADR-0041 decisions 2 and
> 7 are answered, so the university is finally in the path it is accountable
> for. An administrator assigns one staff account to one placement; that
> assignment lets them read the placement and acknowledge its weeks, and grants
> nothing else. Documents, an academic gate, rubric evaluation, email, REST
> APIs, and academic credit remain unauthorized.
>
> **Increment 4 recorded and implemented 2026-08-12:** decision 5 is answered.
> A request shares the résumé already on the candidate profile instead of
> storing a second one, a placement carries the student's deliverables, and a
> file one person uploaded is never rendered for another person's browser.
> Interviews, rubric evaluation, email, REST APIs, and academic credit remain
> unauthorized.

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

### Included in increment 2 (implemented)

- A placement record with a planned, active, completed, and cancelled lifecycle
  that only an authorized company decider advances. Creating one never happens
  by implication.
- Exactly one origin per placement, either an approved `InternshipRequest` or an
  accepted `Recruitment::InternshipApplication`, enforced by a database check
  constraint. The origin is read-only: a placement never mutates an
  application, its status, or its evaluation.
- Weekly progress reports authored by the placed student while the placement is
  active, recording activities, hours, outcomes, and blockers. One report per
  placement per week, append-only once submitted.
- Acknowledgement by an active company decider, recording who and when without
  rewriting the student's text.
- Privacy-safe audit events for placement creation, each transition, report
  submission, and acknowledgement.

### Included in increment 3 (implemented)

- An `InternshipFacultyAssignment` naming one staff account as the university's
  supervisor of one placement. An administrator grants it and an administrator
  revokes it; both are audited at warn level, as a privilege change is.
- One active assignment per placement, enforced by a partial unique index. A
  revoked assignment is kept as evidence of who could read what and when.
- The supervisor reads that placement and its weekly reports, and nothing else.
  Revocation closes the reading immediately, re-derived per request.
- Acknowledgement of a week by the supervisor, in its own pair of columns beside
  the company's, rewriting no part of the student's report.
- An in-app notification to the student when a supervisor is assigned.
- A supervising section on the placement index and an Internships entry in the
  instructor navigation, so an assigned staff member has a door.
- An administrator has a list of every placement and which of them lack a
  supervisor, and an Internships entry in the admin navigation. They host and
  supervise none, so without it the screen that grants supervision had no door
  for the only role that may use it.
- An administrator may open a placement to assign its supervisor, and reads
  no weekly report there: the rows are not loaded and the screen says so.
  Reading the weeks means assigning yourself, which is audited and notifies
  the student.

### Included in increment 4 (implemented)

- A shared résumé: `internship_requests.resume_shared_at` records that a student
  chose to let one company read the résumé already on their `CandidateProfile`.
  No second copy is stored, so deleting it at the profile removes it from every
  request that pointed at it.
- Sharing and unsharing are the student's, on an open request, audited both ways.
- An `InternshipDeliverable`: the work a student hands over during a placement,
  with an author, a title, one attachment, and an audit row naming the file and
  never its contents.
- The SPEC-0029 safety envelope, reused rather than reinvented: the portfolio
  content-type allowlist plus plain text, and the same ten-megabyte ceiling.
- Every download served by an application route as an attachment, never inline,
  never through a signed blob URL, with authorization re-derived per request.
- Access that ends with its record: a company reads a shared résumé while the
  request is open and while the internship it produced runs; it reads
  deliverables while the placement is open; the student reads and deletes their
  own for as long as they exist.

### Deferred to later increments (unauthorized, enforced absent)

- Any faculty gate: approval of a request before the company sees it, of a
  placement transition, or of completion. ADR-0041 decision 4 keeps academic
  eligibility open, and the lifecycle stays the company's.
- Faculty reading of the *request* behind a placement — its motivation text and
  the company's decision reason.
- An academic review record, a score, a rubric, or any assessment output.
- Rubric evaluation dimensions, interviews, email, REST APIs, and any field
  holding academic credit or converting hours to credit.
- Virus scanning, in this context and in every other: no upload anywhere in
  the application is scanned, which is why nothing uploaded is ever rendered
  inline. Adding a scanner is its own decision and would start with the
  candidate profile.
- A retention clock. Nothing expires on a timer; a student deletes their own
  work, and no duration is claimed that nobody is accountable for.

### Excluded

- Position publication, program browsing, program applications, capacity rules,
  and the per-application evaluation — SPEC-0028 owns all of these and this
  specification adds no second model for any of them.
- Résumé, portfolio, deliverable, and any other file or document upload, until
  ADR-0041 decision 5 records the document contract. Requests carry structured
  text only, and the interface states this. **Superseded by increment 4:** a
  request now carries a shared reference to the résumé on the student's
  candidate profile, and a placement carries deliverables. Nothing is
  uploaded to a request itself.
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
| Faculty supervisor | Only placements they are assigned to, and those placements weekly reports | Acknowledge a week, on their own record | The `instructor` account role alone grants nothing; the assignment is granted by an administrator, carries no gate, and does not reach the request behind the placement |
| Administrator | A placement record, to assign or revoke its supervisor. Not its weekly reports | Assign and revoke a faculty supervisor | Every content access needs least privilege and audit evidence; no unbounded browsing of student documents. Reading the weeks means self-assigning, which is audited at warn level and notifies the student |
| Unauthenticated or non-participant | None | None | Safe not-found; no disclosure of a request's existence, its company, or its student |

The final matrix is human-owned; this table is the proposed minimum, not
approval to grant access. Which membership roles count as company supervisor is
ADR-0041 decision 4. The faculty row was decision 2 and was answered on
2026-08-12 — it now describes what ships.

## Invariants

1. A request belongs to exactly one student and exactly one organization and
   cannot be reassigned to a different student or company.
2. A request is visible only to its student, authorized members of its target
   organization, an assigned faculty reviewer, and audited support access.
3. A request has only the approved lifecycle states; a withdrawn or decided
   request accepts no further student edits.
4. A company decision is recorded once, by an authorized member, with the
   reason policy requires, and is never silently overwritten.
5. A placement has exactly one origin — an approved request or an accepted
   `Recruitment::InternshipApplication` — with at most one placement per origin,
   and it is created in the `planned` state.
6. A placement reaches `active`, `completed`, or `cancelled` only through
   explicit authorized transitions. Neither approval nor any report advances a
   placement, and a placement never mutates the record it originated from.
7. A progress report belongs to exactly one placement and one week, is authored
   only by that placement's student while the placement is `active`, and is
   append-only once submitted.
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
- [x] The placement lifecycle defines planned, active, completed, and cancelled
      behavior and proves an approved request is not a completed internship
      (`test/models/internship_placement_test.rb`).
- [x] A placement carries exactly one origin and never mutates the shipped
      application it may point at
      (`test/models/internship_placement_test.rb`,
      `test/operations/internship_request_boundary_test.rb`).
- [x] Progress reporting defines weekly cadence, required fields, append-only
      behavior, and acknowledgement authority
      (`test/models/internship_progress_report_test.rb`).
- [x] Faculty assignment and its visibility are recorded by the academic and
      privacy owners (ADR-0041 decisions 2 and 7, 2026-08-12): an administrator
      assigns one staff account to one placement, one active assignment at a
      time, audited on grant and revoke
      (`test/models/internship_faculty_assignment_test.rb`).
- [x] The supervisor reads only the placements they were assigned, and
      revocation closes that reading immediately
      (`test/models/internship_faculty_assignment_test.rb`,
      `test/controllers/internship_faculty_assignments_controller_test.rb`).
- [x] The supervisor acknowledges a week in their own columns, cannot advance,
      complete, or cancel the placement, and rewrites nothing the student wrote
      (`test/models/internship_faculty_assignment_test.rb`,
      `test/operations/internship_request_boundary_test.rb`).
- [ ] Academic review authority — whether faculty gate a request, a transition,
      or completion — is recorded by the academic owner. Deliberately not taken
      on 2026-08-12; see ADR-0041 decision 4.
- [x] A shared résumé stores no second copy, and unsharing or deleting it at the
      profile closes every request that pointed at it
      (`test/models/internship_document_test.rb`).
- [x] A company reads a shared résumé while the request is open and while the
      internship it produced runs, and not after a rejection or a completion
      (`test/models/internship_document_test.rb`).
- [x] A deliverable is authored only by the placed student, only while the
      placement is open, within the SPEC-0029 allowlist and ceiling, and a
      declared content type cannot talk its way past it
      (`test/models/internship_document_test.rb`).
- [x] Every download is an attachment under `nosniff`, served by a route that
      re-derives authorization, and no signed blob URL is handed out
      (`test/controllers/internship_documents_controller_test.rb`,
      `test/operations/internship_request_boundary_test.rb`).
- [x] The faculty supervisor cannot read a deliverable
      (`test/controllers/internship_documents_controller_test.rb`).
- [x] The student removes their own work and the company cannot
      (`test/models/internship_document_test.rb`).
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
| Browser workflow | `test/system/internship_request_walk_test.rb`, `test/system/internship_placement_walk_test.rb` |
| Placement lifecycle | `test/models/internship_placement_test.rb`, `test/controllers/internship_placements_controller_test.rb` |
| Placement origin and non-mutation | `test/models/internship_placement_test.rb` — both origins accepted, exactly one required, and the shipped application untouched |
| Progress reporting | `test/models/internship_progress_report_test.rb` |
| Student navigation and cross-links | `test/controllers/student_internship_door_test.rb` |
| Faculty assignment, its boundary, and its absence of a gate | `test/models/internship_faculty_assignment_test.rb`, `test/controllers/internship_faculty_assignments_controller_test.rb`, `test/operations/internship_request_boundary_test.rb` |
| Documents: sharing, uploads, and every download | `test/models/internship_document_test.rb`, `test/controllers/internship_documents_controller_test.rb`, `test/operations/internship_request_boundary_test.rb` |
| Academic gate · rubric evaluation | Later increments; not yet authorized, absence enforced by `test/operations/internship_request_boundary_test.rb` |

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
bin/rails test test/models/internship_placement_test.rb \
  test/models/internship_progress_report_test.rb \
  test/controllers/internship_placements_controller_test.rb
bin/rails test test/system/internship_request_walk_test.rb test/system/internship_placement_walk_test.rb
bin/rails test test/controllers/student_internship_door_test.rb
bin/rails test test/models/internship_document_test.rb \
  test/controllers/internship_documents_controller_test.rb
bin/rails test test/models/internship_faculty_assignment_test.rb \
  test/controllers/internship_faculty_assignments_controller_test.rb
bin/docs
git diff --check
```

## Amendment, 2026-08-12: the student's door

Increments 1 and 2 shipped the student's screens without a way in. Nothing in
the application linked to `/internship-requests` or to `/internships/placements`,
so a learner reached either only by typing the URL — and the company work
surface added on the same day counts the weekly reports those students are
expected to write. Three changes, no new record and no new decision:

- **The student navigation carries an Internships entry, unconditionally.** It
  points at the request index, because that is where the lifecycle starts. It is
  offered to every learner rather than only to those with a request, since the
  navigation is how a student learns the capability exists at all — the accepted
  answer on 2026-08-12.
- **The request index shows a running internship first**, with the week's report
  marked missing when it is, using `InternshipPlacement#missing_current_week_report?`
  — a predicate the model had computed for two increments with no reader.
- **The two screens point at each other.** The placement index's link back to
  requests is rendered only for the student workspace: `/internship-requests` is
  student-only and a company decider reaches its own queue from its work
  surface (SPEC-0048).

Visibility is unchanged. `open_placements` scopes the new section to the
student's own placements, which ADR-0041 decision 6 already grants them.

## Amendment, 2026-08-16: the door's address and what stands behind it

The door from 2026-08-12 worked and read badly. Two changes, no new record and
no new decision:

- **The address is `/internship`.** The route's helper names are unchanged, so
  every caller still says `internship_requests_path` and no view, test, or
  redirect had to learn a new name — only the wording a student sees in the
  address bar moved, from a screen named after the record it creates to one
  named after the thing they came for. Every `/internship-requests` written
  above this amendment refers to that same screen at its former address.
- **The former address still arrives.** Renaming reaches the application; it
  does not reach the bookmarks and links already made, and the first thing the
  rename produced was a routing error for somebody who had the old one open.
  `/internship-requests` now answers 301 to `/internship` and carries any deeper
  path across with it, so a saved link to a particular request still opens that
  request. The three company decision endpoints keep their own wording: they are
  POST targets reached from the work surface, never an address a person types.
- **Published programs stand beside position-less requests.** The index reads
  `Recruitment::InternshipProgram.published_for_candidates`, newest first, and
  links each one at the recruitment controller that already owns its detail and
  application actions. A student arriving with nobody in mind now sees the open,
  position-backed opportunities in the same place as the request they may make
  without one; an empty list says so rather than showing nothing.

Ownership is unchanged. This screen still creates and lists nothing but the
student's own requests, and SPEC-0028 keeps every program action.
