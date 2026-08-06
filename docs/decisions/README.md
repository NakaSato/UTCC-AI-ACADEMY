# Decision Records

> [System Development Flow Master](../system-development-flow-master.md) ·
> [Architecture Decision Template](../templates/adr.md)

Create a decision record from the
[architecture decision template](../templates/adr.md) when a consequential
choice has a meaningful losing alternative. Never delete an ADR; supersede or
deprecate it.

## Records

- [ADR-0001 — Adopt a repository-native Markdown development flow](adr-0001-adopt-markdown-development-flow.md) — accepted
- [ADR-0002 — Select the production transactional-email provider](adr-0002-select-production-email-provider.md) — rejected; no provider selected
- [ADR-0003 — Use Mailpit for local email capture](adr-0003-use-mailpit-for-local-email-capture.md) — accepted and implemented; Tier C verification and human review complete
- [ADR-0006 — Define academic-post permissions and draft lifecycle](adr-0006-academic-post-permissions-and-lifecycle.md) — accepted
- [ADR-0007 — Integrate Tiptap with a native Stimulus and Importmap bridge](adr-0007-integrate-tiptap-with-stimulus-importmap.md) — accepted
- [ADR-0008 — Derive the knowledge map from course curricula](adr-0008-real-knowledge-map.md) — accepted
- [ADR-0009 — Define the course syllabus PDF document boundary](adr-0009-course-syllabus-pdf.md) — accepted and implemented
- [ADR-0010 — Define the UTCC SSO and account-linking boundary](adr-0010-utcc-sso-account-linking.md) — draft; institutional identity decisions pending
- [ADR-0011 — Define course-completion certificate policy](adr-0011-course-completion-certificates.md) — draft; academic credential policy pending
- [ADR-0012 — Replace fabricated admin Overview metrics with defined live metrics](adr-0012-live-admin-overview-metrics.md) — baseline approved; future metric definitions and privacy review pending
- [ADR-0013 — Define the admin course lifecycle and catalog boundary](adr-0013-admin-course-lifecycle.md) — baseline approved and implemented; future academic workflow pending
- [ADR-0014 — Define approval queue records and decision history](adr-0014-approval-queue-records.md) — draft; request and authority policy pending
- [ADR-0015 — Define which admin feature flags are real and how settings persist](adr-0015-feature-flag-boundary.md) — draft; supported-flag and runtime policy pending
- [ADR-0016 — Define the learner hearts attempt and refill policy](adr-0016-hearts-attempt-policy.md) — draft; academic and product policy pending
- [ADR-0017 — Define the Helping Hand award and community interaction boundary](adr-0017-helping-hand-community-boundary.md) — accepted; Helping Hand deferred until a moderated community feature is approved
- [ADR-0018 — Define the meaning and effects of learner-marked prior knowledge](adr-0018-prior-knowledge-boundary.md) — accepted; learner marks affect map progress and course completion only
- [ADR-0019 — Define active-session visibility and revocation](adr-0019-session-visibility-and-revocation.md) — accepted; own-account minimized session list and row-destruction revocation implemented
- [ADR-0020 — Define critical-failure observability and alert ownership](adr-0020-critical-failure-observability.md) — accepted; provider-neutral redacted telemetry, signal ownership, and runbook baseline implemented
- [ADR-0021 — Define backup, restore, and recovery verification](adr-0021-backup-restore-verification.md) — accepted; provider-neutral one-hour RPO/four-hour RTO recovery contract and isolated drill baseline implemented
- [ADR-0022 — Define the production deployment, artifact, and rollback boundary](adr-0022-production-deployment-boundary.md) — draft; target, artifact, migration, rollback, and release policy pending
- [ADR-0023 — Define curriculum-scale accessibility and performance quality budgets](adr-0023-curriculum-quality-budgets.md) — draft; accessibility, performance, audience, threshold, and waiver policy pending
