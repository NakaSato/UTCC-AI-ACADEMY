---
id: ADR-0052
type: adr
title: Give a notification somewhere to be read after the ninth
status: proposed
owners: ["@product-owner", "@tech-lead", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-19
supersedes: []
superseded_by: []
depends_on: [ADR-0050, ADR-0044, ADR-0004]
implemented_by: []
touches: []
enforced_by: []
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Give a Notification Somewhere to Be Read After the Ninth

> **Decision state:** **Proposed, and not accepted.** Nothing here is
> implemented and no work is authorized by it. It exists because ADR-0050
> decision 8 named the notification bell as the one list that grows and was
> deliberately not paged, and said the fix is a screen rather than a page —
> which is a new surface, and therefore a decision rather than a pull request.
> Five questions below need a human answer; each carries a recommendation.

> [Decision Records](README.md) ·
> [Paged lists](adr-0050-paged-lists.md) ·
> [Role-aware workspaces](adr-0044-role-aware-workspaces.md) ·
> [Production email deferred](adr-0004-defer-production-email.md) ·
> [Paged lists specification](../specs/spec-paged-lists.md)

## Context

`Notification::RECENT` is 8. The bell renders the most recent eight and there is
no route by which anybody reaches the ninth.

That is the defect ADR-0050 removed from the audit log, in miniature and with
one difference that matters: the audit log's fix was a page, because the audit
log is a screen. The bell is a dropdown in the header. A pagination control
inside a menu is not what a reader of a menu wants, and "previous page" on a
panel that closes when you click outside it is worse than the cap.

The rest of the shape is already built. `Notification` stores a kind and its
interpolations rather than a sentence, so a row reads in the language of
whoever reads it. `NotificationBell` owns the dom id, the stream, the re-fetch
path and the two figures. `/notifications` already exists — as a **frame
endpoint** that renders the bell partial, listed in `route_reachability_test.rb`
as "not a page". `Page` and the pagination control exist and are tested. Nothing
here needs new machinery; it needs a route, a template, and five answers.

What makes this worth doing rather than shrugging at: a notification is the only
thing in this application written *for* somebody by somebody else, and
[ADR-0004](adr-0004-defer-production-email.md) defers production email, so the
bell is the **only** channel. A student invited to a business case, a company
told a request arrived, a supervisor assigned to a placement — each learns about
it here or not at all. Eight is one busy week.

## The five open questions

**1. Where does the screen live, and what happens to `/notifications`?**

*Recommendation:* `/notifications` becomes the screen, and the bell's frame
endpoint moves to `/notifications/bell`. The reader-facing URL should be the
readable one, and the frame is an implementation detail of the header. Costs one
line in `NotificationBell`, one route, and one entry in
`route_reachability_test.rb` — where `notifications#show` stops being an
exception, because it becomes a page that renders a template.

**2. Is it a history or an inbox — do read notifications stay?**

*Recommendation:* a history. Read rows stay, marked as read, and paging goes
back to the first row ever written. An inbox that empties as you read it answers
"what is waiting" — which the bell already answers, with a dot. The question
this screen exists for is "what was I told?", and that one has no other home.

**3. Does opening the screen mark everything read?**

*Recommendation:* no. Marking read stays the explicit action it is today, on the
button that already exists. A screen that clears the dot by being looked at
makes the dot mean "you have not visited" rather than "something happened", and
a reader who opened it to find one thing has silently dismissed the other seven.

**4. Does the bell keep its cap of eight?**

*Recommendation:* yes, with a link. The panel stays a sidebar of the most recent
eight and gains "see all", which is the route the ninth row was missing. The cap
stops being a bound with nothing past it the moment the link exists.

**5. Can a notification be deleted, and does anything prune?**

*Recommendation:* no to both, matching `AuditEvent` — a history somebody can
edit is not one, and at classroom scale nothing needs pruning. If that changes
it is a recurring job, not a button. **This is the one recommendation with a
real counter-argument:** these are personal rows rather than an institutional
record, and "clear my notifications" is an ordinary thing to want. If the
Product Owner wants deletion, it should be decided here rather than added later,
because a screen built on "nothing is deleted" and a screen built on "the reader
owns their list" differ in more than a button.

## What is not being asked

Email, push, digests, per-kind preferences, muting, and read receipts are all
out. ADR-0004 governs the first two and nothing here reopens it. This decision
adds a route to rows the application already writes; it changes nothing about
what is written or who is told.

## Alternatives

### Page the dropdown

Rejected in ADR-0050 and rejected again here. A control inside a menu that
closes on outside-click, on a panel the header re-fetches over a frame, is a
worse reading experience than the cap it replaces.

### Raise `RECENT` from 8 to 50

The audit log's rejected answer, for the audit log's reason: the problem is not
that eight is too few, it is that there is no route past whatever the number is.
Fifty would push the cliff out and leave it exactly as invisible.

### Do nothing

Defensible today and the reason this is proposed rather than assumed. At current
volume most readers never reach the ninth row, and the dot still tells them
something happened. It stops being defensible the first time somebody is told
something that matters and cannot find it again — and because nothing is
delivered anywhere else, that failure is silent on both sides.

## Consequences if accepted

- One screen, one route change, one nav entry, and roughly the amount of code
  the paged lists increment spent on a single list.
- `notifications#show` stops being an exception in `route_reachability_test.rb`.
- The reader gains a place to answer "what was I told?", which no surface in the
  application answers today.
- `Notification::RECENT` keeps its meaning — the size of a sidebar — rather than
  being quietly load-bearing as a retention policy.

## Fitness Functions

*Written for the specification this would produce; none is satisfied today.*

- A reader with more than eight notifications reaches the ninth from the bell in
  one click, and the oldest from the screen in a bounded number of pages.
- Opening the screen does not change any row's `read_at`.
- The screen renders at most `Page::SIZE` rows for any request, whatever the
  count, and an impossible page clamps.
- The bell and the screen render the same row identically, in the reader's
  language, from one partial.

## Decision owner

Product Owner for questions 2, 3 and 5; Tech Lead for 1 and 4; QA owner for the
accessibility of the screen. **Not accepted. No work is authorized.**
