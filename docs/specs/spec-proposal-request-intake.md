---
id: SPEC-0049
type: spec
title: The proposal request intake as built
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0049]
implemented_by:
  - app/models/proposal_request.rb
  - app/controllers/proposal_requests_controller.rb
  - app/views/proposal_requests/new.html.erb
  - app/views/proposal_requests/show.html.erb
enforced_by:
  - test/models/proposal_request_test.rb
  - test/controllers/contributors_test.rb
touches:
  - app/models
  - app/controllers
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - db/migrate
  - test
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-ARCH-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002]
---

# The Proposal Request Intake As Built

> **Review state:** **Accepted by the user on 2026-08-12**, which satisfies
> [ADR-0049](../decisions/adr-0049-proposal-triage-before-public-platform.md)
> decision 1 — the prerequisite for any change to proposals, including Ecosystem
> M13. This specification adds no behavior and proposes none; it records what
> already ships, because nothing did.
>
> Accepting it settles what the boundary **is**, not that all of it is desirable.
> Invariant 4 in particular is a recorded defect rather than an endorsement: three
> of the four statuses cannot be reached, and the author-facing page displays one
> of them as though it were live. It is written down so a change to it has a
> baseline to be measured against, and ADR-0049 decision 6 governs whether those
> statuses gain a code path or are removed.

