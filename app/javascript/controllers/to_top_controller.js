import { Controller } from "@hotwired/stimulus"

// Reveals the scroll-up button after the first viewport.
export default class extends Controller {
  static values = { after: { type: Number, default: 400 } }

  connect() {
    this.animation = null
    this.onScroll = this.onScroll.bind(this)
    this.visible = window.scrollY > this.afterValue
    this.commitVisibility(this.visible)
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    this.stopAnimation()
  }

  onScroll() {
    const visible = window.scrollY > this.afterValue
    if (visible === this.visible) return

    this.visible = visible
    this.animateVisibility()
  }

  scrollUp() {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }

  animateVisibility() {
    const styles = getComputedStyle(this.element)
    const currentOpacity = Number(styles.opacity)
    const currentTransform = styles.transform
    this.stopAnimation()

    if (this.reducedMotion || typeof this.element.animate !== "function") {
      this.commitVisibility(this.visible)
      return
    }

    if (this.visible) this.commitVisibility(true)

    const restingTransform = currentTransform === "none" ? "none" : currentTransform
    const hiddenTransform = "translateY(8px) scale(0.94)"
    const animation = this.element.animate([
      {
        opacity: currentOpacity,
        transform: this.visible && currentOpacity === 0 ? hiddenTransform : restingTransform
      },
      {
        opacity: this.visible ? 1 : 0,
        transform: this.visible ? "none" : hiddenTransform
      }
    ], {
      duration: this.visible ? 200 : 150,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.animation = animation

    animation.addEventListener("finish", () => {
      if (this.animation !== animation) return

      this.animation = null
      if (!this.visible) this.commitVisibility(false)
      animation.cancel()
    }, { once: true })
  }

  stopAnimation() {
    if (!this.animation) return

    const animation = this.animation
    this.animation = null
    animation.cancel()
  }

  commitVisibility(visible) {
    this.element.dataset.visible = String(visible)
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
