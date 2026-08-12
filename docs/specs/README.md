# Executable Specifications

> [System Development Flow Master](../system-development-flow-master.md) ·
> [Specification Template](../templates/spec.md)

Create a specification from the [specification template](../templates/spec.md)
for ambiguous Tier B/C behavior. Acceptance intent belongs to the named human
owner.

## Specifications

- [SPEC-0001 — Deliver the first real bilingual AI1101 topic](spec-m2-first-real-topic.md) — accepted
- [SPEC-0002 — Complete the AI1101 foundation course content](spec-m3-foundation-course.md) — accepted
- [SPEC-0003 — Course-specific curricula](spec-m4-course-specific-curricula.md) — accepted
- [SPEC-0004 — Academic-post permissions and draft lifecycle](spec-academic-post-permissions-and-lifecycle.md) — accepted
- [SPEC-0005 — Academic-post Tiptap editor integration](spec-academic-post-tiptap-editor.md) — accepted
- [SPEC-0006 — Academic-post preview-page editing](spec-academic-post-preview-editing.md) — accepted
- [SPEC-0007 — Academic-post authoring and reader tools](spec-academic-post-authoring-reader-tools.md) — accepted
- [SPEC-0008 — Real course-scoped knowledge map](spec-m5-real-knowledge-map.md) — accepted
- [SPEC-0009 — Downloadable localized course syllabus PDF](spec-m6-course-syllabus-pdf.md) — accepted and implemented
- [SPEC-0010 — UTCC SSO and safe account linking](spec-m6-utcc-sso-account-linking.md) — draft; institutional identity decisions pending
- [SPEC-0011 — Course-completion certificate policy and artifact](spec-m6-course-completion-certificates.md) — accepted; academic credential policy pending
- [SPEC-0012 — Live admin Overview metrics](spec-m7-live-admin-overview-metrics.md) — accepted; baseline approved, future metric definitions and privacy review pending
- [SPEC-0013 — Real admin course catalog and lifecycle states](spec-m7-admin-course-lifecycle.md) — accepted; baseline approved and implemented, future academic workflow pending
- [SPEC-0014 — Persisted admin approval queue and decisions](spec-m7-approval-queue.md) — accepted; request and authority policy pending
- [SPEC-0015 — Persisted admin feature-flag settings](spec-m7-feature-flag-settings.md) — draft; supported-flag and runtime policy pending
- [SPEC-0016 — Learner hearts attempt, refill, and support policy](spec-m8-hearts-attempt-policy.md) — accepted; academic and product policy pending
- [SPEC-0017 — Helping Hand award and learner community boundary](spec-m8-helping-hand-community.md) — accepted; Helping Hand deferred until a moderated community feature is approved
- [SPEC-0018 — Learner-marked prior knowledge and downstream progress policy](spec-m8-prior-knowledge.md) — accepted; learner marks affect map progress and course completion only
- [SPEC-0019 — Active-session visibility and revocation](spec-m9-session-visibility-and-revocation.md) — accepted; own-account minimized session list and row-destruction revocation implemented
- [SPEC-0020 — Critical-failure observability and alert ownership](spec-m9-critical-failure-observability.md) — accepted; provider-neutral redacted telemetry, signal ownership, and runbook baseline implemented
- [SPEC-0021 — Backup, restore, and recovery verification](spec-m9-backup-restore-verification.md) — accepted; provider-neutral one-hour RPO/four-hour RTO recovery contract and isolated drill baseline implemented
- [SPEC-0022 — Production deployment, artifact, migration, and rollback contract](spec-m9-production-deployment.md) — draft; target, artifact, migration, rollback, and release policy pending
- [SPEC-0023 — Curriculum-scale accessibility and performance quality budgets](spec-m9-curriculum-quality-budgets.md) — accepted; accessibility, performance, audience, threshold, and waiver policy pending
- [SPEC-0024 — Recruitment foundation organization membership and candidate profiles](spec-recruitment-foundation-organization-profiles.md) — accepted; Product Owner and Tech Lead reviewed and accepted
- [SPEC-0025 — Recruitment organization invitations for registered users](spec-recruitment-invitations.md) — accepted; Product Owner, Tech Lead, and Security/Privacy reviewed and accepted
- [SPEC-0026 — Recruitment organization job management and publication workflow](spec-recruitment-job-management.md) — accepted; Product, technical, security, and recruitment-domain reviewed and accepted
- [SPEC-0027 — Provider-neutral recruitment job suggestions and human review](spec-recruitment-ai-job-creation.md) — accepted; Product, technical, security, and recruitment-domain reviewed and accepted
- [SPEC-0028 — Organization-scoped internship programs, student applications, and evaluations](spec-recruitment-internship-management.md) — accepted; Product, technical, security, recruitment, and academic reviewed and accepted
- [SPEC-0029 — Structured, consented, and portable candidate profiles](spec-recruitment-candidate-profile.md) — accepted; Product, Privacy, Security, and Recruitment reviewed and accepted
- [SPEC-0030 — Candidate-controlled provider-neutral resume analysis](spec-recruitment-resume-analysis.md) — draft; Product, Privacy, Security, and Recruitment review pending
- [SPEC-0031 — Candidate-controlled search, saved jobs, recommendations, and alerts](spec-recruitment-job-discovery.md) — accepted; Product, Privacy, Security, and Recruitment reviewed and accepted
- [SPEC-0032 — Candidate-owned explainable job match preview](spec-recruitment-match-preview.md) — accepted; Product, Privacy, Security, Recruitment, and QA reviewed and accepted
- [SPEC-0033 — Candidate-owned recruitment applications and auditable pipeline stages](spec-recruitment-application-workflow.md) — accepted; Product, Privacy, Security, Recruitment, and QA reviewed and accepted
- [SPEC-0034 — Provider-neutral advisory recruiter next-action assistance](spec-recruiter-advisory-assistance.md) — accepted; Product, legal, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [SPEC-0035 — Provider-neutral candidate application preparation assistance](spec-candidate-application-assistance.md) — accepted; Product, legal, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [SPEC-0036 — Provider-neutral student internship preparation assistance](spec-internship-application-assistance.md) — accepted; Product, Academic, legal, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [SPEC-0037 — Privacy-safe organization-scoped recruitment reporting](spec-recruitment-reporting.md) — accepted; Product, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [SPEC-0038 — Participant-scoped in-app recruitment application conversations](spec-recruitment-application-conversations.md) — accepted; Product, Privacy, Security, Recruitment, and QA reviewed and accepted
- [SPEC-0039 — Governed enterprise recruitment integrations and adoption controls](spec-recruitment-enterprise-integrations.md) — accepted; Product, legal, Privacy, Security, Recruitment, Data, Platform, and QA reviewed and accepted
- [SPEC-0040 — Invitation-only company business-case collaboration and project workspace boundary](spec-company-business-case-collaboration.md) — accepted; Product, Security, Privacy, Academic, Recruitment, and QA reviewed and accepted
- [SPEC-0041 — Student-initiated internship requests, placements, and progress reporting](spec-student-internship-requests.md) — accepted; increment 1 implemented and scoped against the shipped SPEC-0028 internship management
- [SPEC-0042 — Console sign-in for teaching staff, administrators, and company members](spec-console-sign-in.md) — accepted; second sign-in door at /console over the one shared session mechanism
- [SPEC-0043 — Console account identity, admin-created accounts, and the identifier model](spec-console-account-identity.md) — accepted; three identifier columns, at least one required, and an admin creation screen
- [SPEC-0044 — Role-aware navigation, front doors, and company profile addresses](spec-role-aware-workspaces.md) — accepted; User#workspace drives the nav, the strip, and where / lands; organizations addressed by name
- [SPEC-0045 — Error pages for every failed request, rendered and flat](spec-error-pages.md) — accepted; exceptions_app renders bilingual branded pages that read no database, and public/ is generated from the same copy
- [SPEC-0047 — Dark mode, the palette toggle, and the fill/ink split](spec-dark-mode.md) — accepted; the tokens flip, no template carries a `dark:` utility, and crimson splits into a fill and an ink
- [SPEC-0046 — Toast notifications and the two ways to raise one](spec-toast-notifications.md) — accepted; one host, one row template, one clock, four kinds, six positions, reached by a Stimulus dispatch or by turbo_stream.toast
- [SPEC-0048 — The company work surface at /company/:slug/work](spec-company-work-surface.md) — accepted; counts with links to the queues they count, the same board for every active member, and application figures delegated to OrganizationReporting
- [SPEC-0049 — The proposal request intake as built](spec-proposal-request-intake.md) — accepted; records the shipped intake that had no governing document, including the dead statuses, so any change to proposals has a baseline
- [SPEC-0050 — Proposal triage, increment 1](spec-proposal-triage.md) — accepted; an administrator answers a proposal with a recorded decision and a reason the author reads, which makes all four statuses reachable and no public surface
- [SPEC-0051 — Paged lists, the page object, and the end of the audit log's truncation](spec-paged-lists.md) — accepted; fifteen screens page at twenty-five rows over two increments, a filter change lands on page 1, and every audit row ever written is reachable
