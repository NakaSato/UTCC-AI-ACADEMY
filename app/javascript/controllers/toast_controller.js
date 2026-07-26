import { Controller } from "@hotwired/stimulus"

// Shows the transient messages the app raises between page loads. The flash
// partial handles anything that survives a redirect; this handles what does
// not, so nothing here is persisted and a reload clears the lot.
//
// Callers dispatch rather than reach for this controller:
//
//   this.dispatch("show", { prefix: "toast", detail: { message, kind } })
//
// The layout routes `toast:show` to #show, so a new caller adds no wiring. The
// row it clones is a <template> in shared/_toasts, which is why no markup lives
// in here.
export default class extends Controller {
  static targets = ["list", "row"]
  static values = { duration: { type: Number, default: 3000 } }

  connect() {
    this.timers = new Set()
  }

  show({ detail: { message, kind = "info" } }) {
    if (!message) return

    const toast = this.rowTarget.content.firstElementChild.cloneNode(true)
    toast.dataset.kind = kind
    toast.querySelector("[data-slot=message]").textContent = message
    this.listTarget.appendChild(toast)

    // A frame between the insert and the flip, or the transition has no start
    // state to move from and the toast simply appears.
    requestAnimationFrame(() => { toast.dataset.visible = "true" })

    this.schedule(() => this.dismiss(toast), this.durationValue)
  }

  dismiss(toast) {
    toast.dataset.visible = "false"

    const remove = () => toast.remove()
    toast.addEventListener("transitionend", remove, { once: true })
    // transitionend does not fire if the element is already off screen or the
    // transition is skipped, and an invisible row left in the list would still
    // take up space in it. Removing twice is harmless.
    this.schedule(remove, 400)
  }

  schedule(callback, delay) {
    const timer = setTimeout(() => {
      this.timers.delete(timer)
      callback()
    }, delay)

    this.timers.add(timer)
  }

  // Turbo swaps the body on navigation, so anything still pending would fire
  // against a detached element.
  disconnect() {
    this.timers.forEach(clearTimeout)
    this.timers.clear()
  }
}
