// A frame fetches after its page has loaded, so it can be refused by a gate the
// page itself already passed: leave a screen open past Session::MAX_AGE and the
// next frame fetch — the leaderboard's board, or the bell answering a broadcast —
// is redirected to the landing page. Turbo cannot find its frame in that
// response, and its default is to write "Content missing" into the frame. That is
// English, in a Thai header, where a bell used to be.
//
// The redirect is the *right* answer; it is just aimed at the wrong scope. So a
// frame that has been redirected is promoted to a full-page visit, which lands on
// the landing page with the "please sign in" flash — exactly what a navigation
// would have done.
//
// Guarded on `redirected` on purpose: a frame that is missing because a template
// stopped rendering it is a bug, and should keep failing loudly instead of
// quietly navigating somewhere.
//
// This lives outside `controllers/` for the same reason `grading.js` does —
// `pin_all_from` would otherwise register it as a Stimulus controller. It is one
// document-level listener, not a behaviour attached to an element.
document.addEventListener("turbo:frame-missing", (event) => {
  const { response, visit } = event.detail

  if (!response.redirected) return

  event.preventDefault()
  visit(response)
})
