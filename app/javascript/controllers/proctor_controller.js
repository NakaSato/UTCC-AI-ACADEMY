import { Controller } from "@hotwired/stimulus"

// Lesson proctoring. Watches for the handful of things the design treats as
// integrity incidents during the exercise and coding task — leaving the window,
// copying the question, pasting a wall of text, the context menu, print, screen
// capture — logs each one and docks the integrity score. Theory and summary are
// reading steps, so the controller remains connected there but inactive.
//
// The sidebar starts with its kept topic events and derived score, and each new
// incident is reported to the same record the admin Integrity tab reads.
// Reporting is fire-and-forget: the log has already drawn the row, and a
// dropped report must not redraw it.
//
// Visual state travels on data attributes read by Tailwind variants, so this
// controller only ever sets an attribute; it never juggles class lists.
export default class extends Controller {
  static targets = ["score", "verdict", "meter", "log", "empty", "row", "guard", "guardDialog"]
  static values = {
    url: String,
    course: String,
    topic: String,
    on: { type: Boolean, default: true },
    score: { type: Number, default: 100 },
    pasteLimit: { type: Number, default: 120 },
    maxEvents: { type: Number, default: 6 },
    activeSteps: Array,
    initialEvents: Array,
    bands: Object,   // { clean: 85, review: 60, risk: 0 }
    events: Object,  // kind -> { weight, text }
    copy: Object     // the verdict and guard sentences
  }

  connect() {
    this.events = [...this.initialEventsValue]
    this.scoreAnimation = null
    this.meterAnimation = null
    this.verdictAnimation = null
    this.logAnimation = null
    this.guardAnimations = null
    this.onBlur = () => this.flag("blur", true)
    this.onFocus = () => this.hideGuard()
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
    this.cancelScoreAnimation()
    this.cancelMeterAnimation()
    this.cancelVerdictAnimation()
    this.cancelLogAnimation()
    this.cancelGuardAnimations()
  }

  get active() {
    return this.onValue && this.activeStepsValue.includes(this.element.dataset.panel)
  }

  resume() {
    this.dismissGuard()
  }

  hideGuard() {
    this.cancelGuardAnimations()
    this.element.dataset.proctorHidden = "false"
  }

  dismissGuard() {
    if (this.element.dataset.proctorHidden !== "true") return this.hideGuard()

    this.cancelGuardAnimations()
    if (this.reducedMotion || !this.hasGuardTarget || !this.hasGuardDialogTarget ||
        typeof this.guardTarget.animate !== "function" ||
        typeof this.guardDialogTarget.animate !== "function") return this.hideGuard()

    this.guardTarget.inert = true
    this.guardTarget.setAttribute("aria-hidden", "true")
    const animations = [
      this.guardTarget.animate([
        { opacity: 1 },
        { opacity: 0 }
      ], {
        duration: 150,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
      }),
      this.guardDialogTarget.animate([
        { opacity: 1, transform: "translateY(0) scale(1)" },
        { opacity: 0, transform: "translateY(-4px) scale(0.99)" }
      ], {
        duration: 170,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
      })
    ]

    this.guardAnimations = animations
    let finished = 0
    animations.forEach((animation) => {
      animation.addEventListener("finish", () => {
        if (this.guardAnimations !== animations) return

        finished += 1
        if (finished !== animations.length) return

        this.guardAnimations = null
        animations.forEach((finishedAnimation) => finishedAnimation.cancel())
        this.guardTarget.removeAttribute("aria-hidden")
        this.guardTarget.inert = false
        this.element.dataset.proctorHidden = "false"
      }, { once: true })
    })
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

    const guardJustOpened = guard && this.element.dataset.proctorHidden !== "true"
    if (guard) {
      this.element.dataset.proctorHidden = "true"
      this.element.dataset.proctorReason = kind
    }

    const previousBand = this.band()
    this.scoreValue = Math.max(0, this.scoreValue - entry.weight)
    this.events = [{ ...entry, kind, stamp: this.stamp() }, ...this.events].slice(0, this.maxEventsValue)
    this.render({ animateMeter: true, animateLog: true })
    this.animateScore()
    this.animateVerdict(previousBand)
    if (guardJustOpened) this.animateGuard()
    this.report(kind)
  }

