---
title: Coding Standard
---

# Coding Standard

**Tags:** [#development](tags.md#development) [#conventions](tags.md#conventions) [#architecture](tags.md#architecture) [#security](tags.md#security)

`CLAUDE.md` remains the detailed architecture authority. This guide collects
review rules that RuboCop cannot enforce.

## Boundaries

- Controllers authenticate, authorize, validate parameters, delegate, and
  render. Domain calculations belong in models or the existing named bridge
  objects.
- Views read the objects they receive. They do not query or reconstruct domain
  state.
- Prefer extending an existing domain boundary over introducing a generic
  service layer.
- Keep persisted identity and taxonomy in Active Record; keep translated
  learning copy behind the existing content modules.

## Interfaces and Naming

- Use domain names already present in routes, models, and locale keys.
- Make invalid states difficult to represent with database constraints and
  model validations.
- Keep public method inputs small and explicit; whitelist external parameters.
- Treat changes to routes, locale array positions, broadcasts, and Turbo Frame
  identifiers as interface changes.

## Errors

- Rescue only exceptions the caller can handle meaningfully.
- Preserve error context in logs without recording credentials, student IDs,
  profile PII, answers, or reset tokens.
- Do not turn authorization failures, delivery failures, or failed grading into
  silent success.
- User-facing errors must be actionable and available in Thai and English.

## Data and Migrations

- Add a new migration; never edit one that may have run elsewhere.
- Use expand → migrate → contract for incompatible schema changes.
- Backfills must be restartable and observable.
- Enforce uniqueness, required relationships, and business invariants in the
  database where practical.
- A migration is Tier C and requires line-by-line human review.

## Dependencies

Add a gem, JavaScript package, external service, or hosted dependency only after
an accepted ADR identifies:

- the capability it supplies;
- alternatives considered, including no dependency;
- maintenance and security ownership;
- failure and removal paths;
- license and supply-chain implications.

## Agent-Written Code

- The human reviewer owns intent and acceptance criteria.
- Review error paths, empty-input boundaries, authorization, concurrency, and
  off-by-one behavior explicitly.
- Never accept tests only because they pass; confirm they prove the invariant.
- Tier C output receives a fresh human read after automated checks pass.
