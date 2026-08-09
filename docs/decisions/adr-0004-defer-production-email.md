---
id: ADR-0004
type: adr
title: Defer production email delivery
status: accepted
owners: ["@product-owner"]
created: 2026-08-01
updated: 2026-08-09
review_by: 2026-08-23
supersedes: [ADR-0002]
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - config/environments/production.rb
  - docs/backlog.json
enforced_by: []
agent_writable: false
---

# Defer Production Email Delivery

**Tags:** [#decisions](../tags.md#decisions) [#roadmap](../roadmap.md#milestone-1--reliable-account-recovery) [#operations](../tags.md#operations) [#security](../tags.md#security)

> [Decision Records](README.md) ·
> [Production Provider Decision](adr-0002-select-production-email-provider.md) ·
> [Local Mailpit Decision](adr-0003-use-mailpit-for-local-email-capture.md) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the Product Owner on 2026-08-01. This decision
> does not authorize production deployment, credentials, or a provider.

## Context

`MAIL-001` requires a human decision about a production transactional-email
provider, credential owner, DNS ownership, privacy, cost, and operations. The
Product Owner rejected ADR-0002 without selecting a replacement provider or
authorizing credentials. Local development and testing can continue through
the accepted loopback-only Mailpit decision in ADR-0003.

The application therefore has a deliberate boundary: local SMTP capture is
available, while production password-reset delivery remains unconfigured. The
repository should record that boundary explicitly instead of treating local
Mailpit as a production solution.

## Decision

Defer production email delivery until the Product Owner supplies and accepts a
replacement provider decision with named owners. During the deferral:

1. Keep ADR-0002 as the historical rejected provider proposal; do not delete it.
2. Keep ADR-0003 as the accepted development-only Mailpit decision.
3. Do not add production SMTP settings, provider credentials, DNS changes, or
   provider integrations.
4. Resolve `MAIL-001` as the completed deferral decision with this ADR as its
   evidence.
5. Keep `MAIL-002` and `MAIL-003` blocked because no provider implementation is
   authorized.

This ADR supersedes ADR-0002 as the current production-email direction. A later
provider selection may supersede this deferral through a new accepted ADR.

## Alternatives

### Select a provider now

Rejected for this decision because the required Product Owner inputs—provider,
credential custodian, budget, privacy approval, DNS owner, and operating
owner—are missing.

### Treat Mailpit as production email

Rejected. Mailpit is unauthenticated, loopback-only, ephemeral development
infrastructure and cannot deliver to a real mailbox.

### Remove password reset

Rejected. Account recovery remains a roadmap requirement; deferral records the
unresolved dependency without silently removing the capability.

## Consequences

- Local SMTP password-reset testing remains available through Mailpit.
- Production password-reset messages remain unavailable until a provider is
  selected and configured.
- No production credential or third-party email data is introduced while the
  decision is unresolved.
- `MAIL-001` is resolved as a completed deferral decision; production email
  remains unavailable.

## Fitness Functions

- `bin/docs` validates this ADR's frontmatter, references, and required
  headings.
- `MAIL-001` records this accepted ADR as its decision evidence.
- `MAIL-002` and `MAIL-003` remain blocked while no provider decision exists.
- `ADR-0003` continues to verify local Mailpit behavior without changing
  production configuration.

## Acceptance criteria

- [x] Product Owner accepts this ADR on 2026-08-01.
- [x] ADR-0002 is marked `superseded` with `superseded_by: [ADR-0004]`.
- [x] `MAIL-001` records ADR-0004 as its current decision evidence.
- [x] `MAIL-002` and `MAIL-003` remain blocked until a provider decision exists.
