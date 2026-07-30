---
title: Build and Release Policy
---

# Build and Release Policy

**Tags:** [#development](tags.md#development) [#verification](tags.md#verification) [#operations](tags.md#operations) [#security](tags.md#security)

This policy separates controls that exist today from controls required before
the first application production deployment.

## Existing Build Gate

`bin/verify` delegates to the Rails continuous-integration pipeline in
`config/ci.rb`. It performs setup, documentation validation, Ruby style checks,
dependency audits, static security analysis, application tests, deterministic
seed replanting, and system tests.

`.github/workflows/ci.yml` independently performs the same policy categories on
a clean runner. A local pass is self-verification; the remote pass is the
independent gate.

## Artifact Rules

Before an application image is released:

- build once and promote the same image through environments;
- tag it with both semantic version and Git SHA;
- embed commit and specification identifiers as metadata;
- generate an SBOM in CycloneDX or SPDX format;
- block Critical known vulnerabilities unless a time-bounded, human-approved
  exception is recorded;
- sign the image and retain provenance;
- never rebuild during deployment.

These rules are requirements, not claims about the current placeholder Kamal
configuration.

## Release Gate

Use `docs/templates/release.md` for production releases. Tier C releases require
a named Release Owner and On-call Owner, a manual approval, an immediate
rollback path, and post-release checks.

Database changes are released in three phases:

1. **Expand:** add backward-compatible schema.
2. **Migrate:** backfill with an observable, restartable operation.
3. **Contract:** remove old schema only after all code has stopped using it.

## Rollback

A rollback plan must identify:

- the exact previously known-good image;
- the command or platform action that restores it;
- feature switches, if any;
- whether the database is backward-compatible;
- the metric or symptom that triggers rollback;
- who has authority to act.

“Redeploy the previous version” is not a plan until it has been tested against
the current database shape.

## Current Gaps

- The application deployment target in `config/deploy.yml` is a placeholder.
- There is no image registry policy, SBOM generation, signing, or attestation.
- There is no canary analysis, application SLO, or automatic rollback.
- Database backup and restore have not been exercised against a production
  environment.

No release document may mark these controls complete until evidence exists.
