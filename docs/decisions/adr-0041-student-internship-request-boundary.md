---
id: ADR-0041
type: adr
title: Define a student-initiated internship request, placement, and progress boundary
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@academic-owner", "@recruitment-domain-owner", "@qa-owner"]
created: 2026-08-09
updated: 2026-08-12
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0028, ADR-0033, ADR-0036, ADR-0040]
implemented_by:
  - SPEC-0041
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
enforced_by:
  - test/operations/internship_request_boundary_test.rb
  - test/models/internship_faculty_assignment_test.rb
  - test/controllers/internship_faculty_assignments_controller_test.rb
agent_writable: true
requires_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-SPEC-001, SKILL-SPEC-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-003, SKILL-SPEC-002]
---

# Define a Student-Initiated Internship Request, Placement, and Progress Boundary

> **Decision state:** Accepted by the user on 2026-08-09 as the governing
> boundary. Decision 1 was answered **yes** — a student may direct a request at
> a company that has published no position — so the request layer is built. The
> recorded decisions below authorize increment 1 only: student-initiated,
> strictly position-less requests and a recorded company decision. Placements,
> progress reports, faculty oversight, document uploads, interviews, rubric
> evaluation, email, REST APIs, and any academic-credit field remain
> unauthorized and each needs its own recorded decision.
>
> **Increment 2 recorded 2026-08-09:** placements and weekly progress reports
> are authorized, with a placement originating from either an approved request
> or an accepted `Recruitment::InternshipApplication` as a read-only reference.
> Faculty oversight, documents, interviews, rubric evaluation, email, REST APIs,
> and academic credit remain unauthorized.
>
> **Increment 4 recorded 2026-08-12:** decision 5 is answered, so documents
> exist. A request shares the résumé already on the candidate profile rather
> than storing a second copy, a placement carries the student's deliverables,
> and both close when the thing they belong to closes. Interviews, rubric
> evaluation, email, REST APIs, and academic credit remain unauthorized.
>
> **Increment 3 recorded 2026-08-12:** decisions 2 and 7 are answered. Faculty
> oversight is an administrator-granted assignment of one staff account to one
> placement, carrying the authority to read that placement and acknowledge its
> weeks and nothing else. Documents, interviews, rubric evaluation, email, REST
> APIs, and academic credit remain unauthorized.

