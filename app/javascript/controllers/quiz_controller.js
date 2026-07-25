import { Controller } from "@hotwired/stimulus"

// The lesson exercise. Grading happens here so feedback is instant; the answer
// key is deliberately public (see LessonContent) until submissions persist.
//
// Visual state travels on data-state and is read by Tailwind variants, so this
// controller only ever sets an attribute — it never juggles class lists.
export default class extends Controller {
  static targets = ["option", "feedback", "feedbackTitle", "feedbackBody", "check", "next", "copy"]
  static values = { correctIndex: Number, gems: { type: Number, default: 5 } }

  connect() {
    this.picked = null
    this.checked = false
  }

  pick(event) {
    if (this.checked) return

    this.picked = Number(event.currentTarget.dataset.index)

    this.optionTargets.forEach((option, index) => {
      const isPicked = index === this.picked
      option.dataset.state = isPicked ? "picked" : ""
      option.setAttribute("aria-checked", String(isPicked))
    })

    this.checkTarget.disabled = false
  }

  check() {
    if (this.picked === null || this.checked) return

    this.checked = true
    const right = this.picked === this.correctIndexValue

    this.optionTargets.forEach((option, index) => {
      if (index === this.correctIndexValue) option.dataset.state = "correct"
      else if (index === this.picked) option.dataset.state = "wrong"
      else option.dataset.state = ""
    })

    const copy = this.copyTarget.dataset
    this.feedbackTarget.dataset.state = right ? "correct" : "wrong"
    this.feedbackTitleTarget.textContent = right ? copy.correctTitle : copy.wrongTitle
    this.feedbackBodyTarget.textContent = right ? copy.correctBody : copy.wrongBody
    this.feedbackTarget.classList.remove("hidden")

    this.checkTarget.disabled = true

    if (right) {
      this.nextTarget.classList.remove("hidden")
      this.dispatch("reward", { detail: { gems: this.gemsValue } })
    }
  }
}
