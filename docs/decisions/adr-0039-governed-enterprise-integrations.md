---
id: ADR-0039
type: adr
title: Define a governed control boundary for enterprise recruitment integrations
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@recruitment-domain-owner", "@data-owner", "@platform-owner", "@qa-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0010, ADR-0024, ADR-0033, ADR-0037, ADR-0038]
implemented_by:
  - SPEC-0039
touches:
  - app/models
  - app/services
  - app/controllers
  - config/routes.rb
  - db/migrate
  - lib
  - test
  - docs/runbooks
enforced_by: []
agent_writable: true
requires_skills: [SKILL-ARCH-001, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-001, SKILL-SPEC-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-ARCH-004, SKILL-SPEC-002]
---

# Define a Governed Control Boundary for Enterprise Recruitment Integrations

> **Decision state:** Agent-prepared draft. No SSO, HRIS, calendar, partner API,
> webhook, or external data exchange is authorized by this record. The Product
> Owner, Tech Lead, Security Owner, Privacy Owner, Recruitment Domain Owner,
> Data Owner, Platform Owner, and QA Owner must approve the provider, tenant,
> consent, data, operating, and compliance choices before implementation.

> [Decision Records](README.md) ·
> [Enterprise integration specification](../specs/spec-recruitment-enterprise-integrations.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Context

Milestone M15 calls for enterprise adoption controls, SSO, HRIS and calendar
integration, a partner API gateway, administrative audit controls, tenant
isolation, retention, export, deletion, and incident-response evidence. The
current recruitment platform is organization-scoped, but it has no approved
external identity provider, HRIS or calendar contract, partner onboarding
model, secret store, data-sharing policy, or integration failure runbook.

An integration is therefore a trust boundary rather than a controller that
forwards requests. A provider can be unavailable, misconfigured, compromised,
or return data that is valid for another tenant. Enterprise adoption also makes
the platform responsible for proving what data crossed which boundary, under
which purpose and consent, and how access was revoked.

## Problem frame

- **Affected users:** Enterprise tenants, candidates, recruiters, university
  administrators, and the platform/security operators responsible for data
  exchange.
- **Current behavior:** Recruitment data remains inside the application; no
  external integration is enabled.
- **Failure risk:** Cross-tenant data exchange, role escalation from provider
  claims, leaked credentials, duplicate imports, unbounded retries, stale
  consent, untracked partner access, or deletion/export gaps.
- **Design outcome:** A provider-neutral integration contract that can be
  reviewed and implemented one connector at a time with explicit tenant,
  consent, data, audit, failure, and disablement controls.

## Decision

The platform will use a separate, provider-neutral integration control boundary
between organization-scoped recruitment features and external systems.

1. An integration registration belongs to exactly one tenant and records its
   type, contract version, lifecycle state, owner, allowed scopes, purpose,
   consent reference, data-retention class, provider identifier, and secret
   reference. It never stores a raw client secret, token, assertion, API key,
   or provider profile payload in the application database, logs, fixtures, or
   audit parameters.
2. Provider adapters own protocol details and expose versioned contracts to the
   recruitment domain. The domain never calls provider SDKs directly, and a
   provider can be replaced without changing candidate, application, or role
   semantics.
3. Every outbound or inbound operation carries a tenant identifier,
   integration identifier, contract version, purpose, actor or system trigger,
   correlation identifier, and idempotency key. The control boundary rejects
   an operation when any required scope, consent, tenant binding, or lifecycle
   state is absent.
4. Local roles and organization memberships remain authoritative. SSO claims,
   HRIS attributes, partner payloads, and calendar identities may be inputs to
   an explicitly approved mapping, but they cannot grant a local role by
   default.
5. External data is allowlisted by integration contract and purpose. Resume,
   application, interview, message, and candidate-profile data are not shared
   merely because a connector is enabled; each field group requires an
   approved direction, purpose, retention, and consent rule.
6. Integrations fail closed when disabled, revoked, expired, out of scope, or
   unable to validate the provider response. Retries are bounded and
   idempotent. Re-enabling an integration does not replay data until the
   approved recovery policy allows it.
7. The first implementation may add one connector only after the provider,
   contract, tenant model, consent, data map, secret custody, audit, retry,
   deletion/export, incident, and rollback evidence are accepted. This ADR
   does not select which connector comes first.

## Proposed trust boundaries and controls

| Boundary | Valuable assets | Minimum control | Failure behavior |
| --- | --- | --- | --- |
| Tenant user → academy | Roles, applications, profiles, messages | Existing authentication plus organization authorization; explicit actor audit | Reject unauthorized tenant access |
| Academy → integration control plane | Consent, scopes, mappings, secret references | Tenant-bound registration, allowlisted fields, versioned contract, lifecycle state | Do not dispatch the operation |
| Control plane → provider | Credentials, outbound personal data, callback state | Secret reference, least-privilege scope, TLS/provider validation, correlation and idempotency | Quarantine the operation; no unbounded retry |
| Provider callback/webhook → academy | Inbound records and status changes | Registered endpoint, signature/issuer validation, replay window, schema validation, tenant lookup | Reject and record privacy-safe failure |
| Integration jobs → recruitment domain | Candidate/application state | Domain service boundary; no direct writes from adapters; transaction and deduplication | Leave domain state unchanged and surface recovery work |
| Academy → logs/audit/metrics | Operational and privacy evidence | Redaction, retention class, correlation ID without raw payloads or secrets | Drop sensitive fields and emit a safe failure signal |

## Alternatives

### Add provider-specific code directly to recruitment controllers

This is fast for the first connector, but couples user-facing workflows to
provider contracts, spreads secrets and retry behavior through the domain, and
makes tenant and data controls inconsistent. It is rejected.

### Select SSO, HRIS, or calendar first and design the boundary around it

This can produce a demonstrable integration quickly, but it turns an unreviewed
provider choice into the platform's architecture and risks importing data or
roles before purpose and consent are approved. It is deferred until the human
integration-priority decision.

### Use a dedicated integration control plane

This adds registration, contract, audit, and operational work before the first
connector, but isolates provider change, makes tenant and consent checks
reusable, and supports staged adoption. This is the proposed boundary, pending
human review.

### Keep enterprise integrations deferred

This avoids external-data risk and recurring provider cost, but supplies no
learning about enterprise onboarding. It remains the safe fallback if the
owners cannot approve the required operating model.

## Consequences

- Enterprise adoption becomes an explicit operating capability rather than a
  collection of one-off API calls.
- Each connector requires a contract, data map, test strategy, runbook,
  rollback/disablement plan, and named owner before it can exchange data.
- The first implementation is slower, but changing providers or revoking a
  tenant is safer and less likely to alter recruitment-domain semantics.
- The platform must operate secret custody, provider monitoring, retry queues,
  consent evidence, export/deletion workflows, and incident response.
- Until the human decisions below are recorded, the application must continue
  operating without external recruitment integrations.

## Fitness Functions

- `bin/docs` rejects this record if its lifecycle metadata, skill IDs, or
  cross-links become invalid.
- A future adapter cannot import provider SDKs into recruitment controllers or
  models; the contract boundary must be visible in the module dependency check.
- Every future integration operation can be traced to one tenant, registration,
  contract version, purpose, scope, actor/trigger, and idempotency key without
  exposing secrets or raw personal data.
- A disabled, revoked, expired, or consent-invalid integration produces no
  external request and no domain mutation.
- A cross-tenant identifier, unverified callback, replayed event, or duplicate
  operation is rejected without creating a candidate, application, role, or
  calendar record.
- Export, deletion, retention, incident, and rollback evidence exists before a
  connector can be enabled for production data.

## Human decisions required

The agent can draft options and controls but cannot make these accountable
decisions:

1. Which of SSO, HRIS, calendar, partner API, or another connector is the first
   enterprise experiment, and what outcome and guardrail will measure it.
2. The target customer/tenant model, data residency, jurisdictions, contract,
   procurement, and service-level obligations.
3. Provider, protocol, issuer, endpoint, client registration, webhook model,
   and secret-custody owner for the selected connector.
4. Exact data fields, direction, purpose, lawful basis/consent, retention,
   export, deletion, training-use, and residency rules.
5. Whether any external identity or HRIS attribute may map to a local role;
   local authorization must remain authoritative by default.
6. Retry, rate-limit, replay, outage, reconciliation, duplicate, and manual
   recovery behavior, including the on-call owner.
7. Partner API onboarding, scopes, versioning, quotas, revocation, abuse
   response, accessibility, and support policy.
