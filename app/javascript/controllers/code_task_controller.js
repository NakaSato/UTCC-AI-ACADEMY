import { Controller } from "@hotwired/stimulus"
import { grade } from "grading"

// The lesson's coding task. "Run & check" sends the source to the server, which
// grades it against patterns that stay there, and answers with a verdict per
// criterion plus the overall result.
//
// The criteria no longer tick as you type. Live ticking needs the patterns in
// the page, which is exactly what moving grading to the server removed — so
// they light up when the run answers instead.
export default class extends Controller {
  static targets = ["editor", "check", "console", "finish", "copy"]
  static values = { url: String, course: String, topic: String, starter: String }

  async run() {
    const copy = this.copyTarget.dataset

    this.consoleTarget.dataset.state = ""
    this.consoleTarget.textContent = `$ python split_customers.py\n${copy.running}`
    this.dispatch("start", { detail: { target: this.consoleTarget } })

    const verdict = await grade({
      url: this.urlValue, course: this.courseValue, topic: this.topicValue,
      kind: "code", answer: this.editorTarget.value
    })

    // Nothing was graded. Putting the console back to idle on its own reads as
    // if the run never happened, so say why — a toast rather than a flash,
    // since no page load is coming.
    if (!verdict) {
      this.consoleTarget.textContent = `$ python split_customers.py\n${copy.idle}`
      this.dispatch("show", {
        prefix: "toast",
        detail: { message: copy.unreachable, kind: "error" }
      })
      return
    }

    this.render(verdict)
  }

  render({ passed, checks, gems }) {
    checks.forEach((ok, index) => {
      if (this.checkTargets[index]) this.checkTargets[index].dataset.state = ok ? "ok" : ""
    })
    this.dispatch("criteria", { detail: { targets: this.checkTargets } })

    const copy = this.copyTarget.dataset
    this.consoleTarget.dataset.state = passed ? "pass" : "fail"
    this.consoleTarget.textContent = passed
      ? `$ python split_customers.py\n40000 10000\n\n${copy.pass}`
      : `$ python split_customers.py\nSyntaxError: invalid syntax\n\n${copy.fail}`
    this.dispatch("result", { detail: { target: this.consoleTarget } })

    this.finishTarget.classList.toggle("hidden", !passed)
    if (passed) {
      this.dispatch("action", { detail: { target: this.finishTarget } })
      this.dispatch("reward", { detail: { gems } })
    }
  }

  reset() {
    this.editorTarget.value = this.starterValue
    this.consoleTarget.dataset.state = ""
    this.consoleTarget.textContent = `$ python split_customers.py\n${this.copyTarget.dataset.idle}`
    this.finishTarget.classList.add("hidden")
    this.checkTargets.forEach((check) => (check.dataset.state = ""))
    this.dispatch("clear", { detail: { target: this.consoleTarget } })
    this.dispatch("clear-criteria", { detail: { targets: this.checkTargets } })
    this.dispatch("clear-action", { detail: { target: this.finishTarget } })
  }
}
