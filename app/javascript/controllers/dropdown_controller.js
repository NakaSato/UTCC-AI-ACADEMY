import { Controller } from "@hotwired/stimulus"

// Shared menus: navigation, preferences, notifications and the account menu.
// They close when you click away or press Escape, so opening one closes its
// siblings for free. Motion is driven here rather than duplicated across every
// panel, and is skipped when the reader asks the operating system for less.
export default class extends Controller {
  static targets = ["button", "panel", "indicator"]

  disconnect() {
    this.stopAnimation()
    this.stopItemAnimations()
    this.stopIndicatorAnimation()
  }

  toggle() {
    this.panelTarget.hidden || this.panelTarget.dataset.state === "closing" ? this.open() : this.close()
  }

  open() {
    this.stopAnimation()

    this.panelTarget.hidden = false
    this.panelTarget.inert = false
    this.panelTarget.removeAttribute("aria-hidden")
    this.panelTarget.dataset.state = "open"
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.rotateIndicator(180)

    this.play([
      { opacity: 0, transform: "translateY(-6px) scale(0.98)", transformOrigin: "top center" },
      { opacity: 1, transform: "translateY(0) scale(1)", transformOrigin: "top center" }
    ], 170)
    this.playItems()
  }

  close() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
    if (this.panelTarget.hidden || this.panelTarget.dataset.state === "closing") return

    this.stopAnimation()
    this.panelTarget.inert = true
    this.panelTarget.setAttribute("aria-hidden", "true")
    this.panelTarget.dataset.state = "closing"
    this.rotateIndicator(0)
    this.stopItemAnimations()

    this.play([
      { opacity: 1, transform: "translateY(0) scale(1)", transformOrigin: "top center" },
      { opacity: 0, transform: "translateY(-4px) scale(0.98)", transformOrigin: "top center" }
    ], 120, () => {
      this.panelTarget.hidden = true
      this.panelTarget.dataset.state = "closed"
    })
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape(event) {
    if (event.key !== "Escape") return

    this.close()
    this.buttonTarget.focus()
  }

  play(keyframes, duration, after = () => {}) {
    if (this.reducedMotion || typeof this.panelTarget.animate !== "function") {
      after()
      return
    }

    const animation = this.panelTarget.animate(keyframes, {
      duration,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.animation = animation

    animation.addEventListener("finish", () => {
      if (this.animation !== animation) return

      this.animation = null
      animation.cancel()
      after()
    }, { once: true })
  }

  stopAnimation() {
    if (!this.animation) return

    const animation = this.animation
    this.animation = null
    animation.cancel()
  }

  playItems() {
    this.stopItemAnimations()
    if (this.reducedMotion) return

    this.itemAnimations = Array.from(this.panelTarget.children).map((item, index) => {
      const animation = item.animate([
        { opacity: 0, transform: "translateY(-3px)" },
        { opacity: 1, transform: "translateY(0)" }
      ], {
        duration: 150,
        delay: 24 + Math.min(index, 6) * 22,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
        fill: "both"
      })

      animation.addEventListener("finish", () => animation.cancel(), { once: true })
      return animation
    })
  }

  stopItemAnimations() {
    this.itemAnimations?.forEach((animation) => animation.cancel())
    this.itemAnimations = []
  }

  rotateIndicator(degrees) {
    if (!this.hasIndicatorTarget) return

    const indicator = this.indicatorTarget
    const destination = `rotate(${degrees}deg)`
    const current = getComputedStyle(indicator).transform
    this.stopIndicatorAnimation()

    if (this.reducedMotion || typeof indicator.animate !== "function") {
      indicator.style.transform = destination
      return
    }

    const animation = indicator.animate([
      { transform: current === "none" ? indicator.style.transform || "rotate(0deg)" : current },
      { transform: destination }
    ], {
      duration: 170,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.indicatorAnimation = animation

    animation.addEventListener("finish", () => {
      if (this.indicatorAnimation !== animation) return

      this.indicatorAnimation = null
      indicator.style.transform = destination
      animation.cancel()
    }, { once: true })
  }

  stopIndicatorAnimation() {
    if (!this.indicatorAnimation) return

    const animation = this.indicatorAnimation
    this.indicatorAnimation = null
    animation.cancel()
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
