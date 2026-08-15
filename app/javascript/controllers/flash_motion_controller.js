import { Controller } from "@hotwired/stimulus"

// Redirect feedback survives one navigation by design. Give it one restrained
// entrance, then remove it before Turbo snapshots the page so browser history
// cannot bring back and re-announce an already consumed message.
export default class extends Controller {
  static targets = ["item"]

  connect() {
    if (this.reducedMotion) return

    this.animations = this.itemTargets.map((item, index) => {
      if (typeof item.animate !== "function") return null

      const animation = item.animate([
        { opacity: 0.35, transform: "translateY(-6px)" },
        { opacity: 1, transform: "translateY(0)" }
      ], {
        duration: 220,
        delay: Math.min(index * 35, 105),
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
      })

      animation.addEventListener("finish", () => animation.cancel(), { once: true })
      return animation
    }).filter(Boolean)
  }

  disconnect() {
    this.animations?.forEach((animation) => animation.cancel())
    this.animations = []
  }

  remove() {
    this.element.remove()
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
