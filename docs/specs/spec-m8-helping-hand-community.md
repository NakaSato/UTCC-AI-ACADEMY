---
id: SPEC-0017
type: spec
title: Helping Hand award and learner community boundary
status: accepted
owners: ["@product-owner", "@academic-owner", "@tech-lead", "@privacy-owner"]
created: 2026-08-03
updated: 2026-08-05
review_by: 2026-11-01
supersedes: []
superseded_by: []
depends_on: [ADR-0017]
implemented_by: []
touches:
  - app/models/learner_progress.rb
  - app/models
  - app/controllers
  - app/views
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
enforced_by:
  - test/models/awards_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-002, SKILL-ARCH-004, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-004, SKILL-TEST-001]
---

# Helping Hand award and learner community boundary

> **Review state:** Accepted by the user on 2026-08-05 as a deferral. The badge
> remains visible but unavailable and unearnable until a moderated community
> feature has a separate approved policy and implementation.

> [Executable Specifications](README.md) ·
> [M8 community decision](../decisions/adr-0017-helping-hand-community-boundary.md) ·
> [Roadmap Milestone 8](../roadmap.md#milestone-8--community-and-pedagogy-decisions)

## Problem

The `Helping Hand` badge promises ten forum answers, but no forum records
questions, answers, acceptance, moderation, or deletion. The product must first
decide whether peer interaction belongs in the academy and what educationally
useful, safe contribution the badge should recognize.

## Scope

### Included in the deferral

- Preserve the existing server-side unearnable rule.
- Add truthful Thai/English copy that labels the badge unavailable.
- Keep the badge independent from progress, grades, completion, certificates,
  reports, access, notifications, and other academic state.
- Record the boundary that no community records, endpoints, moderation workflow,
  staff override, or award-credit path is introduced.

### Excluded

- Enabling open learner messaging without moderation and ownership.
- Adding forum, Q&A, peer-review, contribution, moderation, or reporting records
  before a separate community policy is approved.
- Treating marketing landing-page community cards as learner contributions.
- Awarding activity from browser counters, client-supplied approval, or raw view
  counts.
- Using the award to determine grades, course completion, certificates, or
  access unless separately approved.
- Real-time chat, anonymous posting, automated safety decisions, or production
  notifications unless separately specified.

## Invariants

1. The award is either based on an approved server-side contribution rule or is
   explicitly unavailable; it is never silently earned from fabricated data.
2. A learner cannot approve their own contribution, earn duplicate credit from
   retries, or earn credit from content outside the approved scope.
3. A contribution must satisfy the approved visibility, lifecycle, and quality
   state before it counts toward the award.
4. Authorization is enforced server-side for creating, reading, editing,
   reporting, moderating, hiding, and deleting community records.
5. Untrusted learner content is sanitized before rendering and is not placed in
   award, audit, notification, or analytics fields without an approved reason.
6. Moderation, deletion, account removal, or an appeal follows the approved rule
   for whether previously earned credit is retained, suspended, or recalculated.
7. The feature does not alter grades, completion, certificates, or access unless
   those downstream effects are explicitly approved.
8. Thai and English labels, hints, denial messages, and moderation states remain
   structurally aligned.

## Acceptance Criteria

- [x] The user approves deferring the community feature and keeping the badge
      unavailable (`docs/decisions/adr-0017-helping-hand-community-boundary.md`).
- [x] No forum, peer-review, or contribution records or endpoints are added;
      the current unearnable behavior remains unchanged
      (`test/models/awards_test.rb`).
- [x] The badge has truthful, structurally aligned Thai and English unavailable
      copy (`test/models/awards_test.rb`).
- [x] Progress, grades, completion, certificates, reports, access, and other
      academic state remain unaffected by the deferred badge.
- [x] Full repository verification passes (`bin/verify`).

## Error and boundary cases

- A learner edits or deletes an answer after it has contributed to the award.
- A moderator rejects or hides an answer after a learner reaches the threshold.
- A user loses course/section membership or is suspended after contributing.
- Two tabs submit the same answer or two moderators act on one report at once.
- A question or answer contains personal data, unsafe advice, plagiarism, or
  content intended to manipulate the award.
- A report is submitted by the content author, a moderator, or an unauthenticated
  visitor.
- A contribution is visible in one locale but not another, or a translation is
  missing for a moderation state.
- The community owner or moderation queue is unavailable; the system must fail
  closed according to the approved policy.

## Human Community Policy Handoff

The deferral closes the current implementation question. Any future community
feature must reopen this handoff and complete the following table before code is
authorized.

| Review point | Decision required |
| --- | --- |
| Product model | No feature, course Q&A, structured peer review, or another model. |
| Educational outcome | What “helping” teaches and what evidence proves it. |
| Eligibility | Who may ask, answer, review, moderate, and earn the badge. |
| Scope and identity | Course/section visibility, names, profiles, and anonymity. |
| Quality gate | Acceptance, rubric, instructor review, or another threshold. |
| Safety | Reports, abuse, plagiarism, personal data, takedown, and escalation. |
| Award semantics | Threshold, retries, duplicate prevention, and retraction. |
| Operations | Owner, moderation SLA, retention, metrics, and rollback. |

## Rollback and observability

- Keep the badge unearnable or remove it as the rollback target until approved
  contribution records and moderation ownership are operational.
- The current rollback target is the existing unearnable badge with unavailable
  copy; there is no community data or moderation history to disable or delete.
- A future implementation must define visibility/retraction behavior and
  aggregate monitoring before it is enabled.

## Verification

```bash
bin/docs
bin/rails test test/models/awards_test.rb
bin/verify
```
