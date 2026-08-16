---
id: SPEC-0046
type: spec
title: Toast notifications and the two ways to raise one
status: accepted
owners: ["@tech-lead", "@product-owner"]
created: 2026-08-09
updated: 2026-08-15
review_by: 2026-11-07
supersedes: []
superseded_by: []
depends_on: [ADR-0046]
implemented_by:
  - app/views/shared/_toasts.html.erb
  - app/views/layouts/application.html.erb
  - app/javascript/controllers/toast_controller.js
  - app/javascript/toast_stream.js
  - app/javascript/application.js
  - app/controllers/notifications_controller.rb
  - config/initializers/toast_stream.rb
  - config/importmap.rb
touches:
  - app/javascript
  - app/views/shared
  - app/views/layouts
  - app/controllers/notifications_controller.rb
  - config/initializers
  - config/importmap.rb
  - config/locales/en.yml
  - config/locales/th.yml
  - test/system/toast_motion_walk_test.rb
enforced_by:
  - test/controllers/toasts_test.rb
  - test/helpers/toast_stream_test.rb
  - test/controllers/notifications_test.rb
  - test/system/notification_bell_walk_test.rb
  - test/system/toast_motion_walk_test.rb
agent_writable: true
requires_skills: [SKILL-SPEC-001, SKILL-SPEC-002, SKILL-PROD-001]
min_reviewer_skills: [SKILL-SPEC-002]
---

# Toast Notifications and the Two Ways to Raise One

> [Specifications](README.md) ·
> [Server-raised toasts decision](../decisions/adr-0046-server-raised-toasts.md) ·
> [Error pages specification](spec-error-pages.md)

## Problem

The app has two kinds of transient message and they need different surfaces. A
message that has to survive a redirect is a flash, and `shared/_flashes` renders
it in the page. A message about something that happened *without* a page load —
a grading call that could not be reached, a bell that was cleared — has no page
to be rendered into, and before the toast host it had nowhere to go.

The host shipped first and was reachable only from the browser: a Stimulus
controller dispatching `toast:show`. An action on the server that succeeded
without navigating still had no way to say so, because nothing in the app
answered with a Turbo Stream at all. Its only option was to redirect in order to
set a flash — which is what the bell's mark-all-read did, turning the clearing
of a dropdown into a full navigation for the sake of one sentence.

The host was also thinner than the messages it has to carry: three kinds, no way
to offer an undo, no way to keep a message up until it is read, and one live
region for everything, so a confirmation and a failure were announced with the
same urgency.

## Invariants

### The host

1. The host ships with the application layout on every screen that uses it, so a
   caller never renders it and two hosts can never exist on one page.
2. The auth layout carries no host. Nothing on those screens raises a toast.
3. The host is `#toasts` and carries `data-controller="toast"`,
   `data-toast-anchor-value`, and `data-action="toast:show@window->toast#show"`.
4. It sits in one of six positions, passed to the partial as `position:` and
   defaulting to `:top_right`. Each position's classes are written out as
   literals — a class Tailwind cannot see as a literal is a class it does not
   build.
5. A top-anchored stack clears the sticky header: the partial sets a floor that
   clears the shorter of the two headers, and the controller raises `--toast-top`
   to the measured height. A bottom-anchored stack has nothing to clear and the
   controller does not measure.
6. The host contains exactly two `[data-toast-target=list]` regions, one
   `data-urgency="polite"` (`role=status`, `aria-live=polite`) and one
   `data-urgency="assertive"` (`role=alert`, `aria-live=assertive`).
7. The host does not take pointer events; a row does. The host spans the
   viewport to place the stack and must not eat clicks meant for the page.

### The row

8. The row's markup exists once, in the `template[data-toast-target=row]`. No
   other file renders a toast row.
9. Its slots are `title`, `message`, `action` and `close`. `title` and `action`
   are hidden until filled.
10. `kind` is `info` (the default), `success`, `warning` or `error`. Each colours
    the row's left border, and all but `info` add a glyph — `info` is the
    default, and a mark for "nothing special happened" is noise.
11. `warning` and `error` are filed into the assertive region, `info` and
    `success` into the polite one.
12. Every row carries a dismiss button, labelled in the reader's language, not
    only the rows that need one.
13. The row's clock stops on `mouseenter` and `focusin` and resumes on
    `mouseleave` and `focusout`, with the time already spent deducted. A timed
    message must not be one the reader has to race.
14. At most three rows are on screen at once, across both regions. A fourth
    dismisses the oldest — what a reader loses to a burst should be the message
    they have already had time to read.

### Raising one

15. The reveal, the clock, the removal, and the cancelling of pending timers on
    Turbo navigation exist once, in `toast_controller.js`.
