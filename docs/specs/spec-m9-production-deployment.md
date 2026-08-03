---
id: SPEC-0022
type: spec
title: Production deployment, artifact, migration, and rollback contract
status: draft
owners: ["@platform-owner", "@tech-lead", "@security-owner", "@release-owner"]
created: 2026-08-03
updated: 2026-08-03
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0022, ADR-0020, ADR-0021]
implemented_by: []
touches:
  - config/deploy.yml
  - Dockerfile
  - .github/workflows/ci.yml
  - bin/kamal
  - config/database.yml
  - config/environments/production.rb
  - docs/build-release.md
  - docs/releases
  - docs/runbooks
  - db
  - lib
enforced_by: []
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-BLD-002, SKILL-BLD-003, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-BLD-002, SKILL-BLD-003]
---

# Production deployment, artifact, migration, and rollback contract

> **Review state:** Draft and blocked on the real target, registry, domain/TLS,
> secrets, process topology, release ownership, artifact provenance, migration
> compatibility, rollback, and post-deploy policy. No production readiness is
> claimed.

> [Executable Specifications](README.md) ·
> [M9 deployment decision](../decisions/adr-0022-production-deployment-boundary.md) ·
> [Roadmap Milestone 9](../roadmap.md#milestone-9--production-hardening)

## Problem

The repository has a Dockerfile, CI gate, and placeholder Kamal configuration,
but not a real production deployment contract. The database and storage have
separate operational boundaries, while the release policy requires immutable
artifacts, provenance, migration safety, rollback, manual approval, and
post-deploy verification.

## Scope

### Included after policy approval

- Name the real hosting, registry, domain/TLS, region, database, storage,
  secrets, job, WebSocket, and capacity boundaries.
- Build once, produce an SBOM and provenance, sign/verify the artifact, and
  promote its immutable digest.
- Define manual approval, Release Owner, On-call Owner, deploy window, abort
  criteria, migration phases, rollback, and post-deploy checks.
- Add release, deployment, rollback, migration, and failed-deploy runbooks.
- Verify safe interaction with backups/recovery, observability, mail, jobs,
  WebSockets, storage, and database connections.

### Excluded

- Choosing a provider, host, registry, domain, region, or paid service without
  the accountable human decision.
- Deploying with the private placeholder host, localhost registry, example TLS,
  repository-held secrets, or mutable “latest” identity.
- Rebuilding an image between verification, approval, and deployment.
- Running a destructive migration or claiming rollback is possible when data
  compatibility has not been verified.
- Automatic production remediation or release approval by an agent or CI job.

## Invariants

1. A release identifies one immutable artifact digest, source commit, applicable
   specs, SBOM, vulnerability result, signature/provenance, environment, and
   human approver.
2. Production secrets are injected from the approved secret boundary and never
   appear in Git, images, logs, release artifacts, or chat notifications.
3. Database changes follow expand → migrate → contract, and both old and new
   application versions are compatible during the approved rollout window.
4. A release has a tested rollback or an explicit human-approved statement that
   rollback requires a data/recovery procedure rather than image reversal.
5. Post-deploy checks cover boot, authenticated read, database, storage, job,
   mail-safe behavior, WebSocket, observability, and backup/recovery signals.
6. Release failure stops promotion and preserves the last known-good artifact;
   it does not silently deploy a rebuilt or unverified substitute.
7. Deployment logs and status messages expose only approved identifiers,
   symptoms, owners, and links; they do not expose learner data or credentials.
8. A real production target cannot be marked ready while required domains,
   TLS, capacity, monitoring, recovery, or support ownership remain placeholders.

## Acceptance Criteria

- [ ] The Platform Owner, Tech Lead, Security Owner, and Release Owner approve
      the target, registry, domain/TLS, region, secrets, process topology,
      capacity, owners, and release window
      (`docs/decisions/adr-0022-production-deployment-boundary.md`).
- [ ] The CI/build path produces and records the approved immutable artifact,
      SBOM, signature, provenance, and vulnerability result
      (`test/release/artifact_provenance_test.rb`).
- [ ] The deployment configuration contains no active placeholder host,
      registry, TLS, secret, or database target
      (`test/release/deployment_configuration_test.rb`).
- [ ] A release record names migration phases, compatibility, approval,
      rollback, owners, and numeric post-deploy checks
      (`docs/releases/release-production-template.md`).
- [ ] Staging or an approved pre-production target exercises deploy, migration,
      health, storage, jobs, WebSockets, mail-safe behavior, and rollback
      (`test/release/deployment_walk_test.rb`).
- [ ] Failed deployment, migration, health, backup, or observability checks stop
      promotion and preserve an actionable evidence trail
      (`test/release/release_gate_test.rb`).
- [ ] Release and rollback runbooks are executable and linked to the approved
      recovery/observability contracts (`docs/runbooks/`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- The registry is unavailable, the image digest differs, or signature/provenance
  verification fails.
- A host, domain, certificate, secret, database, storage volume, or worker is
  configured for the wrong environment.
- One container is updated while another still runs the previous schema/code.
- A migration succeeds but the application health or background job check fails.
- A rolling deployment leaves old WebSocket clients or jobs connected.
- A post-deploy check sends real mail, notifications, or learner-visible data.
- The release fails after a destructive migration or after a backup window is
  missed; image rollback alone is unsafe.
- The rollback target is unavailable or its artifact no longer passes current
  security verification.

## Human Release Handoff

Implementation and production use are held until the accountable owners complete
this table.

| Review point | Decision required |
| --- | --- |
| Target | Host/provider, region, domain, TLS, network, capacity, and support. |
| Artifact | Registry, builder, SBOM, signing, provenance, vulnerability policy. |
| Secrets | Store, rotation, scope, access review, and emergency recovery. |
| Processes | Web, jobs, WebSockets, storage, database, and scaling topology. |
| Migration | Expand/migrate/contract order and backward compatibility. |
| Release | Approval, owners, window, abort threshold, and evidence record. |
| Rollback | Exact action, data caveat, trigger, authority, and verification. |
| Operations | Post-deploy checks, runbooks, monitoring, recovery, and support. |

## Rollback and observability

- Rollback follows the release record's tested action; it may be an image
  reversal, traffic shift, forward-fix, or recovery procedure depending on data
  compatibility.
- Preserve the deployed artifact, migration output, health evidence, and
  observability timeline for incident review; do not erase evidence to make a
  release appear green.
- Monitor deployment status, error/latency symptoms, queue/mail/WebSocket
  health, database saturation, storage, backup freshness, and recovery signals
  under ADR-0020 and ADR-0021.

## Verification

```bash
bin/docs
bin/verify
```
