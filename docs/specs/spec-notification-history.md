---
id: SPEC-0053
type: spec
title: The notification history screen, and the bell that links to it
status: accepted
owners: ["@product-owner", "@tech-lead", "@qa-owner"]
created: 2026-08-12
updated: 2026-08-12
review_by: 2026-08-26
supersedes: []
superseded_by: []
depends_on: [ADR-0052, ADR-0050, ADR-0004]
implemented_by:
  - config/routes.rb
  - app/controllers/notifications_controller.rb
  - app/views/notifications/show.html.erb
  - app/views/shared/_app_notifications.html.erb
  - app/views/shared/_app_notifications_refetch.html.erb
enforced_by:
  - test/controllers/notifications_test.rb
  - test/controllers/notification_broadcast_test.rb
  - test/models/notification_bell_test.rb
  - test/operations/route_reachability_test.rb
touches:
  - app/controllers
  - app/views
  - config/routes.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-ARCH-002]
min_reviewer_skills: [SKILL-SPEC-002, SKILL-ARCH-002]
---

# The Notification History Screen, and the Bell That Links to It

> **Review state:** Accepted on 2026-08-12 on the authority of
> [ADR-0052](../decisions/adr-0052-notification-history.md), which the user
> accepted the same day by taking all five recommendations as written. This adds
> no product decision; it records what shipped against them.

> [Executable Specifications](README.md) ·
> [Notification history decision](../decisions/adr-0052-notification-history.md) ·
> [Paged lists](spec-paged-lists.md) ·
> [Production email deferred](../decisions/adr-0004-defer-production-email.md)

## Problem

`Notification::RECENT` is 8, the bell renders the most recent eight, and no
route reached the ninth. Because [ADR-0004](../decisions/adr-0004-defer-production-email.md)
defers production email, the bell is the only channel there is: a student
invited to a business case, a company told a request arrived, a supervisor
assigned to a placement each learn about it there or not at all.

The bell answers *what is waiting* — that is the dot. Nothing answered *what was
I told?*

## The routes

| Route | Action | What it is |
| --- | --- | --- |
| `GET /notifications` | `notifications#show` | The reader's history. A page, with a template |
| `GET /notifications/bell` | `notifications#bell` | The panel the header's frame comes back for. Not a page |
| `POST /notifications/read` | `notifications#read_all` | Unchanged: everything unread becomes read |

The readable URL belongs to the reader's screen; the frame is an implementation
detail of the header and now says so in its path. `notifications#show` is no
longer an exception in `route_reachability_test.rb`; `notifications#bell` is.
The exception moved rather than disappeared, which is what a frame endpoint
honestly is.

## The screen

- **Every row this account has, newest first**, paged at `Page::SIZE` like every
  other list that grows with the institution (SPEC-0051).
- **A history, not an inbox.** Read rows stay, marked read. The unread ones
  carry the same dot and tint the bell uses.
- **Reading the screen writes nothing.** No `read_at` moves because somebody
  looked. The one write is the button, which the screen carries a copy of —
  shown only when something is unread.
- **A row says the same thing here as in the bell**, because the sentence, the
  action link and the read state all come from `Notification` rather than from
  either template. The markup differs — a dropdown row is not a card — and that
  is the only difference permitted.
- **Scoped to the reader.** `Current.user.notifications`, never a parameter.
  There is no route to anybody else's history and no administrator view.
- Timestamps are numeric and in the reader's zone, like the audit log and the
  bell: Thai writes the Buddhist year and no `strftime` of a Gregorian date
  produces it.

## The bell

Unchanged except for one link. It stays a sidebar of the most recent eight and
gains **"see all"** at the foot of the panel, out of the frame like every other
destination in that menu. The cap stops being a bound with nothing past it the
moment the link exists.

## What is out

Email, push, digests, per-kind preferences, muting, read receipts, deletion, and
pruning. Nothing here changes what is written or who is told; it adds a route to
rows the application already writes. Deletion is refused for `AuditEvent`'s
reason and is the one answer ADR-0052 records a real counter-argument against.

## Invariants

1. A reader with more than eight notifications reaches the ninth from the bell
   in one click, and every row ever written for them from the screen.
2. `GET /notifications` changes no row's `read_at`.
3. The screen renders at most `Page::SIZE` rows for any request, and an
   impossible page clamps to a real one.
4. The screen shows the reader's own notifications and no others.
5. Signed out, `/notifications` sends the visitor to sign in rather than
   rendering a history.
6. The bell's frame fetches `/notifications/bell`, and the broadcast carries no
   rendered bell — no token, no copy in any language.

## Acceptance Criteria

- Given nine notifications, the oldest renders on `/notifications` and not in
  the bell.
- Given 29, the screen renders 25 and `?page=2` renders 4.
- `GET /notifications` leaves `notifications.unread.count` unchanged, and the
  screen's `main` carries exactly one mark-all-read form.
- A signed-in reader sees none of another account's rows.
- The bell's panel contains a link to `/notifications` reading
  `chrome.notif_see_all`.
- The pushed frame's `src` is `/notifications/bell`.

## Verification

- `test/controllers/notifications_test.rb` — the ninth row, the paging, that
  reading writes nothing, the scoping, the signed-out redirect, and the link.
- `test/controllers/notification_broadcast_test.rb` — the frame endpoint still
  answers with the panel, in the reader's language, carrying a usable token.
- `test/models/notification_bell_test.rb` — the broadcast's `src`.
- `test/operations/route_reachability_test.rb` — the page renders a template and
  the frame endpoint is the recorded exception.

## Consequences

- The sixteenth paged screen, and the last list SPEC-0051 named as growing
  without a bound.
- `Notification::RECENT` keeps its meaning — the size of a sidebar — rather than
  being quietly load-bearing as a retention policy.
- No navigation entry: the way in is the bell, which is where a reader already
  goes to ask this question.
