---
id: SPEC-0030
type: spec
title: Candidate-controlled provider-neutral resume analysis
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0029, ADR-0030, SPEC-0029]
implemented_by:
  - app/models/recruitment/candidate_resume_analysis.rb
  - app/models/recruitment/candidate_resume_finding.rb
  - app/services/recruitment/candidate_resume_analysis_generator.rb
  - app/controllers/recruitment/candidate_resume_analyses_controller.rb
  - app/views/recruitment/candidate_profiles/edit.html.erb
  - db/migrate/20260808110000_create_recruitment_candidate_resume_analyses.rb
  - test/models/recruitment/candidate_resume_analysis_test.rb
  - test/models/recruitment/candidate_resume_finding_test.rb
  - test/controllers/recruitment/candidate_resume_analyses_controller_test.rb
touches:
  - app/models
  - app/controllers
  - app/services
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test/models
  - test/controllers
enforced_by:
  - test/models/recruitment/candidate_resume_analysis_test.rb
  - test/models/recruitment/candidate_resume_finding_test.rb
  - test/controllers/recruitment/candidate_resume_analyses_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-SPEC-002, SKILL-TEST-001, SKILL-AI-001, SKILL-AI-002]
min_reviewer_skills: [SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-001, SKILL-AI-002]
---

# Candidate-Controlled Provider-Neutral Resume Analysis

> **Review state:** Accepted by the user on 2026-08-08 for the first
> provider-neutral, candidate-reviewed implementation slice. No production model
> provider or consequential downstream use is authorized.

> [Executable Specifications](README.md) ·
> [Resume-analysis boundary ADR](../decisions/adr-0030-provider-neutral-resume-analysis.md) ·
> [Candidate-profile specification](spec-recruitment-candidate-profile.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Scope

## Problem

Candidates need structured resume information without an opaque score or an
automatic change to their portable profile. Recruiters and future AI services
also need a clear distinction between resume evidence, deterministic workflow
inference, uncertainty, and a candidate-corrected value.

### Included

- Explicit candidate-triggered analysis of an attached resume.
- Persisted analysis metadata and per-finding evidence, source type, confidence,
  inference flag, uncertainty, and review status.
- Bounded `rules_preview` parsing for `text/plain` section labels: skills, tools,
  experience, education/qualifications, certifications, and languages.
- Metadata-only findings for PDF and Word files until a text-extraction adapter is
  approved and evaluated.
- Candidate correction, acceptance, rejection, and application of accepted facts.
- Facts applied from resume findings are marked `document_extracted` and retain
  their finding confidence. Non-fact signals are never copied into the profile.

### Excluded

- Hosted model calls, recruiter search, matching, ranking, recommendations, or
  hiring decisions.
- Protected-characteristic extraction, proxy inference, or downstream scoring.
- Automatic application of findings or automatic consent to reuse profile data.
- Accuracy claims for document types without a supported text extractor.

## Data contract

`CandidateResumeAnalysis` stores the candidate profile, requesting/reviewing
user, provider, source label, source metadata, uncertainty, lifecycle status,
and timestamps. `CandidateResumeFinding` stores one proposed item and requires a
kind, title, evidence, source type, confidence from 0 to 1, inference flag, and
review status.

The source types mean:

- `resume_text`: directly matched from a supported text section.
- `resume_metadata`: observed attachment metadata only.
- `rules_inference`: generated workflow guidance or uncertainty, not a resume
  fact and not a hiring judgment.

## Invariants

1. Only the profile owner can request, review, correct, accept, reject, or apply
   an analysis.
2. Every finding keeps evidence and uncertainty visible alongside its proposed
   value; source type and inference flag cannot be omitted.
3. Applying requires at least one accepted fact-compatible finding and creates
   only `skill`, `experience`, or `certification` facts.
4. An analysis cannot be applied twice, and non-fact signals never become profile
   facts.
5. The provider does not produce protected-characteristic fields or candidate
   ranking values.
6. Plain-text input is bounded to one megabyte and decoded with replacement for
   invalid bytes; binary document content is not read by the preview provider.

## Acceptance Criteria

- [x] A student can request an analysis only after attaching a resume.
- [x] A student can inspect evidence, confidence, source type, and uncertainty.
- [x] A student can correct, accept, or reject findings before application.
- [x] Accepted compatible findings become provenance-aware profile facts only when
      the student explicitly applies them.
- [x] Unsupported binary files disclose that their text was not parsed.
- [x] Another student or staff account cannot read or mutate the analysis.
- [x] Analysis and review actions are audited.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/candidate_resume_analysis_test.rb test/models/recruitment/candidate_resume_finding_test.rb test/controllers/recruitment/candidate_resume_analyses_controller_test.rb
    bin/verify
