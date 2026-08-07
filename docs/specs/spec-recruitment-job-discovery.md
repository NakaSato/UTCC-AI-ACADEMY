---
id: SPEC-0031
type: spec
title: Candidate-controlled search, saved jobs, recommendations, and alerts
status: draft
owners: ["@product-owner", "@tech-lead", "@security-owner", "@recruitment-domain-owner", "@privacy-owner"]
created: 2026-08-07
updated: 2026-08-07
review_by: 2026-08-21
supersedes: []
superseded_by: []
depends_on: [ADR-0026, ADR-0029, ADR-0030, ADR-0031, SPEC-0026, SPEC-0029]
implemented_by:
  - app/services/recruitment/job_discovery.rb
  - app/services/recruitment/job_alert_notifier.rb
  - app/models/recruitment/saved_job.rb
  - app/models/recruitment/job_discovery_dismissal.rb
  - app/models/recruitment/job_discovery_preference.rb
  - app/controllers/recruitment/job_posts_controller.rb
  - app/controllers/recruitment/saved_jobs_controller.rb
  - app/controllers/recruitment/job_discovery_dismissals_controller.rb
  - app/controllers/recruitment/job_discovery_preferences_controller.rb
  - db/migrate/20260808120000_create_recruitment_job_discovery.rb
  - test/models/recruitment/job_discovery_test.rb
  - test/models/recruitment/saved_job_test.rb
  - test/controllers/recruitment/job_discovery_controller_test.rb
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
  - test/models/recruitment/job_discovery_test.rb
  - test/models/recruitment/saved_job_test.rb
  - test/controllers/recruitment/job_discovery_controller_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-ARCH-003, SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
min_reviewer_skills: [SKILL-ARCH-004, SKILL-TEST-001, SKILL-AI-002]
---

# Candidate-Controlled Search, Saved Jobs, Recommendations, and Alerts

> [Executable Specifications](README.md) ·
> [Job-discovery boundary ADR](../decisions/adr-0031-candidate-controlled-job-discovery.md) ·
> [Candidate-profile specification](spec-recruitment-candidate-profile.md) ·
> [AI Recruitment Platform Roadmap](../roadmap.md#ai-recruitment-platform-roadmap) ·
> [Project Development Flow](../development-flow.md)

## Problem

The published-job list currently provides browsing but no structured discovery,
candidate-owned revisit path, or explainable personalization. M7 needs to help a
student find relevant work without converting advisory suggestions into a hiring
decision or sending unwanted communication.

## Scope

### Included

- Candidate search across title, summary, description, category, department,
  team, and location, plus category, employment type, work mode, and location
  filters.
- Student-owned saved jobs with save/remove controls.
- Student-owned recommendation dismissals with restoration.
- Rules-based recommendation explanations based on matching candidate facts and
  explicit discovery preferences.
- In-app alert preferences with separate consent, daily/weekly frequency limits,
  enable/disable controls, and last-delivery tracking.

### Excluded

- Recruiter search, candidate ranking, hiring eligibility, or a numeric match
  score.
- Email, SMS, push, background scheduler, semantic/vector search, or external AI
  provider integration.
- Protected-characteristic inference or use of sensitive profile data beyond the
  candidate's own profile facts and explicit preferences.

## Invariants

1. Candidate discovery includes only published, active, non-expired jobs.
2. Saved-job and dismissal rows are unique per student/job pair and cannot be
   created by staff or another student's request.
3. A recommendation has at least one visible reason and a visible uncertainty
   statement; it has no hiring score or protected-characteristic field.
4. Dismissed and saved jobs are excluded from recommendations until restored or
   unsaved.
5. Alerts cannot be enabled without alert consent. Delivery is at most once per
   selected daily/weekly interval and is never implied by profile consent.
6. Search text is length-bounded and SQL-escaped; filter values are allow-listed.

## Acceptance Criteria

- [ ] Candidates can search and filter published jobs.
- [ ] Students can save and remove jobs from their own saved list.
- [ ] Students can dismiss and restore recommendations.
- [ ] Recommendations show explicit reasons and uncertainty without a score.
- [ ] Students can consent to, configure, and stop in-app alerts.
- [ ] A repeated visit before the configured interval creates no second alert.
- [ ] Staff and other students cannot access or mutate another student's state.

## Boundary Cases

- Empty search returns all currently visible jobs; invalid filter values do not
  broaden the query.
- A job becoming paused, closed, archived, inactive, or expired disappears from
  discovery but remains in a student's saved history until explicitly removed.
- Duplicate save/dismiss requests are idempotent from the user perspective.
- Turning off consent also disables alerts and clears the consent timestamp.
- Notification infrastructure being disabled does not advance the delivery clock.

## Verification

    bin/docs
    bin/rails test test/models/recruitment/job_discovery_test.rb test/models/recruitment/saved_job_test.rb test/controllers/recruitment/job_discovery_controller_test.rb
    bin/verify
