import { Controller } from "@hotwired/stimulus"

// Keeps the lesson sidebar's "gems earned" counter in step with the exercise and
// the coding task, which each announce what the server awarded them.
//
// It used to do the reporting too, posting a pass the browser had decided on its
// own. Grading moved to the server, so the submission is the report and this is
// only a counter again. The number it shows is optimistic and lives in browser
// memory — the progress screens count the rows.
export default class extends Controller {
  static targets = ["total"]

  connect() {
    this.earned = 0
    this.animation = null
  }

  disconnect() {
    this.animation?.cancel()
    this.animation = null
  }

  add({ detail: { gems } }) {
    this.earned += gems
    this.totalTarget.textContent = `+${this.earned}`
    this.bump()
  }

  // A passing verdict already updated the number before movement begins. The
  // bump is only acknowledgement; it cannot award gems or delay the result.
  bump() {
    this.animation?.cancel()
    this.animation = null
    if (this.reducedMotion || typeof this.totalTarget.animate !== "function") return

    const animation = this.totalTarget.animate([
      { transform: "translateY(0) scale(1)" },
      { transform: "translateY(-2px) scale(1.16)", offset: 0.45 },
      { transform: "translateY(0) scale(1)" }
    ], {
      duration: 320,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.animation = animation
    animation.addEventListener("finish", () => {
      if (this.animation !== animation) return

      this.animation = null
      animation.cancel()
    }, { once: true })
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
