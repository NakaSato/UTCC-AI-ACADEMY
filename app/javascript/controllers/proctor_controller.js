import { Controller } from "@hotwired/stimulus"

// Lesson proctoring. Watches for the handful of things the design treats as
// integrity incidents — leaving the window, copying the question, pasting a
// wall of text, the context menu, print, screen capture — logs each one and
// docks the integrity score.
//
// The sidebar's score is still per-page, but each incident is reported to the
// server and kept — the admin Integrity tab reads the record. Reporting is
// fire-and-forget: the log has already drawn the row, and a dropped report
// must not redraw it.
//
// Visual state travels on data attributes read by Tailwind variants, so this
// controller only ever sets an attribute; it never juggles class lists.
export default class extends Controller {
  static targets = ["score", "verdict", "meter", "log", "empty", "row"]
  static values = {
    url: String,
    course: String,
    topic: String,
    on: { type: Boolean, default: true },
    score: { type: Number, default: 100 },
    pasteLimit: { type: Number, default: 120 },
    maxEvents: { type: Number, default: 6 },
    bands: Object,   // { clean: 85, review: 60, risk: 0 }
    events: Object,  // kind -> { weight, text }
    copy: Object     // the verdict and guard sentences
  }

  connect() {
    this.events = []
    this.onBlur = () => this.flag("blur", true)
    this.onFocus = () => { this.element.dataset.proctorHidden = "false" }
    this.onVisibility = () => (document.hidden ? this.onBlur() : this.onFocus())
    this.onCopy = (event) => this.intercept(event, "copy")
    this.onContextMenu = (event) => this.intercept(event, "menu")
    this.onPaste = (event) => {
      if (!this.active) return
      const text = (event.clipboardData && event.clipboardData.getData("text")) || ""
      if (text.length > this.pasteLimitValue) this.intercept(event, "paste")
      else this.flag("paste_small")
    }
    this.onKey = (event) => {
      if (!this.active) return
      const key = (event.key || "").toLowerCase()
      const capture =
        key === "printscreen" ||
        ((event.metaKey || event.ctrlKey) && event.shiftKey && ["3", "4", "5", "s"].includes(key))

      if (capture) this.intercept(event, "capture", true)
      else if ((event.metaKey || event.ctrlKey) && key === "p") this.intercept(event, "print")
    }

    window.addEventListener("blur", this.onBlur)
    window.addEventListener("focus", this.onFocus)
    document.addEventListener("visibilitychange", this.onVisibility)
    document.addEventListener("copy", this.onCopy)
    document.addEventListener("paste", this.onPaste)
    document.addEventListener("contextmenu", this.onContextMenu)
    document.addEventListener("keydown", this.onKey)

    this.render()
  }

  disconnect() {
    window.removeEventListener("blur", this.onBlur)
    window.removeEventListener("focus", this.onFocus)
    document.removeEventListener("visibilitychange", this.onVisibility)
    document.removeEventListener("copy", this.onCopy)
    document.removeEventListener("paste", this.onPaste)
    document.removeEventListener("contextmenu", this.onContextMenu)
    document.removeEventListener("keydown", this.onKey)
  }

  get active() {
    return this.onValue
  }

  // The guard only lifts on the learner's own say-so, so a tab-switch costs
  // them a deliberate click back into the exercise.
  resume() {
    this.element.dataset.proctorHidden = "false"
  }

  intercept(event, kind, guard = false) {
    if (!this.active) return
    event.preventDefault()
    this.flag(kind, guard)
  }

  flag(kind, guard = false) {
    if (!this.active) return

    const entry = this.eventsValue[kind]
    if (!entry) return

    if (guard) {
      this.element.dataset.proctorHidden = "true"
      this.element.dataset.proctorReason = kind
    }

    this.scoreValue = Math.max(0, this.scoreValue - entry.weight)
    this.events = [{ ...entry, kind, stamp: this.stamp() }, ...this.events].slice(0, this.maxEventsValue)
    this.render()
    this.report(kind)
  }

  report(kind) {
    if (!this.hasUrlValue) return
    const token = document.querySelector("meta[name=csrf-token]")?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ kind, course: this.courseValue, topic: this.topicValue })
    }).catch(() => {
      // Offline, or the request was blocked. The sidebar row is already drawn.
    })
  }

  stamp() {
    return new Date().toTimeString().slice(0, 8)
  }

  band() {
    const bands = this.bandsValue
    return Object.keys(bands).find((name) => this.scoreValue >= bands[name]) || "risk"
  }

  render() {
    const copy = this.copyValue
    this.element.dataset.proctor = this.onValue ? "on" : "off"

    this.scoreTarget.textContent = this.scoreValue
    this.meterTarget.style.width = `${this.scoreValue}%`

    const band = this.band()
    this.verdictTarget.textContent = copy[`verdict_${band}`]
    this.element.dataset.band = band

    this.renderLog()
  }

  renderLog() {
    if (!this.hasLogTarget) return

    this.emptyTarget.hidden = this.events.length > 0
    this.logTarget.replaceChildren(
      ...this.events.map((event) => {
        const row = this.rowTarget.content.firstElementChild.cloneNode(true)
        row.dataset.weight = event.weight >= 15 ? "high" : event.weight >= 8 ? "medium" : "low"
        row.querySelector("[data-slot=text]").textContent = event.text
        row.querySelector("[data-slot=meta]").textContent = `${event.stamp} · −${event.weight}`
        return row
      })
    )
  }
}
