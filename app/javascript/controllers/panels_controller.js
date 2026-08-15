import { Controller } from "@hotwired/stimulus"

// Tabs whose panels are all already in the document, so switching is a
// show/hide rather than a navigation. Everything past the show/hide is opt-in,
// read off the tab or the panel:
//
//   tab   data-panel    which panel this tab shows (required)
//         data-path     URL to keep in the address bar
//         data-title    document title to go with it
//         data-percent  width for the `progress` target
//         data-index    ordered steps: tabs also get data-state=done|current|todo
//   panel data-panel    which tab shows it (required)
//         data-focus    focus its first field once shown
//         data-motion   move it in from the direction of travel once shown
//   summary elements opt into final-step motion with the `summaryMark`,
//         `summaryReward`, and `summaryAction` targets
//
// Anything else can trigger a switch by carrying `data-panel` and the action —
// an in-panel "next step" button, say. The tab named by that panel stays the
// source of truth for the rest, so only the tab spells out path and title.
//
// The controller element carries `data-panel` too, so the rest of the subtree
// can react in CSS alone with `group-data-[panel=…]:`.
export default class extends Controller {
  static targets = [
    "tab", "panel", "progress", "replay", "stepIndicator", "stepLabel",
    "summaryMark", "summaryReward", "summaryAction"
  ]

  disconnect() {
    this.panelAnimation?.cancel()
    this.panelAnimation = null
    this.progressAnimation?.cancel()
    this.progressAnimation = null
    this.cancelStepIndicatorAnimation()
    this.cancelStepLabelAnimation()
    this.cancelTabSelectionAnimation()
    this.cancelSummaryMarkAnimation()
    this.cancelSummaryRewardAnimations()
    this.cancelSummaryActionAnimations()
  }

