---
id: ADR-0046
type: adr
title: Let the server raise a toast by dispatching the client's event, not by streaming a row
status: accepted
owners: ["@tech-lead", "@product-owner"]
created: 2026-08-09
updated: 2026-08-10
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0045]
implemented_by:
  - SPEC-0046
touches:
  - app/javascript/toast_stream.js
  - app/javascript/application.js
  - app/javascript/controllers/toast_controller.js
  - app/views/shared/_toasts.html.erb
  - app/controllers/notifications_controller.rb
  - config/initializers/toast_stream.rb
  - config/importmap.rb
enforced_by:
  - test/helpers/toast_stream_test.rb
  - test/controllers/toasts_test.rb
  - test/controllers/notifications_test.rb
  - test/system/notification_bell_walk_test.rb
agent_writable: true
requires_skills: [SKILL-PROD-001, SKILL-ARCH-002, SKILL-SPEC-001]
min_reviewer_skills: [SKILL-ARCH-002, SKILL-SPEC-002]
---

# Let the Server Raise a Toast by Dispatching the Client's Event, Not by Streaming a Row

> **Decision state:** Accepted by the user on 2026-08-09. `turbo_stream.toast`
> renders a custom Turbo Stream action that dispatches the same `toast:show`
> event a Stimulus controller dispatches. The row's markup and its lifetime stay
> in one template and one controller.

> [Decision Records](README.md) ·
> [Toast notifications specification](../specs/spec-toast-notifications.md) ·
> [Rendered error pages decision](adr-0045-rendered-error-pages.md)

## Context

The app already had a toast host: `shared/_toasts` ships in the application
layout inside a fixed container, `toast_controller.js` clones a `<template>`
row, reveals it, times it out and removes it, and any Stimulus controller raises
one by dispatching `toast:show`. What it had no way to do was raise one from the
server. Nothing in the app answered with a Turbo Stream at all, so an action
that succeeded without a page load had no way to say so except by redirecting
and using a flash — which is the wrong surface for something that did not
navigate.

The obvious recipe is `turbo_stream.prepend "toasts", partial: "shared/toast"`:
the server sends a finished row and Turbo puts it in the list.

## Decision

1. A custom Turbo Stream action, `toast`, registered on `Turbo.StreamActions` in
   `app/javascript/toast_stream.js`. It reads the message out of the stream
   element's template and dispatches `toast:show` on `window` — the same event,
   with the same detail shape, that a Stimulus controller dispatches.
2. `turbo_stream.toast(message, kind: :info)` builds the tag, registered through
   Turbo's `:turbo_streams_tag_builder` load hook.
3. The message is HTML-escaped into the template by the builder.
   `turbo_stream_action_tag` marks whatever it is handed as `html_safe`, so
   escaping at the call site is what keeps a message built from someone's own
   words from carrying markup.
4. `kind` is checked against the four the row has a variant for — `info`,
   `success`, `warning`, `error` — and an unknown one raises.
5. The host carries `id="toasts"` so the stream tag has a target to name.
6. The payload both callers share is `{ message, kind, title, duration, action }`
   — enough for an undo and for a message that stays until it is read. There is
   no arbitrary-HTML toast; see the alternative below.
7. `notifications#read_all` is the first caller, and the reason the API exists
   rather than the other way round: clearing the bell was a full navigation
   whose only purpose was to redraw the bell and say it had worked.

## Alternatives

**`turbo_stream.prepend` a rendered row.** The recipe, and the reason it was
rejected is duplication of the two things that are currently in one place: the
row's markup, which lives in the `<template>` in `shared/_toasts`, and its
lifetime — reveal, timeout, removal, timer cleanup on Turbo navigation — which
lives in `toast_controller.js`. A prepended row is markup the controller never
saw, so it would need either a second controller attached per row or a
`MutationObserver` in the existing one, and the partial and the template would
have to be kept identical by hand. Two sources for one row is how a toast ends
up looking different depending on who raised it.

