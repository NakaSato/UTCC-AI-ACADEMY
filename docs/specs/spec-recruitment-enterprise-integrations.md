---
id: SPEC-0039
type: spec
title: Governed enterprise recruitment integrations and adoption controls
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@recruitment-domain-owner", "@data-owner", "@platform-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0039, ADR-0010, ADR-0024, ADR-0033, ADR-0037, ADR-0038]
implemented_by: []
enforced_by: []
touches:
  - app/models
  - app/services
  - app/controllers
  - config/routes.rb
  - db/migrate
  - lib
  - test
  - docs/runbooks
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-004]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-004]
---

# Governed Enterprise Recruitment Integrations and Adoption Controls

> **Review state:** Draft design only. This specification authorizes no
> external request, callback, account linking, synchronization, calendar event,
> partner access, or production data exchange. It becomes implementation-ready
> only after the human decisions in the review handoff are recorded.

> [Executable Specifications](README.md) ·
> [Enterprise integration ADR](../decisions/adr-0039-governed-enterprise-integrations.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap)

## Problem

Enterprise adoption needs SSO, HRIS, calendar, and partner-API capabilities,
but an integration can cross tenant, consent, identity, privacy, and operational
boundaries. The platform currently has no integration registry, provider
adapter contract, secret-custody reference, field-level data map, or external
failure/recovery policy. The first step is a reviewable control contract, not a
provider implementation.

## Scope

### Included

- A tenant-scoped integration registration and lifecycle model.
- Provider-neutral adapter and versioned contract requirements.
- Allowlisted data, purpose, consent, retention, export, and deletion controls.
- Authentication, authorization, secret-reference, callback-validation, and
  tenant-isolation requirements.
- Idempotency, bounded retries, rate limits, reconciliation, disablement,
  revocation, and incident-response requirements.
- Privacy-safe audit and operational evidence for external operations.
- A human review handoff for selecting the first connector and operating model.

### Excluded

- Selecting an SSO, HRIS, calendar, or API provider.
- Implementing OAuth/OIDC, SAML, SCIM, HRIS sync, calendar sync, webhooks, or
  an API gateway.
- Sending email, calendar invitations, candidate messages, or recruitment data
  to external systems.
- Importing external roles, users, candidates, jobs, applications, or schedules.
- Storing provider secrets, tokens, assertions, raw callbacks, or provider
  payloads in the application.
- Automatic hiring decisions, candidate ranking, role assignment, or AI
  actions triggered by an integration.

## Domain boundary

The integration control plane owns registration, lifecycle, contract version,
scope, purpose, consent reference, data map, provider adapter, dispatch,
callback validation, idempotency, retry, reconciliation, audit, and disablement.

The recruitment domain remains the authority for users, organization
memberships, candidate profiles, job posts, applications, application stages,
messages, and recruitment decisions. Adapters may request a domain operation
through an approved service contract; they may not write recruitment tables
directly or infer authorization from provider payloads.

## Invariants

1. Every integration registration belongs to exactly one tenant and cannot be
   used by another tenant.
2. Every external operation identifies one registration, contract version,
   purpose, scope, actor or system trigger, correlation ID, and idempotency key.
3. A registration cannot dispatch while disabled, revoked, expired, missing
   consent, missing scope, or missing an approved provider contract.
4. Raw secrets, tokens, assertions, authorization codes, and provider payloads
   are never stored in application rows, audit parameters, logs, fixtures, or
   browser responses; only a secret reference and privacy-safe outcome may be
   retained.
5. External identity, HRIS, partner, and calendar attributes cannot create or
   change local roles unless an approved mapping policy explicitly permits it;
   local organization authorization remains authoritative.
6. Outbound fields are allowlisted by contract and purpose. Enabling a
   registration never grants access to all candidate, profile, application,
   interview, or message data.
7. An inbound callback must pass registered-provider, signature/issuer,
   timestamp/replay, schema, tenant, and idempotency validation before any
   domain mutation.
8. A retry cannot create duplicate users, candidates, applications, messages,
   jobs, calendar records, or audit outcomes for the same idempotency key.
9. Revocation and disablement stop new dispatches and invalidate queued work;
   re-enablement does not replay data without an approved recovery decision.
