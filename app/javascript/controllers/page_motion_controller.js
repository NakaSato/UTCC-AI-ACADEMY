import { Controller } from "@hotwired/stimulus"

// Turbo replaces <body> on a page visit, so the layout is the one stable seam
// for page movement. Remember the visit action outside the controller instance:
// a restoration connects a fresh controller just like an ordinary advance, but
// should put cached content back exactly where the reader left it.
let visitAction = null

document.addEventListener("turbo:visit", (event) => {
  visitAction = event.detail.action
})

export default class extends Controller {
  connect() {
    // Turbo may render a cached preview before the definitive response. Moving
    // both would make one navigation visibly pulse twice, so wait for the final
    // body while retaining the action for its controller instance.
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    const action = visitAction
    visitAction = null

    if (action === "restore" || this.reducedMotion) return

    const content = this.element.querySelector("main#main")
    if (!content || typeof content.animate !== "function") return

    this.animation = content.animate([
      { opacity: 0.88, transform: "translateY(7px)" },
      { opacity: 1, transform: "translateY(0)" }
    ], {
      duration: 180,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    const animation = this.animation
    animation.addEventListener("finish", () => {
      if (this.animation !== animation) return

      this.animation = null
      animation.cancel()
    }, { once: true })
  }

  disconnect() {
    this.animation?.cancel()
    this.animation = null
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
