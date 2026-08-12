---
id: SPEC-0050
type: spec
title: Proposal triage, increment 1
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0049, SPEC-0049, ADR-0013, ADR-0044]
implemented_by:
  - app/models/proposal_request.rb
  - app/models/proposal_decision.rb
  - app/models/admin_console.rb
  - app/controllers/admin_controller.rb
  - app/views/admin/_proposals.html.erb
  - app/views/proposal_requests/show.html.erb
enforced_by:
  - test/models/proposal_decision_test.rb
  - test/controllers/admin_proposals_test.rb
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

# Proposal Triage, Increment 1

> **Review state:** **Authorized by the user on 2026-08-12**, who answered both
> questions [ADR-0049](../decisions/adr-0049-proposal-triage-before-public-platform.md)
> left open — the triage screen is a new Proposals tab in the admin console, and
> the four shipped statuses stay with all four made reachable — and scheduled
> increment 1 as M13-001. This specification is the successor SPEC-0049 named:
> it is the first document about proposals that adds behavior.

> [Executable Specifications](README.md) ·
> [The intake as built](spec-proposal-request-intake.md) ·
> [Proposal triage decision](../decisions/adr-0049-proposal-triage-before-public-platform.md) ·
> [Admin console boundary](../decisions/adr-0013-admin-course-lifecycle.md) ·
> [Role-aware workspaces](../decisions/adr-0044-role-aware-workspaces.md)

## Problem

M13's stated outcome is the proportion of proposals that receive an auditable
decision and an author-visible explanation. [SPEC-0049](spec-proposal-request-intake.md)
invariant 4 records why that proportion is zero and cannot be anything else: no
code path assigns `status`, there is no screen on which anybody could decide a
proposal, and the author's page renders a status that can never move. A student
who writes one is answered by silence, and the platform has no record of anyone
having read it.

The whole of the outcome is reachable without a single public surface. This is
that slice and nothing beyond it.

## Scope

**In:** one administrator-facing list of proposals; a recorded decision per
transition carrying who made it, when, the status it moved to, and the reason
shown to the author; the author reading that status and that reason on the page
they already have; every status in the shipped vocabulary reachable.

**Out, and refused by the same rule that refused it yesterday:** public
discovery, voting, following, comments, moderation, revision history,
attachments, duplicate detection, AI assistance, search, an API, and any
notification or email. Roadmap §15 decisions 3, 5, 6, 7, 9, 10, and 12 remain
unanswered, and nothing here assumes an answer to them.

**Deliberately out, though it would be small:** telling the author through the
bell. ADR-0049 decision 4 says the author is told at their next visit, and
notifications are §15 decision 9 — unanswered. A decision that reaches a student
through a channel nobody has specified is a wider change than it looks.

## Domain model boundary

`proposal_decisions` — one row per transition, appended, never modified.

| Column | Rule |
| --- | --- |
| `proposal_request_id` | required; the proposal decided |
| `actor_id` | required; the account that decided it, which must be an administrator |
| `to_status` | required; one of `in_review`, `planned`, `declined`. A database check constraint repeats the list |
| `reason` | required, ≤ 1,000 characters, whitespace-normalized; **this text is shown to the author** |
| `created_at` | when it was decided |

`submitted` is absent from `to_status` on purpose: it is the state the intake
writes, and nothing decides a proposal *into* it. A proposal cannot be returned
to the queue it came from, because "undecided again" is not an outcome an author
can be told about.

Indexes cover `proposal_request_id` and `(proposal_request_id, created_at)`.

**The transitions**, guarded in `ProposalRequest#decide!` and nowhere else:

| From | To |
| --- | --- |
| `submitted` | `in_review`, `planned`, `declined` |
| `in_review` | `planned`, `declined` |
| `planned` | — terminal |
| `declined` | — terminal |

`planned` and `declined` are answers; a decided proposal is not re-decided. This
is what makes all four statuses reachable, which is ADR-0049 decision 6 as the
user settled it, and it needs no migration of `proposal_requests`: the check
constraint and `ProposalRequest::STATUSES` already list exactly these four.

The status column and the decision rows are written in one transaction under a
row lock, so a status without the record explaining it cannot exist.

## Role and access contract

- **Administrators, and only administrators, decide.** `allow_only :admin` on
  the console, and `actor_is_an_administrator` on `ProposalDecision` — the model
  rule is what makes an instructor-signed decision invalid however it is created.
  ADR-0049 rejected the instructor workspace precisely because
  `user_must_be_a_contributor` admits instructors as *authors*.
- **The author reads their own proposal, and the reason on it.** Nothing else
  about the decision is exposed: not the deciding administrator's name, not the
  earlier decisions in the chain. The author is told what was decided and why,
  which is the whole of the promised explanation.
- **Nobody else reads a proposal.** There is still no index for authors, no
  cross-author route, and no export. SPEC-0049's access contract is unchanged in
  every respect except that an administrator now has a screen.
