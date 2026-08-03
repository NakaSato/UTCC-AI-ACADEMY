---
id: ADR-0015
type: adr
title: Define which admin feature flags are real and how settings persist
status: accepted
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0014, SPEC-0014]
implemented_by: []
touches:
  - app/models/admin_console.rb
  - app/views/admin/_features.html.erb
  - app/controllers/admin_controller.rb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define which admin feature flags are real and how settings persist

> **Decision state:** The high-level boundary was approved by the user on
> 2026-08-04: use a typed allow-list of explicitly supported flags, with one
> runtime consumer and safe defaults per flag. The concrete flag table,
> consumers, scopes, defaults, actors, and academic/privacy review remain
> implementation prerequisites.

> [Decision Records](README.md) ·
> [M7 feature-flag specification](../specs/spec-m7-feature-flag-settings.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Context

The admin Features tab renders a Ruby list of toggles and selectors with
shipped defaults. The controls are disabled because no setting record exists,
and the application has no common runtime boundary that reads these values.
Persisting every visible control would make labels look authoritative even when
the corresponding feature does not change behavior.

Feature settings can also affect every learner account, course availability,
academic-integrity behavior, or language experience. They need scope, actor,
audit, rollback, and safe defaults rather than a generic key/value table that
silently accepts arbitrary keys.

## Problem frame

- **Affected user:** An administrator deciding which supported academy behaviors
  are enabled and a learner experiencing the resulting behavior.
- **Current behavior:** The screen presents nine sample controls, none of which
  persists or necessarily changes the application.
- **Failure risk:** An admin believes a setting changed, or a setting changes a
  sensitive behavior without an owner, scope, audit event, or rollback path.
- **Success signal:** Every rendered control is either removed as unsupported or
  has a real runtime consumer, persisted value, authorized mutation, and audit
  evidence.

## Decision boundary

1. Only explicitly approved flags may appear in the admin screen or settings
   store; unsupported sample controls are removed rather than persisted.
2. Each approved flag has a typed value, documented scope, default, runtime
   consumer, owner, and safe failure behavior.
3. Settings are read through one runtime boundary; application code must not
   query arbitrary setting keys or rely on UI defaults.
4. Sensitive behavior changes require the approved authorization, audit event,
   effective-time semantics, and rollback behavior for that flag.
5. An invalid, stale, unauthorized, or failed update leaves the previous value
   unchanged and creates no success audit event.
6. Defaults remain safe if a setting row is missing, malformed, or temporarily
   unavailable.
7. A setting mutation cannot be smuggled through an unapproved key, option, or
   scope posted by the browser.

## Alternatives

### Persist a typed allow-list of supported flags

Each supported flag has an explicit definition and runtime adapter. This keeps
the boundary narrow and testable, but requires a new definition when behavior
is added. It is the recommended option.

### Persist the current Ruby matrix as generic JSON

This is quick, but it stores controls that have no runtime consumer, weakens
type and option validation, and turns a design mock into institution-wide
policy. It is rejected.

### Remove the entire Features tab

This is the safest state while no supported flag has an owner or behavior. It
avoids misleading controls but provides no operational control for features the
team may intentionally support later.

### Use environment variables only

This can be appropriate for deployment-wide operational switches, but it does
not provide administrator visibility, audit, or scoped UI behavior. It should
remain an explicit alternative for infrastructure flags rather than the default
for academic product settings.

## Human decisions required

- Which of the current controls are real product behavior and which must be
  removed.
- For each retained flag: owner, type, default, scope, runtime consumer, and
  safe failure behavior.
- Whether scope is global, course, section, role, or learner, and who may edit
  each scope.
- Whether changes are immediate, scheduled, or require approval; define
  effective time and rollback semantics.
- Whether proctoring, language, leaderboard, hearts, and notifications have
  academic or privacy review requirements.
- Audit fields, settings retention, correction, and display of current values.
- How a missing or corrupted setting behaves in each consumer.

## Consequences

- The first implementation may remove most of the current tab, but every
  remaining control will have a real effect and an accountable owner.
- A typed allow-list prevents accidental flags but requires code changes for
  new behavior; that is intentional for high-impact academic settings.
- Runtime consumers must be tested independently from the admin form so a
  visually successful update cannot be mistaken for behavior change.
- Persistent settings create operational state that must be backed up, audited,
  and included in release/rollback planning.

## Fitness Functions

- `bin/docs` validates the decision record and review metadata.
- Tests prove every rendered setting has a runtime consumer, typed validation,
  safe defaults, authorization, and audit behavior.
- A browser walkthrough demonstrates an approved setting changing behavior in
  Thai and English, or proves unsupported controls are absent.
- Security and academic review confirm that sensitive flags do not broaden
  access or weaken integrity controls unexpectedly.