10. Export, deletion, retention, and incident-response behavior is defined for
    every shared field group before production data exchange.

## Acceptance Criteria

These are design-gate criteria for the current slice. Connector implementation
must add enforcing tests before a connector moves beyond draft.

- [ ] ADR-0039 records the proposed control boundary, alternatives, trust
      boundaries, fitness functions, and accountable human decisions.
- [ ] The integration lifecycle includes at least proposed, enabled, paused,
      suspended, and revoked states with fail-closed behavior.
- [ ] A connector contract identifies tenant, purpose, scope, direction,
      field allowlist, consent, retention, version, idempotency, retry,
      callback, audit, export, deletion, and rollback behavior.
- [ ] The provider adapter boundary prevents provider SDKs and raw external
      payloads from entering recruitment controllers or domain models.
- [ ] The review handoff names the unresolved provider, jurisdiction, data,
      role-mapping, operating, and support decisions; no decision is implied by
      this draft.
- [ ] `bin/docs` validates the metadata, links, and skill references for this
      specification.

### Required future implementation evidence

Before implementation is accepted, the spec owner must add real test paths for
the following contracts:

| Contract | Required evidence |
| --- | --- |
| Tenant isolation and authorization | Model/service and request tests for cross-tenant access and local-role authority |
| Secret and payload hygiene | Logging, audit, error, and persistence tests proving redaction |
| Provider contract | Contract tests for validation, versioning, schema rejection, and callback replay |
| Idempotency and retry | Concurrent and failure tests proving bounded, duplicate-free recovery |
| Lifecycle and revocation | Tests proving disabled/revoked integrations cannot dispatch or mutate domain state |
| Data governance | Export, deletion, retention, consent, and field-allowlist tests for the selected provider |
| Operations | System/runbook checks for outage, reconciliation, alert ownership, and rollback/disablement |

## Error and boundary cases

- A provider is unavailable after the operation is accepted: persist only a
  privacy-safe failure state, apply bounded retry, and expose reconciliation to
  the named operator.
- A callback has a valid signature but an unknown tenant, registration, schema,
  or idempotency key: reject it without a domain mutation.
- A user loses consent or the integration is revoked while work is queued:
  cancel or quarantine the work before dispatch.
- A provider repeats an event or changes a stable identifier: deduplicate by
  the contract key and route identity conflict to manual review.
- A provider sends a role/group claim not covered by policy: retain no role
  change and require the local authorization owner to decide.
- A tenant requests deletion while provider copies may exist: block completion
  until the approved provider deletion and evidence policy is satisfied.
- A provider contract version changes: reject unsupported payloads and require a
  reviewed adapter version; do not silently coerce fields.

## Human review handoff

The Product Owner, Tech Lead, Security Owner, Privacy Owner, Recruitment Domain
Owner, Data Owner, Platform Owner, and QA Owner must record:

1. The first connector, target tenant, outcome metric, guardrail, and evaluation
   window.
2. Provider/protocol, region, jurisdiction, procurement, service-level,
   secret-custody, and incident-response ownership.
3. Exact data fields and direction, purpose, consent/lawful basis, training-use,
   retention, export, deletion, and residency rules.
4. Identity and role mapping, including whether the local role model can ever
   be changed by an external claim.
5. Rate limits, retry/reconciliation, webhook replay, outage, manual recovery,
   support, and disablement behavior.
6. Partner API onboarding, versioning, quotas, scopes, revocation, abuse
   response, accessibility, and customer communication policy.

## Rollback and observability

This design slice has no runtime migration or external dependency to roll back.
Before connector code is written, the implementation plan must define how to
disable dispatch, invalidate queued work, preserve audit evidence, reconcile
partial provider effects, and return the recruitment domain to its prior
behavior without deleting required records.

Future operations must measure privacy-safe counts and latency for dispatches,
callback validation failures, consent denials, retries, duplicate conflicts,
provider outages, revocations, reconciliation backlog, export/deletion status,
and manual recovery. Metrics must carry tenant-safe dimensions and must never
contain tokens, raw payloads, candidate identifiers, or message content.

## Verification

```bash
bin/docs
git diff --check
```