  // The new score and integrity band are already visible before this cue runs.
  // It acknowledges a local incident only; initial and restored scores stay
  // still because connect calls render without calling this method.
  animateScore() {
    this.cancelScoreAnimation()
    if (this.reducedMotion || typeof this.scoreTarget.animate !== "function") return

    const animation = this.scoreTarget.animate([
      { opacity: 0.55, transform: "translateY(-2px) scale(1.12)" },
      { opacity: 1, transform: "translateY(0) scale(1)" }
    ], {
      duration: 240,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.scoreAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.scoreAnimation !== animation) return

      this.scoreAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelScoreAnimation() {
    this.scoreAnimation?.cancel()
    this.scoreAnimation = null
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  // Measure before cancelling so a rapid second incident continues from the
  // width currently on screen rather than jumping to the older destination.
  // The destination is committed underneath before decoration begins.
  animateMeter(percent) {
    const trackWidth = this.meterTarget.parentElement?.getBoundingClientRect().width
    const visibleWidth = this.meterTarget.getBoundingClientRect().width
    const inlinePercent = Number.parseFloat(this.meterTarget.style.width)
    const interrupted = this.meterAnimation && this.meterAnimation.playState !== "finished"
    const visiblePercent = interrupted && trackWidth > 0
      ? (visibleWidth / trackWidth) * 100
      : inlinePercent
    const fromPercent = Number.isFinite(visiblePercent)
      ? Number(visiblePercent.toFixed(3))
      : percent

    this.cancelMeterAnimation()
    this.meterTarget.style.width = `${percent}%`

    if (this.reducedMotion || typeof this.meterTarget.animate !== "function" ||
        fromPercent === percent) return

    const animation = this.meterTarget.animate([
      { width: `${fromPercent}%` },
      { width: `${percent}%` }
    ], {
      duration: 300,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.meterAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.meterAnimation !== animation) return

      this.meterAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelMeterAnimation() {
    this.meterAnimation?.cancel()
    this.meterAnimation = null
  }

  // The translated verdict and band color are already applied by render.
  // Deductions inside the same band stay still so routine incidents do not
  // repeatedly compete for attention.
  animateVerdict(previousBand) {
    const currentBand = this.band()
    if (previousBand === currentBand) return

    this.cancelVerdictAnimation()
    if (this.reducedMotion || typeof this.verdictTarget.animate !== "function") return

    const animation = this.verdictTarget.animate([
      { opacity: 0.45, transform: "translateY(3px)" },
      { opacity: 1, transform: "translateY(0)" }
    ], {
      duration: 220,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.verdictAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.verdictAnimation !== animation) return

      this.verdictAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelVerdictAnimation() {
    this.verdictAnimation?.cancel()
    this.verdictAnimation = null
  }

  // The log is rebuilt from local state before the newest row moves. Existing
  // and restored rows stay still instead of replaying whenever another event
  // arrives.
  animateLogRow(row) {
    this.cancelLogAnimation()
    if (!(row instanceof Element) || this.reducedMotion || typeof row.animate !== "function") return

    const animation = row.animate([
      { opacity: 0.45, transform: "translateX(-6px)" },
      { opacity: 1, transform: "translateX(0)" }
    ], {
      duration: 260,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.logAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.logAnimation !== animation) return

      this.logAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelLogAnimation() {
    this.logAnimation?.cancel()
    this.logAnimation = null
  }

  // The guard is already visible and blocks the lesson before its two layers
  // settle. A second guarded incident while it is open does not replay the cue.
  animateGuard() {
    this.cancelGuardAnimations()
    if (this.reducedMotion || !this.hasGuardTarget || !this.hasGuardDialogTarget ||
        typeof this.guardTarget.animate !== "function" ||
        typeof this.guardDialogTarget.animate !== "function") return

    const animations = [
      this.guardTarget.animate([
        { opacity: 0 },
        { opacity: 1 }
      ], {
        duration: 180,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
      }),
      this.guardDialogTarget.animate([
        { opacity: 0.45, transform: "translateY(8px) scale(0.98)" },
        { opacity: 1, transform: "translateY(0) scale(1)" }
      ], {
        duration: 260,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
      })
    ]

    this.guardAnimations = animations
    let finished = 0
    animations.forEach((animation) => {
      animation.addEventListener("finish", () => {
        if (this.guardAnimations !== animations) return

        finished += 1
        if (finished !== animations.length) return

        this.guardAnimations = null
        animations.forEach((finishedAnimation) => finishedAnimation.cancel())
      }, { once: true })
    })
  }

  cancelGuardAnimations() {
    this.guardAnimations?.forEach((animation) => animation.cancel())
    this.guardAnimations = null
  }

  report(kind) {
    if (!this.hasUrlValue) return
    const token = document.querySelector("meta[name=csrf-token]")?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({
        kind,
        course: this.courseValue,
        topic: this.topicValue,
        step: this.element.dataset.panel
      })
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

  render({ animateMeter = false, animateLog = false } = {}) {
    const copy = this.copyValue
    this.element.dataset.proctor = this.onValue ? "on" : "off"

    this.scoreTarget.textContent = this.scoreValue
    if (animateMeter) this.animateMeter(this.scoreValue)
    else this.meterTarget.style.width = `${this.scoreValue}%`

    const band = this.band()
    this.verdictTarget.textContent = copy[`verdict_${band}`]
    this.element.dataset.band = band

    this.renderLog({ animateNewest: animateLog })
  }

  renderLog({ animateNewest = false } = {}) {
    if (!this.hasLogTarget) return

    this.cancelLogAnimation()
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

    if (animateNewest) this.animateLogRow(this.logTarget.firstElementChild)
  }
}
