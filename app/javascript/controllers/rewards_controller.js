import { Controller } from "@hotwired/stimulus"

// Keeps the lesson sidebar's "gems earned" counter in step with the exercise
// and the coding task, which each announce their own reward.
export default class extends Controller {
  static targets = ["total"]

  connect() {
    this.earned = 0
  }

  add({ detail: { gems } }) {
    this.earned += gems
    this.totalTarget.textContent = `+${this.earned}`
  }
}
