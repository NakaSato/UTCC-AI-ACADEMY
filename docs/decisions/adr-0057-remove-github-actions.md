---
id: ADR-0057
type: adr
title: Remove the GitHub Actions workflows and make the local gate the only gate
status: draft
owners: ["@repository-owner", "@platform-owner", "@release-owner"]
created: 2026-10-17
updated: 2026-10-17
review_by: 2027-01-15
supersedes: []
superseded_by: []
depends_on: [ADR-0001, ADR-0022, ADR-0023]
implemented_by: []
touches:
  - .github/dependabot.yml
  - config/ci.rb
  - bin/verify
  - test/release/deployment_configuration_test.rb
  - test/scripts/slack_status_update_test.rb
  - docs/build-release.md
  - docs/agent-flow.md
  - docs/slack.md
enforced_by: []
agent_writable: true
---

# Remove the GitHub Actions workflows and make the local gate the only gate

## Context

The repository had four workflows under `.github/workflows/`:

- `ci.yml` — the independent copy of `config/ci.rb` on a clean runner, plus the
  failed-`main` Slack alert and the lifecycle-status Slack mirror.
- `pages.yml` — the GitHub Pages documentation publisher.
- `release-artifact.yml` — built, scanned, signed, and attested the production
  image in GHCR (ADR-0022).
- `render-deploy.yml` — the manual production promotion through the Render
  deploy hook (ADR-0022, RB-0004).

None of them had run since August 2026. GitHub Actions refused every run for an
account billing lock (recorded in `docs/backlog.json` and
`docs/specs/spec-error-pages.md`), so the "independent gate" the process
documents described was not running, and the documentation site was already
served by Vercel, not by `pages.yml`.

On 2026-10-17 the repository owner chose to delete the workflows rather than
keep files that describe a gate nobody runs.

## Decision

1. Delete all four workflows. Keep `.github/dependabot.yml` for the `bundler`
   ecosystem only; drop its `github-actions` entry, because there are no
   actions left to update.
2. `bin/verify` (which delegates to `bin/ci` and `config/ci.rb`) is the only
   build gate. Its steps do not change. "Green on your machine" was already
   the definition of done in `docs/process.md`; it is now also the only
   evidence.
3. Delete the two tests that read workflow files (the deploy-digest check and
   the Slack-status job shape). `script/slack-status-update` and its remaining
   tests stay; nothing invokes the script now.
4. Production promotion has **no automated path**. ADR-0022's artifact rules
   (immutable digest, SBOM, Critical scan, signature, provenance) still stand
   as requirements, but nothing implements them. RB-0004 cannot be executed as
   written until a replacement is chosen.
5. ADR-0001 (`agent_writable: false`) lists `.github/workflows/ci.yml` as a
   fitness function. Only its `touches` entry was removed, because `bin/docs`
   rejects a missing path. Its body is left for its owner to amend.

## Alternatives

- **Keep the workflows and fix the billing lock.** Restores the independent
  gate and the signed-artifact pipeline. Not chosen by the owner.
- **Keep only `ci.yml`.** Smaller loss of independence, but it would stay
  dormant for the same billing reason.
- **Move to another hosted CI.** Possible later; it would need its own ADR.

## Consequences

- There is no independent gate. An agent that runs `bin/verify` is reporting
  on itself, so the human reading the diff must run `bin/verify` too, for every
  tier, before pushing (`docs/agent-flow.md`).
- Nothing posts to Slack about builds or lifecycle status.
- No release artifact is built or signed, and RB-0004 is blocked. Any
  production deploy before a replacement exists is outside ADR-0022's
  boundary and needs the Release Owner's explicit sign-off.
- The documentation site is unaffected: Vercel builds it on push.

## Fitness Functions

- `bin/docs` fails if any document's `touches` names a workflow file that no
  longer exists.
- `config/ci.rb` remains the single list of gate steps.
