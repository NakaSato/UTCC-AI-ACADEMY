---
id: SPEC-0029
type: spec
title: Structured, consented, and portable candidate profiles
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-08
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0024, ADR-0029, SPEC-0024]
implemented_by:
  - app/models/candidate_profile.rb
  - app/models/candidate_profile_fact.rb
  - app/controllers/recruitment/candidate_profiles_controller.rb
  - db/migrate/20260807210000_extend_candidate_profiles.rb
  - db/migrate/20260807220000_create_active_storage_variant_records.rb
  - test/models/candidate_profile_test.rb
  - test/models/candidate_profile_fact_test.rb
  - test/controllers/recruitment/candidate_profiles_controller_test.rb
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
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
---

# Structured, Consented, and Portable Candidate Profiles

> [Executable Specifications](README.md) ·
> [Candidate-profile boundary ADR](../decisions/adr-0029-candidate-profile-data-boundary.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

> **Review state:** Accepted by the user on 2026-08-08 for the first structured
> candidate-profile implementation slice, including consent, portability,
> provenance, attachment, export, and deletion boundaries.

## Problem

The existing candidate profile stores only a headline, summary, location, and
visibility. Candidates need a complete profile they can inspect, correct, carry
between opportunities, and remove, while employers and future AI features must
not receive data without an explicit visibility and reuse decision.

## Scope

### Included

- Profile headline, summary, preferred location, salary expectation, GitHub,
  LinkedIn, and portfolio references.
- Resume and portfolio file attachments through Active Storage with limits.
- Repeatable education, experience, skill, certification, and language facts.
- Fact source (`self_reported`, `document_extracted`, `human_reviewed`) and
  confidence from 0 to 1.
- Private/application-only/searchable visibility and independent application
  data-reuse consent with timestamp.
- Candidate-owned export and destructive delete actions.

### Excluded

- Resume parsing, AI extraction, skill inference, recruiter search, matching,
  ranking, applications, and protected-characteristic inference.
- Automatic consent from uploading a resume or changing visibility.

## Invariants

1. Each student has at most one candidate profile; non-students cannot own one.
2. Each fact belongs to exactly one profile and cannot be addressed through
   another user’s self-service route.
3. Fact kinds, sources, and confidence values are restricted to approved sets;
   confidence is between 0 and 1.
4. Visibility defaults to `private`; `searchable` requires an explicit profile
   choice but does not imply application-data reuse consent.
5. A profile export includes source/confidence metadata and the consent state.
6. Deleting a profile removes its facts and attachments and leaves no self-service
   profile record to read.
7. Resume and portfolio uploads accept only approved content types and bounded
   sizes; file names and URLs are treated as untrusted display data.

## Acceptance Criteria

- [x] A student can save and correct structured profile fields and repeatable
      facts.
- [x] A student can upload/remove resume and portfolio files within limits.
- [x] A student can choose visibility and application-data reuse independently.
- [x] Fact export preserves source and confidence metadata.
- [x] A student can download an export and permanently delete their profile.
- [x] Other students and staff cannot access the profile self-service data.

## Boundary Cases

- Invalid URLs, salary ranges, fact kinds, sources, confidence, and oversized or
  unsupported files are rejected without partial profile writes.
- Blank nested fact rows are ignored; persisted facts can be individually
  deleted from the profile form.
- Deletion removes attachments before the profile row is destroyed.
- The profile remains private when consent is withdrawn.

## Verification

    bin/docs
    bin/rails test test/models/candidate_profile_test.rb test/models/candidate_profile_fact_test.rb test/controllers/recruitment/candidate_profiles_controller_test.rb
    bin/verify
