---
id: ADR-0029
type: adr
title: Keep candidate profile data candidate-owned, portable, and provenance-aware
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0024, SPEC-0024, ADR-0028]
implemented_by:
  - SPEC-0029
  - app/models/candidate_profile.rb
  - app/models/candidate_profile_fact.rb
  - app/controllers/recruitment/candidate_profiles_controller.rb
  - db/migrate/20260807210000_extend_candidate_profiles.rb
  - db/migrate/20260807220000_create_active_storage_variant_records.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test/models
  - test/controllers
enforced_by:
  - test/models/candidate_profile_test.rb
  - test/models/candidate_profile_fact_test.rb
  - test/controllers/recruitment/candidate_profiles_controller_test.rb
agent_writable: true
---

# Keep Candidate Profile Data Candidate-Owned, Portable, and Provenance-Aware

> [Decision Records](README.md) ·
> [Candidate-profile specification](../specs/spec-recruitment-candidate-profile.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Decision state:** Accepted by the user on 2026-08-08 for candidate-owned,
> portable, provenance-aware profile data, consented visibility/reuse,
> bounded attachments, export/delete controls, and privacy boundaries.

## Context

Milestone M1 created a private candidate-profile shell. M5 needs a complete
profile without making candidate data searchable by default or pretending that
manual profile entries came from an AI extractor. Resumes and portfolio links
are sensitive, and candidates need to inspect, correct, export, and delete what
the platform stores about them.

## Decision

- Keep one profile per student, owned by that student and reachable only through
  the self-service route in this increment.
- Store portable contact/work references and salary/location preferences on the
  profile; store repeatable education, experience, skill, certification, and
  language entries as provenance-aware facts.
- Mark manually entered facts as `self_reported` with full confidence by
  default; later document extraction must use a different source and preserve
  its confidence for candidate correction before use.
- Support `private`, `application_only`, and `searchable` visibility. Searchable
  is an explicit candidate choice, not a default.
- Store a separate application-data-reuse consent boolean and timestamp. A
  profile visibility choice cannot silently imply consent to reuse.
- Use Active Storage for a resume and portfolio files, with content-type and
  size limits. Export returns structured profile/fact metadata, not opaque
  internal records.
- Let the candidate delete the profile and attached data from the self-service
  screen. Recruiter browsing, matching, ranking, and AI extraction remain out
  of scope until later milestones and policies are approved.

## Alternatives

### Store all profile data in one JSON document

Rejected. It makes per-fact correction, provenance, validation, indexing, and
safe export harder.

### Make every profile searchable after completion

Rejected. Searchability is a consequential disclosure choice and must be
explicit, reversible, and independent from application-data reuse consent.

### Parse resumes during profile editing

Rejected for M5. Resume extraction belongs to M6 and requires a separate model,
source, confidence, correction, and fairness review boundary.

## Consequences

- Profile editing becomes a richer form and creates a few more records.
- Attachment deletion and retention need operational review before production.
- Later application and matching work can consume explicit profile fields while
  retaining a source trail and consent decision.

## Fitness Functions

- Staff and other students cannot use the self-service profile route.
- A profile cannot be saved for a non-student, and facts cannot escape its
  profile owner.
- Visibility defaults to private; reuse consent is independently persisted.
- Fact source and confidence are validated and remain present on export.
- Delete removes the profile, facts, and attached blobs through the owner action.
- `bin/docs` and focused candidate-profile tests pass.
