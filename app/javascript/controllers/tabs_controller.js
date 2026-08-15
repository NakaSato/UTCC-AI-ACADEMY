import { Controller } from "@hotwired/stimulus"

// Curriculum filter tabs: click a level, show only cards carrying that level.
export default class extends Controller {
  static targets = ["tab", "item"]

  connect() {
    this.animations = []
    this.selectedLevel = this.tabTargets.find((tab) => tab.getAttribute("aria-selected") === "true")?.dataset.level
  }

  disconnect() {
    this.cancelAnimations()
  }

  select(event) {
    const level = event.currentTarget.dataset.level
    if (level === this.selectedLevel) return

    this.tabTargets.forEach((tab) => {
      tab.setAttribute("aria-selected", String(tab.dataset.level === level))
    })

    const visibleItems = []
    this.itemTargets.forEach((item) => {
      const match = level === "all" || item.dataset.level === level
      item.hidden = !match
      if (match) visibleItems.push(item)
    })

    this.selectedLevel = level
    this.cancelAnimations()
    this.animateItems(visibleItems)
  }

  animateItems(items) {
    if (this.reducedMotion) return

    this.animations = items.map((item, index) => {
      const animation = item.animate(
        [
          { opacity: 0.45, transform: "translateY(6px) scale(0.985)" },
          { opacity: 1, transform: "none" }
        ],
        {
          duration: 220,
          delay: Math.min(index * 35, 105),
          easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
          fill: "both"
        }
      )

      animation.addEventListener("finish", () => {
        this.animations = this.animations.filter((candidate) => candidate !== animation)
        animation.cancel()
      }, { once: true })
      return animation
    })
  }

  cancelAnimations() {
    this.animations?.forEach((animation) => animation.cancel())
    this.animations = []
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
