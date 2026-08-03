---
id: SPEC-0015
type: spec
title: Persisted admin feature-flag settings
status: draft
owners: ["@product-owner", "@tech-lead", "@academic-owner"]
created: 2026-08-03
updated: 2026-08-04
review_by: 2026-08-10
supersedes: []
superseded_by: []
depends_on: [ADR-0015, ADR-0014, SPEC-0014]
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Persisted admin feature-flag settings

> **Review state:** The high-level typed allow-list boundary is approved, but
> this specification remains draft and blocked on the supported-flag list,
> scopes, runtime consumers, and academic/privacy policy. The current disabled
> controls must not become persisted settings by default. The `notifications`
> row is approved as the first bounded policy entry; remaining rows require
> separate review.

> [Executable Specifications](README.md) ·
> [M7 feature-flag decision](../decisions/adr-0015-feature-flag-boundary.md) ·
> [Roadmap Milestone 7](../roadmap.md#milestone-7--operational-admin-controls)

## Problem

The Features tab contains controls that are neither persisted nor connected to
runtime behavior. Administrators cannot tell which settings are operational,
and implementing a generic save action would create policy without an approved
consumer or scope.

## Scope

### Included after policy approval

- Define an allow-list of supported feature keys and typed option values.
- Persist the approved setting and scope with a safe default.
- Expose values through one runtime settings boundary used by consumers.
- Add admin-only updates with validation, stale-write protection, and audit.
- Show current state and effective scope in Thai and English.
- Remove or explicitly mark unsupported current controls as unavailable.

### Excluded

- Persisting a control solely because it appears in the current locale matrix.
- Changing behavior for a flag whose runtime consumer is not implemented.
- Arbitrary user-submitted feature keys, options, or scopes.
- Replacing deployment environment variables for infrastructure operations.
- Making academic-integrity, access, or learner-assessment policy decisions
  without the named owner.

## Invariants

1. Every rendered setting has one approved key, type, scope, default, owner, and
   runtime consumer.
2. Unsupported keys and options cannot be created or updated through the
   browser or a direct request.
3. A missing, malformed, or unavailable setting resolves to its approved safe
   default and does not disable required access or integrity protections.
4. A successful update changes the persisted setting and runtime behavior within
   the approved effective-time rule, and writes one audit event.
5. An invalid, unauthorized, stale, or failed update leaves the previous value
   and audit log unchanged.
6. The setting's scope is enforced by the runtime consumer, not only by the
   admin form.
7. Sensitive setting values and learner-level data are not exposed beyond the
   approved admin display and audit fields.
8. Existing behavior remains unchanged for settings that are removed or not
   approved.

## Acceptance Criteria

- [ ] The Product Owner, Tech Lead, and Academic Owner approve the supported
      flag table, scope, default, runtime consumer, actor, and safety policy
      (`docs/decisions/adr-0015-feature-flag-boundary.md`).
- [ ] The Features tab renders only approved supported flags or an honest
      unavailable state; no inert sample control remains
      (`test/controllers/admin_features_test.rb`).
- [ ] Typed settings, scopes, defaults, and allow-list validation are enforced
      (`test/models/feature_setting_test.rb`).
- [ ] An authorized update persists and changes the approved runtime behavior,
      with one audit event (`test/controllers/admin_features_test.rb`).
- [ ] Invalid, unauthorized, stale, and failed updates leave settings and audit
      history unchanged (`test/controllers/admin_features_test.rb`).
- [ ] Missing settings resolve to safe defaults and do not break consumers
      (`test/models/feature_setting_test.rb`).
- [ ] Thai and English browser walkthroughs demonstrate the approved setting or
      truthful unavailable state (`test/system/admin_features_walk_test.rb`).
- [ ] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- No supported flags remain after policy review.
- A setting row is missing, duplicated, malformed, or has an unknown option.
- A scope target is deleted or the acting administrator lacks that scope.
- Two administrators update the same setting from stale screens.
- A runtime consumer fails while the settings write succeeds; the transaction
  and fallback behavior must follow the approved policy.
- A direct request posts a key, option, or scope absent from the rendered form.
- A flag affects proctoring, access, notifications, leaderboard, or language and
  requires a safety/academic review before taking effect.

## Human Feature Policy Handoff

Implementation is held until the accountable owners complete this table. The
agent can implement an approved typed setting, but cannot decide whether an
institution-wide learner behavior should exist.

The approved rows are:

- `notifications`: boolean, global scope, default on, consumed by notification
  creation and delivery, editable by an administrator, effective immediately,
  fail-safe on, and rollback-supported. Its content and audit behavior remain
  localized and within existing privacy boundaries.
- `search`: boolean, global scope, default on, consumed by the learner/admin
  search UI and query behavior, editable by an administrator, effective
  immediately, fail-safe on, and rollback-supported.
- `leaderboard`: boolean, global scope, default off, consumed by learner
  leaderboard visibility, editable by an administrator or Academic Owner,
  effective immediately, fail-safe off for privacy, and rollback-supported.

| Review point | Decision required |
| --- | --- |
| Supported list | Keep, remove, or defer each current control. |
| Runtime behavior | Name the real consumer and observable behavior for each retained flag. |
| Scope and actors | Choose global/course/section/role/learner scope and authorized editors. |
| Defaults and failure | Define safe default, missing-row behavior, and consumer failure behavior. |
| Effective time | Choose immediate, scheduled, approval-gated, and rollback semantics. |
| Academic/privacy review | Review proctoring, access, language, leaderboard, hearts, and notification effects. |
| Audit and operations | Approve event fields, retention, correction, support, and monitoring. |

## Rollback and observability

- Rollback restores the previous typed value or safe default without deleting
  settings history or audit events.
- Record update failures, fallback use, and consumer errors without exposing
  learner-level data.
- Monitor effective setting changes only after an owner and expected behavior are
  documented for each flag.

## Verification

```bash
bin/docs
bin/rails test test/models/feature_setting_test.rb
bin/rails test test/controllers/admin_features_test.rb
bin/rails test:system test/system/admin_features_walk_test.rb
bin/verify
```
