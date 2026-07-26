import { Controller } from "@hotwired/stimulus"

// Keeps the lesson sidebar's "gems earned" counter in step with the exercise
// and the coding task, which each announce their own reward — and reports the
// pass to the server, which is the only thing that remembers it.
//
// The exercise reports "learned", the coding task "applied"; the server files
// both against the same topic. Posting is fire-and-forget: the counter has
// already moved and the feedback is on screen, so a failed report must not undo
// what the student just earned. The progress screens read the record, not this.
export default class extends Controller {
  static targets = ["total"]
  static values = { url: String, course: String, topic: String }

  connect() {
    this.earned = 0
  }

  add({ detail: { gems, kind } }) {
    this.earned += gems
    this.totalTarget.textContent = `+${this.earned}`

    if (kind) this.report(kind)
  }

  report(kind) {
    const token = document.querySelector("meta[name=csrf-token]")?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ kind, course: this.courseValue, topic: this.topicValue })
    }).catch(() => {
      // Offline, or the request was blocked. The next pass reports again.
    })
  }
}
