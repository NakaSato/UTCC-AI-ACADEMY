---
id: ADR-0009
type: adr
title: Define the course syllabus PDF document boundary
status: accepted
owners: ["@product-owner", "@tech-lead"]
created: 2026-08-02
updated: 2026-08-02
review_by: 2026-08-09
supersedes: []
superseded_by: []
depends_on: [SPEC-0003, SPEC-0008]
implemented_by:
  - Gemfile
  - app/services/course_syllabus_pdf.rb
  - app/controllers/course_documents_controller.rb
  - app/views/courses/show.html.erb
  - app/assets/fonts/NotoSansThai-Regular.ttf
touches:
  - app/controllers/courses_controller.rb
  - app/controllers/course_documents_controller.rb
  - app/services/course_syllabus_pdf.rb
  - app/views/courses/show.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
enforced_by:
  - test/controllers/course_syllabus_documents_test.rb
  - test/system/course_syllabus_document_walk_test.rb
agent_writable: false
requires_skills: [SKILL-PROD-001, SKILL-ARCH-001, SKILL-ARCH-002, SKILL-SPEC-003, SKILL-HUM-002]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Define the course syllabus PDF document boundary

> **Decision state:** Accepted by the user on 2026-08-02. The approved
> server-generated document boundary is implemented with Prawn 2.5 and a
> bundled Noto Sans Thai font; SSO, certificates, sharing, and stored versions
> remain outside this slice.

> [Decision Records](README.md) ·
> [M6 syllabus PDF specification](../specs/spec-m6-course-syllabus-pdf.md) ·
> [Roadmap Milestone 6](../roadmap.md#milestone-6--institutional-access-and-documents) ·
> [M5 knowledge map](../specs/spec-m5-real-knowledge-map.md)

## Context

The course page already displays a course-specific syllabus from `Course` and
`Syllabus`, but its “Download syllabus (PDF)” control is a non-functional
button. Students need a durable, printable representation of the selected
course's current modules and topics. The first document slice should reuse the
course curriculum boundary established in M4 and avoid introducing SSO,
certificate issuance, or a second syllabus data source.

The current application has no PDF renderer or document route. Adding a
renderer is a dependency and deployment decision, while the syllabus content
and locale policy are academic/product decisions. Neither should be hidden in
the implementation.

## Decision

This draft proposes a course-document adapter boundary for a real syllabus PDF;
the renderer and policy choices below remain pending human review.

## Proposed boundary

1. A signed-in learner requests a syllabus document for one selected course.
2. The document adapter reads the selected `Course` and its owned
   `CourseModule`/`Topic` rows plus localized curriculum copy.
3. The response is an actual PDF with an explicit `application/pdf` content type
   and a deterministic, localized filename.
4. The document contains no learner completion data, student identifiers, or
   certificate claims.
5. SSO/account linking, certificate issuance, document storage, and sharing
   links remain separate decisions.

The adapter boundary is intentionally separate from `CoursesController` so a
renderer can change without changing course lookup or curriculum ownership.
This implementation uses Prawn 2.5, a pure-Ruby renderer, and bundles Noto Sans
Thai under its SIL Open Font License. The dependency is isolated behind this
adapter so a future renderer can replace it without changing course lookup or
curriculum ownership.

## Alternatives

### Browser print-to-PDF

Uses the existing HTML page and adds no server dependency. It cannot guarantee
an `application/pdf` response, stable filenames, or a consistent result across
browsers, so it does not satisfy the document contract by itself.

### Server-side PDF renderer

Produces a real file with stable headers and can share the course data boundary.
The trade-off is a new library or runtime dependency, font and Thai-layout
verification, and a larger test surface. This is the candidate direction for
M6, pending renderer selection and supply-chain review.

### External document service

Could provide mature rendering and storage, but would send institutional course
content to a new service and introduce availability, privacy, credentials, and
cost obligations. It is out of scope for the first slice.

## Consequences

- The course syllabus becomes a generated view of current curriculum records,
  not a separately authored PDF artifact.
- A course update changes the next generated document without a regeneration
  job.
- Thai font embedding, long titles, page breaks, and missing curriculum copy
  become explicit verification concerns.
- Caching, signed sharing URLs, and archival/versioned documents are deferred.
- The disabled SSO control remains disabled until the institutional identity
  decision is separately accepted.

## Resolved human decisions

- Server-generated PDF is the M6 rendering approach; Prawn is the isolated
  implementation dependency and Noto Sans Thai is bundled for Thai output.
- An unmodeled or unknown course returns `404`; no other course is used as a
  compatibility fallback.
- Any authenticated learner may download a catalog course's current syllabus;
  the PDF contains no learner state or student identifier.
- The requested supported locale controls copy, with the application locale
  fallback; filenames are deterministic ASCII-safe course/locale names.
- SSO, certificates, sharing links, stored versions, and background jobs are
  deferred to later M6 decisions.

## Fitness Functions

- `bin/docs` validates this record's lifecycle metadata and skill references.
- Document tests prove `application/pdf`, `Content-Disposition`, selected-course
  outlines, localized content, and safe invalid-course behavior.
- The system walkthrough reaches the AI1101 and AI1102 document links from their
  course pages.
