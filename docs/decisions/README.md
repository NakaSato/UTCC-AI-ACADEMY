# Decision Records

> [System Development Flow Master](../system-development-flow-master.md) ·
> [Architecture Decision Template](../templates/adr.md)

Create a decision record from the
[architecture decision template](../templates/adr.md) when a consequential
choice has a meaningful losing alternative. Never delete an ADR; supersede or
deprecate it.

## Records

- [ADR-0001 — Adopt a repository-native Markdown development flow](adr-0001-adopt-markdown-development-flow.md) — accepted
- [ADR-0002 — Select the production transactional-email provider](adr-0002-select-production-email-provider.md) — superseded by ADR-0004; the choice was deferred rather than rejected, and no provider is selected
- [ADR-0003 — Use Mailpit for local email capture](adr-0003-use-mailpit-for-local-email-capture.md) — accepted and implemented; Tier C verification and human review complete
- [ADR-0004 — Defer production email delivery](adr-0004-defer-production-email.md) — accepted; supersedes ADR-0002 and is why MAIL-002 and MAIL-003 are blocked, with Mailpit the approved verification boundary
- [ADR-0005 — Model course-specific curricula](adr-0005-course-specific-curricula.md) — accepted
- [ADR-0006 — Define academic-post permissions and draft lifecycle](adr-0006-academic-post-permissions-and-lifecycle.md) — accepted
- [ADR-0007 — Integrate Tiptap with a native Stimulus and Importmap bridge](adr-0007-integrate-tiptap-with-stimulus-importmap.md) — accepted
- [ADR-0008 — Derive the knowledge map from course curricula](adr-0008-real-knowledge-map.md) — accepted
- [ADR-0009 — Define the course syllabus PDF document boundary](adr-0009-course-syllabus-pdf.md) — accepted and implemented
- [ADR-0010 — Define the UTCC SSO and account-linking boundary](adr-0010-utcc-sso-account-linking.md) — draft; institutional identity decisions pending
- [ADR-0011 — Define course-completion certificate policy](adr-0011-course-completion-certificates.md) — accepted; academic credential policy pending
- [ADR-0012 — Replace fabricated admin Overview metrics with defined live metrics](adr-0012-live-admin-overview-metrics.md) — accepted; baseline approved, future metric definitions and privacy review pending
- [ADR-0013 — Define the admin course lifecycle and catalog boundary](adr-0013-admin-course-lifecycle.md) — accepted; baseline approved and implemented, future academic workflow pending
- [ADR-0014 — Define approval queue records and decision history](adr-0014-approval-queue-records.md) — accepted; request and authority policy pending
- [ADR-0015 — Define which admin feature flags are real and how settings persist](adr-0015-feature-flag-boundary.md) — accepted; supported-flag and runtime policy pending
- [ADR-0016 — Define the learner hearts attempt and refill policy](adr-0016-hearts-attempt-policy.md) — accepted; academic and product policy pending
- [ADR-0017 — Define the Helping Hand award and community interaction boundary](adr-0017-helping-hand-community-boundary.md) — accepted; Helping Hand deferred until a moderated community feature is approved
- [ADR-0018 — Define the meaning and effects of learner-marked prior knowledge](adr-0018-prior-knowledge-boundary.md) — accepted; learner marks affect map progress and course completion only
- [ADR-0019 — Define active-session visibility and revocation](adr-0019-session-visibility-and-revocation.md) — accepted; own-account minimized session list and row-destruction revocation implemented
- [ADR-0020 — Define critical-failure observability and alert ownership](adr-0020-critical-failure-observability.md) — accepted; provider-neutral redacted telemetry, signal ownership, and runbook baseline implemented
- [ADR-0021 — Define backup, restore, and recovery verification](adr-0021-backup-restore-verification.md) — accepted; provider-neutral one-hour RPO/four-hour RTO recovery contract and isolated drill baseline implemented
- [ADR-0022 — Define the production deployment, artifact, and rollback boundary](adr-0022-production-deployment-boundary.md) — draft; target, artifact, migration, rollback, and release policy pending
- [ADR-0023 — Define curriculum-scale accessibility and performance quality budgets](adr-0023-curriculum-quality-budgets.md) — accepted; accessibility, performance, audience, threshold, and waiver policy pending
- [ADR-0024 — Use organization memberships for recruitment company access](adr-0024-recruitment-organization-membership.md) — accepted; Product Owner and Tech Lead reviewed and accepted
- [ADR-0025 — Use secure in-app invitations for registered recruitment staff](adr-0025-recruitment-in-app-invitations.md) — accepted; Product Owner, Tech Lead, and Security/Privacy reviewed and accepted
- [ADR-0026 — Keep job posts organization-scoped with explicit publication states](adr-0026-recruitment-job-post-boundary.md) — accepted; Product, technical, security, and recruitment-domain reviewed and accepted
- [ADR-0027 — Persist provider-neutral job suggestions with human review](adr-0027-provider-neutral-job-suggestions.md) — accepted; Product, technical, security, and recruitment-domain reviewed and accepted
- [ADR-0028 — Keep internship programs, applications, mentors, and evaluations organization-scoped](adr-0028-recruitment-internship-program-boundary.md) — accepted; Product, technical, security, recruitment, and academic reviewed and accepted
- [ADR-0029 — Keep candidate profile data candidate-owned, portable, and provenance-aware](adr-0029-candidate-profile-data-boundary.md) — accepted; Product, Privacy, Security, and Recruitment reviewed and accepted
- [ADR-0030 — Keep resume analysis provider-neutral, evidence-bound, and candidate-reviewed](adr-0030-provider-neutral-resume-analysis.md) — accepted; Product, Privacy, Security, and Recruitment reviewed and accepted
- [ADR-0031 — Keep job discovery candidate-controlled and advisory](adr-0031-candidate-controlled-job-discovery.md) — accepted; Product, Privacy, Security, and Recruitment reviewed and accepted
- [ADR-0032 — Start matching with candidate-owned factor previews instead of consequential ranking](adr-0032-factor-level-job-match-previews.md) — accepted; Product, Privacy, Security, Recruitment, and QA reviewed and accepted
- [ADR-0033 — Keep recruitment applications candidate-owned with an auditable organization-scoped pipeline](adr-0033-recruitment-application-workflow-boundary.md) — accepted; Product, Privacy, Security, Recruitment, and QA reviewed and accepted
- [ADR-0034 — Start the AI recruiter agent with advisory application next-action assistance](adr-0034-recruiter-advisory-next-action-assistance.md) — accepted; Product, legal, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [ADR-0035 — Start the AI candidate agent with candidate-controlled application preparation guidance](adr-0035-candidate-application-preparation-assistance.md) — accepted; Product, legal, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [ADR-0036 — Start the AI internship agent with student-controlled preparation guidance](adr-0036-internship-preparation-assistance.md) — accepted; Product, Academic, legal, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [ADR-0037 — Start recruitment analytics with organization-scoped aggregate reporting and small-cell suppression](adr-0037-privacy-safe-recruitment-reporting.md) — accepted; Product, Privacy, Security, Recruitment, Data, and QA reviewed and accepted
- [ADR-0038 — Start recruitment communication with participant-scoped in-app application conversations](adr-0038-in-app-application-conversations.md) — accepted; Product, Privacy, Security, Recruitment, and QA reviewed and accepted
- [ADR-0039 — Define a governed control boundary for enterprise recruitment integrations](adr-0039-governed-enterprise-integrations.md) — accepted; Product, legal, Privacy, Security, Recruitment, Data, Platform, and QA reviewed and accepted
- [ADR-0040 — Define an invitation-only company business-case collaboration boundary](adr-0040-company-business-case-collaboration-boundary.md) — accepted; Product, Security, Privacy, Academic, Recruitment, and QA reviewed and accepted
- [ADR-0041 — Define a student-initiated internship request, placement, and progress boundary](adr-0041-student-internship-request-boundary.md) — accepted; decision 1 answered yes, so increment 1 ships position-less requests. Placements, progress reports, faculty oversight, and documents remain deferred
- [ADR-0042 — Give teaching staff, administrators, and company members their own sign-in door](adr-0042-console-sign-in-boundary.md) — accepted; /console authenticates on ID or email, refuses accounts without console access without creating a session, and lands each role on its own console
- [ADR-0043 — Identify console accounts by username or email and create them from the admin screen](adr-0043-console-account-identity.md) — accepted; student_id becomes nullable and student-only, username joins it, and /admin is where console accounts come from
- [ADR-0044 — Give each population its own navigation, front door, and company address](adr-0044-role-aware-workspaces.md) — accepted; one shell and four workspaces, with a company profile at /:slug. Dashboard content deferred to its own slice
- [ADR-0045 — Render error pages through the app, and keep flat files for when it is gone](adr-0045-rendered-error-pages.md) — accepted; a controller that reads nothing renders every 4xx and 5xx, and the generated files in public/ cover the failures it cannot answer
- [ADR-0047 — Ship dark mode by overriding tokens, and split crimson into a fill and an ink](adr-0047-dark-mode-by-token-override.md) — accepted; session-backed like the language toggle, no pre-paint script, and `brand-ink` exists because one crimson cannot meet AA in both jobs
- [ADR-0046 — Let the server raise a toast by dispatching the client's event, not by streaming a row](adr-0046-server-raised-toasts.md) — accepted; a custom Turbo Stream action raises `toast:show`, so the row's markup and lifetime stay in one template and one controller
- [ADR-0048 — Give a company a work surface, and leave the other three workspaces alone](adr-0048-company-work-surface.md) — accepted; /company/:slug/work is where a company member lands, every active member sees the same board, and the governed candidate figures keep their ADR-0037 gate
- [ADR-0049 — Give a proposal an answer before giving the public a platform](adr-0049-proposal-triage-before-public-platform.md) — proposed; the M13 gate document. Three of four proposal statuses are unreachable and the outcome's baseline is zero, so the first increment is triage, not participation
