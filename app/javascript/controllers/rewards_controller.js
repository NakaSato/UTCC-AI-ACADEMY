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
  }

  add({ detail: { gems } }) {
    this.earned += gems
    this.totalTarget.textContent = `+${this.earned}`
  }
}