  // Triggers are sometimes real links, so the page still works without JS.
  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.dataset.panel)
  }

  show(name) {
    const changed = name !== this.element.dataset.panel
    const tab = this.tabTargets.find((tab) => tab.dataset.panel === name)
    const index = Number(tab?.dataset.index)
    const previousTab = this.tabTargets.find(
      (candidate) => candidate.dataset.panel === this.element.dataset.panel
    )
    const previousIndex = Number(previousTab?.dataset.index)
    const direction = Number.isFinite(index) && Number.isFinite(previousIndex)
      ? Math.sign(index - previousIndex)
      : 0

    this.element.dataset.panel = name

    this.tabTargets.forEach((other) => {
      const selected = other.dataset.panel === name
      other.setAttribute("aria-selected", String(selected))

      if ("index" in other.dataset) {
        other.dataset.state =
          selected ? "current" : Number(other.dataset.index) < index ? "done" : "todo"
      }
    })

    this.animateTabSelection(tab, changed)
    this.animateStepIndicator(tab, direction)

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panel !== name

      if (!panel.hidden) {
        if ("motion" in panel.dataset) this.animatePanel(panel, direction)
        if ("focus" in panel.dataset) panel.querySelector("input:not([type=hidden])")?.focus()
      }
    })

    this.animateStepLabel(name, direction)

    this.animateSummaryMark(name, direction)
    this.animateSummaryRewards(name, direction)
    this.animateSummaryActions(name, direction)

    if (tab?.dataset.path) history.replaceState(history.state, "", tab.dataset.path)
    if (tab?.dataset.title) document.title = tab.dataset.title

    if (this.hasProgressTarget && tab?.dataset.percent) {
      this.animateProgress(Number(tab.dataset.percent), direction)
    }

    this.replay()
  }

  // Compact auth panels stay still, but their selected tab can opt into one
  // small confirmation after aria-selected, focus, URL, and title state change.
  animateTabSelection(tab, changed) {
    this.cancelTabSelectionAnimation()

    if (!changed || !tab || !("tabMotion" in tab.dataset) || this.reducedMotion() ||
        typeof tab.animate !== "function") return

    const animation = tab.animate([
      { opacity: 0.72, transform: "translateY(1px) scale(0.96)" },
      { opacity: 1, transform: "translateY(0) scale(1.03)", offset: 0.64 },
      { opacity: 1, transform: "none" }
    ], {
      duration: 200,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })
    this.tabSelectionAnimation = animation

    animation.addEventListener("finish", () => {
      if (this.tabSelectionAnimation === animation) this.tabSelectionAnimation = null
    }, { once: true })
  }

  cancelTabSelectionAnimation() {
    this.tabSelectionAnimation?.cancel()
    this.tabSelectionAnimation = null
  }

  // Only explicit content panels move. `panels` also drives compact auth and
  // progress tabs, where horizontal movement would be noise. Web Animations
  // needs its own reduced-motion check because the CSS duration clamp cannot
  // reach animations created in JavaScript.
  animatePanel(panel, direction) {
    this.panelAnimation?.cancel()
    this.panelAnimation = null

    if (direction === 0 || this.reducedMotion() || typeof panel.animate !== "function") return

    const offset = direction < 0 ? -12 : 12
    const animation = panel.animate(
      [
        { opacity: 0, transform: `translateX(${offset}px)` },
        { opacity: 1, transform: "translateX(0)" }
      ],
      { duration: 220, easing: "cubic-bezier(0.22, 0.9, 0.3, 1)" }
    )

    this.panelAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.panelAnimation === animation) this.panelAnimation = null
    }, { once: true })
  }

  // Measure before cancelling so an interrupted selection continues from the
  // bar's visible position rather than jumping to the older destination.
  animateProgress(percent, direction) {
    if (!Number.isFinite(percent)) return

    const trackWidth = this.progressTarget.parentElement?.getBoundingClientRect().width
    const visibleWidth = this.progressTarget.getBoundingClientRect().width
    const inlinePercent = Number.parseFloat(this.progressTarget.style.width)
    const visiblePercent = this.progressAnimation && trackWidth > 0
      ? (visibleWidth / trackWidth) * 100
      : inlinePercent
    const fromPercent = Number(visiblePercent.toFixed(3))

    this.progressAnimation?.cancel()
    this.progressAnimation = null
    this.progressTarget.style.width = `${percent}%`

    if (direction === 0 || this.reducedMotion() ||
        typeof this.progressTarget.animate !== "function" || fromPercent === percent) return

    const animation = this.progressTarget.animate(
      [
        { width: `${fromPercent}%` },
        { width: `${percent}%` }
      ],
      { duration: 300, easing: "cubic-bezier(0.22, 0.9, 0.3, 1)" }
    )

    this.progressAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.progressAnimation === animation) this.progressAnimation = null
    }, { once: true })
  }

  // State changes before decoration: the selected circle already has its
  // current-step color and accessible tab state when this confirmation runs.
  animateStepIndicator(tab, direction) {
    this.cancelStepIndicatorAnimation()

    const indicator = tab?.querySelector("[data-panels-target~='stepIndicator']")
    if (!indicator || direction === 0 || this.reducedMotion() ||
        typeof indicator.animate !== "function") return

    const animation = indicator.animate(
      [
        { transform: "scale(0.84)" },
        { transform: "scale(1.1)", offset: 0.62 },
        { transform: "scale(1)" }
      ],
      { duration: 240, easing: "cubic-bezier(0.22, 0.9, 0.3, 1)" }
    )

    this.stepIndicatorAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.stepIndicatorAnimation === animation) this.stepIndicatorAnimation = null
    }, { once: true })
  }

  cancelStepIndicatorAnimation() {
    this.stepIndicatorAnimation?.cancel()
    this.stepIndicatorAnimation = null
  }

  // Labels are panel targets too, so their hidden state is already correct.
  // This small vertical offset echoes direction without competing with content.
  animateStepLabel(name, direction) {
    this.cancelStepLabelAnimation()

    const label = this.stepLabelTargets.find((candidate) => candidate.dataset.panel === name)
    if (!label || direction === 0 || this.reducedMotion() ||
        typeof label.animate !== "function") return

    const offset = direction < 0 ? -4 : 4
    const animation = label.animate(
      [
        { opacity: 0.45, transform: `translateY(${offset}px)` },
        { opacity: 1, transform: "translateY(0)" }
      ],
      { duration: 180, easing: "cubic-bezier(0.22, 0.9, 0.3, 1)" }
    )

    this.stepLabelAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.stepLabelAnimation === animation) this.stepLabelAnimation = null
    }, { once: true })
  }

  cancelStepLabelAnimation() {
    this.stepLabelAnimation?.cancel()
    this.stepLabelAnimation = null
  }

  // The mark confirms arrival without changing or delaying completion state.
  // It starts alongside the reward-card sequence, then settles once.
  animateSummaryMark(name, direction) {
    this.cancelSummaryMarkAnimation()

    if (name !== "summary" || direction === 0 || this.reducedMotion() ||
        !this.hasSummaryMarkTarget || typeof this.summaryMarkTarget.animate !== "function") return

    const animation = this.summaryMarkTarget.animate(
      [
        { opacity: 0.55, transform: "scale(0.78) rotate(-5deg)" },
        { opacity: 1, transform: "scale(1.08) rotate(0deg)", offset: 0.68 },
        { opacity: 1, transform: "scale(1) rotate(0deg)" }
      ],
      {
        duration: 360,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
        fill: "backwards"
      }
    )

    this.summaryMarkAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.summaryMarkAnimation === animation) this.summaryMarkAnimation = null
    }, { once: true })
  }

  cancelSummaryMarkAnimation() {
    this.summaryMarkAnimation?.cancel()
    this.summaryMarkAnimation = null
  }

  // Summary is already visible before these decorative animations begin. The
  // delay lives in the animation options so all cards are scheduled together,
  // and a new panel selection can cancel the whole sequence immediately.
  animateSummaryRewards(name, direction) {
    this.cancelSummaryRewardAnimations()

    if (name !== "summary" || direction === 0 || this.reducedMotion()) return

    this.summaryRewardTargets
      .filter((card) => typeof card.animate === "function")
      .forEach((card, index) => {
        const animation = card.animate(
          [
            { opacity: 0.4, transform: "translateY(8px) scale(0.985)" },
            { opacity: 1, transform: "translateY(0) scale(1)" }
          ],
          {
            duration: 280,
            delay: Math.min(index * 45, 135),
            easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
            fill: "backwards"
          }
        )

        this.summaryRewardAnimations.push(animation)
        animation.addEventListener("finish", () => {
          this.summaryRewardAnimations = this.summaryRewardAnimations.filter(
            (candidate) => candidate !== animation
          )
        }, { once: true })
      })
  }

  cancelSummaryRewardAnimations() {
    this.summaryRewardAnimations?.forEach((animation) => animation.cancel())
    this.summaryRewardAnimations = []
  }

  // Actions follow the first completion cues but remain ordinary, immediately
  // usable links throughout the decorative delay and movement.
  animateSummaryActions(name, direction) {
    this.cancelSummaryActionAnimations()

    if (name !== "summary" || direction === 0 || this.reducedMotion()) return

    this.summaryActionTargets
      .filter((action) => typeof action.animate === "function")
      .forEach((action, index) => {
        const animation = action.animate(
          [
            { opacity: 0.55, transform: "translateY(6px)" },
            { opacity: 1, transform: "translateY(0)" }
          ],
          {
            duration: 260,
            delay: 180 + Math.min(index * 40, 40),
            easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
            fill: "backwards"
          }
        )

        this.summaryActionAnimations.push(animation)
        animation.addEventListener("finish", () => {
          this.summaryActionAnimations = this.summaryActionAnimations.filter(
            (candidate) => candidate !== animation
          )
        }, { once: true })
      })
  }

  cancelSummaryActionAnimations() {
    this.summaryActionAnimations?.forEach((animation) => animation.cancel())
    this.summaryActionAnimations = []
  }

  reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  // Rows animate in on load; arriving by tab is the same arrival, so play it
  // again. The reflow between the two writes is what restarts the animation.
  replay() {
    this.replayTargets.forEach((element) => {
      element.dataset.in = "false"
      element.offsetHeight
      element.dataset.in = "true"
    })
  }
}
