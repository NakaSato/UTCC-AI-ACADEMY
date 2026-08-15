import { Controller } from "@hotwired/stimulus"

// Adds restrained entrance motion to content owned by a native disclosure.
// The details element remains the source of truth for open/closed semantics.
export default class extends Controller {
  static targets = ["content"]

  disconnect() {
    this.cancelAnimation()
  }

  toggle() {
    this.cancelAnimation()
    if (!this.element.open || !this.hasContentTarget || this.reducedMotion) return

    const animation = this.contentTarget.animate(
      [
        { opacity: 0.45, transform: "translateY(-4px)" },
        { opacity: 1, transform: "none" }
      ],
      {
        duration: 190,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
        fill: "both"
      }
    )
    this.animation = animation

    animation.addEventListener("finish", () => {
      if (this.animation !== animation) return

      this.animation = null
      animation.cancel()
    }, { once: true })
  }

  cancelAnimation() {
    this.animation?.cancel()
    this.animation = null
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