16. There are exactly two ways to raise one, and both arrive as a `toast:show`
    event on `window`:
    - a Stimulus controller: `this.dispatch("show", { prefix: "toast", detail: … })`
    - a controller action: `render turbo_stream: turbo_stream.toast(message, …)`
17. The detail is `{ message, kind, title, duration, action: { label, href, method } }`.
    Only `message` is required; an empty one raises nothing, from either caller.
18. `duration` is milliseconds. `0` keeps the toast until it is dismissed.
    Omitted leaves the controller's default alone, so the tag builder does not
    default it either.
19. `turbo_stream.toast` renders
    `<turbo-stream kind="…" action="toast" target="toasts"><template>…</template></turbo-stream>`,
    with the message HTML-escaped into the template and everything else as
    attributes. What is not given is not sent.
20. It raises `ArgumentError` on an unknown `kind`, and on an `action` missing
    either `:label` or `:href` — half an action renders no link at all, which
    reads as the toast simply not offering the undo it was meant to.
21. A message is read from the DOM as text and written to the DOM as text.
    Markup in a message is never markup. There is no arbitrary-HTML toast: a
    toast is the most likely place in the app to interpolate someone's own
    words, and `title` plus one action covers what rich content was wanted for.
22. Nothing about a toast is persisted: a reload clears the lot.
23. `toast_stream.js` sits outside `app/javascript/controllers/`, because
    `pin_all_from` would register it as a Stimulus controller.

### The first caller

24. `notifications#read_all` answers a Turbo request with two streams — the bell
    replaced, and a success toast — and a plain HTML request with the redirect it
    always did. Clearing a dropdown is not a navigation.
25. The bell is redrawn from that response, not from the broadcast. The
    broadcast is for the reader's *other* tabs; a bell that cleared itself only
    once the websocket came back would leave the dot sitting under a toast
    saying it was gone.

## Acceptance Criteria

- The host renders once on a signed-in screen and once on the landing page, with
  its id, its anchor, both regions and the window action.
- The auth screens render no host.
- The row template carries all four slots and the dismiss label in Thai.
- `turbo_stream.toast("Saved")` renders `action="toast"`, `target="toasts"`,
  `kind="info"`, and no `title`, `duration` or `action-*`.
- All four kinds build; `kind: :urgent` raises naming the four.
- `title:` and `duration: 0` ride as attributes.
- `action: { label:, href:, method: }` rides as `action-label`, `action-href`
  and `action-method`; `{ label: }` alone raises.
- `turbo_stream.toast("<script>alert(1)</script>")` renders the escaped text and
  contains no `<script>`; a Thai message survives unescaped.
- A stream carrying an `info`, a `success`, a `warning` and an `error` files two
  rows into each region, renders the action link with `data-turbo-method`, and
  leaves all four up when their duration is `0`.
- A row under the pointer outlives its duration and leaves once the pointer
  does.
- Five toasts raised at once leave three on screen: the three most recent.
- Clicking the dismiss button removes a row before its time is up.
- `POST /notifications/read` as a Turbo request replaces `notification-bell` and
  toasts; as HTML it redirects back.
- In a browser: clearing the bell shows the toast, clears the dot, and does not
  change the path.

## Verification

- `test/controllers/toasts_test.rb` — the host, its id, anchor, both regions,
  one host per page, its absence on the auth layout, every row slot, the
  dismiss label, and the lesson's toast copy.
- `test/helpers/toast_stream_test.rb` — the tag's shape, all four kinds, the
  title, duration and action attributes, the omissions, the escaping, and both
  `ArgumentError`s.
- `test/controllers/notifications_test.rb` — the Turbo response's two streams
  and the HTML redirect.
- `test/system/notification_bell_walk_test.rb` — the whole path in a browser:
  the frame's form answered with a stream rather than a frame, the bell redrawn,
  the toast shown, the path unchanged, a toast dismissed by hand, and a burst of
  five capped at three. Action Cable's test adapter delivers nothing in a system
  test, which is what makes this a test of the response rather than of the
  broadcast.
- `bin/verify` runs the whole gate.

## Out of scope

Turning flashes into toasts. The split is deliberate: a flash survives a
redirect and is rendered into the page, a toast does not and is not. Neither is
a fallback for the other.

Toast queueing. The limit drops the oldest rather than holding a message back:
a queued toast arrives describing something that finished a while ago, which is
worse than not arriving.

Adopting a third-party toast component. Evaluated against the Rails Blocks
component on 2026-08-10 and rejected — see ADR-0046 for the two blocking
reasons, of which the CSP is the one that would apply to any component whose
server path is an injected `<script>`.
