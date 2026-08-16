---
id: SPEC-0009
type: spec
title: Downloadable localized course syllabus PDF
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-10-31
supersedes: []
superseded_by: []
depends_on: [SPEC-0003, SPEC-0008, ADR-0009]
implemented_by:
  - Gemfile
  - app/services/course_syllabus_pdf.rb
  - app/controllers/course_documents_controller.rb
  - app/views/courses/show.html.erb
  - app/assets/fonts/NotoSansThai-Regular.ttf
touches:
  - app/controllers/courses_controller.rb
  - app/views/courses/show.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/course_syllabus_documents_test.rb
  - test/system/course_syllabus_document_walk_test.rb
agent_writable: false
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-SPEC-003, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-TEST-001, SKILL-HUM-001]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002, SKILL-TEST-001]
---

# Downloadable localized course syllabus PDF

> **Review state:** Accepted by the user on 2026-08-02 after the bounded
> implementation and focused browser/controller evidence were reviewed.

> [Executable Specifications](README.md) ·
> [M6 architecture decision](../decisions/adr-0009-course-syllabus-pdf.md) ·
> [Roadmap Milestone 6](../roadmap.md#milestone-6--institutional-access-and-documents) ·
> [M5 real knowledge map](spec-m5-real-knowledge-map.md)

## Problem

The course page promises “Download syllabus (PDF)” but currently renders a
button with no document route or file. Learners cannot retain or share a
course outline, and adding a document without a course boundary could silently
reintroduce the shared-syllabus behavior removed in M4 and M5.

## Scope

### Included

- Add a GET document route for one selected course.
- Generate a real PDF from the selected course's owned modules and topics.
- Include the course code, localized title, module order, topic order, topic
  names, topic kind, and duration where available.
- Support Thai and English using the application's locale boundary.
- Return a deterministic filename and explicit PDF content type.
- Replace the course-page placeholder button with the document link.
- Preserve authentication and avoid including learner-specific progress.

### Excluded

- UTCC SSO, identity linking, or emergency-access policy.
- Completion certificates, verification URLs, signatures, or QR codes.
- Stored document versions, public sharing links, or background generation.
- A separate syllabus authoring system or a second curriculum source.
- Any change to course, topic, lesson, or completion semantics.

## Invariants

1. Every syllabus document is generated for exactly one selected course.
2. A document never contains modules or topics owned by another course.
3. The document's module and topic order matches the selected course's current
   curriculum order.
4. The response is a PDF with an explicit content type and safe filename.
5. The document contains no learner completion, student ID, or certificate
   assertion.
6. Thai and English documents use the requested supported locale and do not
   silently mix localized course content.
7. Unknown or unauthorized course requests follow the human-approved safe
   boundary and never fall back to another course's syllabus.

## Acceptance Criteria

- [x] An authenticated learner can download an AI1101 PDF with the expected
      content type, disposition, filename, course code, and ordered topics
      (`test/controllers/course_syllabus_documents_test.rb`).
- [x] An authenticated learner can download an AI1102 PDF whose content is
      distinct and contains no AI1101 topic (`test/controllers/course_syllabus_documents_test.rb`).
- [x] Thai and English requests produce the selected locale's title and topic
      labels (`test/controllers/course_syllabus_documents_test.rb`).
- [x] The course page's syllabus control is a working document link rather than
      a non-functional button (`test/controllers/course_syllabus_documents_test.rb`).
- [x] Unknown, unmodeled, and unauthorized course requests follow the approved
      safe response without exposing another course (`test/controllers/course_syllabus_documents_test.rb`).
- [x] A browser walkthrough downloads or inspects both course documents and
      verifies their headers and course identity (`test/system/course_syllabus_document_walk_test.rb`).

## Boundary cases and unresolved policy

- A course with no owned curriculum must use the human-approved `404`, empty
  document, or compatibility behavior recorded in ADR-0009.
- A request with an unsupported locale must use the application's approved
  locale fallback and must not mix locales within one document.
- Long Thai and English names must wrap without clipping or losing course/topic
  identity.
- If the renderer cannot represent a character or font, the response must fail
  safely and expose an actionable server-side error without returning a corrupt
  PDF.
- A course update must affect the next generated document; no stale stored PDF
  may be served in this slice.

## Human Design Review Record

The Product Owner and Tech Lead approved the following choices for this slice:

| Review point | Evidence | Accepted decision |
| --- | --- | --- |
| PDF renderer and dependency boundary | [ADR-0009 alternatives](../decisions/adr-0009-course-syllabus-pdf.md#alternatives) | Prawn adapter with bundled Noto Sans Thai. |
| Course visibility and authorization | Course document controller (`app/controllers/course_documents_controller.rb`) | Any authenticated learner may download a catalog course syllabus. |
| Unmodeled-course behavior | [Boundary cases](#boundary-cases-and-unresolved-policy) | Unknown and unmodeled courses return `404`. |
| Locale, filename, Thai font, and accessibility | [ADR-0009 consequences](../decisions/adr-0009-course-syllabus-pdf.md#consequences) | Requested supported locale, deterministic ASCII-safe filename, bundled Thai font. |
| M6 scope boundary | [Excluded scope](#excluded) | SSO, certificates, sharing, and stored versions remain separate. |

The enforcing controller and system test paths are recorded in `enforced_by`,
and all acceptance criteria are covered by the focused evidence.

## Rollback and observability

- Roll back the route and course-page link together if renderer failures or
  malformed documents occur; leave the existing HTML syllabus available.
- Record document-generation failures without logging student identifiers or
  full document contents.
- A future production rollout should measure successful PDF responses, renderer
  failures, and locale-specific failure rates.

## Verification

```bash
bin/docs
bin/rails test test/controllers/course_syllabus_documents_test.rb
bin/rails test:system test/system/course_syllabus_document_walk_test.rb
bin/verify
```