- **A proposal's content is never edited by anybody**, author or administrator.
  Triage records an answer beside the submission; it does not rewrite it.

## Reachability

- `/admin?tab=proposals` — the list, newest first, each row carrying the
  reference, category, author, submitted date, current status, and the reason
  from the last decision if there is one. The tab carries a badge counting
  proposals that are `submitted` or `in_review`, the same way Approvals counts
  pending requests.
- `POST /admin/proposals/:id/decision` — records one decision. Answers with a
  redirect back to the tab, like every other admin write.
- `/proposal-requests/:id` — the author's page, unchanged except that the status
  it renders can now move and the reason appears beneath it when one exists.

No new door for the author, and no new navigation entry outside the admin
console, which keeps ADR-0044 point 3 true: every entry in a workspace's
navigation is a door that workspace can open.

## Invariants

1. Every status change to a proposal has exactly one `ProposalDecision`
   explaining it, written in the same transaction. A status the application
   changed with no record is impossible.
2. A decision is never modified or deleted. `before_update` and `before_destroy`
   abort, as they do on `ApprovalDecision`.
3. Only an administrator holds a decision, enforced at the model and at the
   controller.
4. Every status in `ProposalRequest::STATUSES` and in the
   `proposal_requests_status` check constraint is reachable by a code path, and
   no path reaches a status absent from either. This retires SPEC-0049
   invariant 4, which recorded the opposite as a defect.
5. `planned` and `declined` are terminal: a decided proposal cannot be decided
   again, so an author is never told two contradictory things about the same
   proposal.
6. Every decision carries a reason, and that exact text is what the author
   reads. There is no internal note the author cannot see, because a second
   field would immediately raise the question this increment is not answering.
7. Deciding a proposal records an audit event at warning level naming the
   reference, the outcome, and the acting administrator — never the reason text,
   which is the author's words back to them and not an audit concern.
8. Nothing in this slice writes to `docs/` or `docs/backlog.json`, which
   `test/operations/documentation_write_boundary_test.rb` holds for the whole
   application.

## Acceptance Criteria

- An administrator opening `/admin?tab=proposals` sees every proposal, newest
  first, with its author and current status.
- The tab's badge counts proposals awaiting a decision, and is absent when there
  are none.
- An administrator moves a `submitted` proposal to `in_review` with a reason; the
  status changes, one decision row is written, and an audit event is recorded.
- The same administrator then moves it to `planned`; a second decision row joins
  the first, and both remain.
- A decision without a reason is refused, and no status change is written.
- A decision on a `planned` or `declined` proposal is refused.
- A decision to `submitted`, or to any status outside the vocabulary, is refused
  by the model and by the database if the model is bypassed.
- An instructor or a student posting to the decision route is turned away by
  `allow_only :admin` and writes nothing.
- The author of a decided proposal reads the new status and the reason on their
  own page; the author of an undecided one reads `submitted` and no reason.
- One author still cannot reach another's proposal, decided or not.
- An attempt to update or destroy a decision row leaves it unchanged.

## Error and boundary cases

- `decide!` raises `ActiveRecord::RecordInvalid` on a disallowed transition, a
  missing reason, or a non-administrator actor; the controller rescues it and
  redirects back to the tab with an alert, writing nothing.
- The proposal is locked and its status re-read inside the transaction, so two
  administrators deciding at once produce one decision and one refusal rather
  than two decisions.
- A reason of whitespace normalizes to `nil` and fails presence, so a blank
  explanation cannot be stored as though it were one.
- Deleting a user still deletes their proposals, and now the decisions on them.
  That is a consequence worth naming: the record of having answered a
  contribution does not outlive the account that made it, and no retention
  policy is claimed here any more than in SPEC-0049.

## Verification

- `test/models/proposal_decision_test.rb` covers the allowed and refused
  transitions, the terminal statuses, the reason requirement and its
  normalization, the administrator rule, immutability of a written decision, the
  single-transaction guarantee, and — the assertion SPEC-0049 said could not be
  written until decision 6 settled — that every status the check constraint
  allows is reachable and no other status is.
- `test/controllers/admin_proposals_test.rb` covers the tab rendering, the
  badge, a decision through the screen, the refusals, and a non-administrator
  turned away.
- `test/controllers/contributors_test.rb` covers what the author reads, which is
  where SPEC-0049's intake coverage already lives.
- `test/operations/route_reachability_test.rb` covers the new route leading
  somewhere.
- `bin/verify` runs the whole gate.

## Human handoff

Nothing in this specification widens the audience, opens a public surface, or
sends anything to anybody. What still needs a Product Owner decision before it
can be built is unchanged from ADR-0049: the seven §15 questions, the target and
window for the outcome, and whether an in-app-only explanation remains
sufficient once there is evidence about whether authors return to read it.

The first measurable thing this increment produces is that proportion, which was
zero by construction and is now a number somebody can look at.