> [Executable Specifications](README.md) ·
> [Proposal triage decision](../decisions/adr-0049-proposal-triage-before-public-platform.md) ·
> [M13 roadmap section](../roadmap.md#milestone-m13--public-feature-request-and-core-team-development-platform)

## Problem

A student or instructor can describe a product idea to the core team. The
feature shipped without an ADR or a specification, so there is no recorded
statement of who may submit, what is stored, who may read it afterwards, or what
happens next. The consequence is not hypothetical: the model carries four
statuses, three of which no code path can produce, and the author-facing page
displays that status as though it were live. Nobody noticed because no document
claimed otherwise.

Until this is written down, any change to proposals — the M13 platform, a new
field, a status rename — has no baseline to be kept consistent with, which the
repository's invariants require.

## Scope

The shipped intake only. Voting, comments, following, moderation, public
discovery, duplicate detection, revision history, attachments, notifications,
reviewer assignment, roadmap linkage, and AI assistance are **not** in this
specification because they are not in the application. ADR-0049 governs whether
and in what order they arrive.

## Domain model boundary

`proposal_requests` — one row per submitted idea, owned by one user.

| Column | Rule |
| --- | --- |
| `title` | required, ≤ 160 characters, whitespace-normalized |
| `category` | required, one of `feature`, `curriculum`, `community`, `platform`; a database check constraint repeats the list |
| `problem` | required, ≤ 2,000 characters |
| `idea` | required, ≤ 4,000 characters |
| `impact` | required, ≤ 1,000 characters |
| `status` | required, defaults to `submitted`; a database check constraint allows `submitted`, `in_review`, `planned`, `declined` |
| `user_id` | required; the submitting account |

Indexes cover `user_id`, `(user_id, created_at)`, and `(status, created_at)`.
The last one supports a status-ordered listing that does not exist.

`ProposalRequest#reference` formats the primary key as `PR-0000`. It is a
display string derived on read, not a stored column, and it is what the author
is shown after submitting.

## Role and access contract

- **Students and instructors** may submit. `user_must_be_a_contributor` rejects
  any other account at the model layer, and `allow_only :student, :instructor`
  refuses at the controller. Both are load-bearing: the model rule is what makes
  an administrator-owned proposal invalid regardless of how it is created.
  A signed-in account with the wrong role is redirected to root with the
  forbidden flash rather than refused outright, because `authorize_role` lands
  both of its denials there.
- **The author** may read their own proposal, and only their own: `show` finds
  through `Current.user.proposal_requests`, so another user's ID raises
  `ActiveRecord::RecordNotFound` rather than authorizing.
- **Signed-out visitors** are sent to the credential screen with the deep link
  preserved in `session[:return_to_after_authenticating]`, because the intake is
  an explicit contribution entry point rather than a page that merely requires
  an account.
- **Nobody else may read a proposal through the application.** There is no
  index, no administrator screen, no core-team view, and no export. Submitted
  proposals are reachable only by their author and by direct database access.

## Reachability

The intake is linked from the footer's community column, the contributors page,
and the signed-out authentication hero. All three link to `new`.

Routes are `new`, `create`, and `show` only. There is no `index`, `edit`,
`update`, or `destroy`; an author cannot correct a submission and cannot
withdraw one.

## Invariants

1. A proposal always belongs to a student or an instructor account. No other
   role can hold one, whatever created it.
2. An author reads only their own proposals; there is no route by which one user
   reaches another's.
3. Every stored proposal has all five copy fields present and normalized, and a
   category from the allowed list. The database repeats both constraints, so a
   row that bypasses the model is still refused.
4. `status` is `submitted` for every row the application can create, and the
   application contains no path that changes it. `in_review`, `planned`, and
   `declined` are declared in `ProposalRequest::STATUSES` and in the
   `proposal_requests_status` check constraint, and are unreachable. **This is a
   defect of the shipped feature, recorded rather than endorsed** — ADR-0049
   decision 6 governs whether they gain a code path or are removed.
5. Deleting a user deletes their proposals (`dependent: :destroy`). There is no
   retention or anonymization policy beyond that, and none is claimed.
6. Nothing in the application writes proposal content to `docs/` or to
   `docs/backlog.json`. ADR-0049 decision 7 proposes keeping it that way.

## Acceptance Criteria

These describe the current build. They are written so that a change to any of
them is a deliberate change to a recorded boundary, not a silent one.

- A student submitting all five fields with a valid category creates a proposal
  and is redirected to its page, which shows the `PR-0000` reference, the
  category, and the status.
- An instructor may do the same.
- An administrator or any other console role cannot hold a valid proposal, and
  requesting `new` redirects to root with the forbidden flash.
- A missing or over-length field re-renders the form with
  `422 Unprocessable Entity` and no row is written.
- An unknown category is refused by the model, and by the database if the model
  is bypassed.
- Surrounding whitespace is stripped from all five copy fields before storage.
- A signed-out visitor requesting `new` is sent to the login screen and returns
  to `new` after authenticating.
- An author requesting another author's proposal receives 404.
- A proposal's status reads `submitted` at every point in its life.

## Error and boundary cases

- `create` uses `save!` and rescues `ActiveRecord::RecordInvalid` to re-render;
  any other failure surfaces as a 500 through the rendered error pages.
- An empty-string field is normalized to `nil` before validation, so
  whitespace-only input fails presence rather than storing a blank.
- The category select is built from `ProposalRequest::CATEGORIES`, so the form
  and the constraint cannot drift apart. The status vocabulary has no such
  binding, which is invariant 4's defect in one sentence.

## Verification

- `test/models/proposal_request_test.rb` covers a valid learner submission, the
  refusal of a non-contributor account, normalization with an invalid category,
  and the `PR-0000` reference format.
- `test/controllers/contributors_test.rb` covers the form for a signed-in
  contributor, a successful submission through to the confirmation page, the
  refusal of an unauthenticated request, the deep-link return to the form after
  signing in, one contributor receiving 404 for another's proposal, an
  incomplete submission re-rendering the form as 422 while writing no row, and
  a staff account being turned away from the form.
- `test/controllers/footer_test.rb` and
  `test/controllers/sessions_controller_test.rb` cover the footer links that
  reach the intake, the latter on the signed-out authentication pages in both
  locales.
- `test/operations/route_reachability_test.rb` covers that all three actions
  exist and that the two GET routes render a template.
- `bin/verify` runs the whole gate.

**Not covered by any test:** that no code path changes `status`. It cannot be
usefully asserted until ADR-0049 decision 6 settles what the status vocabulary
should be — an assertion that the three dead statuses stay dead would have to be
deleted by the change that revives them, and an assertion that they are absent
would fail against the check constraint that still lists them.

The two gaps this document was written with — a contributor reading another's
proposal, and the 422 re-render — were closed on 2026-08-12 rather than
recorded, because neither needed a product decision. Writing them found one
thing the draft had wrong: a signed-in account with the wrong role is redirected
to root, not refused, which the access contract above now says.

## Human review handoff

**Accepted by the user on 2026-08-12**, describing existing behavior only. The
confirmation this was waiting on — that the recorded boundary is the intended
one, invariant 4 included — has been given, and invariant 4 remains a defect
that is now recorded rather than one that was unknown.

Acceptance satisfies ADR-0049 decision 1 and nothing further. It does not
schedule Ecosystem M13, does not authorize increment 1, and does not endorse the
three unreachable statuses; ADR-0049 decision 6 still governs whether they gain a
code path or are removed, and that change now has this document to be measured
against.
