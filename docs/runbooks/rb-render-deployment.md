---
id: RB-0004
type: runbook
title: Deploy and roll back the Render production image
status: draft
owners: ["@release-owner", "@platform-owner", "@on-call-owner", "@tech-lead"]
created: 2026-08-06
updated: 2026-08-06
review_by: 2026-08-13
depends_on: [ADR-0020, ADR-0021, ADR-0022, SPEC-0022]
touches:
  - render.yaml
  - .github/workflows/release-artifact.yml
  - .github/workflows/render-deploy.yml
  - docs/releases
  - config/database.yml
enforced_by:
  - test/release/artifact_provenance_test.rb
  - test/release/deployment_configuration_test.rb
  - test/release/release_gate_test.rb
agent_writable: true
---

# Deploy and roll back the Render production image

> This runbook defines the approved Render image and release boundary. It does
> not contain credentials, trigger a deployment, or claim that the production
> dashboard has been configured.

## Preconditions

- The CI workflow for the exact source commit is green.
- The Release Owner has reviewed the planned release record and migration
  compatibility.
- The GHCR package contains the image digest, SBOM, vulnerability result,
  signature, and provenance evidence for that commit.
- The Render workspace has the registry credential named
  utcc-ai-academy-ghcr, the production environment has required reviewers, and
  RENDER_DEPLOY_HOOK_URL is stored only as a GitHub Actions secret.
- RAILS_MASTER_KEY and DATABASE_URL exist in the Render dashboard and are not
  copied into GitHub logs, artifacts, or messages.
- Backup freshness and the isolated recovery evidence meet ADR-0021.
- Mailpit is used only for isolated staging. Production mail remains deferred
  until MAIL-002 and MAIL-003 are separately completed.

## Procedure

1. Open the release evidence artifact for the exact Git commit. Confirm that
   the manifest reference is the full GHCR image plus sha256 digest and that
   the vulnerability result has no unapproved Critical finding.
2. Review the database changes. Run Expand first, then the pre-deploy
   migration, and schedule Contract only after the old application version is
   no longer active.
3. Start the Render Production Deploy workflow with the full immutable image
   reference. The workflow requires the production environment approval and
   sends the digest through the Render deploy hook.
4. Render runs bin/rails db:migrate as the pre-deploy command. Wait for that
   migration to finish. If it fails, stop
   promotion, preserve the deploy evidence, and do not retry with a different
   image until the failure is understood.
5. Confirm the Render health check reports healthy and complete the
   post-deploy checks in the planned release record.
6. Record the Render deploy identifier, deployed digest, migration result,
   health evidence, operator, and outcome without recording secrets or learner
   data.

## Rollback

1. The Release Owner or On-call Owner may initiate rollback when three
   consecutive health checks fail, the authenticated smoke path fails, or the
   first 15 minutes exceed one percent HTTP 5xx responses.
2. Confirm the target digest is still available in GHCR and that the current
   database schema is backward-compatible with that image.
3. Use the Render dashboard rollback action or Render API for the exact
   known-good deploy. Do not use the mutable release tag.
4. If the schema or data is not backward-compatible, do not roll back the
   image. Use a forward fix or the isolated recovery procedure from
   RB-0003, with the Tech Lead and Platform Owner.
5. Re-run health, authenticated read, job, WebSocket, storage, and recovery
   checks. Preserve all failing evidence for incident review.

## Verification

- Three consecutive /up checks succeed within 30 seconds.
- Three synthetic authenticated read checks succeed within two minutes.
- No unexpected migration error remains in the Render deploy log.
- No failed Solid Queue job is created by the smoke path.
- A WebSocket connection and a storage read succeed in the approved synthetic
  environment.
- No real email or Mailpit endpoint is used by the production check.
- HTTP 5xx remains below one percent during the first 15 minutes.
- The deployed digest equals the release manifest digest.
- Backup freshness and recovery signals remain within the ADR-0021 contract.

## Escalation

- Deployment, registry, or platform failure: Platform Owner.
- Migration or application failure: Tech Lead.
- Release approval or rollback decision: Release Owner.
- Secret, signature, vulnerability, or telemetry boundary: Security Owner.
- Data recovery or backup failure: On-call Owner and Platform Owner.
