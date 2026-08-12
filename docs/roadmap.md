---
---

# Product Roadmap

**Tags:** [#product](tags.md#product) [#roadmap](tags.md#roadmap) [#planning](tags.md#planning)

This roadmap starts from the current successful implementation and orders the
combined work by user impact, risk, learning value, and dependency.

It is a product-level plan, not a fixed delivery contract. Sprint scope may change as the team learns, but each sprint must still produce a working increment. See [process.md](process.md) for the team's two-week sprint process and [feature-inventory.md](feature-inventory.md) for the full feature inventory.

This single file contains one consolidated delivery order across the UTCC
Academy, AI Recruitment Platform, and Industry–University Collaboration
Ecosystem. The detailed track sections remain below as supporting scope,
outcomes, dependencies, and human approval gates. Milestone IDs remain
track-scoped so that `UTCC M10`, `AI M10`, and `Ecosystem M10` cannot be confused.

## Unified Roadmap — Ordered Delivery Plan

**Status:** Proposed consolidated order for Product Owner, Engineering Manager,
Tech Lead, domain owners, Security/Privacy, and Data review.

The order below is a dependency-aware planning recommendation, not an accepted
priority or delivery promise. It combines all milestones currently recorded in
this file. Product Owner and Engineering Manager decisions may reorder items
when evidence, capacity, risk, or learning value changes; the opportunity cost
must be recorded when that happens.

Statuses mirror `backlog.json`: **Complete** items carry recorded owner
approval, **In review** items are defined and awaiting verification, and the
remaining labels are planning states.

### Ordering principles

1. Establish the working platform and access boundary.
2. Create the product-discovery and internal-record foundations early so later
   work is traceable.
3. Prove the academy content seam before scaling curricula and multilingual
   knowledge workflows.
4. Establish company, candidate, and internship boundaries before matching,
   agents, analytics, and enterprise integrations.
5. Keep production hardening continuous across every increment.
6. Keep human approval for product priority, security/privacy, technical
   feasibility, academic policy, and consequential AI decisions.

### Consolidated sequence

| Order | Track ID | Milestone | Outcome | Main dependency | Status |
| ---: | --- | --- | --- | --- | --- |
| 0 | UTCC M0 | Successful Platform Baseline | The end-to-end academy workflow is operational | None | Complete |
| 1 | UTCC M1 | Reliable Account Recovery | Students can recover access in production | UTCC M0 | Now |
| 2 | AI M1 | Foundation | Recruitment users, organizations, profiles, permissions, consent, and audit boundaries exist | UTCC M1, shared identity | Complete |
| 3 | Ecosystem M13 | Public Feature Request and Core Team Development Platform | Public users can submit proposals and receive traceable product decisions | Existing proposal intake, roadmap governance | Proposed |
| 4 | Ecosystem M14 | Core Team Internal Work Dashboard | Core team work is privately managed through Markdown records linked to governed Slack collaboration | Ecosystem M13, repository lifecycle, Slack policy | Proposed |
| 5 | UTCC M2 | First Real Topic | One production-quality bilingual topic proves the content model | UTCC M0, M1 | Complete |
| 6 | UTCC M3 | Complete Foundation Course | Every topic in the first course has unique approved learning content | UTCC M2 | Complete |
| 7 | UTCC M4 | Course-Specific Curricula | Courses can have distinct modules, topics, and requirements | UTCC M3 | Complete |
| 8 | UTCC M5 | Real Knowledge Map | The map reflects curriculum relationships and learner progress | UTCC M4 | Complete |
| 9 | UTCC M10 | Academic Writing | Students and teachers can create, review, and publish academic posts | UTCC M0, content and role decisions | Complete |
| 10 | Ecosystem M12 | Technical Blog Translation Platform | Approved technical knowledge can be reviewed and published in multiple languages | UTCC M10, content model, editorial policy | Proposed |
| 11 | UTCC M6 | Institutional Access and Documents | UTCC SSO and syllabus/document workflows work end to end | UTCC M4, institutional decisions | Later |
| 12 | UTCC M7 | Operational Admin Controls | Administrative metrics, courses, approvals, and feature controls are trustworthy | UTCC M6, admin policy | Complete |
| 13 | UTCC M8 | Community and Pedagogy Decisions | Social and prior-knowledge behaviors have approved academic rules | Teaching-policy decisions | Complete |
| 14 | Ecosystem M10 | Company Business Case Platform | Companies and invited students collaborate on real business challenges | AI M1, company and confidentiality policy | Complete |
| 15 | AI M2 | Job Management | Companies can manage and publish structured jobs and programs | AI M1 | Complete |
| 16 | AI M3 | AI Job Creation | AI helps produce quality job specifications with human approval | AI M2 | Complete |
| 17 | AI M4 | Internship Management | Internship programs, applications, mentorship, and evaluation are supported | AI M1, M2 | Complete |
| 18 | Ecosystem M11 | Student Internship Request Platform | Students can request internships and complete a supported learning cycle | Ecosystem M10, AI M1, institutional internship policy | Complete |
| 19 | AI M5 | Candidate Profile | Candidates have structured, consented, searchable profiles | AI M1 | Complete |
| 20 | AI M6 | AI Resume Analysis | Candidate data, skills, and gaps can be extracted with reviewable AI assistance | AI M5 | Complete |
| 21 | AI M7 | Job Discovery | Candidates can find relevant opportunities | AI M2, M5 | Complete |
| 22 | AI M8 | AI Matching Engine | Candidates and opportunities receive explainable matching recommendations | AI M6, M7 | Complete |
| 23 | AI M9 | Recruitment Workflow | Applications move through interview and offer stages | AI M2, M5 | Complete |
| 24 | AI M10 | AI Recruiter Agent | Recruiters receive governed assistance across screening and coordination | AI M8, M9 | Complete |
| 25 | AI M11 | AI Candidate Agent | Candidates receive governed assistance with search, preparation, and growth | AI M6, M7 | Complete |
| 26 | AI M12 | AI Internship Agent | Students and mentors receive governed matching, progress, and evaluation assistance | AI M4, M6, M8 | Complete |
| 27 | AI M13 | Analytics and Reporting | Recruitment, internship, and AI-effectiveness outcomes are measurable | AI M8, M9 | Complete |
| 28 | AI M14 | Notifications and Communication | Participants receive timely, consented communication and history | AI M9 | Complete |
| 29 | AI M15 | Enterprise and Integration | The platform supports governed enterprise adoption and integrations | AI M1, M9, M13, M14 | Complete |

### Cross-cutting lane

| Track ID | Milestone | Operating rule |
| --- | --- | --- |
| UTCC M9 | Production Hardening | Session control, mail/jobs/WebSockets/database monitoring, backup/restore, deployment safety, accessibility, performance, and application/security monitoring continue across every order above. |

### Unified roadmap gates

Before any proposed milestone enters execution, the accountable human owners
must confirm:

- The problem, affected users, baseline, primary outcome, and guardrails
- Scope, exclusions, dependencies, and opportunity cost
- Required ADRs, specifications, threat models, and data decisions
- The human Product Owner and next lifecycle owner
- Localization, accessibility, privacy, security, and operational constraints
- The appropriate backlog item and traceability links

The unified table changes planning direction only. It does not accept a
milestone, create backlog work, approve a release, or override the detailed
track-level decisions below.

## UTCC Academy Roadmap

## Status

- **Complete** — implemented, tested, and available in the current application
- **Now** — the next working increment
- **Next** — ordered work that follows the current increment
- **Later** — valuable work that still requires a product or institutional decision

## Roadmap summary

| Order | Milestone | Outcome | Status |
| --- | --- | --- | --- |
| 0 | Successful platform baseline | The end-to-end academy workflow is operational | Complete |
| 1 | Reliable account recovery | Students can recover access in production | Now |
| 2 | First real topic | One complete bilingual topic proves the content model | Complete |
| 3 | Complete foundation course | Every topic in the first course has unique learning content | Complete |
| 4 | Course-specific curricula | Courses can have different modules, topics, and requirements | Complete |
| 5 | Real knowledge map | The map reflects actual curriculum and learner progress | Complete |
| 6 | Institutional access and documents | UTCC SSO and syllabus downloads work end to end | Later |
| 7 | Operational admin controls | Placeholder admin screens become real management tools | Complete |
| 8 | Community and pedagogy decisions | Social awards and heart behavior have real rules | Complete |
| 9 | Production hardening | Session control, delivery monitoring, and deployment are strengthened | Continuous |
| 10 | Academic writing | Students and teachers can create, review, and collaboratively publish academic posts | Complete |

## Milestone 0 — Successful platform baseline

**Status: Complete**

The current application already provides a working vertical platform:

- Student registration, login, profiles, and role-based access
- Persisted courses, modules, topics, sections, enrolments, submissions, and progress
- Server-side quiz and coding-task grading
- Instructor reports and localized CSV export
- Leaderboards, awards, hearts, notifications, and activity tracking
- Academic-integrity event recording and admin case handling
- Admin user, section, landing-page, and audit management
- Thai and English interfaces
- Responsive navigation, accessibility support, SEO metadata, and crawler files
- PostgreSQL-backed jobs, cache, and WebSockets
- Automated testing, linting, security scanning, and deployment support

This baseline is considered successful because a student can register, sign in, complete a graded activity, record progress, appear in reporting, and have that result reviewed through the staff interfaces.

## Milestone 1 — Reliable account recovery

**Status: Now**

See the [worked development-flow example](examples/milestone-1-reliable-account-recovery.md)
for the phase-by-phase artifacts, skills, gates, and current human handoff.
The current provider alternatives and unresolved human inputs are recorded in
[draft ADR-0002](decisions/adr-0002-select-production-email-provider.md).

### Goal

A student who has added an email address can request and receive a password-reset message in production.

### Scope

- Select an SMTP or transactional-email provider
- Configure authenticated production delivery
- Verify the sending domain and `no-reply` address
- Store provider credentials outside the repository
- Add delivery-error reporting and operational logging
- Confirm reset links use the production host and HTTPS
- Document local preview and production verification

### Success criteria

- A reset request does not disclose whether an account exists
- A real reset message reaches a test mailbox
- The reset link expires correctly and can only be used as designed
- A successful reset invalidates the user's existing sessions
- Delivery failure is visible to operators
- Automated tests and `bin/ci` pass

## Milestone 2 — First real topic

**Status: Complete**

### Goal

Replace the shared placeholder lesson with one production-quality, topic-specific bilingual lesson.

### Scope

- Choose the first AI1101 topic with the Product Owner and instructor
- Define the topic's learning objectives
- Add unique Thai and English theory content
- Add a topic-specific quiz and answer key
- Add a topic-specific coding or applied exercise
- Add topic-specific grading criteria and feedback
- Preserve the existing four-step lesson flow
- Validate the content with an instructor and a small student group

### Success criteria

- The selected topic renders content that is not shared with other topics
- Thai and English versions communicate the same learning objectives
- Quiz and code answers are graded on the server
- Failed and successful attempts are recorded
- A pass updates progress and unlocks the correct next topic
- The complete path can be demonstrated during Sprint Review

This is the first implementation target after account recovery because it proves the content seam with a small vertical slice before committing to the whole curriculum.

## Milestone 3 — Complete foundation course

**Status: Complete**

### Goal

Give every current AI1101 topic its own approved bilingual lesson and assessment.

### Scope

- Establish a reusable lesson-content template
- Assign content ownership and academic review
- Write unique theory, quiz, coding, and summary content for every topic
- Define measurable learning objectives for every topic
- Review difficulty and expected completion time
- Test topic-specific grading rules
- Check terminology consistency across Thai and English
- Run learner testing after each module rather than waiting for the full course

### Success criteria

- No AI1101 topic falls back to the shared placeholder lesson
- Every topic has approved Thai and English content
- Every assessment maps to a stated learning objective
- Progress, unlocking, reporting, and awards continue to work
- Content and locale consistency tests cover all topics

## Milestone 4 — Course-specific curricula

**Status: Complete**

### Goal

Allow each course to own a different syllabus instead of sharing one module and topic structure.

### Scope

- Associate course modules with a course
- Define ordering and uniqueness rules within each course
- Migrate the existing shared syllabus safely
- Update course, lesson, progress, map, and reporting queries
- Define whether completion is reusable across courses
- Provide seed and fixture data for multiple distinct curricula
- Update progress denominators and certificate requirements

### Success criteria

- At least two courses have visibly different syllabi
- Topic URLs resolve unambiguously within a course
- Progress is calculated against the selected course's requirements
- Locked/current/done states remain correct
- Instructor reports and leaderboards use the correct course data
- Existing completion data remains valid after migration

## Milestone 5 — Real knowledge map

**Status: Complete**

### Goal

Make the knowledge map a real view of curriculum relationships and learner mastery.

### Scope

- Derive map nodes from course modules and topics
- Replace placeholder counts with recorded progress
- Connect project nodes to their required topics
- Decide whether prerequisites are sequential or graph-based
- Implement or remove "Mark as known"
- Implement or remove map settings
- Link a selected node to the correct course and lesson

### Success criteria

- Map totals agree with course and progress screens
- Node state changes after a learner passes the relevant activity
- Project prerequisites are visible and accurate
- Every actionable control performs a real operation
- Invalid course, mode, and node parameters fall back safely

## Milestone 6 — Institutional access and documents

**Status: Later**

### Goal

Complete the university-facing access and document workflows.

### Scope

- Integrate UTCC SSO
- Define account linking between SSO identity and student ID
- Preserve role assignment and local emergency access
- Generate downloadable course-syllabus PDFs
- Localize generated documents
- Decide whether completion certificates are downloadable and verifiable

### Success criteria

- A UTCC account can sign in and reach the correct academy account
- Duplicate academy accounts are not created during account linking
- SSO failures have a safe fallback
- Syllabus downloads contain current course data
- Document links return real files with correct filenames and content types

## Milestone 7 — Operational admin controls

**Status: Complete**

### Goal

Replace the remaining placeholder admin tabs with trustworthy operational tools.

### Scope

- Replace Overview figures with database-backed metrics
- Replace the placeholder Courses table with real course administration
- Define course lifecycle states such as draft, published, and archived
- Implement approval-queue records and decisions
- Decide which feature flags are genuinely needed
- Persist approved feature-flag settings
- Record every administrative mutation in the audit log

### Success criteria

- No admin metric or row is presented as real when it is fabricated
- Course changes affect the learner-facing catalog predictably
- Approval decisions have an actor, timestamp, state, and audit event
- Feature switches change actual behavior or are removed
- Failed admin actions do not create misleading audit entries

## Milestone 8 — Community and pedagogy decisions

**Status: Complete**

### Goal

Resolve features whose implementation depends on teaching policy rather than engineering alone.

### Decisions required

- Should reaching zero hearts block another attempt?
- If attempts are blocked, how and when are hearts restored?
- Can instructors override a blocked learner?
- What learner behavior should earn the "Helping Hand" award?
- Is a forum, peer-review flow, or another collaboration feature appropriate?
- Should manually marking prior knowledge affect progress, unlocking, or certificates?

### Success criteria

- Each behavior has an approved written rule before implementation
- The interface explains the rule before it affects a learner
- Staff have an appropriate review or override path
- New behavior is reflected consistently in progress and reporting

## Milestone 9 — Production hardening

**Status: Continuous**

### Scope

- Add user-visible active-session management
- Support explicit session revocation after suspected compromise
- Review whether the 30-day absolute session limit remains appropriate
- Monitor mail, background jobs, WebSockets, and database capacity
- Replace placeholder Kamal deployment settings before using Kamal
- Define backup and restore verification with the database provider
- Add application-error and security-event monitoring
- Run accessibility and performance checks as the curriculum grows

### Success criteria

- A user or administrator can revoke compromised sessions
- Critical background failures are visible without reading server logs manually
- Restore procedures are tested, not only documented
- Production deployment configuration names real infrastructure
- Performance remains within the repository's query budgets

## Milestone 10 — Academic writing

**Status: Complete**

### Goal

Give normal users (students) and teachers a focused academic-writing workspace
where they can create a draft, invite co-authors, edit together, and preview a
well-structured academic post before publication.

The visual and interaction direction should use the supplied Academic Reader
prototype as reference: `Academic Reader.dc.html`, `katex-el.js`, and
`support.js` from the Academic content reader updates folder. The prototype is
design evidence, not an implementation or persistence contract.

### Scope

- Allow normal users/students and teachers to create and edit their own
  academic posts.
- Support draft, review, and published states with ownership and permission
  rules.
- Allow a draft owner to invite multiple users to collaborate, with explicit
  roles and revocation of access.
- Provide an editor in the post preview page so authors can move from reading
  preview to editing without losing context.
- Support academic-post structure: title, authors, affiliations, abstract,
  sections, subsections, references, citations, figures, captions, tables,
  code blocks, links, lists, quotations, notes, and mathematical equations.
- Provide reader and authoring tools inspired by the prototype: table of
  contents, citation popovers, KaTeX rendering, themes, dark mode, font and
  reading-width controls, search/library views, highlighting, comments,
  translation, and copy/export actions where permissions allow.
- Preserve Thai and English content alignment and existing role-based access
  controls.

### Success criteria

- A student and a teacher can each create, save, reopen, and edit an academic
  post draft.
- A draft owner can invite at least two other users; invited users can join,
  edit only within their granted permission, and be removed by the owner.
- Concurrent edits do not silently overwrite another user's saved work; the
  conflict or merge behavior is visible and tested.
- The preview page renders the same saved content as the editor, including
  citations, references, figures, tables, and KaTeX equations.
- A post can be moved through the defined lifecycle only by authorized users,
  and published content is protected from unauthorized edits.
- The academic-post tools have focused tests, accessibility coverage, and
  Thai/English locale coverage.
- The complete author-to-preview-to-publish path can be demonstrated in a
  browser walkthrough.

### Product decisions required before implementation

1. Whether “normal user” means the existing `student` role and whether
   teachers map to the existing `instructor` role.
2. Whether collaborators may edit simultaneously in real time or whether
   saved draft revisions are sufficient for the first increment.
3. How invitations are delivered and accepted while production email remains
   deferred.
4. Which users may publish, and whether teacher approval is required.
5. Which export formats are required first: HTML, PDF, Markdown, or another
   academic format.

### Reference prototype capabilities

The supplied reader prototype demonstrates the desired presentation language
and interaction vocabulary: academic typography, multiple themes, dark mode,
font-size and reading-width controls, section navigation, citation details,
KaTeX equations, code and table presentation, text highlighting, comments,
translation, copy-source, and library filtering. These should be validated
against the authoring workflow before becoming implementation requirements.

## Product decisions required before scheduling

The following decisions materially change scope and should not be inferred during implementation:

1. Email provider, sending domain ownership, and credential owner
2. First topic selected for production content
3. Academic content owner and bilingual review process
4. Whether courses keep separate or reusable completion credit
5. UTCC SSO protocol, identity attributes, and support contact
6. Heart behavior at zero
7. Meaning of "Helping Hand" and whether community features are in scope
8. Session-revocation policy

## Definition of done for every milestone

A roadmap item is complete only when:

- The behavior is shippable and demonstrable in the running application
- New behavior has automated test coverage
- `bin/ci` passes locally and in continuous integration
- Thai and English copy are updated together
- Positionally indexed locale structures remain aligned
- Security and authorization rules remain enforced
- Relevant documentation is updated
- Placeholder behavior replaced by the milestone is removed or clearly labelled

## AI Recruitment Platform Roadmap

**Tags:** [#product](tags.md#product) [#roadmap](tags.md#roadmap) [#planning](tags.md#planning)

**Status:** Draft for Product Owner, legal, security, and domain-owner review

**Accountable decision:** A human Product Owner must confirm the target market,
priority, capacity, and milestone order before any milestone becomes execution
work. This document is a strategic roadmap, not an implementation contract.

### Vision

Build an AI-native recruitment ecosystem where AI Agents assist job seekers,
recruiters, hiring managers, and interns throughout the hiring lifecycle while
humans retain responsibility for consequential employment decisions.

The platform should automate repetitive work, explain recommendations, preserve
user control, and make hiring more accessible without turning opaque model
outputs into automatic hiring decisions.

### Problem framing

Recruitment participants currently spend substantial time moving information
between resumes, job descriptions, application systems, interviews, and
spreadsheets. Employers need faster, more consistent workflows; candidates need
better discovery and career guidance; students and interns need structured
programs with meaningful learning outcomes.

The baseline, target market, jurisdiction, existing workflow, and measurable
starting metrics are not yet established. These must be collected during
discovery before targets or a delivery commitment are accepted.

#### Users and jobs to be done

| User | Primary job | Proposed AI assistance |
| --- | --- | --- |
| Organization | Define a role or internship program and hire fairly | Generate structured requirements, benchmark options, and organize workflow |
| Recruiter | Source, screen, coordinate, and communicate with candidates | Draft content, summarize evidence, rank with explanations, and surface next actions |
| Hiring Manager | Compare qualified applicants and make a hiring decision | Review evidence, compare scorecards, and estimate onboarding effort |
| Professional candidate | Find suitable work and improve career prospects | Build a profile, discover roles, prepare for interviews, and plan skill growth |
| Student or intern | Find a useful placement and complete a learning program | Match to programs, follow a learning roadmap, and track progress |
| Mentor | Support and evaluate an intern | Receive guidance, review progress, and produce fair evaluations |

#### Non-goals for this roadmap

- Fully autonomous hiring, rejection, or employment decisions
- Auto-application without explicit candidate permission for each defined scope
- Inferring protected characteristics or using them as hidden ranking features
- Treating an AI score as proof of candidate quality
- Committing to a specific model vendor, vector database, HRIS, or jurisdiction
- Treating the illustrative six-month timeline as an approved delivery promise

### Product principles

1. **Human accountability:** Employers and candidates can review, edit, approve,
   or reject consequential AI suggestions.
2. **Explainable assistance:** Recommendations show the evidence, uncertainty,
   and criteria that contributed to them.
3. **Permissioned agents:** Every agent action has a user, scope, consent, and
   audit trail; external actions require explicit authorization.
4. **Fairness and accessibility:** Screening and matching are monitored for
   disparate impact, accessibility barriers, and proxy discrimination.
5. **Data minimization:** Resume, transcript, interview, and profile data are
   collected and retained only for stated purposes.
6. **Reversible delivery:** Each milestone produces a small, demonstrable
   vertical slice with a rollback or disablement path for AI behavior.

### Core platform map

```text
AI Recruitment Platform
├── Company
│   ├── Organization
│   ├── Recruiter
│   ├── Hiring Manager
│   └── AI Recruiter Agent
├── Candidate
│   ├── Professional
│   ├── Student
│   ├── Intern
│   └── AI Career Agent
├── Jobs
│   ├── Full Time
│   ├── Part Time
│   ├── Internship
│   ├── Contract
│   └── Freelance
├── Matching Engine
├── Interview
├── Offer
└── Analytics
```

### Outcome framework

The roadmap should be measured by user outcomes, not by the number of AI
features shipped. Baselines and targets remain **TBD** until the Product Owner
and Data owner approve the definitions and instrumentation.

| Outcome area | Primary metric | Candidate data source | Guardrail |
| --- | --- | --- | --- |
| Job creation | Median time from hiring request to approved publication | Job and approval events | Major-edit rate and factual-error rate in AI drafts |
| Screening | Median recruiter review time per qualified applicant | Application and review events | Qualified-candidate false-negative rate and subgroup parity |
| Matching | Precision of recommended candidates/jobs and recruiter acceptance rate | Recommendation, review, and outcome events | Explanation satisfaction and override rate |
| Hiring | Time-to-fill and offer acceptance rate | Pipeline and offer events | Candidate withdrawal rate and adverse-impact indicators |
| Internship | Placement, completion, and learning-outcome achievement rate | Program, progress, and evaluation events | Student satisfaction and mentor workload |
| Candidate experience | Application completion and satisfaction rate | Funnel events and consented surveys | Unwanted outreach, privacy complaints, and accessibility failures |
| AI effectiveness | Accepted recommendation rate with a recorded human decision | Agent action and approval events | Unauthorized action, hallucination, drift, and incident rate |

The Product Owner must select one primary outcome for each active milestone,
define the evaluation window, and document how the metric could be gamed before
the milestone enters delivery.

### Roadmap summary

| ID | Milestone | Objective | Status | Main dependency |
| --- | --- | --- | --- | --- |
| M1 | Foundation | Establish identity, organizations, profiles, and permissions | Proposed | None |
| M2 | Job Management | Enable companies to manage and publish jobs | Proposed | M1 |
| M3 | AI Job Creation | Reduce the effort required to produce a quality job specification | Proposed | M2 |
| M4 | Internship Management | Support internship programs, applications, mentorship, and evaluation | Proposed | M1, M2 |
| M5 | Candidate Profile | Build structured, consented, searchable candidate profiles | Proposed | M1 |
| M6 | AI Resume Analysis | Extract candidate data and identify skills and gaps | Proposed | M5 |
| M7 | Job Discovery | Help candidates find relevant opportunities | Proposed | M2, M5 |
| M8 | AI Matching Engine | Match candidates and jobs with explainable recommendations | Proposed | M6, M7 |
| M9 | Recruitment Workflow | Manage applications through interview and offer stages | Proposed | M2, M5 |
| M10 | AI Recruiter Agent | Assist recruiters across screening and hiring coordination | Proposed | M8, M9 |
| M11 | AI Candidate Agent | Assist candidates with search, preparation, and career growth | Proposed | M6, M7 |
| M12 | AI Internship Agent | Assist student matching, mentorship, progress, and evaluation | Proposed | M4, M6, M8 |
| M13 | Analytics and Reporting | Provide recruitment, internship, and AI-effectiveness insight | Proposed | M8, M9 |
| M14 | Notifications and Communication | Coordinate timely, consented communication | Proposed | M9 |
| M15 | Enterprise and Integration | Prepare for enterprise adoption and governed integrations | Proposed | M1, M9, M13, M14 |

The dependency order is directional. The Product Owner and Tech Lead may reorder
milestones when discovery evidence, risk, or learning value justifies it, but
the opportunity cost must be recorded.

### Milestone 1 — Foundation

**Objective:** Establish the core recruitment platform and a trustworthy access
boundary.

#### Deliverables

- Authentication and account recovery
- Company and candidate profiles
- Organization and team management
- Roles and permissions for organization, recruiter, hiring manager, mentor,
  professional, student, and intern users
- Consent, data-use, retention, and audit-event foundations

#### Success criteria

- Users can sign in, recover access, and reach only the organization or
  candidate data authorized for their role.
- A company can manage its organization and invite permitted staff members.
- A candidate can create, review, export, and delete the profile data allowed by
  the approved retention policy.
- Security, privacy, accessibility, and audit invariants have human review.

### Milestone 2 — Job Management

**Objective:** Enable companies to create and publish structured job postings.

#### Deliverables

- Create, edit, archive, and delete job posts
- Job templates and categories
- Draft, review, publish, pause, and close states
- Employment type: full time, part time, internship, contract, and freelance
- Location, remote policy, salary range, department, team, seniority, and status
- Approval and visibility rules

#### Success criteria

- An authorized company user can create and publish a complete job posting.
- Draft and published content have distinct permissions and audit history.
- Candidates see only jobs whose visibility and publication rules allow access.
- Salary, location, employment type, and closing status are structured and
  searchable.

### Milestone 3 — AI Job Creation

**Objective:** Accelerate job creation while keeping the recruiter in control.

#### Employer inputs

- Job title, department, employment type, work location, salary range, team,
  hiring reason, number of positions, and seniority

#### AI Recruiter Agent suggestions

- Job summary
- Responsibilities and expected deliverables
- Required, preferred, and nice-to-have skills
- Qualifications and KPIs
- Career path
- Interview questions
- Salary recommendation and market benchmark
- Search-engine optimization suggestions
- Diversity and inclusive-language checks
- Estimated hiring-time range with uncertainty

#### Success criteria

- AI produces a complete draft from the approved input fields.
- Recruiters can accept, edit, regenerate, or reject each suggestion.
- Every generated claim has a source or uncertainty label where applicable.
- No AI-generated job becomes public without the required human approval.
- Draft quality, major-edit rate, time-to-publish, and fairness guardrails are
  instrumented.

### Milestone 4 — Internship Management

**Objective:** Support organizations and universities in running useful,
structured internship programs.

#### Company program inputs

- Program name, department, duration, mentor, maximum students, required skills,
  learning outcomes, working days, remote policy, paid or unpaid status,
  certificate policy, and equipment provided

#### AI Internship Agent suggestions

- Internship description
- Learning roadmap and weekly plan
- Mentor guide
- Evaluation criteria
- Final-project suggestions

#### Workflow

```text
Create program → AI draft → Human review → Publish → Student applications
→ Screening → Interview → Offer → Internship → Evaluation → Certificate
```

#### Success criteria

- An organization can publish an internship program with explicit learning
  outcomes and capacity.
- Students can apply, see status, and withdraw according to the approved rules.
- Mentors can view assigned participants and submit structured evaluations.
- Program completion and certificate eligibility are based on recorded,
  reviewable evidence.

### Milestone 5 — Candidate Profile

**Objective:** Build complete, consented, and portable candidate profiles.

#### Candidate inputs

- Resume, portfolio, education, experience, skills, certifications, languages,
  salary expectation, preferred location, GitHub, and LinkedIn references

#### Success criteria

- A candidate can upload, review, correct, and delete profile information.
- Structured fields retain their source and confidence where extracted from a
  document.
- Candidates control profile visibility and application-data reuse.
- The profile supports professional, student, and intern journeys without
  forcing irrelevant fields.

### Milestone 6 — AI Resume Analysis

**Objective:** Extract useful structure from resumes without treating extraction
as a final judgment.

#### AI outputs

- Resume parsing
- Skill and tool extraction
- Experience and seniority detection
- Qualification extraction
- ATS-readiness signals
- Skill-gap analysis
- Candidate strengths and uncertainty summary

#### Success criteria

- Candidates can inspect and correct extracted information before it is used.
- Recruiters can distinguish source evidence from model inference.
- Extraction accuracy and correction rate are measured by document type and
  relevant subgroup.
- The system does not infer or expose protected characteristics for ranking.

### Milestone 7 — Job Discovery

**Objective:** Make job discovery more useful than keyword search alone.

#### Deliverables

- Search and filters
- Saved jobs
- Personalized recommendations
- Job alerts with consent and frequency controls
- Candidate-facing explanation of why a job was suggested

#### Success criteria

- Candidates can find, save, revisit, and apply to jobs using structured and
  natural-language discovery.
- Recommendations can be dismissed and their preferences corrected.
- Alerts are permissioned, rate-limited, and easy to stop.
- Discovery improves relevant application starts without increasing unwanted
  communication or candidate confusion.

### Milestone 8 — AI Matching Engine

**Objective:** Match candidates and jobs using evidence-rich, explainable
recommendations.

#### Proposed matching approach

```text
Semantic search + vector retrieval + LLM ranking + skill graph + experience graph
```

#### Match dimensions

- Skill fit
- Experience fit
- Salary fit
- Location and work-mode fit
- Learning or growth fit
- Candidate- and employer-defined preferences

#### Example explanation

```text
Backend Engineer — recommended match: 98%
Skills: 92% · Experience: 95% · Salary: 90% · Preferences: 88%
Why: demonstrated .NET, Azure, Redis, RabbitMQ, Docker, and Kubernetes experience
What is missing: production PostgreSQL evidence
```

The numeric score is a decision-support signal, not a probability of hiring or
an eligibility decision. The score display, weighting, calibration, and use in
screening require human review.

#### Success criteria

- Candidates and recruiters can see the factors, evidence, uncertainty, and
  limitations behind a recommendation.
- Matching quality is evaluated against a human-reviewed dataset and live
  outcomes without leaking protected information.
- Recruiters can override recommendations and record why.
- Fairness, drift, privacy, and security monitoring are defined before ranking
  influences a consequential workflow.

### Milestone 9 — Recruitment Workflow

**Objective:** Manage the end-to-end hiring pipeline.

#### Deliverables

- Application tracking
- Configurable screening and hiring stages
- Interview scheduling
- Interview scorecards
- Hiring-team review
- Offer creation, review, and status management
- Candidate communications and withdrawal handling

#### Success criteria

- A published job can move through a complete application-to-offer workflow.
- Every stage has authorized actors, visible status, timestamps, and audit data.
- Candidates can see the status and required next action permitted by policy.
- Hiring teams can compare evidence without exposing data outside the role
  boundary.

### Milestone 10 — AI Recruiter Agent

**Objective:** Assist recruiters throughout hiring while preserving review and
approval boundaries.

#### Agent capabilities

- Generate and refine job descriptions
- Screen resumes against approved criteria
- Rank candidates with explanations
- Generate interview questions and scorecard prompts
- Schedule interviews using authorized availability
- Summarize interviews from permitted recordings or notes
- Recommend next steps and offer options
- Detect possible bias, missing evidence, and process delays
- Forecast hiring timelines with confidence ranges

#### Success criteria

- Recruiters can inspect agent evidence, correct the output, and approve the
  next action.
- The agent cannot reject, disqualify, contact, or offer a candidate outside an
  explicit permission and approval policy.
- Every agent action is attributable, replayable, and auditable.
- Recommendation acceptance, override, error, drift, and adverse-impact
  measures are visible to authorized operators.

### Milestone 11 — AI Candidate Agent

**Objective:** Give job seekers a career assistant rather than a passive search
interface.

#### Agent capabilities

- Build and improve resumes
- Optimize for an approved ATS-readiness rubric without fabricating experience
- Find and explain relevant jobs
- Apply only with explicit candidate permission
- Track applications and deadlines
- Prepare for interviews
- Recommend courses and learning paths
- Suggest salary-negotiation preparation
- Identify career paths, skill gaps, and promotion readiness
- Compare company fit using available evidence and clear uncertainty

#### Success criteria

- Candidates can review, edit, and approve every externally visible application
  artifact.
- The agent never invents qualifications, experience, or certifications.
- Auto-apply, if approved, is scoped, revocable, rate-limited, and fully logged.
- Candidates can understand and correct the assumptions behind guidance.

### Milestone 12 — AI Internship Agent

**Objective:** Improve student placement and internship learning outcomes.

#### Agent capabilities

- Match students to programs and mentors
- Recommend learning roadmaps
- Create weekly plans
- Track progress against learning outcomes
- Suggest mentor interventions
- Draft evaluation evidence and final-project ideas
- Recommend certificate eligibility for human approval

#### Success criteria

- A student can see why an internship or mentor was recommended.
- Mentors can correct plans and document exceptions.
- Weekly progress is based on consented evidence and does not become covert
  surveillance.
- Evaluations and certificates require the authorized human decision.

### Milestone 13 — Analytics and Reporting

**Objective:** Provide trustworthy insight into recruitment, internships, and AI
effectiveness.

#### Deliverables

- Recruitment dashboard
- Hiring funnel and time-to-hire reports
- Internship placement, completion, and outcome reports
- AI recommendation acceptance and override metrics
- Data-quality, fairness, drift, and incident reporting
- Role-based exports with privacy controls

#### Success criteria

- Each metric has a definition, owner, data source, refresh behavior, and
  limitation.
- Reports distinguish correlation from causation and AI assistance from human
  decisions.
- Sensitive reports are restricted, audited, and retention-controlled.

### Milestone 14 — Notifications and Communication

**Objective:** Keep participants informed without creating unwanted or unsafe
communication.

#### Deliverables

- Email and in-app notifications
- Application-status updates
- Interview reminders
- Offer notifications
- Internship progress reminders
- Preferences, consent, unsubscribe, templates, localization, and delivery
  monitoring

#### Success criteria

- Every message has an authorized event, recipient, purpose, and delivery state.
- Candidates can control notification preferences and stop non-essential
  messages.
- Operational failures are visible without exposing resume, transcript,
  interview, or other sensitive content.

### Milestone 15 — Enterprise and Integration

**Objective:** Prepare the platform for governed enterprise adoption.

#### Deliverables

- Single sign-on
- HRIS integration
- Calendar integration
- API gateway and partner access
- Audit logs and administrative controls
- Security, privacy, accessibility, and compliance evidence
- Tenant isolation, retention, export, deletion, and incident-response controls

#### Success criteria

- Enterprise users can authenticate and access only their tenant's data.
- Integrations have versioned contracts, consent boundaries, retries, and
  failure handling.
- Security and privacy owners approve the operating model before production
  data is exchanged.
- The platform can demonstrate who accessed, changed, generated, or exported
  consequential recruitment data.

### Illustrative delivery timeline

This timeline is a planning example only. It is not a commitment and must not
be used to promise delivery until discovery, staffing, architecture, legal
review, and dependencies are complete.

```text
Phase 1 · Months 1–2
M1 Foundation → M2 Job Management

Phase 2 · Months 2–3
M3 AI Job Creation → M4 Internship Management → M5 Candidate Profile

Phase 3 · Months 3–4
M6 AI Resume Analysis → M7 Job Discovery → M8 AI Matching Engine

Phase 4 · Months 4–5
M9 Recruitment Workflow → M10 AI Recruiter Agent → M11 AI Candidate Agent

Phase 5 · Months 5–6
M12 AI Internship Agent → M13 Analytics → M14 Notifications → M15 Enterprise
```

The dependency-aware delivery plan should reserve capacity for security,
privacy, accessibility, observability, model evaluation, and production
hardening in every phase.

### Cross-cutting AI agent requirements

All agents must provide:

- Explicit user, tenant, role, consent, and action scope
- Human review for consequential employment decisions
- Evidence citations or source references where available
- Confidence and uncertainty information
- Safe refusal when required data or authorization is missing
- Prompt, model, retrieval, tool, and output version traceability
- Audit events that avoid storing unnecessary sensitive content
- Rate limits, spend controls, timeouts, and disablement controls
- Evaluation datasets and regression tests before changing behavior
- Monitoring for hallucination, drift, bias, privacy leakage, and abuse

### Decisions required before scheduling execution

The following are human-owned decisions and must be recorded in ADRs,
specifications, or policy documents before the affected milestone is accepted:

1. Target market, initial geography, employment-law jurisdiction, and launch
   customer segment
2. Product owner, technical owner, security owner, privacy owner, and data
   owner
3. Whether the first release serves professional recruitment, internships, or
   both
4. Role and tenant model, including university, employer, recruiter, mentor,
   and student boundaries
5. Permitted AI actions versus advisory-only actions
6. Fairness, accessibility, explainability, and human-review policy for
   employment decisions
7. Consent, retention, deletion, export, training-use, and data residency rules
8. Model provider, hosting boundary, retrieval architecture, and cost budget
9. Evaluation dataset ownership, labeling policy, and release thresholds
10. Interview recording, transcription, and summarization policy
11. Auto-apply permissions, rate limits, and candidate notification behavior
12. Salary benchmark sources, licensing, freshness, and geographic coverage
13. Integration priorities for HRIS, SSO, calendars, email, and job boards
14. Primary outcome metric, baseline, target, guardrails, and evaluation window
15. Milestone priority, capacity, opportunity cost, and go/no-go criteria

### Definition of ready for a milestone

A milestone is ready to enter execution only when:

- The affected user and problem are stated with evidence.
- One accountable human owner is named.
- Scope, exclusions, dependencies, and opportunity cost are explicit.
- Primary outcome, baseline, target, data source, and guardrails are approved.
- AI actions, human approval boundaries, and failure behavior are specified.
- Required legal, privacy, security, accessibility, and domain reviews are named.
- Tier B/C invariants and acceptance criteria can be verified.
- The required ADR, specification, test strategy, and operating artifacts are
  identified.

### Definition of done for every milestone

- The increment is demonstrable in the running product.
- Automated tests and focused AI evaluations pass.
- Human acceptance criteria are reviewed by the accountable owner.
- Thai and English copy are updated together where applicable.
- Authorization, privacy, security, and audit invariants remain enforced.
- AI outputs are explainable, attributable, and disableable.
- Operational telemetry and an appropriate runbook exist before production use.
- The outcome metric and guardrails are measured for the agreed evaluation
  window.
- Documentation, backlog traceability, and the next decision are updated.

### Initial sequencing recommendation for discovery

Before building the full platform, run one thin vertical slice that connects:

```text
Organization setup → structured job draft → human approval → publication
→ candidate profile → explainable shortlist → recruiter review
```

This slice validates the two-sided data model, permission boundary, AI job
generation, candidate evidence, matching explanation, and primary outcome
instrumentation before adding interviews, offers, autonomous agents, or
enterprise integrations.

The slice should not be considered approved delivery until the Product Owner,
Tech Lead, Security/Privacy owner, and recruitment-domain owner record their
decisions.

### Related planning records

- [UTCC Academy roadmap](#utcc-academy-roadmap)
- [Project development flow](development-flow.md)
- [System development flow master](system-development-flow-master.md)
- [Canonical skill library](skills-library-README.md)
- [External feature proposal template](templates/external-feature-proposal.md)


## Company Business Case Platform Roadmap

**Status:** Phase 1 implemented (2026-08-09) — invitation-only, text-only
collaboration slice per SPEC-0040/ADR-0040; uploads, email, reporting, and
later milestones remain proposals

**Version:** 1.0
**Platform:** Ruby on Rails
**Prepared for:** UTCC AI Academy

### Industry–University Collaboration Ecosystem

#### Track roadmap summary

| ID | Milestone | Outcome | Status | Main dependency |
| --- | --- | --- | --- | --- |
| M10 | Company Business Case Platform | Companies and invited students can collaborate on real business challenges | Phase 1 implemented | Existing identity and platform services |
| M11 | Student Internship Request Platform | Students can request internships from partner companies and complete a supported learning cycle | Increments 1–3 implemented | M10 company boundary, shared identity, and institutional internship policy |
| M12 | Technical Blog Translation Platform | Technical writers and reviewers can publish accurate, multilingual technical knowledge | Proposed | Shared identity, content model, editorial policy, and translation-provider decision |
| M13 | Public Feature Request and Core Team Development Platform | Public users can submit, follow, discuss, and trace product proposals through review and release | Proposed | Existing proposal intake, moderation policy, roadmap traceability, and core-team ownership |
| M14 | Core Team Internal Work Dashboard | Core team members can manage private Markdown work records and connect them to governed Slack collaboration | Proposed | Core-team identity, repository lifecycle records, Slack policy, and M13 proposal decisions |

#### Milestone M10 — Company Business Case Platform

M10 is scoped to this roadmap track. It does not replace UTCC Academy M10
Academic Writing or AI Recruitment Platform M10 AI Recruiter Agent.

Phase 1 of this milestone is implemented: organization-owned business cases
with draft/published/closed lifecycle, single-use student invitations,
participant and mentor assignments, milestones, append-only text submissions,
comments, and audit events (SPEC-0040). File uploads, email delivery,
administrator support/reporting, and the revenue and AI capabilities below
remain proposed future work gated on their own review decisions.

### 1. Executive Summary

The Company Business Case Platform is a new feature that enables companies to submit real business challenges and collaborate with invited students through a secure, structured project environment.

Unlike a traditional job board or internship portal, this platform focuses on **innovation, learning, and collaborative problem-solving**. Companies gain access to fresh ideas and future talent, while students gain practical experience by solving authentic business problems under faculty and industry mentorship.

The platform is designed around Japanese management philosophies, emphasizing continuous improvement, quality, people development, and long-term partnerships.

### 2. Vision

To establish a sustainable Industry–University Collaboration Ecosystem where companies, students, and the university work together to solve real-world business challenges, develop future talent, and create long-term value through innovation.

### 3. Objectives

- Connect companies with talented students.
- Transform classroom learning into real business experience.
- Create structured collaboration between academia and industry.
- Support innovation through milestone-driven projects.
- Build a sustainable platform for long-term partnerships.
- Enable future AI-assisted project management and evaluation.

### 4. Business Philosophy

The platform follows Japanese management principles that emphasize continuous learning, quality, and mutual benefit.

#### 4.1 Kaizen (改善) – Continuous Improvement

Every business case becomes an opportunity for continuous learning and iterative improvement.

##### Application

- Continuous feedback from companies
- Incremental milestone reviews
- Iterative solution refinement
- Knowledge captured for future projects

#### 4.2 Genchi Genbutsu (現地現物) – Go and See

Students work on actual business challenges instead of hypothetical assignments.

##### Application

- Real company requirements
- Real business data
- Direct communication with stakeholders
- Evidence-based decision making

#### 4.3 Hitozukuri (人づくり) – Developing People

The primary goal is developing capable professionals.

##### Application

- Student mentoring
- Faculty guidance
- Industry coaching
- Skill development
- Career readiness

#### 4.4 Monozukuri (ものづくり) – Craftsmanship

Deliver quality solutions through disciplined engineering practices.

##### Application

- Structured development
- Quality reviews
- Documentation
- Professional software engineering

#### 4.5 Sanpō Yoshi (三方よし)

Create value for every stakeholder.

| Stakeholder | Benefit |
|-------------|----------|
| Company | Innovation and talent discovery |
| Student | Experience and career development |
| University | Industry collaboration and research |

#### 4.6 Omotenashi (おもてなし)

Provide an exceptional collaboration experience.

##### Application

- Clear workflows
- Easy communication
- Transparent progress
- Professional support

### 5. Business Process

```
Company
      │
      ▼
Create Business Case
      │
      ▼
Publish (Invite Only)
      │
      ▼
Invite Students
      │
      ▼
Student Accept Invitation
      │
      ▼
Project Workspace
      │
      ▼
Milestone Progress
      │
      ▼
Solution Submission
      │
      ▼
Company Review
      │
      ▼
Project Completion
```

### 6. Functional Requirements

#### 6.1 Company Business Case

Companies can create business cases containing:

- Business title
- Background
- Problem statement
- Business requirements
- Expected solution
- Required skills
- Technology stack
- Timeline
- Attachments
- Maximum students
- Visibility settings

Status:

- Draft
- Published
- Closed

#### 6.2 Student Invitation

Only invited students can access a project.

Features:

- Invite selected students
- Email invitation
- Secure invitation token
- Accept or decline invitation
- Expiration management

#### 6.3 Student Workspace

Students can:

- View requirements
- Download attachments
- Track milestones
- Submit deliverables
- Upload source code
- Ask questions
- Receive feedback

#### 6.4 Company Workspace

Companies can:

- Manage business cases
- Invite students
- Review submissions
- Approve milestones
- Give feedback
- Complete projects

#### 6.5 Milestone Management

Each project contains structured milestones.

Example:

1. Requirement Analysis
2. Solution Design
3. Prototype
4. Development
5. Testing
6. Final Presentation

#### 6.6 Notifications

Notifications include:

- Invitation sent
- Invitation accepted
- Submission received
- Milestone completed
- Feedback available
- Project completed

### 7. User Roles

#### Company

Permissions:

- Create business cases
- Invite students
- Review work
- Approve milestones
- Close projects

#### Student

Permissions:

- Access invited projects only
- Submit work
- Upload files
- View feedback
- Track progress

#### Faculty

Permissions:

- Monitor projects
- Mentor students
- Review progress
- Support collaboration

#### Administrator

Permissions:

- Manage users
- Manage companies
- Configure platform
- Generate reports

### 8. Technical Architecture

The current application baseline uses the following implementation choices.
The business-case feature must extend these boundaries rather than introduce a
parallel identity, authorization, or job-processing stack.

**Framework**

- Ruby on Rails 8.1.3

**Database**

- PostgreSQL

**Authentication**

- Rails has_secure_password with signed Session records and cookies

**Authorization**

- The repository's custom role-based authorization concern
- Existing roles: student, instructor, and admin
- Company and organization membership rules remain to be designed

**Storage**

- Active Storage

**Background Jobs**

- Solid Queue

**Notifications**

- In-app Notification records and Turbo refresh
- Action Mailer for email delivery

**Frontend**

- Hotwire / Turbo
- Stimulus
- Tailwind CSS

### 9. Database Design

#### Existing records to reuse

- users with the existing student, instructor, and admin roles
- notifications for in-app events
- sessions for authentication
- audit_events for durable administrative history
- Active Storage records for attachments

#### Proposed business-case records

These are new domain records, not tables that currently exist:

- companies
- business_cases
- invitations
- milestones
- business_case_submissions
- comments

The existing submissions table is tied to course activities and grading. It
must not be reused for business-case deliverables without an explicit data-model
decision and migration boundary.

### 10. Revenue Plan

The platform supports multiple revenue opportunities.

#### Business Case Publishing

Companies pay to publish business challenges.

#### Corporate Membership

Annual subscription providing access to collaboration features.

#### Premium Collaboration Services

Advanced reporting, project management, and dedicated support.

#### Recruitment Services

Companies recruit outstanding students directly from completed projects.

#### AI Services

Subscription-based AI features including:

- Requirement generation
- Solution recommendations
- Evaluation assistance
- Student matching

#### Corporate Training

Industry workshops delivered by faculty.

#### Consulting Services

Business consulting and applied research conducted by university experts.

### 11. Expected Outcomes

#### Companies

- Solve real business challenges.
- Discover future employees.
- Accelerate innovation.
- Strengthen university partnerships.

#### Students

- Gain practical experience.
- Develop professional skills.
- Build portfolios.
- Improve employability.

#### University

- Expand industry collaboration.
- Support applied research.
- Create sustainable revenue opportunities.
- Enhance institutional reputation.

### 12. Future AI Roadmap

Future enhancements include:

- AI Requirement Generator
- AI Business Analysis
- AI Solution Recommendation
- AI Student Matching
- AI Skill Gap Analysis
- AI Project Risk Assessment
- AI Automated Evaluation
- AI Learning Analytics

### 13. Milestone M10 Deliverables

- Company Portal
- Business Case Management
- Invite-Only Access
- Student Workspace
- Company Workspace
- Milestone Tracking
- Submission Management
- Feedback Workflow
- Notifications
- Reporting Dashboard
- Secure Role-Based Access Control
- REST API Foundation

### 14. Long-Term Vision

The Company Business Case Platform will evolve into an Industry–University Collaboration Ecosystem where companies, students, faculty, and researchers continuously collaborate to solve real business challenges.

Guided by Japanese management philosophy, the platform promotes continuous improvement, quality, people development, and mutual prosperity. Rather than serving only as a project management system, it becomes a sustainable innovation ecosystem that creates long-term value for industry, education, and society.

#### Milestone M11 — Student Internship Request Platform

M11 is scoped to this roadmap track. It extends the company and partner
boundaries established by M10; it does not replace UTCC Academy M10 Academic
Writing, AI Recruitment Platform M4 Internship Management, or AI Recruitment
Platform M11 AI Candidate Agent.

**Status:** Increments 1 to 4 implemented (2026-08-09 and 2026-08-12) —
student-initiated, position-less internship requests to companies that opt in, a
recorded company decision, placements with weekly progress reports, faculty
oversight, and the document contract. A placement originates from either an
approved request or an accepted recruitment application. A supervisor is an
administrator-granted assignment of one staff account to one placement, who
reads it and acknowledges its weeks and holds no gate over the company or the
student. A request shares the résumé already on the candidate profile rather
than storing a second copy, and a placement carries the student's deliverables.
Every authorized increment of [SPEC-0041](specs/spec-student-internship-requests.md)
has shipped; interviews, an academic gate, rubric evaluation, email, REST APIs,
and academic credit remain unauthorized and are enforced absent by
`test/operations/internship_request_boundary_test.rb`.

Corrected 2026-08-09: company internship **positions and evaluations already
exist** and ship under
[SPEC-0028](specs/spec-recruitment-internship-management.md) —
`Recruitment::InternshipProgram` with capacity and a mentor,
`Recruitment::InternshipApplication` (one student application per published
program, with accept, reject, and withdraw), and one
`Recruitment::InternshipEvaluation` per accepted application. What does not
exist is a student-initiated **request** to a company that has published no
position, a **placement** record for the internship after acceptance, a
**progress report**, and any **faculty** actor in the internship path.

Consequently the recommended first vertical slice in §12 below is already
largely implemented. The genuine remainder is scoped by
[ADR-0041](decisions/adr-0041-student-internship-request-boundary.md) and
[SPEC-0041](specs/spec-student-internship-requests.md). ADR-0041's first human
decision was answered yes on 2026-08-09 — a student may approach a company that
has published no position — so increment 1 is implemented: position-less
requests to companies that opted in, and one recorded company decision. An
approved request records a decision only; it neither starts nor completes an
internship. The remaining requirements below still require Product Owner,
university, company-partner, security/privacy, and technical review before
execution.

### 1. Executive Summary

The Student Internship Request Platform enables students to actively request
internship opportunities from partner companies through a structured and
transparent process.

Unlike a vacancy-first portal where companies publish openings and students
passively apply, this platform lets students present their skills, career
interests, portfolios, and learning goals. Companies can review the request and
accept an internship based on organizational needs and available supervision.

The platform connects the student, company, and university around one
traceable workflow: preparation, request, decision, planning, progress,
feedback, evaluation, and completion.

### 2. Problem framing and outcome

#### Affected users and current gap

- **Students** need a trusted way to discover suitable partner companies,
  present their readiness, and ask for an internship without relying on
  disconnected email, spreadsheets, or personal contacts.
- **Companies** need enough structured evidence to decide whether they can host
  a student, define a suitable position, and provide supervision.
- **Faculty** need visibility into eligibility, approvals, learning objectives,
  reports, and evaluation evidence.
- **Administrators** need auditable records for partner companies, requests,
  assignments, outcomes, and reporting.

The current baseline, number of eligible students, existing manual workflow,
company response rate, and internship completion rate are **TBD**. They must be
measured during discovery before a delivery target is accepted.

#### Proposed primary outcome

Increase the proportion of eligible students with a complete profile who submit
an internship request and receive a traceable company decision within the
agreed evaluation window.

**Data source:** profile-completion, request-state, company-decision,
assignment, and completion events.

**Target and evaluation window:** TBD by the Product Owner and Data owner after
baseline collection.

**Guardrails:**

- No unauthorized company can view a student's private profile, documents, or
  request history.
- Students and companies can see the current request or assignment state and
  the next required action.
- Faculty workload, student satisfaction, company response quality, and
  accessibility do not materially worsen.
- Sensitive documents and internship data follow an approved consent,
  retention, export, and deletion policy.

### 3. Vision

Create a student-centered internship ecosystem where learners proactively
engage with industry, develop professional competencies, and establish
meaningful relationships with companies before graduation.

### 4. Objectives

- Enable students to request internships directly from partner companies.
- Simplify internship matching between students and employers.
- Provide a structured approval workflow with clear ownership and status.
- Support internship planning, weekly progress, and supervisor feedback.
- Improve student employability through industry engagement.
- Build long-term partnerships between companies and the university.

### 5. Business philosophy

The platform follows Japanese management principles that emphasize people
development, continuous improvement, quality, and mutual prosperity.

#### 5.1 Kaizen (改善) — Continuous Improvement

Students improve their skills, portfolios, and professional readiness through
mentor and company feedback.

#### 5.2 Genchi Genbutsu (現地現物) — Go and See

Students gain first-hand experience in real business environments through
workplace exposure, practical tasks, and evidence-based learning.

#### 5.3 Hitozukuri (人づくり) — Developing People

Internships develop future professionals through career development,
leadership, communication, professional ethics, and industry readiness.

#### 5.4 Monozukuri (ものづくり) — Craftsmanship

Students learn to deliver quality work with discipline, documentation, and
attention to detail.

#### 5.5 Sanpō Yoshi (三方よし)

| Stakeholder | Benefit |
| --- | --- |
| Student | Professional experience, feedback, and career development |
| Company | Access to future talent and fresh perspectives |
| University | Stronger partnerships and improved graduate outcomes |

#### 5.6 Omotenashi (おもてなし)

The experience should be simple, transparent, supportive, and timely, with
clear communication and status visibility for every participant.

### 6. Business process

```text
Student
      │
      ▼
Complete Student Profile
      │
      ▼
Upload Resume & Portfolio
      │
      ▼
Browse Partner Companies and Positions
      │
      ▼
Submit Internship Request
      │
      ▼
Company Review
      │
      ▼
Interview (Optional)
      │
      ▼
Accept Internship
      │
      ▼
Internship Plan
      │
      ▼
Progress Monitoring and Weekly Reports
      │
      ▼
Evaluation
      │
      ▼
Internship Completion
```

The student-facing request statuses are proposed as **Draft**, **Submitted**,
**Under Review**, **Interview**, **Approved**, **Rejected**, and **Completed**.
The assignment/workspace lifecycle must separately distinguish planned, active,
and completed work so that an approved request is not incorrectly treated as a
finished internship.

### 7. Functional requirements

#### 7.1 Student profile and readiness

Students can manage:

- Personal information and contact preferences
- Academic program and eligibility information
- Skills and certifications
- Resume
- Portfolio links and uploaded work
- Career interests and learning goals
- Preferred internship period and location
- Consent for company and faculty access

The platform should show profile completeness and identify missing information
before a request can be submitted.

#### 7.2 Partner companies and internship positions

Partner companies can maintain approved organization information and publish or
offer internship positions containing:

- Position title and description
- Learning objectives and expected activities
- Required or preferred skills
- Supervisor and contact details
- Internship period, location, and working arrangement
- Capacity and application/request rules
- Required documents and privacy classification
- Open, paused, closed, or archived state

The company and organization boundary must reuse M10 records and membership
rules rather than introduce a second company identity model.

#### 7.3 Internship request workflow

Students can:

- Search and browse eligible partner companies and positions
- Select a position or submit a company-directed request where policy allows
- Write a motivation statement and learning goals
- Attach a resume, portfolio, and supporting documents
- Submit, withdraw, and track a request according to approved policy
- View the decision, required next action, and communication history

Companies can review the request, record a decision, request an interview,
provide a reason for rejection where policy requires it, and convert an
approved request into an internship assignment.

#### 7.4 Company workspace

Authorized company members can:

- Review only requests for their organization
- View the minimum student evidence required for the decision
- Schedule or record interviews
- Approve or reject requests
- Define internship objectives and expected deliverables
- Assign a company supervisor
- Monitor reports and provide feedback
- Complete the company evaluation

#### 7.5 Faculty workspace

Authorized faculty can:

- Review academic eligibility and internship objectives
- Monitor approved assignments and report submission status
- Review weekly reports and deliverables where permitted
- Support student and company communication
- Record academic approval, intervention, or completion evidence

#### 7.6 Internship workspace

Students and supervisors can:

- View the approved internship plan and objectives
- Record weekly activities, hours, outcomes, and blockers
- Submit reports and upload deliverables
- Receive and acknowledge supervisor feedback
- Track planned versus completed activities
- Complete student, company, and faculty evaluations as authorized

#### 7.7 Evaluation

The evaluation model should support approved rubrics for:

- Technical skills
- Communication
- Professionalism
- Teamwork
- Problem solving
- Learning progress
- Overall performance

Evaluation visibility, edits, submission deadlines, and whether scores affect
academic credit are institutional decisions and must not be inferred from the
interface.

#### 7.8 Notifications and reporting

Notifications may include:

- Request submitted
- Request reviewed
- Interview scheduled
- Internship approved or rejected
- Weekly report reminder
- Feedback available
- Evaluation completed
- Internship completed

Dashboards and reports should expose request funnel, response time, active
assignments, report completion, evaluation completion, and outcome data with
role-appropriate aggregation and no unnecessary student PII.

### 8. User roles and authorization

#### Student

- Manage their own profile and documents
- Submit and track their own internship requests
- Access only approved assignments and permitted feedback
- Submit reports, deliverables, and evaluations

#### Company

- Manage the organization's approved positions
- Review requests addressed to that organization
- Approve or reject requests within company authority
- Assign supervisors and evaluate assigned students

#### Faculty

- Review academic requirements and assigned internships
- Monitor progress and reports within the university's authority
- Support or escalate student-company issues

#### Administrator

- Manage users, companies, memberships, and policy configuration
- Configure workflow and evaluation rubrics
- Review audit events and operational reports
- Handle exceptional cases without bypassing durable authorization records

Every access to a student profile, document, request, report, or evaluation
must be checked server-side and recorded where the approved audit policy
requires it.

### 9. Technical architecture

M11 must extend the current application boundaries established by M10 and the
UTCC Academy baseline; it must not introduce a parallel authentication,
authorization, storage, or job-processing stack.

**Framework**

- Ruby on Rails 8.1.3

**Database**

- PostgreSQL

**Authentication**

- Existing `has_secure_password` authentication, signed Session records, and
  cookies

**Authorization**

- Existing role-based authorization concern, extended with company membership,
  faculty assignment, and request/assignment ownership rules

**Storage**

- Active Storage for resumes, portfolios, reports, and deliverables, subject
  to file-type, size, scanning, access, retention, and deletion rules

**Background jobs and notifications**

- Solid Queue for asynchronous work
- Existing in-app Notification records and Turbo refresh
- Action Mailer only after the production email provider and credential owner
  are approved

**Frontend**

- Hotwire / Turbo
- Stimulus
- Tailwind CSS

**API**

- A versioned REST API foundation may expose only approved resources and fields;
  API authorization must be equivalent to browser authorization

### 10. Data model

#### Existing records to reuse

- `users` and the existing student, instructor, and admin roles
- M10 `companies` and company-membership records once approved
- `notifications` for in-app events
- `sessions` for authentication
- `audit_events` for durable administrative history
- Active Storage records for attachments

#### Proposed internship records

- `internship_positions`
- `internship_requests`
- `internship_assignments`
- `internship_reports`
- `evaluations`
- Interview scheduling records, if the first increment requires persisted
  interview coordination

The data-model ADR must define ownership, uniqueness, state transitions,
consent, retention, deletion, and the boundary between a request, an approved
assignment, an academic requirement, and a completed internship. Resumes,
portfolios, reports, and deliverables must not be exposed through guessable
URLs or broad company queries.

### 11. Milestone M11 deliverables

- Student Profile Management
- Resume and Portfolio Management
- Partner Company and Internship Position Management
- Internship Request Workflow
- Company Review Workspace
- Faculty Monitoring Workspace
- Optional Interview Scheduling
- Internship Plan and Assignment Workspace
- Weekly Report and Deliverable Management
- Evaluation System
- Notification Center
- Dashboard and Reporting
- Secure role- and membership-based access control
- Consent, audit, retention, and file-security foundations
- Versioned REST API foundation
- Instrumentation for the primary outcome and guardrails

### 12. Dependencies and sequencing

M11 depends on:

1. M10's company, organization, membership, and company-workspace boundary.
2. The existing identity, session, storage, notification, and audit services.
3. A human decision on student eligibility, academic approval, and internship
   completion rules.
4. A data privacy and retention policy covering resumes, portfolios, reports,
   evaluations, and company information.
5. An approved production email provider if email invitations or reminders are
   included in the first increment.

The recommended first vertical slice is:

```text
Complete student profile → select partner position → submit request
→ company review → auditable approve/reject decision
```

Planning, assignment, weekly reports, and evaluation should follow as separate
increments after the request and decision boundary is validated. AI matching,
AI resume review, and AI evaluation assistance are future experiments and are
not required to prove the M11 core workflow.

### 13. Product decisions required before scheduling

1. Which existing roles represent company users and faculty, and whether a new
   company role or membership model is required.
2. How partner companies are verified, who may create positions, and whether
   faculty or administrator approval is required before publication.
3. Which students are eligible, whether a student may submit multiple active
   requests, and how withdrawal, duplicate requests, expiration, and rejection
   work.
4. Whether a request may target a company without a published position.
5. Whether interviews are only scheduled in the platform or also integrated
   with an external calendar or meeting provider.
6. Which reports, deliverables, evaluations, and scores are visible to each
   role, and whether any result affects academic credit.
7. Consent, data retention, export, deletion, and company access rules for
   student documents and internship records.
8. The primary outcome, baseline, target, guardrails, and evaluation window.
9. Which REST API resources are needed first and which consumers are approved.
10. The owner of the production email provider and notification policy.

### 14. Long-term vision

The Student Internship Request Platform will become the primary gateway for
student-initiated industry engagement, linking preparation, internship
experience, feedback, and employability outcomes.

Together with the Company Business Case Platform, it forms a broader
Industry–University Collaboration Ecosystem: companies can offer authentic
business challenges and internships, students can build evidence through real
work, faculty can support learning quality, and the university can measure
partnership outcomes over time.

### 15. Integration with the consolidated roadmap

- **UTCC Academy identity:** Reuse User accounts. Students map to the
  existing student role, faculty initially maps to instructor, and
  administrators use the existing admin boundary.
- **UTCC Academy platform services:** Reuse Active Storage, audit events,
  in-app notifications, Action Mailer, signed sessions, and the existing
  role-authorization concern.
- **Academic collaboration:** The existing academic-post invitation and
  membership flows are useful reference patterns, but business-case
  invitations need their own company, project, permission, expiration, and
  acceptance rules.
- **AI Recruitment Platform:** This track is complementary to, not a duplicate
  of, Internship Management, Candidate Profile, Recruitment Workflow, and
  Notifications. Shared candidate identity, skills, outcomes, and company data
  require a future cross-track data-model decision.
- **M10 naming:** Milestone IDs are track-scoped. This M10 must not be added to
  the current UTCC Academy backlog until its Product Owner, Tech Lead, Security
  or Privacy owner, and university-industry domain owner approve the scope.
- **M11 naming:** This M11 is also track-scoped. It must not be confused with
  AI Recruitment Platform M11 AI Candidate Agent, and it must not be added to
  the current UTCC Academy backlog until its Product Owner, Tech Lead,
  Security or Privacy owner, and university-industry domain owner approve the
  scope.
- **M10 → M11 boundary:** M10 owns company business-case collaboration and its
  organization boundary. M11 owns student-initiated internship requests,
  approved internship assignments, progress, and evaluations. Shared company,
  student, skill, and outcome data require an explicit cross-track data-model
  decision.

Before execution, M10 requires a problem baseline, primary outcome and
guardrails, a company/tenant and faculty-role decision, a data-retention and
business-data privacy policy, an invitation threat model, a data-model ADR,
and a specification covering permissions, file handling, state transitions,
notifications, and audit events. M11 additionally requires an internship
eligibility and academic-approval decision, a request/assignment state model,
student-document consent rules, an evaluation-rubric decision, and a
specification covering request withdrawal, duplicate requests, company review,
interview handling, weekly reports, and completion evidence.

#### Milestone M12 — Technical Blog Translation Platform

M12 is scoped to this roadmap track. It creates a multilingual technical
knowledge workflow alongside the M10 Company Business Case Platform and M11
Student Internship Request Platform. It does not replace UTCC Academy M10
Academic Writing or AI Recruitment Platform M12 AI Internship Agent.

**Status:** Proposal — not implemented

No technical-blog translation, translation-memory, terminology, technical
validation, or multilingual publishing workflow exists in the current
application. The requirements below describe the proposed future capability
and require Product Owner, editorial, technical-domain, security/privacy, and
technical review before execution.

### 1. Executive Summary

The Technical Blog Translation Platform enables technical writers to publish
high-quality technical articles that can be translated, reviewed, and
localized into multiple languages while preserving technical accuracy and
consistency.

Unlike machine-only translation, the platform combines AI-assisted translation,
human translation, subject-matter validation, and editorial approval. The
result is professional multilingual technical content for students,
developers, researchers, readers, and industry partners.

The platform supports knowledge sharing, international collaboration, and
continuous improvement of technical documentation.

### 2. Problem framing and outcome

#### Affected users and current gap

- **Technical writers** need to publish once, maintain revisions, and reach
  readers in multiple languages without duplicating entire editorial
  workflows.
- **Translators** need context, terminology, translation memory, and a review
  surface that protects code, links, diagrams, and technical meaning.
- **Technical reviewers** need to validate implementation details, examples,
  diagrams, and terms before localized content is published.
- **Editors** need auditable assignment, revision, approval, and publishing
  states.
- **Readers** need accurate technical content in their preferred language and a
  clear way to report translation problems.

The current baseline, number of technical articles, target languages,
translation turnaround time, readership by language, and critical translation
issue rate are **TBD**. Discovery must establish these measures before a
delivery target is accepted.

#### Proposed primary outcome

Increase successful target-language reading sessions on approved localized
technical articles. A successful session means that a reader can access the
preferred-language version and does not report a critical translation or
technical defect during the agreed evaluation window.

**Data source:** article/version publication events, language selection,
localized article reads, reader feedback, and severity-classified translation
issue reports.

**Target and evaluation window:** TBD by the Product Owner, editorial owner,
and Data owner after baseline collection.

**Guardrails:**

- No AI-generated translation is published without the approved human review
  and technical-validation path.
- Code blocks, commands, links, diagrams, citations, and downloadable resources
  remain accurate or are explicitly flagged for review.
- Published translations identify their source version, language, reviewers,
  and approval history.
- Critical translation defects, unauthorized publication, reader privacy
  complaints, and reviewer workload remain within agreed limits.
- Translation providers do not receive content or personal data beyond the
  approved data-use and retention policy.

#### Non-goals for the first increment

- Fully automatic translation or publication without human approval
- Automatic rewriting or translation of executable code
- Replacing the existing academic-post authoring workflow
- Supporting every language, content format, or external publishing channel
  before one bilingual vertical slice is validated
- Selecting an AI vendor, search engine, or translation-memory implementation
  before the required architecture and data decisions are recorded

### 3. Vision

Become a multilingual technical knowledge platform where technical writers,
translators, subject-matter experts, editors, and AI collaborate to deliver
high-quality technical content to a global audience.

### 4. Objectives

- Centralize technical blog publishing.
- Enable multilingual translation workflows.
- Improve access to technical knowledge across language boundaries.
- Preserve technical terminology and implementation meaning.
- Support collaborative review and approval.
- Build a reusable multilingual technical knowledge base.

### 5. Business philosophy

The platform is inspired by Japanese management philosophy, emphasizing
quality, continuous improvement, craftsmanship, and knowledge sharing.

#### 5.1 Kaizen (改善) — Continuous Improvement

Every translation improves through version-controlled drafts, editorial
feedback, terminology updates, and repeated review.

#### 5.2 Genchi Genbutsu (現地現物) — Go and See

Translations must reflect real technical implementations, not literal
word-for-word conversions. Code examples, diagrams, and implementation details
are validated against the source.

#### 5.3 Hitozukuri (人づくり) — Developing People

Writers, translators, reviewers, and editors develop their skills through
mentoring, collaboration, and AI-assisted learning.

#### 5.4 Monozukuri (ものづくり) — Craftsmanship

Technical documentation requires precision, consistency, terminology control,
and compliance with an approved style guide.

#### 5.5 Sanpō Yoshi (三方よし)

| Stakeholder | Benefit |
| --- | --- |
| Technical Writer | Reach a global audience and improve content quality |
| Reader | Access accurate technical knowledge in a preferred language |
| Organization | Expand technical content and community engagement |

#### 5.6 Omotenashi (おもてなし)

Provide a clean reading experience, a clear translation workflow, consistent
terminology, and a responsive editorial process.

### 6. Business process

```text
Technical Writer
        │
        ▼
Create Technical Blog
        │
        ▼
Editorial Review
        │
        ▼
Publish Original Article
        │
        ▼
AI-Assisted or Manual Translation
        │
        ▼
Translator Review
        │
        ▼
Technical Validation
        │
        ▼
Editorial Approval
        │
        ▼
Publish Multilingual Version
        │
        ▼
Reader Feedback
        │
        ▼
Continuous Improvement
```

The proposed article lifecycle is **Draft**, **Review**, **Published**, and
**Archived**. Each translation must have its own state and source-version
reference so that revising the original does not silently change a published
localized article.

### 7. Functional requirements

#### 7.1 Technical blog management

Technical writers can:

- Create articles and save drafts
- Edit content through an approved structured editor
- Submit original content for editorial review
- Publish and archive approved source articles
- Organize articles with categories and tags
- Add images, diagrams, captions, links, citations, and downloadable resources
- Embed code snippets while preserving syntax and copy behavior
- View source revisions and the status of related translations

Articles should preserve the distinction between prose, code, metadata, and
attachments so translation cannot corrupt executable examples or resource
links.

#### 7.2 Translation workflow

The translation workspace supports:

- AI-assisted translation with provider, model, and prompt provenance
- Manual translation and translator-owned edits
- Translation-memory suggestions from approved prior segments
- Terminology suggestions and required-term warnings
- Side-by-side source and target editing
- Version comparison and source-version tracking
- Language-specific review and publishing states
- Explicit handling for untranslated, stale, rejected, and superseded content

AI output is a draft input to the workflow. It must be attributable,
disableable, and reviewable before it can be approved.

#### 7.3 Editorial workflow

Editors can:

- Assign translation and review work
- Review source articles and localized versions
- Request revisions with comments and severity
- Compare source, previous, and proposed versions
- Approve or reject translations
- Publish localized versions only after required gates pass
- Unpublish or supersede a translation without deleting its history

Published content should be immutable by version; corrections create a new
reviewable version with an explicit reason.

#### 7.4 Technical validation

Subject-matter experts can:

- Verify technical accuracy against the source implementation
- Validate code samples, commands, API names, and configuration values
- Review diagrams, screenshots, captions, and alt text
- Approve or propose terminology
- Record validation findings and required revisions
- Confirm that a localized version remains technically usable

Validation results should distinguish factual, terminology, code, rendering,
and language-quality issues.

#### 7.5 Reader experience

Readers can:

- Switch between available languages
- Search and filter technical articles
- See source version, language, and last-reviewed metadata
- Bookmark articles where the reader account model permits it
- Download approved resources
- Leave comments or structured translation feedback where enabled
- Report translation, code, link, or rendering issues

Readers should never be shown an unapproved translation merely because an AI
draft exists.

#### 7.6 Notifications and reporting

Notifications may include:

- New article submitted
- Translation assigned
- Review requested
- Revision requested
- Technical validation requested
- Translation approved
- Article published or archived
- Translation issue reported

Dashboards should expose article and translation funnel, language coverage,
review turnaround, stale translations, critical issue rate, reader reach, and
reviewer workload with role-appropriate aggregation.

### 8. User roles and authorization

#### Technical Writer

- Create and edit owned technical articles
- Submit source articles for review
- View translation status and review feedback

#### Translator

- Translate assigned articles
- Edit target-language content
- Use approved terminology and translation memory
- Submit translations for technical and editorial review

#### Technical Reviewer

- Validate technical accuracy for assigned content
- Review code samples, diagrams, and terminology
- Approve or request changes within the review scope

#### Editor

- Manage source and translation workflows
- Assign reviewers and request revisions
- Approve and publish localized content

#### Reader

- Read approved articles
- Search, bookmark, and download permitted resources
- Submit feedback and report translation issues

#### Administrator

- Manage users, roles, languages, and workflow configuration
- Configure terminology and content policies
- Review audit events, reports, and moderation queues
- Manage provider settings without exposing credentials or content history

Authorization must enforce ownership, assignment, language, review scope, and
publication state server-side. A reader, translator, or reviewer must not gain
access to unpublished content merely by guessing an identifier.

### 9. Technical architecture

M12 must extend the current application boundaries and the existing academic
content patterns; it must not introduce a parallel authentication,
authorization, storage, or job-processing stack.

**Framework**

- Ruby on Rails 8.1.3

**Database**

- PostgreSQL

**Authentication**

- Existing `has_secure_password` authentication, signed Session records, and
  cookies

**Authorization**

- Existing role-based authorization concern, extended with writer, translator,
  reviewer, editor, assignment, and publication-state rules

**Storage**

- Active Storage for images, diagrams, and downloadable resources, subject to
  file-type, size, scanning, access, retention, and deletion rules

**Background jobs and notifications**

- Solid Queue for asynchronous translation, indexing, and notification work
- Existing in-app Notification records and Turbo refresh
- Action Mailer only after the production email provider and credential owner
  are approved

**Frontend**

- Hotwire / Turbo
- Stimulus
- Tailwind CSS

**Search**

- PostgreSQL full-text search for the first increment
- Elasticsearch or another search service only after an ADR demonstrates the
  need and documents operational ownership

**Translation engine**

- Provider-independent AI Translation API boundary
- Translation Memory and Terminology services owned by the application domain
- Human review required before publication
- Provider data handling, retention, regional processing, and disablement must
  be explicit

**API**

- A versioned REST API foundation may expose approved article, translation,
  review, and feedback resources; API authorization must equal browser
  authorization

### 10. Data model

#### Existing records to reuse or evaluate

- `users` and the existing student, instructor, and admin roles
- Existing `academic_posts`, revisions, memberships, and invitation patterns as
  reference or a deliberate reuse candidate after a data-model decision
- `notifications` for in-app events
- `audit_events` for durable administrative history
- Active Storage records for media and downloadable resources

The existing academic-post workflow must not be silently repurposed. The ADR
must decide whether technical articles share a content core with academic
posts, use a separate domain, or use an explicit adapter between the two.

#### Proposed translation records

- `technical_articles`
- `article_versions`
- `article_translations`
- `languages`
- `translation_memory_entries`
- `terminology_terms`
- Review assignments and findings
- Reader comments and translation issue reports

The data model must preserve source-version and target-version lineage,
language uniqueness, publication history, reviewer identity, AI provenance,
terminology status, and deletion/retention rules. Translation memory must not
reuse confidential or restricted content outside its approved scope.

### 11. Milestone M12 deliverables

- Technical Blog Management
- Source Article Versioning
- AI-Assisted and Manual Translation Workflow
- Translation Memory
- Terminology Management
- Editorial Review Workflow
- Technical Validation Process
- Multilingual Publishing
- Reader Feedback and Translation Issue Reporting
- Notification Center
- Dashboard and Analytics
- Secure role-, assignment-, and publication-state access control
- AI provider provenance and disablement controls
- REST API foundation
- Instrumentation for the primary outcome and guardrails

### 12. Dependencies and sequencing

M12 depends on:

1. Existing identity, session, storage, notification, and audit services.
2. A decision on whether technical articles share or remain separate from
   `academic_posts` and the current academic-writing workflow.
3. Editorial ownership, review roles, language policy, and publication rules.
4. A privacy, copyright, data-retention, and provider-use policy for source
   content, reader data, translation memory, and AI requests.
5. An approved translation-provider boundary and credential owner if AI
   translation is included in the first increment.

The recommended first vertical slice is:

```text
Create English technical article → editorial approval → AI/manual Thai
translation → translator review → technical validation → editor publication
→ reader language switch and issue report
```

Translation memory, terminology automation, additional languages, advanced
search, comments, and analytics should follow after the source-to-approved-
localized-version boundary is validated. The first increment should prove
that code, links, diagrams, version lineage, and human approval remain intact.

### 13. Product decisions required before scheduling

1. Which source and target languages are in the first increment, and whether
   Thai or English is the canonical source language.
2. Which existing roles map to technical writer, translator, technical
   reviewer, and editor, and whether memberships or new role records are
   required.
3. Whether technical articles share a content model with academic posts or use
   a separate model with explicit interoperability.
4. Which AI translation providers may receive content, what data may be sent,
   and who owns provider credentials and disablement decisions.
5. Which content structures must be preserved in the first release: Markdown,
   rich text, code, diagrams, equations, citations, tables, and downloads.
6. Who owns the terminology glossary, translation memory, style guide, and
   final approval for conflicting language choices.
7. Which review gates are mandatory for each content type and language, and
   whether a published source revision invalidates an existing translation.
8. Whether reader comments, bookmarks, and issue reports are public,
   authenticated, moderated, or private to editors.
9. Copyright, licensing, attribution, takedown, and public/private visibility
   rules for articles and translated content.
10. Whether PostgreSQL full-text search is sufficient and which API consumers
    are approved for the first increment.
11. The primary outcome, baseline, target, guardrails, and evaluation window.

### 14. Long-term vision

The Technical Blog Translation Platform will become a multilingual technical
knowledge hub where writers, translators, reviewers, editors, readers, and AI
collaborate to publish durable, accurate documentation for a global audience.

Together with the Company Business Case Platform and Student Internship
Request Platform, it forms a broader ecosystem for industry collaboration,
professional development, knowledge sharing, and global technical
communication.

### 15. Integration with the consolidated roadmap

- **UTCC Academy identity:** Reuse User accounts, signed sessions, existing
  role boundaries, and the university's approved account lifecycle.
- **UTCC Academy academic writing:** Academic posts, revisions, memberships,
  and invitations are reference patterns. Technical articles must have an
  explicit content-model boundary before reuse or migration.
- **UTCC Academy platform services:** Reuse Active Storage, audit events,
  in-app notifications, Action Mailer, and the existing role-authorization
  concern.
- **Company Business Case Platform M10:** M10 can provide real technical
  project knowledge and company-authored content, but company data and
  publication rights require explicit authorization and licensing rules.
- **Student Internship Request Platform M11:** M11 can provide student and
  faculty learning opportunities, but internship records, private feedback,
  and student work must not become public technical content without consent.
- **AI Recruitment Platform:** This M12 is separate from AI Recruitment
  Platform M12 AI Internship Agent. Shared user, skill, content, and outcome
  data require a future cross-track data-model decision.
- **M12 naming:** Milestone IDs are track-scoped. This M12 must not be added to
  the current UTCC Academy backlog until its Product Owner, Tech Lead,
  Security or Privacy owner, editorial owner, and technical-domain owner
  approve the scope.

Before execution, M12 requires a problem baseline, primary outcome and
guardrails, language and editorial ownership decisions, an explicit academic-
post/content-model boundary, a translation-provider and data-use decision, a
copyright and retention policy, a data-model ADR, and a specification covering
content versioning, translation lineage, review gates, technical validation,
AI provenance, publication, feedback, and audit events.

#### Milestone M13 — Public Feature Request and Core Team Development Platform

M13 is scoped to this roadmap track. It extends the current narrow proposal
intake and the repository's external-feature-proposal governance into a public,
traceable product-improvement workflow. It does not replace UTCC Academy M10
Academic Writing, Company Business Case Platform M10, Student Internship
Request Platform M11, Technical Blog Translation Platform M12, or AI
Recruitment Platform M13 Analytics and Reporting.

**Status:** Increment 1 delivered 2026-08-12 — the rest of the platform is
still a proposal

The current application has a limited `proposal_requests` path for signed-in
student or instructor contributors. It captures a title, category, problem,
idea, impact, and a small status set, but it does not yet provide public
proposal discovery, community voting or following, threaded discussion,
moderation, product and technical assessments, roadmap links, development
tracking, or release outcome review. M13 describes the complete future
capability and requires Product Owner, core-team, security/privacy, moderation,
and technical review before execution.

**What has shipped, and what it deliberately is not.**
[ADR-0049](decisions/adr-0049-proposal-triage-before-public-platform.md) took
the first increment as triage rather than participation, on the reasoning that
every deferred surface opens the abuse, identity, and privacy questions above
while none of them moves this milestone's stated outcome — the proportion of
proposals receiving an auditable decision and an author-visible explanation.
That proportion was zero by construction: three of the four statuses could not
be reached and no screen existed on which anybody could answer a proposal.
[SPEC-0050](specs/spec-proposal-triage.md) delivered as backlog item M13-001 on
2026-08-12: an administrator answers a proposal from the console's Proposals
tab, each transition writes a decision recording who decided it and the reason,
and the author reads that reason on the page they already have. All four
statuses are now reachable, which retires the defect
[SPEC-0049](specs/spec-proposal-request-intake.md) recorded.

**No public surface was opened.** Intake is still signed-in students and
instructors, and discovery, voting, following, comments, moderation, revision
history, attachments, duplicate detection, AI assistance, search, an API, and
every form of notification remain unbuilt and unauthorized. Seven of the twelve
product decisions in §15 are still open, and the outcome now has a number
somebody can measure rather than a baseline nobody had.

### 1. Executive Summary

The Public Feature Request and Core Team Development Platform enables public
users to submit structured feature proposals, describe the problem they are
experiencing, suggest possible solutions, and participate in a transparent
product-development process.

The platform provides a controlled workflow for collecting, validating,
prioritizing, deciding, planning, implementing, releasing, and reviewing
proposals. Users can search existing requests, support and follow proposals,
provide additional information, and receive status updates. The core team can
evaluate user value, technical feasibility, business alignment, security,
resources, dependencies, and product strategy.

Unlike a basic feedback form, M13 creates a traceable collaboration boundary
between public users and the development team while keeping internal notes,
sensitive evidence, security reports, and consequential product decisions
properly protected.

### 2. Problem framing and outcome

#### Affected users and current gap

- **Public users** may discover product limitations, workflow difficulties, or
  opportunities but lack a reliable channel to submit and follow them.
- **Proposal authors** need guidance for describing the problem, affected
  users, workaround, and expected outcome rather than only naming a feature.
- **Moderators** need to remove spam, confidential information, abuse, and
  duplicate or unsafe content before it becomes public evidence.
- **Product owners** need comparable evidence and a documented decision path.
- **Technical reviewers** need a place to record feasibility, architecture,
  security, privacy, performance, and operational concerns.
- **Developers and users** need a durable connection between a proposal,
  roadmap item, implementation state, release, and post-release learning.

The current baseline for proposal volume, valid-submission rate, duplicate
rate, time to first review, decision latency, author satisfaction, and the
number of requests arriving through other channels is **TBD**. Discovery must
establish the baseline before a delivery target is accepted.

#### Proposed primary outcome

Increase the proportion of valid feature proposals that receive an auditable
triage decision and an author-visible explanation within the agreed evaluation
window.

**Data source:** proposal submission, moderation, review, decision, status,
notification, and author-response events.

**Target and evaluation window:** TBD by the Product Owner and Data owner after
baseline collection.

**Guardrails:**

- Votes and follower counts remain community evidence and never automatically
  set roadmap priority.
- Internal notes, personal information, confidential company data, and
  security disclosures are never exposed through public pages or search.
- Moderation, review, and notification workloads remain within agreed service
  and staffing limits.
- Public status and release claims are linked to durable records and are not
  presented as commitments before human approval.
- Spam, bot voting, harassment, duplicate noise, and unauthorized state changes
  remain within agreed limits.

#### Non-goals for the first increment

- Fully autonomous approval, rejection, prioritization, or roadmap placement
- Treating popularity as a substitute for Product Owner judgment
- Public disclosure of confidential security vulnerabilities; those require a
  separate private reporting path
- Replacing the repository's external-feature-proposal intake and human triage
  policy with an untrusted public workflow
- Building a full project-management or issue-tracking product before the
  proposal-to-decision boundary is validated
- Sending proposal content to an AI provider before data-use and provider
  decisions are approved

### 3. Vision

Create a transparent, community-driven product-development ecosystem where
public users contribute evidence, the core team makes informed decisions, and
approved improvements create meaningful value for users, the organization, and
the wider community.

### 4. Objectives

- Allow public users to submit structured feature proposals.
- Capture real problems, affected users, workarounds, and expected outcomes.
- Provide transparent moderation, review, decision, and status workflows.
- Let the community discuss, support, and follow proposals constructively.
- Help the core team identify high-value product improvements.
- Connect approved proposals to roadmap items and development work.
- Track progress from submission through release and outcome review.
- Reduce duplicate and incomplete requests.
- Improve communication between users and the development team.
- Preserve reusable product-discovery evidence and decisions.
- Support future AI-assisted analysis without delegating human decisions.

### 5. Business philosophy

M13 applies Japanese management principles to create a disciplined,
user-centered, and continuously improving development process.

#### 5.1 Kaizen (改善) — Continuous Improvement

Every proposal is an opportunity to improve the product incrementally through
feedback, delivery, measurement, and follow-up learning.

#### 5.2 Genchi Genbutsu (現地現物) — Go and See

The core team should understand the actual user situation through examples,
screenshots, workflows, interviews, and observation before selecting a
solution.

#### 5.3 Hitozukuri (人づくり) — Developing People

The platform helps users write clearer requirements and develops product,
moderation, technical-review, and community-collaboration skills.

#### 5.4 Monozukuri (ものづくり) — Craftsmanship and Quality

Approved features require clear acceptance criteria, technical design, tests,
documentation, security review, and post-release quality monitoring.

#### 5.5 Sanpō Yoshi (三方よし)

| Stakeholder | Benefit |
| --- | --- |
| Public user | Better product experience and transparent communication |
| Core team | Clearer requirements, evidence, and prioritization context |
| Organization | Stronger product value, trust, and user engagement |

#### 5.6 Omotenashi (おもてなし)

The proposal experience should be simple, respectful, accessible, transparent,
and supportive, with clear status explanations and timely communication.

#### 5.7 Hansei (反省) — Reflection and Learning

After release, the team compares expected and actual outcomes, records lessons,
and updates standards, policies, and follow-up work.

### 6. Business process

```text
Public User
      │
      ▼
Search Existing Feature Requests
      │
      ├── Existing Request Found
      │         │
      │         ▼
      │     Vote / Comment / Follow
      │
      └── No Existing Request
                │
                ▼
       Create Feature Proposal
                │
                ▼
       Submit for Initial Review
                │
                ▼
       Moderation and Validation
                │
                ▼
       Product Team Assessment
                │
                ▼
       Technical Team Assessment
                │
                ▼
       Core Team Decision
                │
        ┌───────┼─────────┬──────────┐
        ▼       ▼         ▼          ▼
   Approved  Rejected  Duplicate  Need Info
        │                            │
        ▼                            ▼
 Add to Roadmap              User Updates Proposal
        │                            │
        ▼                            └──────► Review
 Development Planning
        │
        ▼
 Implementation → Testing → Release
        │
        ▼
 Public Notification → Outcome Review
```

### 7. Proposal lifecycle

#### 7.1 Proposal statuses

The detailed lifecycle is proposed as:

- Draft
- Submitted
- Under Moderation
- Needs Information
- Under Product Review
- Under Technical Review
- Community Review
- Approved
- Planned
- In Development
- In Testing
- Released
- Rejected
- Duplicate
- Deferred
- Archived

The implementation must distinguish public status from internal workflow state
when revealing review notes or pending actions. A public status change requires
an authorized actor, a durable history entry, and a public explanation when
policy requires one.

#### 7.2 Status definitions

| Status | Description |
| --- | --- |
| Draft | Proposal is not yet submitted |
| Submitted | Proposal is waiting for initial review |
| Under Moderation | Content and submission quality are being checked |
| Needs Information | Additional details are required from the author |
| Under Product Review | Product value, user impact, and alignment are assessed |
| Under Technical Review | Feasibility, risks, dependencies, and effort are assessed |
| Community Review | Proposal is open for permitted public feedback |
| Approved | Proposal is accepted in principle, not necessarily scheduled |
| Planned | Proposal is connected to an approved roadmap item |
| In Development | Development work has started |
| In Testing | Feature is undergoing quality assurance or user testing |
| Released | Feature is available to users |
| Rejected | Proposal will not be implemented under the current decision |
| Duplicate | Proposal is linked to a primary request |
| Deferred | Proposal may be reconsidered later |
| Archived | Proposal is no longer active or visible in the active workflow |

### 8. Functional requirements

#### 8.1 Public feature proposal submission

Registered public users can create a proposal containing:

- Title and summary
- Current problem and workaround
- Proposed solution
- Expected outcome
- Affected users
- User and business value
- Example use case
- Product area and category
- Optional screenshots, documents, and external references
- Visibility preference and contact permission

Submission guidance must explain that a proposal is evidence for review, not a
delivery promise. The form must warn users not to submit passwords, access
keys, private identity documents, confidential company information,
proprietary source code, or sensitive security vulnerabilities.

#### 8.2 Required proposal fields

| Field | Type | Required |
| --- | --- | ---: |
| Title | String | Yes |
| Summary | Text | Yes |
| Problem statement | Structured text | Yes |
| Proposed solution | Structured text | Yes |
| Expected outcome | Structured text | Yes |
| Affected users | Text | Yes |
| Product area | Controlled value | Yes |
| Category | Controlled value | Yes |
| Current workaround | Text | No |
| Use case or evidence | Structured text | No |
| Attachments | Active Storage | No |
| Visibility | Controlled value | Yes |
| Contact permission | Boolean | Yes |

The exact rich-content format, maximum lengths, and public/private fields are
specification decisions, not implementation guesses.

#### 8.3 Categories and product areas

Initial categories may include:

- New Feature
- Feature Improvement
- User Experience
- Accessibility
- Performance
- Integration
- Reporting
- Security
- Administration
- Mobile Experience
- API
- Documentation
- Artificial Intelligence
- Other

Initial product areas may include Public Website, User Account, Company
Portal, Student Portal, Faculty Portal, Administration, Business Case
Platform, Internship Platform, Technical Blog Platform, Notifications,
Search, Reporting, and API/Integrations.

The Product Owner owns the taxonomy and may change it only with a migration or
compatibility decision when historical reports depend on it.

#### 8.4 Existing proposal search and duplicate prevention

Before submission, users should be able to search existing public proposals by:

- Keyword
- Category
- Product area
- Status
- Most supported
- Recently submitted
- Recently released

The system may suggest similar proposals while a user writes a title or
description. Similarity suggestions are advisory. A human moderator or core
team member must decide whether two proposals are duplicates.

Duplicate handling should support:

- Selecting a primary proposal
- Recording the duplicate reason
- Redirecting users to the primary proposal
- Preserving the original record and audit history
- Transferring votes or followers only under an approved policy

#### 8.5 Voting

Authenticated users may support public proposals with:

- At most one active vote per user per proposal
- Vote removal
- Vote count and permitted history
- Abuse and automation prevention
- Notifications for important changes where the user opted in

Votes provide community context but do not determine priority, approval,
security risk acceptance, or release timing.

#### 8.6 Comments and discussion

The discussion workflow may support:

- Comments and replies
- Mentions where identity and notification policy allow
- Supporting information and permitted attachments
- Helpful-comment signals
- Inappropriate-content reports
- Core-team response indicators
- Discussion locking and moderation history

Public comments must be sanitized, rate-limited, and governed by a moderation
policy. Internal notes must use a separate authorization boundary.

#### 8.7 Follow and subscription

Users can follow proposals without voting. Followers may receive:

- Status changes
- Core-team responses
- Requests for information
- Roadmap assignment
- Development start
- Testing or beta availability
- Release and outcome updates

Notification consent, channel, frequency, unsubscribe, and retention rules
must be explicit.

#### 8.8 Proposal editing and revision history

Authors can:

- Edit drafts
- Respond when information is requested
- Add supporting material
- Correct inaccurate information
- Withdraw a proposal where policy allows
- View their revision history and status history

Submitted content must preserve revision and author identity. Changes that
affect the product problem, intended outcome, visibility, or safety require a
new review decision rather than silently changing the previously assessed
record.

#### 8.9 Moderation

Moderators can:

- Review new proposals and comments
- Remove personal or confidential information
- Request clarification
- Reject spam or abusive content
- Merge duplicate requests
- Lock discussions
- Suspend abusive accounts within policy
- Record moderation reasons and affected content

Moderation must not approve a roadmap item or accept technical risk. It only
determines whether content is safe and suitable for the next review boundary.

#### 8.10 Product and technical review

The product review records:

- Problem clarity
- Affected-user evidence
- User and business value
- Strategic alignment
- Product fit
- Alternatives and non-feature options
- Accessibility impact
- Expected outcome and guardrails
- Opportunity cost and priority rationale

The technical review records:

- Feasibility and architecture impact
- Data-model and migration impact
- Security and privacy risks
- Performance and operational impact
- Integration and dependency requirements
- Maintenance cost and testing needs
- Technical recommendation and unresolved questions

Review records must name the human owner, status, date, and scope. AI may
organize evidence or suggest questions but cannot complete or accept the
human-owned decision.

#### 8.11 Core-team decision and roadmap integration

Authorized core-team members can decide to:

- Approve in principle
- Reject with a public explanation where policy requires it
- Defer
- Request more information
- Merge with another proposal
- Add to a research backlog
- Create a limited experiment
- Add to a roadmap item
- Release as a beta feature

An approved proposal can link to one or more roadmap or backlog records, but a
proposal must not mutate `docs/backlog.json` or change milestone priority
without the repository's normal human Product Owner decision and traceability
gate.

#### 8.12 Development and release tracking

Public updates may show:

- Roadmap connection
- Responsible owner or team, where public disclosure is appropriate
- Current development state
- Testing or beta state
- Release date and release notes
- Post-release feedback and outcome summary

Internal implementation tasks, private risks, credentials, security findings,
and confidential dependencies remain restricted. Public progress must be linked
to a durable development or release record so status does not become stale.

#### 8.13 Dashboards and reporting

The core-team dashboard should expose:

- New submissions and moderation queue
- Proposals needing author information
- Product and technical review workload
- Duplicate candidates
- Supported proposals
- Approved but unplanned proposals
- Proposals in development, testing, and recently released
- Moderation reports and unresolved safety issues
- Decision and review-time metrics

The public-user dashboard should include:

- My proposals and drafts
- Requests requiring updates
- Followed and supported proposals
- Proposal notifications
- Released proposals
- Saved searches where the account model permits them

### 9. User roles and authorization

#### Public visitor

- View public proposals, status, public discussions, and released features
- Search public content

#### Registered public user

- Create proposals and edit owned drafts
- Submit proposals
- Vote, follow, comment, and report inappropriate content
- Upload permitted supporting materials

#### Proposal author

- Respond to information requests
- Update a proposal within revision rules
- View proposal and decision history
- Receive permitted core-team communication

#### Moderator

- Review submitted content
- Request clarification and manage reports
- Remove sensitive data, moderate discussions, merge duplicates, and lock
  threads

#### Product Owner or Product Manager

- Conduct product assessments
- Set product area and product priority
- Publish public decisions
- Connect approved proposals to roadmap items

#### Technical Reviewer

- Conduct feasibility and risk assessments
- Record dependencies, estimates, and recommendations
- Review architecture, security, privacy, testing, and operations impact

#### Developer

- View assigned proposals
- Link approved proposals to development work
- Record implementation progress and technical notes within the allowed scope

#### Core-team administrator

- Manage roles, categories, product areas, workflow configuration, reports,
  audit access, and moderation policy

The repository currently maps student and instructor accounts to the narrow
contributor intake and uses the existing admin boundary. Whether public users
need a new account class, whether students/instructors retain proposal access,
and how product, technical, and moderation roles are represented are product
and authorization decisions.

### 10. Public and internal proposal views

#### Public proposal page

Where visibility permits, a public page may display:

- Title, summary, author display name, and submission date
- Current public status
- Product area and category
- Problem, proposed solution, and expected outcome
- Approved attachments
- Vote and follower counts
- Public core-team response
- Roadmap connection and public development progress
- Release information and public comments
- Public revision or status history

#### Internal core-team view

Authorized team members may additionally view product and technical
assessments, private contact information, internal notes, security/privacy
flags, moderation evidence, and operational workload. Internal information
must never leak through public search, counters, exports, API responses, or
notifications.

### 11. Technical architecture

M13 must extend the existing application boundary, external-feature-proposal
governance, and current proposal intake. It must not introduce a parallel
authentication, authorization, storage, notification, or job-processing stack.

**Framework**

- Ruby on Rails 8.1.3

**Database**

- PostgreSQL

**Authentication**

- Existing `has_secure_password` authentication, signed Session records, and
  cookies for registered users
- The public visitor and account-registration boundary requires a product and
  privacy decision

**Authorization**

- Existing role-based authorization concern
- Extended with proposal ownership, visibility, assignment, moderation,
  product-review, technical-review, and core-team decision rules

**Storage**

- Active Storage for approved screenshots and documents, subject to file-type,
  size, malware scanning, access, retention, and deletion policies

**Background jobs and notifications**

- Solid Queue for notification, indexing, moderation-support, and reminder work
- Existing in-app Notification records and Turbo refresh
- Action Mailer only after the production email provider and credential owner
  are approved

**Frontend and content**

- Hotwire / Turbo
- Stimulus
- Tailwind CSS
- A structured content format must be selected for proposal fields,
  sanitization, revision rendering, and accessible display

**Search**

- PostgreSQL full-text search for the first increment
- Elasticsearch, OpenSearch, or another service only after an ADR demonstrates
  the need and documents cost, privacy, operations, and ownership

**API**

- A versioned REST API foundation may expose approved public proposal,
  discussion, status, and feedback resources
- Internal assessments, moderation evidence, and private author data require
  separate authorization and must not be exposed by default

**Anti-abuse controls**

- Rate limiting, CAPTCHA or equivalent bot protection, spam detection, and
  duplicate-vote controls require an explicit provider and operating decision

### 12. Data model

#### Existing records to reuse or evaluate

- `users` and existing student, instructor, and admin roles
- `proposal_requests` as the current narrow intake boundary, subject to an ADR
  deciding whether to extend, migrate, or adapt it into the public proposal
  domain
- `notifications` for in-app events
- `sessions` for authentication
- `audit_events` for durable administrative history
- Active Storage records for attachments
- `docs/roadmap.md` and `docs/backlog.json` as governed planning records, not
  arbitrary mutable application rows

The current `proposal_requests` record must not be silently presented as the
complete M13 model. Existing data ownership, status values, author role rules,
privacy, and migration behavior require an explicit data-model decision.

#### Proposed proposal-domain records

- `feature_proposals` or an explicitly extended `proposal_requests`
- Proposal revisions
- Proposal categories and product areas
- Proposal votes and followers
- Proposal comments and comment moderation records
- Proposal reviews and review assignments
- Product assessments
- Technical assessments
- Proposal decisions
- Duplicate relations
- Proposal status histories
- Roadmap or backlog links
- Development updates and release links
- Moderation reports

The final model must enforce one active vote per user/proposal, one active
follow per user/proposal, valid state transitions, author and reviewer
ownership, public/private boundaries, duplicate relationships, and durable
decision history at the database and application layers where appropriate.

### 13. Milestone M13 deliverables

- Public Feature Proposal Portal
- Structured Proposal Submission and Draft Management
- Existing Proposal Search and Similarity Suggestions
- Duplicate Review and Primary-Proposal Linking
- Voting and Following
- Public Discussion and Moderation Workflow
- Proposal Revision and Status History
- Product Review Workspace
- Technical Review Workspace
- Information Request and Author Response Workflow
- Core-Team Decision Workflow
- Roadmap and Backlog Traceability
- Development, Testing, Release, and Outcome Updates
- Public User and Core-Team Dashboards
- Notification Center
- Secure role-, ownership-, and visibility-based access control
- Audit, privacy, anti-spam, and file-security foundations
- Versioned REST API foundation
- Instrumentation for the primary outcome and guardrails

### 14. Dependencies and sequencing

M13 depends on:

1. The existing identity, session, storage, notification, and audit services.
2. A decision about the current `proposal_requests` intake and public-account
   boundary.
3. A human-owned moderation, privacy, copyright, retention, and public-content
   policy.
4. Product Owner and core-team ownership for product and technical decisions.
5. A roadmap/backlog traceability rule that preserves repository lifecycle
   gates and does not let public input approve work automatically.
6. An approved notification provider and credential owner if email updates are
   included in the first increment.

The recommended first vertical slice is:

```text
Registered public user → structured proposal → moderation → product triage
→ author-visible decision and status history
```

Community voting, following, discussion, duplicate consolidation, technical
assessment, roadmap links, development progress, release updates, and outcome
review should follow after the proposal-to-decision boundary is validated.
AI-assisted duplicate detection, summarization, classification, and acceptance
criteria generation are future experiments and are not required for the core
M13 workflow.

### 15. Product decisions required before scheduling

1. Whether M13 is for registered public users only or permits anonymous
   submission, and how verification, contact permission, and account deletion
   work.
2. How the current `proposal_requests` model and signed-in student/instructor
   intake will evolve without losing existing records or changing access
   unexpectedly.
3. Which proposal fields are public, author-only, reviewer-only, or internal,
   and which attachments may be downloaded.
4. The public lifecycle, internal workflow states, status transition owners,
   and explanation policy for approval, rejection, deferral, and duplicates.
5. Whether votes and followers are available to all registered users, and the
   anti-bot, abuse, identity, and privacy rules governing them.
6. Comment moderation, reporting, discussion locking, author contact, and
   account-suspension policy.
7. The required Product Owner, Technical Reviewer, Moderator, Developer, and
   Core-Team Administrator roles and their mapping to existing accounts.
8. How proposals link to `docs/roadmap.md`, `docs/backlog.json`, ADRs, specs,
   development tasks, releases, and outcome reports without bypassing human
   approval gates.
9. The private workflow for security vulnerabilities and other confidential
   reports that must not use public proposals.
10. Search, rich-content, attachment, notification, CAPTCHA/rate-limit, and
    API-provider decisions.
11. The primary outcome, baseline, target, guardrails, and evaluation window.
12. Whether AI assistance may analyze public proposals, what data may be sent
    to a provider, and how recommendations are attributed, disabled, and
    reviewed.

### 16. Definition of done

M13 is complete only when:

- Eligible public users can create, submit, and track proposals.
- Users can search existing proposals before submission.
- Authenticated users can vote, follow, comment, and report content according
  to the approved policy.
- Moderators can review, sanitize, merge, lock, and explain moderation actions.
- Product and technical reviewers can record their assessments independently.
- Authorized core-team members can approve, reject, defer, request information,
  or mark duplicates with durable reasons.
- Approved proposals can link to roadmap and development records without
  bypassing repository gates.
- Public development, testing, release, and outcome statuses are current and
  appropriately scoped.
- Notifications respect consent and do not leak private information.
- Authorization, anti-abuse, file, privacy, and audit controls are tested.
- User documentation and moderation guidance are available.
- Automated verification passes and a human Product Owner accepts the outcome.

### 17. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| High volume of low-quality requests | Submission guidance, moderation, rate limits, and scoped intake |
| Duplicate proposals | Search, similarity suggestions, human duplicate decisions, and preserved history |
| Popularity replaces product strategy | Treat votes as evidence, not automatic priority |
| Users expect every request to be built | Publish review states, decision explanations, and non-commitment language |
| Public content contains confidential data | Warnings, sanitization, private reporting, restricted attachments, and removal policy |
| Discussions become abusive or unproductive | Reporting, moderation, rate limits, locking, and account controls |
| Development status becomes stale | Named status owner, durable links, reminders, and outcome review |
| Internal decisions leak | Separate public explanations from internal notes, exports, and API fields |
| Scope expands into a full project tracker | Thin vertical slices, explicit non-goals, and roadmap traceability |
| AI recommendations create hidden decisions | Human approval, provenance, disablement, evaluation, and audit |

### 18. Long-term vision

The Public Feature Request and Core Team Development Platform will become the
central product-improvement channel for the UTCC AI Academy ecosystem.

Public users will contribute ideas, explain real problems, participate in
constructive discussion, and follow approved proposals from submission through
release. The core team will gain reliable evidence for product discovery,
technical assessment, prioritization, implementation, and outcome review.

Together with the Company Business Case Platform, Student Internship Request
Platform, and Technical Blog Translation Platform, M13 will strengthen the
Industry–University Collaboration Ecosystem and establish a transparent,
community-driven foundation for sustainable product development.

### 19. Integration with the consolidated roadmap

- **Existing external proposal governance:** The repository's External Feature
  Proposal template remains the intake and triage pattern for untrusted
  external requests. M13 may provide a public product surface, but it must not
  turn public content into approved backlog work automatically.
- **Current proposal intake:** The existing `proposal_requests` flow is an
  early foundation for a narrow signed-in contributor experience. M13 must
  preserve its useful evidence and decide explicitly whether to extend,
  migrate, or adapt it.
- **UTCC Academy identity:** Reuse existing users, signed sessions, account
  recovery, and role boundaries unless a human-approved public-account decision
  establishes a new boundary.
- **UTCC Academy platform services:** Reuse Active Storage, audit events,
  in-app notifications, Action Mailer, and the existing authorization concern.
- **Company Business Case Platform M10:** Company-authored requests or
  business-case feedback may inform public proposals, but confidential company
  data, intellectual property, and partner identities require explicit consent.
- **Student Internship Request Platform M11:** Student or faculty feedback may
  become a proposal, but private internship records, evaluations, and student
  work must not become public evidence without authorization.
- **Technical Blog Translation Platform M12:** Technical content issues may be
  proposed through M13, while source content, translation drafts, reviewer
  notes, and provider data remain governed by M12's content and privacy rules.
- **AI Recruitment Platform:** This M13 is separate from AI Recruitment
  Platform M13 Analytics and Reporting. Shared proposal, product, user, and
  outcome data require a future cross-track data-model decision.
- **M13 naming:** Milestone IDs are track-scoped. This M13 must not be added to
  the current UTCC Academy backlog or treated as an accepted product priority
  until its Product Owner, core-team owner, Technical Reviewer, Moderator,
  Security or Privacy owner, and repository owner approve the scope.

Before execution, M13 requires a problem baseline, primary outcome and
guardrails, a public-account and role decision, a moderation and confidential-
reporting policy, a `proposal_requests` migration or boundary ADR, a public
content and retention policy, anti-abuse and notification decisions, and a
specification covering proposal fields, visibility, revisions, status
transitions, votes, follows, comments, duplicate handling, assessments,
roadmap links, release updates, audit events, and human approval gates.

#### Milestone M14 — Core Team Internal Work Dashboard

M14 is scoped to this roadmap track. It provides a private internal execution
surface for decisions and work that may originate from M13, while preserving
the repository's Markdown lifecycle records and Slack policy. It does not
replace UTCC Academy M10 Academic Writing, Company Business Case Platform M10,
Student Internship Request Platform M11, Technical Blog Translation Platform
M12, Public Feature Request Platform M13, or AI Recruitment Platform M14
Notifications and Communication.

**Status:** Proposal — not implemented

**Access:** Core Team Only

The repository already contains Markdown-based roadmap, backlog, decision,
specification, release, runbook, and outcome records, plus a policy that keeps
Slack as an engagement and notification layer rather than the system of record.
It does not yet provide a private application dashboard for projects,
milestones, Markdown work items, assignments, review queues, revisions, and
approved Slack links. M14 describes that proposed capability and requires
Product Owner, Engineering Manager, core-team, security/privacy, platform,
and Slack-workspace-owner review before execution.

### 1. Executive Summary

The Core Team Internal Work Dashboard is a private collaboration platform for
planning, documenting, assigning, discussing, and monitoring internal work
using Markdown-based records and governed Slack integration.

The dashboard can organize product requirements, development tasks, technical
notes, decisions, meeting records, incidents, release plans, and team updates
into projects and milestones. Team members can assign owners and reviewers,
track status, preserve revisions, and connect relevant Slack discussions to a
durable work record.

Slack remains useful for fast conversation, questions, alerts, and coordination.
The dashboard and repository preserve confirmed requirements, decisions,
ownership, acceptance criteria, release evidence, and long-term knowledge.
Slack messages must not approve work, change lifecycle state, or become a
permanent record without an authorized review and durable link.

### 2. Problem framing and outcome

#### Affected users and current gap

- **Core team members** need one view of assigned work, active projects,
  blockers, reviews, and next actions.
- **Product owners** need a structured link between requirements, decisions,
  roadmap items, implementation, release, and outcome review.
- **Technical leads and reviewers** need versioned Markdown designs, review
  evidence, dependencies, and approval history.
- **Engineering managers** need visibility into WIP, ownership, capacity,
  blocked work, and review load.
- **New team members** need searchable historical context without reconstructing
  decisions from Slack history.

The current baseline for work scattered across Slack and other tools, owner
clarity, decision-retrieval time, stale-status rate, review latency, WIP,
notification volume, and onboarding time is **TBD**. Discovery must establish
these measures before a delivery target is accepted.

#### Proposed primary outcome

Increase the proportion of active core-team work that has a current owner,
status, next action, and linked durable record by the agreed review date.

**Data source:** work-item creation, assignment, status, revision, review,
blocker, decision, Slack-link, and repository-lifecycle events.

**Target and evaluation window:** TBD by the Product Owner, Engineering
Manager, and Data owner after baseline collection.

**Guardrails:**

- Private work, credentials, security findings, personal information, and
  confidential partner data remain restricted to authorized team members.
- Slack volume, notification fatigue, and duplicate records do not materially
  increase.
- Dashboard records link to the repository lifecycle artifacts and do not
  bypass human approval, release, security, or outcome gates.
- Every active work item has one accountable owner, while review and approval
  remain distinct responsibilities where the risk tier requires it.
- The dashboard remains usable when Slack or an external integration is
  unavailable.

#### Non-goals for the first increment

- Replacing the repository as the durable lifecycle source of truth
- Treating Slack as a database, approval system, or authoritative status source
- Building a general-purpose public project-management or issue-tracking
  product
- Automatically converting Slack messages, comments, or AI summaries into
  accepted requirements or decisions
- Adding a new authentication, authorization, job, or storage stack
- Exposing internal work to public users, companies, students, or external
  integrations by default

### 3. Vision

Create a simple, private, and transparent internal operating system where the
core team manages work through structured Markdown records while continuing to
collaborate naturally through Slack.

### 4. Objectives

- Create a central private dashboard for core-team work.
- Use Markdown as a portable format for requirements and documentation.
- Connect Slack discussions with permanent, authorized work records.
- Organize work by project, milestone, type, status, and priority.
- Assign one clear owner and an appropriate reviewer.
- Track work from planning through completion, release, and learning.
- Preserve technical and product knowledge for future team members.
- Improve visibility across the core team and expose blockers earlier.
- Reduce duplicated communication without increasing notification volume.
- Provide a foundation for future AI-assisted work organization with human
  review.

### 5. Guiding principle

#### Slack for conversation, dashboard and repository for record

Slack is used for:

- Fast communication and questions
- Team discussion and immediate coordination
- Alerts that link to a durable record
- Short progress signals with an owner and next action

The dashboard or repository is used for:

- Confirmed requirements and acceptance criteria
- Assigned work and milestones
- Technical designs and decision records
- Meeting decisions and incident records
- Release plans, evidence, and outcome reports
- Long-term searchable knowledge

A Slack conversation becomes part of the durable record only when an authorized
team member links it, summarizes its decision in the appropriate artifact, or
converts it into a draft work item for review. This preserves the repository
policy that Slack is an engagement layer, not an approval system.

### 6. Business philosophy

#### 6.1 Kaizen (改善) — Continuous Improvement

Record improvement ideas, review completed work, identify process problems,
create follow-up actions, and update templates and standards.

#### 6.2 Kanban (看板) — Visual Work Management

Make backlog, ready, in-progress, review, blocked, testing, and completed work
visible without treating a board column as the durable decision record.

#### 6.3 Genchi Genbutsu (現地現物) — Go and See

Attach screenshots, logs, reproduction steps, affected source references, user
workflows, and evidence so decisions reflect actual behavior.

#### 6.4 Hitozukuri (人づくり) — Developing People

Share technical knowledge, assign reviewers and mentors, record learning notes,
and maintain onboarding documentation.

#### 6.5 Monozukuri (ものづくり) — Craftsmanship and Quality

Define acceptance criteria, technical review, testing requirements, code-review
evidence, and release documentation before work is considered complete.

#### 6.6 Omotenashi (おもてなし) — Thoughtful Collaboration

Provide clear ownership, useful notifications, accessible documents, simple
Markdown editing, respectful review, and low-friction asynchronous work.

#### 6.7 Hansei (反省) — Reflection

Use milestone retrospectives, incident reviews, release reviews, lessons
learned, and owned follow-up actions to improve the way the team works.

### 7. Internal work process

```text
Core Team Member
       │
       ▼
Create Markdown Work Item
       │
       ▼
Define Problem and Outcome
       │
       ▼
Assign Owner and Reviewer
       │
       ▼
Add to Project or Milestone
       │
       ▼
Discuss Through Slack
       │
       ▼
Record Decision in Dashboard or Repository
       │
       ▼
Move to Development
       │
       ▼
Implementation and Review
       │
       ▼
Testing and Release Evidence
       │
       ▼
Complete Work and Publish Link
       │
       ▼
Capture Lessons Learned
```

### 8. Functional requirements

#### 8.1 Internal dashboard

The dashboard should display:

- My assigned work
- Work requiring review
- Blocked work
- Active projects and milestones
- Recent decisions and revisions
- Recent authorized Slack-linked activity
- Upcoming releases
- Open incidents
- Team announcements
- Recently updated documents

All views must enforce the core-team-only visibility boundary and distinguish
draft, accepted, and published lifecycle artifacts.

#### 8.2 Project and milestone management

Authorized core-team members can:

- Create projects and define objectives
- Assign project owners and add permitted members
- Create milestones and completion criteria
- Connect related public proposals, roadmap items, repositories, ADRs, specs,
  releases, runbooks, incidents, and outcome reports
- Connect an approved Slack channel without copying all channel history
- Track status and archive completed projects

Proposed project states are **Proposed**, **Planning**, **Active**, **On Hold**,
**Completed**, and **Archived**. Milestones do not require a fixed duration
unless an explicit schedule is approved.

#### 8.3 Markdown work items

Every work item uses Markdown as its primary content format and may include:

- Headings, paragraphs, lists, checklists, tables, code blocks, and quotes
- Sanitized links and images
- Supported diagrams and references
- User mentions within the internal authorization boundary
- Links to related work items and lifecycle artifacts
- Attachments subject to file-security rules

Work item types may include Product Requirement, Feature, Task, Technical
Design, Bug, Improvement, Research, Decision Record, Meeting Note, Incident,
Release Plan, Retrospective, Documentation, and Announcement.

Each type may use an approved Markdown template. The first release should
prioritize Product Requirement, Task, Technical Design, Decision Record,
Meeting Note, Incident, and Release Plan templates.

#### 8.4 Work item fields and states

| Field | Type | Required |
| --- | --- | ---: |
| Title | String | Yes |
| Item type | Controlled value | Yes |
| Markdown content | Text | Yes |
| Project | Reference | No |
| Milestone | Reference | No |
| Parent item | Reference | No |
| Owner | User reference | Yes |
| Reviewer | User reference | No |
| Priority | Controlled value | Yes |
| Status | Controlled value | Yes |
| Due date | Date | No |
| Slack link | Reference | No |
| Repository reference | Link or artifact reference | No |
| Visibility | Controlled value | Yes |
| Created by | User reference | Yes |

The proposed work states are **Draft**, **Backlog**, **Ready**, **In Progress**,
**Blocked**, **In Review**, **In Testing**, **Ready for Release**,
**Completed**, **Cancelled**, and **Archived**. State transitions require an
authorized actor and a history entry.

Priority may be **Urgent**, **High**, **Medium**, **Low**, or **Research**.
Priority is based on product impact, operational risk, dependency, and team
capacity; it is not assigned by message volume alone.

#### 8.5 Assignment, dependencies, and work views

The dashboard should support:

- One accountable work owner
- Optional reviewer and approval owner
- Parent/child work relationships
- Explicit dependencies and blockers
- Due dates and reminders
- Kanban, list, my-work, review-queue, and blocked-work views
- Filters by project, milestone, owner, reviewer, priority, type, label, and
  due date

The board is a view over durable work records. Dragging a card must not bypass
required review, approval, migration, or release gates.

#### 8.6 Review, approval, and version history

Documents requiring review may include product requirements, technical designs,
architecture decisions, security decisions, release plans, and incident
reports.

Review actions include:

- Request review
- Add review comments
- Request changes
- Approve or reject within the review scope
- Record the approval date and actor
- Lock the approved version

Every Markdown document should preserve prior content, author, date, change
summary, approval state, and a diff between versions. Approved documents are
updated through a new revision instead of silently replacing the accepted
version.

#### 8.7 Comments and mentions

Team members can comment, reply, mention authorized teammates, resolve
discussion threads, convert a comment into a draft task, and link a comment to
a Markdown section. Important decisions belong in the main Markdown content or
a dedicated decision record, not only in comments.

#### 8.8 Slack workspace and message integration

Authorized administrators can connect an approved Slack workspace and map
selected channels and team identities. The integration may support:

- Workspace and channel identification
- User identity mapping
- Permission configuration
- Integration status and audit history
- Links to Slack messages or threads
- Optional Markdown summaries written by a team member

The dashboard may publish selected updates to Slack, but each message should
contain only the appropriate title, state, owner, short summary, durable link,
and next action. It must not expose private notes, credentials, security
details, or unnecessary personal data.

Slack cannot approve, reject, release, or change an authoritative lifecycle
state by itself. Slack actions are untrusted input and must use the same
authorization and audit checks as dashboard actions.

#### 8.9 Convert Slack discussion to work item

Authorized team members may:

1. Select a Slack discussion or thread.
2. Choose a work item type.
3. Add a clear title and Markdown summary.
4. Assign an owner and optional reviewer.
5. Select a project or milestone.
6. Save a draft work item for normal review.

The conversion must never treat a raw Slack message as an accepted
requirement, decision, incident, or release record without the required human
review.

#### 8.10 Notifications

Team members may configure assigned-work, review-request, mention, blocker,
milestone, release, incident, and daily/weekly summary notifications.

Notification controls must include consent where required, channel and
frequency preferences, deduplication, quiet periods, failure visibility, and
an operating owner. The system should minimize notification volume and follow
the repository Slack policy.

#### 8.11 Search and internal knowledge

The dashboard should search authorized content across:

- Work titles and Markdown
- Projects and milestones
- Decisions, meeting notes, technical designs, incidents, and releases
- Comments and labels
- Slack-linked summaries, not unrestricted Slack history
- Related repository lifecycle artifacts

Filters include type, status, owner, project, milestone, date, label, and
approval state. Search results must enforce the same private visibility rules
as direct pages and API responses.

### 9. Markdown templates

The first template set should include:

#### Product requirement

```markdown
# Requirement Title

## Background

## Problem

## Target Users

## Proposed Solution

## Expected Outcome

## Acceptance Criteria

- [ ] Criterion

## Risks

## Dependencies
```

#### Technical design

```markdown
# Technical Design

## Summary

## Current Architecture

## Proposed Architecture

## Data Model

## Security

## Testing Strategy

## Rollback Plan
```

#### Decision record

```markdown
# Decision

## Context

## Options Considered

## Decision

## Reason

## Consequences

## Decision Owner
```

#### Meeting note

```markdown
# Meeting Title

## Date

## Participants

## Discussion

## Decisions

## Action Items

- [ ] Action — Owner
```

#### Incident and retrospective

Templates should link to the repository's incident/postmortem and outcome
artifact rules rather than creating an ungoverned parallel record.

### 10. User roles and authorization

#### Core team member

- View authorized internal work
- Create work items and comments
- Link approved Slack discussions
- Update permitted status fields
- Search internal knowledge

#### Work owner

- Maintain assigned Markdown content
- Update status and priority within policy
- Complete acceptance criteria
- Request review and record progress

#### Reviewer

- Review assigned documents
- Add review comments
- Request changes
- Approve documents within the assigned scope

#### Project lead

- Create and manage projects and milestones
- Assign work and manage project priorities
- Approve project documentation within authority
- Publish project updates through governed links

#### Product Owner or Product Manager

- Manage product requirements and roadmap relationships
- Set product priority
- Approve requirement documents
- Connect approved public proposals without bypassing lifecycle gates

#### Technical Lead

- Approve technical designs and architecture decisions
- Assign technical reviewers
- Review security and operational impact

#### Administrator

- Manage users, roles, templates, workflows, integration settings, and audit
  access

Core-team-only access must be enforced server-side at page, record, attachment,
search, notification, export, webhook, and API boundaries. A Slack channel
membership alone does not grant dashboard access.

### 11. Technical architecture

M14 must extend the current application and repository governance; it must not
introduce a parallel authentication, authorization, storage, notification, or
job-processing stack.

**Framework**

- Ruby on Rails 8.1.3

**Database**

- PostgreSQL

**Authentication**

- Existing `has_secure_password` authentication, signed Session records, and
  cookies

**Authorization**

- Existing role-based authorization concern, extended with core-team
  membership, project membership, work ownership, reviewer scope, and
  administrator permissions

**Markdown processing**

- A CommonMark-compatible renderer selected through an ADR
- HTML sanitization, safe link handling, accessible rendering, and syntax
  highlighting for permitted code blocks

**Storage**

- Active Storage for approved attachments, subject to file-type, size,
  malware-scanning, access, retention, and deletion rules

**Background jobs and notifications**

- Solid Queue for indexing, reminders, notification fan-out, and integration
  work
- Existing in-app Notification records and Turbo refresh
- Action Mailer only after the production email provider and credential owner
  are approved

**Frontend**

- Hotwire / Turbo
- Stimulus
- Tailwind CSS

**Slack integration**

- Provider-independent Slack integration boundary
- OAuth or approved credential flow with encrypted secret storage
- Request-signature verification for inbound events
- Channel/user mapping and explicit publish permissions
- Integration disablement and recovery path

**Search**

- PostgreSQL full-text search for the first increment
- OpenSearch or another service only after an ADR demonstrates the operational
  need and assigns ownership

**API**

- Versioned REST API for approved internal resources
- API authorization and audit behavior equivalent to browser access
- Webhooks only for approved integrations with signature verification and
  replay protection

### 12. Data model

#### Existing records and artifacts to reuse

- `users`, `sessions`, and existing account recovery
- Existing role authorization concern and `audit_events`
- `notifications` for in-app events
- Active Storage records for attachments
- `docs/roadmap.md`, `docs/backlog.json`, decisions, specs, releases, runbooks,
  postmortems, and outcomes as governed lifecycle artifacts
- `docs/slack.md` as the Slack engagement, notification, and trust-boundary
  policy

The dashboard must link to repository artifacts rather than creating duplicate
accepted ADR, spec, release, runbook, postmortem, or outcome records without an
explicit boundary decision.

#### Proposed internal-work records

- `teams` or a core-team membership boundary
- `projects`
- `project_memberships`
- `milestones`
- `work_items`
- Work-item revisions
- Work-item assignments and dependencies
- Work-item comments and mentions
- Reviews and approvals
- Markdown templates
- Decision-record links
- Slack workspaces, channels, and message links
- Activity records, using existing audit events where sufficient
- Labels and notification preferences

The data-model ADR must define ownership, visibility, status transitions,
version locking, concurrency behavior, dependency cycles, Slack-link
retention, attachment access, and links to repository lifecycle IDs.

### 13. Milestone M14 deliverables

- Secure Core Team Dashboard
- Core-Team Membership and Role Management
- Project and Milestone Management
- Markdown Work Items and Templates
- Task, Checklist, Dependency, and Assignment Management
- Kanban, List, My Work, Review, and Blocked-Work Views
- Document Revision History and Version Comparison
- Review and Approval Workflow
- Decision, Meeting, Incident, Release, and Retrospective Links
- Governed Slack Workspace and Channel Integration
- Slack Message/Thread Linking
- Dashboard-to-Slack Link Publishing
- Draft Slack-to-Work-Item Conversion
- Internal Search and Knowledge References
- Notification Center and Preferences
- Activity History and Audit Logging
- Secure Attachment and Markdown Sanitization Controls
- Versioned REST API Foundation
- Instrumentation for the primary outcome and guardrails

### 14. Dependencies and sequencing

M14 depends on:

1. Existing core-team identity, role, session, storage, notification, and audit
   boundaries.
2. Repository lifecycle artifact ownership and the rule that Slack is not an
   approval or source-of-truth system.
3. A Product Owner and Engineering Manager decision on project, WIP, review,
   and ownership policy.
4. A core-team membership and access-revocation policy.
5. A Slack workspace owner, approved integration credentials, channel policy,
   and secret-custody decision.
6. A Markdown rendering, sanitization, attachment, retention, and search
   decision.

The recommended first vertical slice is:

```text
Authorized core-team member → create private Markdown work item
→ assign owner/reviewer → revise and review → searchable history
→ optional governed Slack link
```

Projects, milestones, Kanban views, Slack publishing, Slack-to-draft
conversion, notifications, and advanced search should follow after the private
work-item and revision/authorization boundary is validated. AI drafting,
summarization, task extraction, and risk analysis are future experiments and
are not required to prove M14.

### 15. Product decisions required before scheduling

1. Which users and roles constitute the core team, how membership is granted,
   and how access is revoked after role or employment changes.
2. Whether the dashboard is an application view over repository Markdown,
   stores private work items in the database, or uses a hybrid boundary.
3. Which artifacts must remain repository-native and which may be mirrored or
   linked from the dashboard.
4. The project, milestone, WIP, priority, dependency, and ownership policy.
5. The complete work-item state machine and which states require human review,
   approval, release, or outcome evidence.
6. The Markdown dialect, allowed extensions, sanitization rules, image and
   attachment handling, and version/concurrency behavior.
7. Whether work-item comments, mentions, and internal notes have separate
   retention or export rules.
8. The Slack workspace, channel allowlist, user identity mapping, OAuth or
   credential owner, webhook verification, and integration disablement path.
9. Which updates may be published to Slack and which data must never leave the
   dashboard or repository.
10. Notification channels, quiet hours, batching, escalation, and on-call
    handling for blocked work and incidents.
11. Search scope, indexing freshness, deletion behavior, and whether an
    external search service is justified.
12. API consumers, webhook consumers, data retention, and internal export
    policy.
13. The primary outcome, baseline, target, guardrails, and evaluation window.
14. Whether AI may process internal Markdown or Slack-linked summaries, what
    data can reach a provider, and how human review and provenance work.

### 16. Definition of done

M14 is complete only when:

- Authorized core-team members can access the private dashboard.
- Projects, milestones, work items, owners, reviewers, priorities, statuses,
  dependencies, and blockers are represented and searchable.
- Markdown content renders safely and preserves revision history.
- Board, list, my-work, review, and blocked-work views reflect durable records.
- Reviewers can request changes, approve, and lock an approved version within
  their authority.
- Slack workspace and channel integration is explicitly authorized and
  independently disableable.
- Authorized users can publish links and next actions to Slack without leaking
  private content.
- Slack threads can be linked or converted to draft work items, but cannot
  bypass human lifecycle gates.
- Internal search, notifications, attachments, API access, and exports enforce
  the core-team boundary.
- Audit records capture ownership, content, status, review, approval, and
  integration changes.
- Security, authorization, Markdown, Slack, and failure-path tests pass.
- Core-team and administrator documentation is available.
- Automated verification passes and the Product Owner accepts the outcome.

### 17. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Dashboard duplicates Slack communication | Define Slack as conversation and dashboard/repository as record |
| Important decisions remain only in Slack | Provide link, summary, decision-record, and review workflows |
| Slack integration publishes private information | Explicit publish action, allowlisted channels, redaction, audit, and disablement |
| Notification fatigue | Preferences, batching, deduplication, quiet periods, and clear next actions |
| Markdown documents become inconsistent | Templates, schema guidance, reviews, version history, and rendering tests |
| Work items become stale | Named owners, review dates, blocked-work alerts, and milestone review |
| Core-team access leaks through search or API | Server-side policy checks, private-by-default indexes, and authorization tests |
| Slack or provider outage blocks work | Dashboard remains usable independently and integration failures are visible |
| Dashboard becomes an administrative burden | Thin vertical slices, reusable templates, and outcome measurement |
| AI summarizes sensitive internal context | Provider boundary, data minimization, provenance, disablement, and human review |

### 18. Long-term vision

The Core Team Internal Work Dashboard will become the operational center for
UTCC AI Academy product development without displacing the repository's
durable lifecycle governance.

It will connect public feature proposals, product requirements, technical
designs, development tasks, testing, releases, incidents, and organizational
knowledge in one private internal workspace. Markdown will keep documentation
portable and reviewable, while Slack will remain the fast communication layer
for links, signals, owners, and next actions.

Guided by Kaizen, Kanban, Genchi Genbutsu, Hitozukuri, Monozukuri, Omotenashi,
and Hansei, the platform will support disciplined execution, faster onboarding,
clear accountability, safer collaboration, and long-term organizational
learning.

### 19. Integration with the consolidated roadmap

- **Repository development flow:** M14 must link to the existing Plan, Design,
  Spec, Code, Test, Build, Release, Operate, and Measure artifacts rather than
  creating a parallel approval process.
- **Slack policy:** Slack remains an engagement and notification surface. It
  carries a durable artifact link, accountable human, state, and next action;
  it never approves a transition or serves as the source of truth.
- **M13 Public Feature Request Platform:** Approved public proposals may create
  internal draft work items through an authorized Product Owner, but public
  votes, comments, or Slack messages cannot create accepted internal work by
  themselves.
- **Company Business Case Platform M10:** Internal projects may link to
  company work, but confidential company data and partner documents retain
  their original access boundary.
- **Student Internship Request Platform M11:** Internship records, evaluations,
  and student work remain restricted; only authorized summaries or links may
  enter internal work records.
- **Technical Blog Translation Platform M12:** Technical content work may use
  M14 projects and review items, while source content, translation drafts, and
  provider data remain governed by M12.
- **AI Recruitment Platform:** This M14 is separate from AI Recruitment
  Platform M14 Notifications and Communication. Shared project, user, work,
  and notification data require a future cross-track data-model decision.
- **M14 naming:** Milestone IDs are track-scoped. This M14 must not be added to
  the current UTCC Academy backlog or treated as an accepted delivery priority
  until its Product Owner, Engineering Manager, Technical Lead, Security or
  Privacy owner, Slack workspace owner, and core-team owner approve the scope.

Before execution, M14 requires a problem baseline, primary outcome and
guardrails, a core-team membership decision, a repository/dashboard boundary
ADR, a Markdown rendering and sanitization ADR, a Slack integration and
credential-custody ADR, a work-item state and review specification, and a
security/operations specification covering private visibility, attachments,
search, notifications, webhooks, audit events, failure handling, and
integration disablement.
