---
---

# Product Roadmap

**Tags:** [#product](tags.md#product) [#roadmap](tags.md#roadmap) [#planning](tags.md#planning)

This roadmap starts from the current successful implementation and orders the remaining work by user impact, risk, and dependency.

It is a product-level plan, not a fixed delivery contract. Sprint scope may change as the team learns, but each sprint must still produce a working increment. See [process.md](process.md) for the team's two-week sprint process and [feature-inventory.md](feature-inventory.md) for the full feature inventory.

This single file contains the UTCC Academy, AI Recruitment Platform, and
Company Business Case Platform roadmap tracks. Each track keeps its own scope,
outcomes, dependencies, and human approval gates.

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
| 2 | First real topic | One complete bilingual topic proves the content model | Next |
| 3 | Complete foundation course | Every topic in the first course has unique learning content | Next |
| 4 | Course-specific curricula | Courses can have different modules, topics, and requirements | Next |
| 5 | Real knowledge map | The map reflects actual curriculum and learner progress | Next |
| 6 | Institutional access and documents | UTCC SSO and syllabus downloads work end to end | Later |
| 7 | Operational admin controls | Placeholder admin screens become real management tools | Later |
| 8 | Community and pedagogy decisions | Social awards and heart behavior have real rules | Later |
| 9 | Production hardening | Session control, delivery monitoring, and deployment are strengthened | Continuous |
| 10 | Academic writing | Students and teachers can create, review, and collaboratively publish academic posts | Next |

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

**Status: Next**

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

**Status: Next**

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

**Status: Next**

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

**Status: Next**

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

**Status: Later**

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

**Status: Later**

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

**Status: Next**

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

**Status:** Proposal — not implemented

**Version:** 1.0
**Platform:** Ruby on Rails
**Prepared for:** UTCC AI Academy

### Industry–University Collaboration Ecosystem

#### Milestone M10 — Company Business Case Platform

M10 is scoped to this roadmap track. It does not replace UTCC Academy M10
Academic Writing or AI Recruitment Platform M10 AI Recruiter Agent.

No company, business-case, project-milestone, or project-submission models or
routes exist in the current application; the requirements below describe the
proposed future capability.

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

Before execution, the roadmap requires a problem baseline, primary outcome and
guardrails, a company/tenant and faculty-role decision, a data-retention and
business-data privacy policy, an invitation threat model, a data-model ADR,
and a specification covering permissions, file handling, state transitions,
notifications, and audit events.
