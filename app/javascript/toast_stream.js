import { Turbo } from "@hotwired/turbo-rails"

// The server's way into the toast host. A controller answering with
//
//   render turbo_stream: turbo_stream.toast(t("flash.saved"), kind: :success)
//
// sends <turbo-stream action="toast" kind="success" target="toasts"> with the
// message as its template's text, and this is what that action does with it.
//
// It raises the same `toast:show` event a Stimulus controller raises rather
// than writing a row itself. That is the whole point: the row's markup lives in
// one <template> in shared/_toasts, and its reveal, its clock and its removal
// live in one controller. A stream that appended finished markup would need a
// second copy of both, and the two would drift.
//
// Everything but the message rides as an attribute, and the message is read as
// text and written as text — see the escaping in
// config/initializers/toast_stream.rb — so a message carrying a student's own
// words cannot carry markup with them.
//
// Outside controllers/ for the same reason frame_recovery.js is: `pin_all_from`
// would otherwise register it as a Stimulus controller, and this is one
// registration, not a behaviour attached to an element.
Turbo.StreamActions.toast = function () {
  const message = this.templateContent.textContent.trim()
  if (!message) return

  const read = name => this.getAttribute(name) || undefined
  const label = read("action-label")
  const href = read("action-href")

  window.dispatchEvent(new CustomEvent("toast:show", {
    detail: {
      message,
      kind: read("kind") || "info",
      title: read("title"),
      // Absent means "use the controller's default"; "0" means "stay".
      duration: this.hasAttribute("duration") ? Number(this.getAttribute("duration")) : undefined,
      action: label && href ? { label, href, method: read("action-method") } : undefined
    }
  }))
}
