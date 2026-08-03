---
---

# Feature Inventory

**Tags:** [#product](tags.md#product) [#features](tags.md#features) [#status](tags.md#status)

This inventory reflects the routes, controllers, models, views, and documented behavior currently present in UTCC AI Academy.

## Public experience

- Marketing landing page with:
  - AI topics
  - Learning tracks and level filters
  - Community stories
  - Events
  - FAQs
  - Registration and sign-in calls to action
- Thai and English interfaces
- Browser-language detection and manual language switching
- Privacy policy and terms of service
- Search-engine support:
  - Sitemap with translated URLs
  - `robots.txt`
  - `llms.txt`
  - Canonical and `hreflang` links
  - Organization, course, event, and FAQ structured data

## Accounts and security

- Student registration using a 13-digit student ID
- Terms acceptance during registration
- Student-ID/password login
- "Remember me" sessions
- Logout
- 30-day absolute session expiry
- Password-strength validation
- Password reset by email
- Signed-in password change with current-password verification
- Profile editing:
  - Name
  - Email
  - Faculty
  - Study year
- Role-based access:
  - Student
  - Instructor
  - Admin
- Login, registration, password-reset, grading, and incident-report rate limits
- Login protection by both IP address and student ID
- Sensitive parameter filtering
- Return to the originally requested page after login

## Course catalog

- Persisted course catalog
- Filters for:
  - All
  - Core
  - Popular
  - Machine learning
  - Generative AI
  - Data
  - Ethics
- Course cards showing:
  - Credits
  - Rating
  - Project count
  - Study hours
  - Level
  - Instructor
  - Learner count
  - Core/certificate labels
  - Personal progress
- Recommended starting course
- Unknown-course handling

## Course and syllabus

- Course-detail page
- Persisted modules and topics
- Module accordions
- Topic type and estimated duration
- Done/current/locked module states
- Sequential module unlocking
- Continue from the next unfinished topic
- Learned and applied progress bars
- Course metadata and instructor information

## Lessons and grading

- Four lesson stages:
  - Theory
  - Quiz
  - Coding task
  - Summary
- Shareable lesson-step URLs
- Server-side quiz grading
- Server-side code-criteria grading
- Starter-code reset
- Pass/fail feedback and per-criterion results
- Every submission attempt stored, including failures
- Percentage scores stored with submissions
- Progress awarded only after a passing result
- Idempotent completion recording
- Automatic next-topic navigation
- Lesson reward summary

## Academic-integrity monitoring

- Student-only lesson proctoring
- Detection and recording of:
  - Leaving the window
  - Copying
  - Small and large pastes
  - Context-menu usage
  - Printing
  - Screenshot shortcuts
- Per-event integrity-score deductions
- Lesson guard after serious events
- Persisted proctor events
- Teacher-controlled per-course/lesson visibility for the student integrity log
- Risk/review/clean case scoring

## Personal learning

- "My Learning" screen
- In-progress and completed-course tabs
- Expandable course details
- Learned versus applied progress
- Continue-learning links
- Certificate counts
- Profile summary
- Achievement shelf

## Progress and gamification

- Overall learned/applied totals
- Study-time estimates
- Weekly learning statistics
- 84-day activity heatmap
- Course progress and next-topic indicators
- XP and levels
- Gems
- Learning streak
- Rank
- Projects completed
- Certificates earned
- Achievement badges
- Five-heart system based on recent failed attempts
- Heart refill time
- Persistent-failure recovery awards

## Knowledge map

- Course and project modes
- Hierarchical topic navigation
- Breadcrumbs
- Selected-node details
- Learned, partially learned, and unstarted states
- Project-topic indicators
- Collapsible legend
- Links from map topics into lessons

## Leaderboard

- Weekly ranking
- Semester ranking
- University-wide ranking
- Section-aware leaderboard
- XP, completed topics, and streak columns
- Current-student highlighting
- Podium positions
- Lazy-loaded results with loading skeleton

## Notifications

- Real-time notification-bell refresh through WebSockets
- Unread count
- Recent-notification panel
- Mark-all-read
- Cross-device refresh
- Notifications for:
  - Section enrolment
  - Role changes
  - Integrity notices
  - Integrity escalation
- Notifications rendered in the reader's selected language

## Instructor console

- Instructor/admin access control
- Assigned-section reporting
- Cohort size and average progress
- Project completion rate
- Inactive-student count
- Average exercise score
- Hardest topics based on first-attempt failures
- Student roster showing:
  - Student ID
  - Name
  - Progress
  - Projects completed
  - Last activity
- Localized CSV grade export

## Admin console

### Fully backed by records

- Live user, student, staff, section, and completion counts
- User search and role filters
- Role assignment
- Protection against changing one's own admin role
- Section management:
  - Create sections
  - Assign or change instructors
  - Enrol students
  - Remove students
- Integrity-case management:
  - Review evidence
  - Notify student
  - Escalate to instructor
  - Close case
- Landing-page CMS:
  - Edit Thai and English content
  - Restore shipped copy by clearing overrides
  - Add cards
  - Reorder cards
  - Delete cards
  - Configure track level and duration
  - Configure event dates
- Persistent admin audit log
- Audit filtering by informational/warning level

## Platform capabilities

- Responsive desktop/mobile navigation
- Sticky header and mobile drawer
- Accessible dropdowns, tabs, forms, and native accordions
- URL-backed filters and screen state
- Turbo navigation and frame recovery after session expiry
- Content Security Policy with nonce-protected scripts
- PostgreSQL-backed jobs, cache, and WebSockets
- Health-check endpoint
- Docker, Render, and partial Kamal deployment support
- Automated tests, linting, dependency audits, and security scans

## Present but not fully functional

- Every topic currently displays the same placeholder lesson, quiz, and coding task.
- Every course currently shares the same syllabus.
- Knowledge-map content is placeholder-backed; "Map settings" and "Mark as known" do nothing.
- "Download syllabus (PDF)" has no implementation.
- UTCC SSO is displayed but disabled.
- Reset emails are generated, but production SMTP is not configured.
- Admin Overview, Courses, Approval Queue, and Feature Control contain placeholder data.
- Admin feature switches are disabled and not persisted.
- The "Helping Hand" achievement cannot be earned until a forum exists.
- Hearts are informational and do not block lessons.