> [Decision Records](README.md) ·
> [Student internship request specification](../specs/spec-student-internship-requests.md) ·
> [Existing internship management](../specs/spec-recruitment-internship-management.md) ·
> [Student Internship Request Platform roadmap](../roadmap.md#milestone-m11--student-internship-request-platform) ·
> [Project Development Flow](../development-flow.md)

## Context

The M11 roadmap track proposes a Student Internship Request Platform. Before
designing it, the existing internship capability has to be stated accurately,
because the roadmap's own baseline is wrong on two counts.

The roadmap says "No internship-request, internship-position, assignment,
weekly-report, or evaluation workflow exists in the current application."
Positions and evaluations do exist. ADR-0028 and SPEC-0028 ship
`Recruitment::InternshipProgram` (a company-owned position with capacity, a
mentor, a draft/review/published/paused/closed/archived lifecycle, and
publication gated on completeness), `Recruitment::InternshipApplication` (a
student-created application with pending/accepted/rejected/withdrawn status,
one per student per program, capacity-checked acceptance), and
`Recruitment::InternshipEvaluation` (one structured evaluation per accepted
application, written by the assigned mentor or an authorized reviewer).
SPEC-0036 adds advisory, provider-neutral preparation guidance for the student.

This matters because the roadmap's recommended first vertical slice —
"Complete student profile → select partner position → submit request → company
review → auditable approve/reject decision" — is, with the exception of the
profile-completeness gate, **already implemented**. Building it again as a
second internship domain would produce two overlapping request models, two
capacity rules, and two places where a student's internship outcome lives.

What genuinely does not exist is narrower and clearer:

1. A request a student can initiate toward a company that has **published no
   position** — the "company-directed request" the roadmap contrasts with a
   vacancy-first portal.
2. A **placement** record: the approved, in-progress internship itself, with a
   planned/active/completed lifecycle distinct from the request decision. Today
   an `accepted` application is the terminal company-side state, so an approved
   request and a finished internship are indistinguishable.
3. **Progress reporting**: periodic activity, hours, outcomes, blockers, and
   supervisor acknowledgement. Nothing in the repository records these.
4. A **faculty actor** in the internship path. The internship domain authorizes
   entirely through company `OrganizationMembership` roles; the `instructor`
   account role grants no internship authority, and `users.faculty` is only a
   free-text profile string.

## Problem frame

- **Affected users:** Students seeking an internship the catalogue does not
  cover, company supervisors hosting them, faculty accountable for academic
  eligibility and oversight, and the operators responsible for student
  document privacy.
- **Current behavior:** A student may apply only to an already-published
  program, and only one application per program. There is no way to approach a
  company without a position, no record of the internship after acceptance, no
  progress log, and no academic participation.
- **Failure risk:** A duplicate internship domain that contradicts SPEC-0028; a
  student's résumé or portfolio exposed to a company that never hosted them; an
  approved request silently read as a completed internship; a progress report
  or evaluation treated as an academic grade without an academic decision.
- **Design outcome:** One internship domain in which company positions and
  applications stay where they are, and a new bounded context owns
  student-initiated requests, placements, and progress — with academic
  consequences remaining human decisions.

## Decision

1. **Do not re-implement position publication or program applications.**
   `Recruitment::InternshipProgram`, `Recruitment::InternshipApplication`, and
   `Recruitment::InternshipEvaluation` remain the single authority for
   company-published positions, applications against them, and the existing
   end-of-internship evaluation. M11 adds no second position model and no
   second application model.

2. **A request is a distinct record only where it does something an application
   cannot: address a company with no published position.** Decision 1 was
   answered yes, so the request layer exists — and it is strictly position-less.
   A request holds no program reference at all, which is what keeps it from
   becoming a second application model. Had the answer been no, this layer would
   have been withdrawn and M11 reduced to placements, progress reporting, and
   faculty oversight over the existing application.

3. **A placement is separate from the decision that produced it.** Approval
   creates a placement in a `planned` state; a placement moves to `active` and
   then `completed` only through explicit, authorized action. No approval, and
   no report, ever marks an internship complete by implication.

4. **Requests and placements are private to their participants.** A student
   reads only their own; a company reads only those addressed to it; a faculty
   reviewer reads only those they are assigned to. Organization membership alone
   is not access, and an unauthorized identifier discloses nothing — the same
   fail-closed rule ADR-0040 established for business cases.

5. **Faculty authority is an explicit assignment, never an account role.** As
   with business-case mentors, holding `instructor` grants nothing; an
   assignment record scoped to the request or placement does. Which account
   role may hold such an assignment is decision 2 below.

6. **No student documents are accepted until the document contract exists.**
   Résumés, portfolios, and deliverables are the roadmap's most sensitive
   payload and the platform has no upload surface for them. Private storage,
   authorization-rechecked expiring access, type and size limits, scanning,
   retention, export, deletion, and consent must all be recorded first. Until
   then requests carry structured text only. (Decision 5 was answered on
   2026-08-12; see the increment 4 record below for what documents exist and
   under whose contract.)

7. **Progress reports are evidence, not assessment.** A report records what the
   student did and what a supervisor acknowledged. It produces no score, no
   ranking, no completion, and no academic record.

8. **Nothing here touches academic records.** SPEC-0028 already excludes
   academic credit and its invariants forbid any action that alters academic
   records; this record inherits that. Whether an evaluation, a report, or a
   completed placement carries credit or hours is an institutional decision
   recorded outside the platform before any such field exists.

9. **Interviews, email, notifications beyond the existing in-app bell, REST
   APIs, and AI matching or evaluation assistance are out of the first slice.**
   Email stays deferred under ADR-0004.

10. **The new context gets its own namespace.** Every shipped internship model,
    table, controller, route, and locale key is prefixed `recruitment_` /
    `Recruitment::` / `recruitment.internships`, and the `/internships` path is
    taken by program browsing. The new records therefore live in their own
    top-level namespace with their own table prefix and route scope, so no
    reader has to guess which internship domain a name belongs to.

## Proposed bounded context

| Context | Owns | Must not own |
| --- | --- | --- |
| Recruitment internship management (SPEC-0028) | Company positions, capacity, applications against a position, the existing per-application evaluation | Student-initiated requests without a position, placements, progress reports, faculty authority |
| Student internship requests (this record) | Student-initiated requests, company-directed requests, request decisions, placements, progress reports, faculty assignment and academic review | Position publication, program applications, candidate profiles, course grades, credit |
| Organization identity (ADR-0024) | Users, organizations, memberships, company roles | Request-specific or placement-specific access grants |
| Academic platform | Courses, enrolments, progress, grades | Internship request content, company data, placement evidence |
| Platform administration | Support access, configuration, audit evidence | Unbounded reading of student documents or company request content |

## Trust boundaries and minimum controls

| Boundary | Valuable assets | Minimum control | Failure behavior |
| --- | --- | --- | --- |
| Student → company request | Résumé, portfolio, learning goals, personal data | Explicit student submission with recorded consent scope | No company read before submission; withdrawal stops further access |
| Company → request queue | Other students' requests, competitor-visible data | Membership plus request-scoped authorization | Safe not-found; no cross-company request disclosure |
| Faculty → request/placement | Student academic standing, company data | Explicit assignment plus academic-owner policy | No access from `instructor` alone |
| Request → placement | Approval authority, internship reality | Separate authorized transition, never implied by approval | An approved request is not an internship |
| Placement → progress report | Hours, activity, supervisor feedback | Author is the placed student; acknowledgement is the supervisor | Report is evidence only; no score, no completion, no credit |
| Any record → academic outcome | Credit, hours, transcript | Human institutional decision outside the platform | No field exists to hold it in the first slice |
| Documents → storage | Résumés, portfolios, deliverables | Deferred entirely until the document contract is recorded | No upload surface exists; enforced by test |

## Alternatives

### Extend `Recruitment::InternshipApplication` with the new states

The roadmap proposes Draft, Submitted, Under Review, Interview, Approved,
Rejected, and Completed against the shipped `pending/accepted/rejected/
withdrawn`. Adding them here would make one record mean both "I am asking" and
"I am interning", and `Completed` on an application is exactly the conflation
the roadmap itself warns against. Rejected — but note that if decision 1
returns "no", extending the application with a *draft* state and adding
placements alongside it becomes the cheapest correct design.

### Build the roadmap's recommended first slice as written

Rejected as largely redundant: position selection, request submission, company
review, and an audited approve/reject decision are SPEC-0028's shipped
application flow. Only the profile-completeness gate and the company-directed
request are new.

### Give faculty access through the `instructor` account role

Rejected for the same reason ADR-0040 rejected it for mentors: a role held for
teaching a course is not consent to read a specific student's internship
documents and a company's request content.

### Accept résumés and portfolios in the first slice

Rejected. These are the highest-sensitivity records in the track and would
commit the platform to a storage, scanning, retention, and consent contract
that does not exist. Structured text first.

### Create a separate faculty or company identity store

Rejected, consistent with ADR-0040 decision 1 and SPEC-0024: one `User`
identity, with authority expressed as memberships and assignments.

## Consequences

- One internship domain gains a second bounded context, so every future
  internship change starts by asking which context owns it. The alternative —
  two overlapping request models — is worse.
- The answer to decision 1 can shrink this record substantially. That is
  intended: the boundary is written so a "no" removes a layer rather than
  invalidating the design.
- A placement lifecycle separate from the request decision means more records
  than a single status column, and in exchange an approved request can never be
  mistaken for a finished internship.
- Faculty oversight becomes an explicit, auditable assignment rather than an
  implicit consequence of teaching.
- Because documents are deferred, the first slice cannot satisfy the roadmap's
  résumé and portfolio requirements. Those wait for their own contract.
- Academic credit stays outside the platform, so the institution keeps the
  authority the roadmap says it must keep.

## Fitness Functions

- `bin/docs` validates this record's lifecycle metadata, skill references, and
  links.
- No internship-request, placement, or progress-report route, model, or table
  ships before the human decisions below are recorded; a design-gate test
  enforces this.
- No business-case-style upload surface exists for student documents: no
  attachment route and no Active Storage attachment on any record in this
  context, enforced by test.
- A request, placement, progress report, and faculty assignment always resolves
  to exactly one student and one company, and a non-participant receives a safe
  not-found.
- No request decision, placement transition, or progress report writes to
  course progress, grades, certificates, or a recruitment application stage.
- An approved request never sets a placement to `completed`, and no report
  transition marks an internship complete.
- Consequential actions produce privacy-safe audit evidence carrying no
  document content, personal identifiers beyond the acting user, or free-text
  student data.

## Recorded decisions (2026-08-09, increment 1)

The user, acting as the accountable owners, answered the blocking decision and
the four that shape increment 1. Everything else in the list below stays open.

1. **Company-directed requests are authorized (decision 1: yes).** A student may
   direct a request at a company that has published no position.
2. **A request is strictly position-less.** It carries no reference to a
   `Recruitment::InternshipProgram` and no association to one exists. A student
   who wants a published position uses the shipped application path in
   SPEC-0028. This resolves the "it cannot be both" question in decision 2 of
   the domain-model section: there is exactly one path per situation, so no
   second application model appears.
3. **A company opts in before it can be targeted.** An organization is a valid
   target only once an accountable member switches on acceptance of internship
   requests. A company never receives an unsolicited request through a channel
   it did not agree to.
4. **One open request per student per organization, and re-approach is
   allowed.** A student may hold open requests at several companies at once, and
   after a decision or withdrawal may approach the same company again. This is
   deliberately looser than the shipped one-application-per-program unique
   index, which blocks re-application permanently.
5. **Faculty oversight is deferred (decision 2 deferred).** Increment 1 has no
   faculty actor, because academic-eligibility and visibility policy does not
   exist in writing. The `instructor` role continues to grant nothing here.
6. **Placements and progress reports were deferred to increment 2 and are now
   recorded (2026-08-09).** In increment 1, approval recorded a decision and
   nothing more. Increment 2 adds the placement and the weekly progress report,
   with these decisions:
   - **A placement has exactly one origin, and it may be either an approved
     `InternshipRequest` or an accepted `Recruitment::InternshipApplication`.**
     Both are real internships, so both are tracked by one concept rather than
     leaving the shipped application path untracked. The origin is a read-only
     reference: a placement never mutates an application, its status, or its
     evaluation, and SPEC-0028 keeps ownership of that record. A database check
     constraint enforces exactly one origin.
   - **Lifecycle is planned, active, completed, and cancelled.** Creating a
     placement from an approved origin yields `planned`; only an authorized
     company decider advances it. `cancelled` exists because an internship that
     ends early otherwise has to sit in `active` forever or be falsely marked
     `completed`, and this record's whole point is that a state must not claim
     more than happened.
   - **Reports are weekly and record activities, hours, outcomes, and
     blockers.** One report per placement per week, append-only once submitted,
     authored only by the placed student while the placement is active. Hours
     are evidence for a supervisor, never converted to credit or a grade.
   - **A report is acknowledged by an active company decider**, which records
     who acknowledged and when and never rewrites the student's text.
   - **Visibility is the placed student plus the organization's active deciders**
     — the same roles that decide requests. Faculty and administrators remain
     outside until decisions 2 and 7 are recorded.
7. **Documents stay excluded (decision 5 unchanged).** No résumé, portfolio, or
   deliverable upload surface exists. Requests carry structured text, and the
   interface says so. **Amended by increment 4:** a request shares the résumé
   that already exists on the candidate profile, and a placement carries the
   student's deliverables. No file is uploaded to a request.
8. **No academic credit (decision 8: none).** No field in this context holds
   credit or hours, inheriting SPEC-0028's exclusion.
9. **In-app notification only (decision 10).** The existing bell notifies
   deciders on submission and the student on a decision. Email stays deferred
   under ADR-0004.
10. **Append-only retention.** Requests and decisions are preserved as evidence;
    export and deletion requests route to the policy owner rather than being
    executed in-app.

## Recorded decisions (2026-08-12, increment 3)

The user, acting as the accountable owners, answered decisions 2 and 7. The
platform's stated purpose is to connect the student, the company, **and the
university**, and until now the third party was absent from a path the
university is accountable for.

1. **Faculty authority is an assignment, granted by an administrator, on one
   placement.** It is not the `instructor` role — the alternative above rejected
   that, and the reason still holds: teaching a course is not consent to read a
   named student's internship. It is not a second identity store either. It is
   an `InternshipFacultyAssignment` naming one `User`, exactly as company reach
   is an `OrganizationMembership`, and it is granted and revoked in one place by
   one accountable person, with an audit row for each.
2. **Any staff account may be assigned; which one is the administrator's
   judgement.** The platform enforces only that a learner is never a supervisor.
   Which member of faculty supervises which internship is an academic matter the
   platform has no rule for and should not invent one.
3. **One active supervisor per placement.** A revoked assignment is kept as
   evidence of who could read what and when, so the uniqueness is on the active
   assignment rather than on the placement.
4. **The authority is read and acknowledge, and carries no gate.** A supervisor
   does not approve a request, activate a placement, complete or cancel one, and
   records no score. This is deliberate: a gate would mean an absent supervisor
   could strand a student mid-internship, and the company keeps the lifecycle it
   already owns. Decision 8 is unchanged — nothing here records credit.
5. **The acknowledgement is the supervisor's own record.** It sits in its own
   columns beside the company's, because two people confirming they read the
   same week are two different facts and neither may overwrite the other. It
   rewrites no word of the student's report, which stays append-only.
6. **Visibility is the assigned placement and its reports, and nothing else
   (decision 7).** The assignment is the consent, so the assignment is also the
   boundary: a supervisor reads the internships they were given and no others,
   and revocation closes that reading immediately. Whether faculty ever read a
   *request* — the student's motivation, the company's decision reason — is
   **not** answered here and stays out.
7. **The student is told.** Assigning a supervisor notifies the student through
   the existing bell: somebody new can read their internship, and they learn it
   from the platform rather than by inference.
8. **An administrator opens the placement to assign, and reads no week of it.**
   The assignment happens on the placement screen, so an administrator has to
   reach it — but the administrator row of the access contract says support
   scope and no unbounded browsing of student content, and a weekly report is
   student content. So `administrable_by?` is deliberately not `visible_to?`:
   it opens the record and its supervisor control, and the report rows are not
   even loaded. An administrator who genuinely needs to read the weeks assigns
   themselves, which is audited at warn level and notifies the student — a
   documented, visible path rather than a silent one. It follows that an
   administrator is also given a list of every placement: they host none and
   supervise none, so the screen that grants supervision would otherwise be
   one they could open and never find.

## Recorded decisions (2026-08-12, increment 4)

The user answered decision 5. The finding that shaped every part of it: the
platform was never document-free. `CandidateProfile` has accepted a résumé and
portfolio files since SPEC-0029, under an allowlist, a ten-megabyte ceiling,
candidate-owned export, and a delete that removes attachments before the row.
So this is not a document contract written from nothing; it is what internship
records may attach, and what that existing contract did not yet cover.

1. **A request shares a résumé; it never stores one.** `resume_shared_at` is a
   timestamp, not a blob. A second copy would mean two retention clocks and two
   deletions for the one document the platform is least entitled to duplicate,
   and it would break the promise that removing a résumé from a profile removes
   it everywhere. Sharing is per request, made and unmade by the student.
2. **A deliverable is a new record**, because the work a student produces during
   a placement has no home anywhere in the repository. It carries an author, a
   title, one attachment, and an audit row naming the file and never its
   contents.
3. **The safety envelope is the one SPEC-0029 already enforces** — the portfolio
   allowlist plus plain text, and the same ten-megabyte ceiling. Nothing in this
   application is virus-scanned and this decision does not pretend otherwise,
   which is why the second half matters more: a file one person uploaded is
   never rendered for another person's browser. Every download is served by an
   application route, as an attachment, with the content type re-identified by
   Active Storage rather than trusted from the uploader, under `nosniff`.
4. **Downloads do not use signed blob URLs.** A signed URL authorizes the link
   rather than the reader, and it keeps working after a placement ends and after
   a membership is revoked — exactly what this decision's access rule says must
   stop. Authorization is re-derived on every request.
5. **Access follows the record and ends with it.** The company reads a shared
   résumé while the request is open and while the internship it produced is
   running, and never after a rejection or a completion; it reads deliverables
   while the placement is open. The student reads and deletes their own, always.
6. **The faculty supervisor was offered a reader's seat and did not take one.**
   Decision 7 grants them the placement and its weekly reports. A student's
   files are a different thing, and extending the assignment to them was
   considered and declined.
7. **The student deletes; nothing expires on a timer.** They own their work, as
   SPEC-0040 already says of business-case submissions. No background job
   removes anything, so nothing disappears without a person acting, and no
   retention duration is claimed that nobody is accountable for.

## Human decisions still required

The agent can draft models and controls but cannot decide these. Decisions 1, 2,
and 7 have been answered, as have 2, 5, and 7; the rest remain open and gate their own
increments.

1. ~~Whether a student may direct a request at a company with no published
   position.~~ **Answered yes on 2026-08-09; the request layer is built.**
2. ~~Which account role represents faculty for internship purposes, whether
   `instructor` is that role, who may assign a faculty reviewer, and what
   academic eligibility and approval authority they hold.~~ **Answered on
   2026-08-12: an administrator-granted assignment of one staff account to one
   placement, carrying no approval authority.** Academic *eligibility* — whether
   faculty gate a request before a company sees it — was considered and
   deliberately not taken; it stays part of decision 4.
3. Student eligibility, whether a student may hold more than one active
   request, and how withdrawal, duplicate requests, expiry, and rejection
   behave — including whether a rejected student may re-approach the same
   company, which the shipped one-application-per-program index forbids today.
4. Company verification: which organizations may receive requests, and whether
   faculty or administrator approval precedes that.
5. ~~The document contract for résumés, portfolios, and deliverables —
   formats, scanning, size limits, private storage, retention, export,
   deletion, post-internship access, and consent — before any upload
   exists.~~ **Answered on 2026-08-12: the SPEC-0029 envelope, a shared résumé
   rather than a copied one, deliverables owned and deleted by the student,
   and access that ends with the record.** Virus scanning remains absent here
   and everywhere else in the application; if that is unacceptable it is its
   own decision, and it would apply to the candidate profile first.
6. Report cadence, required fields, whether hours are recorded, who
   acknowledges a report, and what happens when reports are missed.
7. ~~Visibility: which reports, deliverables, evaluations, and scores each of
   student, company supervisor, faculty, and administrator may read.~~
   **Answered for faculty on 2026-08-12: the assigned placement and its reports,
   and nothing else.** Deliverables and scores do not exist to be read, and
   whether faculty read the *request* behind a placement stays open.
8. Whether any internship result affects academic credit or hours, and if so
   the institutional record that holds it — this platform holds none until
   decided.
9. Whether interviews are scheduled and persisted in the platform, and whether
   evaluation gains the roadmap's seven rubric dimensions by extending
   SPEC-0028's evaluation or by a placement-scoped record.
10. Notification policy and the production email owner, if reminders are in
    scope; email remains deferred under ADR-0004.
11. Retention, export, and deletion for requests, placements, reports, and
    audit evidence, and the cross-track data-model decision for student, skill,
    company, and outcome data shared with the recruitment platform.
