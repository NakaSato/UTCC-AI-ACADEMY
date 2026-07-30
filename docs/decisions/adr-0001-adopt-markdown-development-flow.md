---
id: ADR-0001
type: adr
title: Adopt a repository-native Markdown development flow
status: accepted
owners: ["@chanthawat"]
created: 2026-07-30
updated: 2026-07-30
review_by: 2027-01-30
supersedes: []
superseded_by: []
depends_on: []
implemented_by: []
touches:
  - AGENTS.md
  - docs/development-flow.md
  - docs/mdlc.md
  - config/ci.rb
  - .github/workflows/ci.yml
enforced_by:
  - bin/docs
  - bin/verify
agent_writable: false
---

# Adopt a Repository-Native Markdown Development Flow

**Tags:** [#decisions](../tags.md#decisions) [#governance](../tags.md#governance) [#process](../tags.md#process) [#verification](../tags.md#verification)

## Context

The repository already stores planning in `docs/roadmap.md` and
`docs/backlog.json`, architecture invariants in `CLAUDE.md`, and verification in
`bin/ci` plus GitHub Actions. `docs/mdlc.md` proposed structured ADRs, specs,
runbooks, and postmortems, but its schema and gates were not operational.

The project needs traceability from intent to verification without creating a
second backlog or claiming that absent production controls already exist.

## Decision

Adopt the lifecycle in `docs/development-flow.md`:

- retain the roadmap and JSON backlog as planning authorities;
- record consequential decisions as ADRs;
- require executable specs for ambiguous Tier B/C behavior;
- use `AGENTS.md` as the shared human/agent working agreement;
- expose the existing CI pipeline through `bin/verify`;
- validate lifecycle frontmatter, references, and enforcement paths with
  `bin/docs`;
- provide release, runbook, postmortem, and outcome templates for use when the
  corresponding event exists;
- keep accountability and approval with named humans.

## Alternatives

### Adopt the canonical lifecycle unchanged

Rejected because PRDs, RFCs, service catalogs, deployment attestations, and
multi-team RACI routing would duplicate or misrepresent this one-repository,
one-owner Rails project.

### Keep the lifecycle as prose only

Rejected because proposed schemas and gates can be cited as if they run. A
machine-checkable subset is safer than a comprehensive but fictional process.

### Use an external project-management system as the authority

Rejected for now because `docs/backlog.json` already drives the published
dashboard and Git history provides the audit trail.

## Consequences

- New lifecycle documents must pass `bin/docs`.
- Accepted specs must name at least one enforcement path.
- Documentation validation becomes part of local and remote CI.
- A human must approve accepted decisions and releases.
- Production supply-chain and progressive-delivery controls remain explicit
  gaps until real infrastructure exists.
- The additional templates create maintenance cost and must be removed or
  superseded if the team does not use them.

## Fitness Functions

- `bin/docs` rejects invalid frontmatter, dangling document references, and
  missing `touches` or `enforced_by` paths.
- `config/ci.rb` runs the documentation gate locally.
- `.github/workflows/ci.yml` runs the same policy independently.
- `docs/backlog.json` remains the only execution-status ledger.
