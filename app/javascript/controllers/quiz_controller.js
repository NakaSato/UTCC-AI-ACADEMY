import { Controller } from "@hotwired/stimulus"
import { grade } from "grading"

// The lesson exercise. The answer goes to the server, which grades it, files the
// attempt and answers with the verdict — this controller knows nothing about
// which option is right until it is told.
//
// Visual state travels on data-state and is read by Tailwind variants, so this
// controller only ever sets an attribute — it never juggles class lists.
export default class extends Controller {
  static targets = ["option", "feedback", "feedbackTitle", "feedbackBody", "check", "next", "copy"]
  static values = { url: String, course: String, topic: String }

  connect() {
    this.picked = null
    this.checked = false
  }

  pick(event) {
    if (this.checked) return

    const picked = Number(event.currentTarget.dataset.index)
    if (picked === this.picked) return

    this.picked = picked

    this.optionTargets.forEach((option, index) => {
      const isPicked = index === this.picked
      option.dataset.state = isPicked ? "picked" : ""
      option.setAttribute("aria-checked", String(isPicked))
    })

    this.checkTarget.disabled = false
    this.dispatch("selection", {
      detail: { target: event.currentTarget.querySelector("[data-quiz-choice-indicator]") }
    })
  }

  async check() {
    if (this.picked === null || this.checked) return

    this.checked = true
    this.checkTarget.disabled = true
    this.dispatch("start", { detail: { target: this.checkTarget } })

    const verdict = await grade({
      url: this.urlValue, course: this.courseValue, topic: this.topicValue,
      kind: "quiz", answer: this.picked
    })

    // Refused or unreachable: let them try again rather than marking an answer
    // the server never saw. Say so, too — re-enabling the button on its own
    // looks identical to the click not having registered, and there is no page
    // load here to carry a flash.
    if (!verdict) {
      this.checked = false
      this.checkTarget.disabled = false
      this.dispatch("show", {
        prefix: "toast",
        detail: { message: this.copyTarget.dataset.unreachable, kind: "error" }
      })
      return
    }

    this.render(verdict)
  }

  render({ passed, correct_index: correctIndex, gems }) {
    this.optionTargets.forEach((option, index) => {
      if (index === correctIndex) option.dataset.state = "correct"
      else if (index === this.picked) option.dataset.state = "wrong"
      else option.dataset.state = ""
    })

    const copy = this.copyTarget.dataset
    this.feedbackTarget.dataset.state = passed ? "correct" : "wrong"
    this.feedbackTitleTarget.textContent = passed ? copy.correctTitle : copy.wrongTitle
    this.feedbackBodyTarget.textContent = passed ? copy.correctBody : copy.wrongBody
    this.feedbackTarget.classList.remove("hidden")
    this.dispatch("result", { detail: { target: this.feedbackTarget } })

    if (passed) {
      this.nextTarget.classList.remove("hidden")
      this.dispatch("action", { detail: { target: this.nextTarget } })
      this.dispatch("reward", { detail: { gems } })
    }
  }
}
