import { Controller } from "@hotwired/stimulus"

// The lesson's coding task. The criteria tick as you type; "Run & check"
// prints the console output and unlocks the final step. The patterns come
// from LessonContent so Ruby stays the single source of truth for grading.
export default class extends Controller {
  static targets = ["editor", "check", "console", "finish", "copy"]
  static values = {
    patterns: Array,
    starter: String,
    gems: { type: Number, default: 10 }
  }

  connect() {
    this.regexes = this.patternsValue.map((source) => new RegExp(source))
    this.evaluate()
  }

  // Live criteria feedback. Running is a separate, explicit step.
  evaluate() {
    this.results.forEach((passed, index) => {
      this.checkTargets[index].dataset.state = passed ? "ok" : ""
    })
  }

  run() {
    const passed = this.results.every(Boolean) && !this.editorTarget.value.includes("___")
    const copy = this.copyTarget.dataset

    this.consoleTarget.dataset.state = passed ? "pass" : "fail"
    this.consoleTarget.textContent = passed
      ? `$ python split_customers.py\n40000 10000\n\n${copy.pass}`
      : `$ python split_customers.py\nSyntaxError: invalid syntax\n\n${copy.fail}`

    this.finishTarget.classList.toggle("hidden", !passed)
    if (passed) this.dispatch("reward", { detail: { gems: this.gemsValue, kind: "applied" } })
  }

  reset() {
    this.editorTarget.value = this.starterValue
    this.consoleTarget.dataset.state = ""
    this.consoleTarget.textContent = `$ python split_customers.py\n${this.copyTarget.dataset.idle}`
    this.finishTarget.classList.add("hidden")
    this.evaluate()
  }

  get results() {
    const code = this.editorTarget.value
    return this.regexes.map((regex) => regex.test(code))
  }
}
