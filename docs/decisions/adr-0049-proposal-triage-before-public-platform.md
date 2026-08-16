---
id: ADR-0049
type: adr
title: Give a proposal an answer before giving the public a platform
status: accepted
owners: ["@product-owner", "@tech-lead", "@security-owner", "@privacy-owner", "@data-owner", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-11-10
supersedes: []
superseded_by: []
depends_on: [ADR-0004, ADR-0006, ADR-0013, ADR-0044]
implemented_by: []
touches: []
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give a Proposal an Answer Before Giving the Public a Platform

> **Decision state:** **Accepted by the user on 2026-08-12**, the same day it was
> proposed, for the Product Owner, Tech Lead, Security owner, Privacy owner, Data
> owner, and QA owner. Ecosystem M13 is order 3 in the unified delivery plan and
> has never entered execution; the roadmap gate required an ADR to confirm or
> refuse, and this is that document.
>
> The seven decisions below are now the boundary. Roadmap §15 lists twelve
> product decisions required before scheduling; this answers five of them and
> **the other seven remain open and out of the first increment** — field
> visibility, voting, comments and moderation, role mapping, the private
> security-report path, search and attachments and notifications, and AI data
> use. Accepting this does not schedule M13, and it authorizes no public
> surface. What it authorizes is decision 1 immediately, and increment 1 —
> triage, at the existing audience, explained in-app — once a backlog item
> carries it.

> [Decision Records](README.md) ·
> [Proposal request intake specification](../specs/spec-proposal-request-intake.md) ·
> [M13 roadmap section](../roadmap.md#milestone-m13--public-feature-request-and-core-team-development-platform) ·
> [Deferred production email](adr-0004-defer-production-email.md) ·
> [Academic-post permissions and draft lifecycle](adr-0006-academic-post-permissions-and-lifecycle.md) ·
> [Admin course lifecycle and catalog boundary](adr-0013-admin-course-lifecycle.md) ·
> [Role-aware workspaces](adr-0044-role-aware-workspaces.md)

## Context

M13 proposes a public feature-request platform: discovery, voting, following,
threaded discussion, moderation, product and technical assessment, roadmap
linkage, development tracking, and release review. The roadmap describes it in
nine hundred lines and marks its baseline TBD pending discovery.

Three facts about the code decide how it should start, and all three are
checkable today.

**The intake already exists, and no lifecycle document describes it.**
`ProposalRequest` ships four categories, four statuses, database check
constraints on both, five validated fields, a `PR-0000` reference, and a
`user_must_be_a_contributor` rule limiting it to students and instructors.
`ProposalRequestsController` routes `new`, `create`, and `show`, and `show` is
scoped to `Current.user.proposal_requests`. It is reached from the footer, the
contributors page, and the signed-out hero. It is covered by
`test/models/proposal_request_test.rb`.

It appears in `docs/roadmap.md` and in no ADR, spec, or runbook. The
repository's own invariant is that changing existing behavior means finding the
governing spec and ADR and keeping them consistent with the code. For this
feature there is nothing to be consistent with. M13 is an extension of a
boundary nobody wrote down.

**Three of its four statuses cannot be reached.** Nothing in `app/` assigns
`status`. There is no index, no review screen, no transition action, and no
administrator path — `grep -rn "ProposalRequest" app/` returns the model, the
controller, its two views, `User#proposal_requests`, and three links to `new`.
`submitted` is the column default and the only value it can hold. `in_review`,
`planned`, and `declined` exist in a Ruby constant and a Postgres check
constraint, and in no code path.

`app/views/proposal_requests/show.html.erb:16` renders
`t("proposal_request.status.#{@proposal.status}")` to the author. The platform
shows every contributor a status, on a page built to display it, and that status
is structurally incapable of ever changing.

M13's proposed primary outcome is the proportion of valid proposals that receive
an auditable triage decision and an author-visible explanation inside an agreed
window. That proportion is not unknown and not merely low. It is zero, and it is
zero by construction. The baseline the roadmap defers to discovery is already
known.

**There is no production email.** ADR-0004 defers it; MAIL-002 and MAIL-003 are
the two blocked items in Milestone 1, waiting on a Product Owner decision that
has not been made. Any increment that promises to tell an author what happened
must do so without sending mail, or it inherits M1's blocker and ships nothing.

## Decision

The accepted policy, in the order the questions should be answered:

1. **Record the boundary that exists before extending it.** SPEC-0049 describes
   the shipped intake as built — fields, constraints, audience, reachability,
   and the dead statuses named as dead. It documents current behavior, changes
   no code, and requires no product decision. It is the prerequisite this
   repository's invariant already imposes on M13 and on any other change to
   proposals, and it is the one part of this ADR that can proceed whatever the
   Product Owner decides about the rest.

2. **The first increment is triage, not participation.** One core-team screen
   that lists proposals and records a decision with a reason, and an author view
   that shows that decision. Public discovery, voting, following, comments,
   revision history, moderation queues, attachments, duplicate detection, and AI
   assistance are all deferred to later increments with their own decisions.

   The reason is that every deferred item opens a public surface and its abuse,
   identity, and privacy questions — roadmap §15 decisions 1, 3, 5, 6, 9, 10,
   and 12 — while none of them moves the stated outcome. A proposal that
   receives a reasoned decision has met the outcome with no public surface at
   all.

3. **The audience does not widen in the first increment.** Intake stays
   signed-in students and instructors, exactly as `user_must_be_a_contributor`
   already enforces. Anonymous and general-public submission (§15 decision 1) is
   precisely the change that creates the CAPTCHA, rate-limit, verification,
   contact-permission, and account-deletion questions, and it can be made later
   without reworking triage.

4. **The explanation is in-app, on the page the author already has.** No email
   until ADR-0004 is superseded and MAIL-002 is unblocked. `show` renders a
   status that a decision has actually moved, plus the reason text. The author
   is told at their next visit rather than in their inbox — a weaker promise
   than M13 describes, and the only one this repository can currently keep.

5. **A decision is a record, not a column.** Each transition writes who decided
   it, when, the status it moved to, and the reason shown to the author. A
   status column overwritten in place cannot answer "who decided this and why",
   which is the whole of "auditable" in the stated outcome.

6. **The status vocabulary is settled now, and the constraint moves with it.**
   The shipped four are a subset of what roadmap §7.1 proposes. Whichever set is
   chosen, `ProposalRequest::STATUSES` and the `proposal_requests_status` check
   constraint change together in one migration, and no status exists in either
   that the code cannot reach. The present mismatch is what this decision is
   meant to stop recurring.

7. **No proposal writes to `docs/` or `backlog.json` automatically.** Roadmap
   §15 decision 8 asks how proposals link to the roadmap, backlog, ADRs, specs,
   releases, and outcomes. The proposed answer is a reference a human records,
   never a generated commit. The backlog is the source of truth for delivery and
   its updates carry recorded human approval; a queue that can append to it is a
   queue that can approve work, and no public intake should be able to.

## Alternatives

### Build M13 as the roadmap specifies, in one milestone

Rejected. Twelve unanswered product decisions, a moderation policy, a private
security-report path, an AI data-use decision, and a public identity model are
not a milestone; they are a programme. The section itself says discovery must
establish the baseline first, and the baseline is establishable today.

### Start with voting and discovery, because that is the visible half

Rejected. It is the half that creates every hard question — bot resistance,
identity, abuse, small-population deanonymization on a campus platform — and it
does not produce a single triage decision. It also makes the first thing the
public sees a queue of proposals nobody has answered, which is worse for trust
than no public queue at all.

### Retire `proposal_requests` and start clean

Rejected. The records are real contributions from students and instructors, the
route is linked from three places including the signed-out hero, and the
migration cost of keeping the table is a rename at worst. §15 decision 2 asks
this question explicitly; the proposed answer is to evolve it, not drop it.

### Do nothing until all twelve decisions in §15 are answered

Rejected as the reason nothing has moved. Decision 1 of this ADR needs no
product input, and the missing specification currently blocks any change to
proposals at all — including the small ones. Recording the boundary is not
scheduling the milestone.

## Consequences

- The gate has a document to act on. M13 can be accepted, narrowed, reordered,
  or refused on evidence rather than on a nine-hundred-line description.
- Accepting decision 1 alone leaves the roadmap unchanged and still removes a
  standing obstacle: proposals become a documented boundary, so a future change
  to them has a spec to stay consistent with.
- Accepting decision 2 makes the first increment small enough to specify: one
  screen, one record, one author-visible field, no public surface.
- The status vocabulary and its check constraint change together in a migration
  whenever decision 6 is answered — including the possibility of deleting three
  statuses rather than implementing them.
- The author-visible explanation stays in-app until production email exists.
  If that is unacceptable to the Product Owner, M13's first increment is blocked
  behind MAIL-002 and should be reordered rather than started.
- Nothing here relaxes ADR-0044's workspaces. A triage screen belongs to an
  existing console; which one is a decision this ADR does not make.

## Fitness Functions

This ADR implements nothing itself; each decision above becomes a checkable
statement in SPEC-0049 or its successor, and decision 1's is due immediately:

- Decision 1 is satisfied when `docs/specs/spec-proposal-request-intake.md` is
  accepted and carries a non-empty `enforced_by`, which `bin/docs` gates.
- Decision 3 is enforced by the existing `user_must_be_a_contributor` validation
  and its model test; widening the audience must change both deliberately.
- Decisions 2, 5, and 6 need tests that do not exist yet: a status the code can
  reach for every status the constraint allows, a decision record per
  transition, and an author who reads the reason on `show`.
- Decision 7 is enforced by the absence of any write path from application code
  to `docs/` or `docs/backlog.json`, which no test asserts today.

  **Corrected 2026-08-12.** It does now:
  `test/operations/documentation_write_boundary_test.rb` holds the property one
  step stronger than this sentence asks for — nothing under `app/` or `lib/`
  writes a file at all, so the guarantee does not depend on anybody remembering
  which paths are documents. Writing it turned up one thing this paragraph did
  not know: a generated file *does* live under `docs/`. `ErrorPages` writes the
  hosted 503 that Render's maintenance mode serves, because that URL must not
  sit on the service that is down (RB-0006). The exception is named and pinned
  to exactly that path; no specification, decision, runbook, or the backlog is
  inside the generated set. `script/` is deliberately outside the scan, being
  tooling a person runs rather than anything a request can reach.

## Human decisions still required

Five of the twelve in roadmap §15 are answered by this decision. **Seven remain
open**, and no work may assume an answer to them:

| §15 | Question | Settled here |
| --- | --- | --- |
| 1 | Anonymous or registered-only submission | Registered-only for increment 1 (decision 3) |
| 2 | How `proposal_requests` evolves | Evolve, do not replace (decisions 1 and 6) |
| 4 | Lifecycle, transition owners, explanation policy | Triage-only lifecycle, recorded transitions (decisions 2 and 5) |
| 8 | Linkage to roadmap, backlog, ADRs, specs, releases | Human-recorded references only, never generated (decision 7) |
| 11 | Primary outcome, baseline, target, window | Baseline is zero and measurable today; target and window still TBD |
| 3, 5, 6, 7, 9, 10, 12 | Field visibility, voting, comments and moderation, roles, private security reports, search/attachments/notifications/API, AI data use | **Not answered.** Out of increment 1 |

Two questions this ADR raises that §15 does not:

- Whether an in-app-only explanation satisfies the outcome while production
  email stays deferred, or whether M13 must wait on MAIL-002.
- Which existing console owns the triage screen, given ADR-0044's four
  workspaces and ADR-0013's admin boundary.

**Answered by the user on 2026-08-12.** The second one: the **admin console,
with a new Proposals tab**. `AdminConsole::TABS` already carries nine tabs
behind `allow_only :admin`, and the admin console is where every recorded
decision in this project is already made. The existing Queue tab was considered
and rejected as the home: `approval_requests.course_id` is `null: false`,
`ApprovalDecision#actor_is_approver` requires an administrator, and its outcome
vocabulary is `approved`/`rejected`, which a triage outcome is not — reuse would
mean widening a shipped and audited course-lifecycle path to carry a record it
was not shaped for. The proposal decision is its own record modelled on that
one: append-only, actor, outcome, note, immutable after creation. The
instructor workspace was rejected because `user_must_be_a_contributor` admits
students *and* instructors, so instructors would decide proposals they may
themselves submit.

The first one stands as decision 4 wrote it: the explanation is in-app, and
M13's first increment does not wait on MAIL-002.

And decision 6 is settled with them: **the four shipped statuses stay, and all
four become reachable.** `submitted → in_review → planned | declined`.
`ProposalRequest::STATUSES` and the `proposal_requests_status` check constraint
already list exactly these four; the defect was that three had no code path, not
that the vocabulary was wrong. Nothing is added to either, nothing is removed
from either, and the migration decision 6 anticipated turns out to be no
migration at all — which is the outcome that leaves the shipped records
untouched.

## Decision owner

Product Owner, with Tech Lead, Security owner, Privacy owner, Data owner, and
QA owner. **Accepted by the user on 2026-08-12.**

Decision 1 is authorized now and is documentation only. Increment 1 — the
triage screen, the decision record, the author-visible reason, and the status
vocabulary settled with its check constraint — is authorized in scope but still
needs a backlog item and the roadmap gate before it is scheduled; acceptance of
a boundary is not a delivery commitment. Everything outside those seven
decisions remains unauthorized and is refused by the same rule that refused it
yesterday.

**Scheduled 2026-08-12**, once the two open questions above were answered.
Increment 1 is specified by [SPEC-0050](../specs/spec-proposal-triage.md) and
delivered as backlog item M13-001. The sentence above still holds for everything
else: the seven §15 questions this ADR did not answer are not answered by
scheduling this one, and the deferred surfaces — discovery, voting, following,
comments, revision history, moderation, attachments, duplicate detection, AI
assistance — remain unauthorized.
