---
---

# Product Roadmap

**Tags:** [#product](tags.md#product) [#roadmap](tags.md#roadmap) [#planning](tags.md#planning)

This roadmap starts from the current successful implementation and orders the remaining work by user impact, risk, and dependency.

It is a product-level plan, not a fixed delivery contract. Sprint scope may change as the team learns, but each sprint must still produce a working increment. See [process.md](process.md) for the team's two-week sprint process and [feature-inventory.md](feature-inventory.md) for the full feature inventory.

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