**Extract the row into a partial rendered both into the `<template>` and by the
stream.** This fixes the markup half and not the lifetime half, and it makes the
template a rendering of a partial that exists only to be rendered twice. The
event keeps one entry point for both callers instead.

**A dedicated ActionCable broadcast.** Already available for anything that has
to reach a session that did not make the request — the notification bell uses
it. Overweight for feedback on the request the visitor just made, and it is the
wrong tab: the bell's broadcast is what redraws the reader's *other* sessions,
while the one that acted is answered in its own response. A tab that waited for
the websocket would show a toast saying the bell was cleared above a bell still
showing its dot.

**Adopt the Rails Blocks toast component** (`railsblocks.com/docs/toast`),
evaluated on 2026-08-10 against its own documentation. Rejected, on two grounds
that are independent of taste:

  * **Its server path cannot run here.** The documented way to raise one from
    the server is `turbo_stream.append("toast-messages", partial:
    "shared/toast_script")`, where the partial is a `<script>` tag calling a
    global `toast()`. This app sends `script-src 'self'` with a per-request
    random nonce and no `unsafe-inline`. A script injected into an existing
    document is checked against *that document's* nonce, and a stream response
    generates a different one, so the tag is blocked — silently, which is the
    worst way for a confirmation to fail. Making it work means putting
    `unsafe-inline` in `script-src`, and that directive is where the whole value
    of the policy sits (see the initializer's own comment).
  * **The component is a download, not a dependency.** The docs describe files
    to copy into `app/views/…`; they are not the files. There is nothing to
    vendor from a documentation site, and its `toast_controller.js` occupies the
    same path as ours, so a copy-in would silently replace the controller the
    lesson's two callers already dispatch to.

Three further mismatches, had neither of those applied: the ViewComponent path
wants a component layer this codebase has decided against, its `html` option is
the arbitrary-HTML toast rejected below, and its accessibility guidance is one
`aria-live="polite"` announcer where this host already splits polite from
assertive. Its stack limit was the one idea worth taking, and was.

**An arbitrary-HTML toast**, as a general-purpose toast component would offer.
Rejected on where the content comes from: a toast is the most likely surface in
this app to interpolate a student's own words — a title they typed, a company
name, a filename — and an API that accepts markup is an API where one caller
eventually interpolates into it. `title` plus one action link covers what rich
content was actually wanted for, and both are read and written as text.

## Consequences

- Both halves of the API converge on one event, so the row's markup, styling and
  timing have exactly one definition, and a caller — Stimulus or server — needs
  no wiring in the partial.
- Any controller action answering a Turbo request can now say something without
  navigating: `render turbo_stream: turbo_stream.toast(...)`.
- The stream action is registered globally, once, in `application.js`. It lives
  outside `controllers/` because `pin_all_from` would otherwise register it as a
  Stimulus controller — the same reason `frame_recovery.js` is there.
- Clearing the bell no longer navigates. The dropdown stays where it was, the
  bell comes back cleared in the same response, and the toast says so.
- A form inside a `<turbo-frame>` answered with a stream is the shape that
  writes "Content missing" where the frame was if Turbo does not intercept it.
  It does — `StreamObserver` is document-level — but that is not a thing to
  reason about twice, so a system test drives it in a browser.
- The host grew with the API: four kinds, an optional title, an optional action
  link, a per-toast duration with `0` meaning "until dismissed", a dismiss
  button on every row, a clock that stops while the row is hovered or focused,
  six positions, and separate polite and assertive live regions. Each is in
  SPEC-0046 as an invariant.

## Fitness Functions

- `test/helpers/toast_stream_test.rb` — the tag's action, target and every
  attribute; the omissions; the escaping; both `ArgumentError`s.
- `test/controllers/toasts_test.rb` — the host, its id, its anchor, both live
  regions, every row slot, and the action that routes `toast:show`.
- `test/controllers/notifications_test.rb` — the Turbo response's two streams,
  and the HTML redirect that is left for a browser without Turbo.
- `test/system/notification_bell_walk_test.rb` — the whole path in a browser,
  a toast dismissed by hand, and a burst of five capped at three.
- `bin/verify` runs the whole gate.
