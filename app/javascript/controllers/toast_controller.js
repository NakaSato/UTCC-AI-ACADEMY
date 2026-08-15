import { Controller } from "@hotwired/stimulus"

// Shows the transient messages the app raises between page loads. The flash
// partial handles anything that survives a redirect; this handles what does
// not, so nothing here is persisted and a reload clears the lot.
//
// Callers dispatch rather than reach for this controller:
//
//   this.dispatch("show", { prefix: "toast", detail: { message, kind } })
//
// and the server dispatches the same event through the custom Turbo Stream
// action in toast_stream.js. The layout routes `toast:show` to #show, so a new
// caller adds no wiring. The row it clones is a <template> in shared/_toasts,
// which is why no markup lives in here — the full detail a caller may send is
// documented there.
export default class extends Controller {
  static targets = ["list", "row"]
  static values = {
    duration: { type: Number, default: 3000 },
    anchor: { type: String, default: "top" },
    // A burst is the case this exists for: nothing in the app raises four at
    // once on purpose, but the lesson's grading failures can arrive in a
    // flurry, and a stack tall enough to cover the page is worse than the
    // messages are useful.
    limit: { type: Number, default: 3 }
  }

  connect() {
    this.timers = new Set()
    this.animations = new Map()
    // row -> { remaining, startedAt, timer }. A toast being read is a toast
    // whose clock is stopped, so each one keeps its own.
    this.clocks = new Map()
    // Insertion order across both regions, which is the order the limit drops
    // them in — the DOM cannot answer that, since a row's region depends on its
    // kind rather than on when it arrived.
    this.live = []
    this.clearChrome()
  }

  // The host is fixed, and what it has to clear differs by layout: the app
  // header carries the hearts strip inside the same sticky element, the
  // marketing one does not. The partial sets a floor that clears the shorter of
  // the two; this raises it to whatever is actually there, so neither layout
  // has to be told and a change to the strip needs no second edit here.
  //
  // Only a top-anchored stack has anything to clear.
  clearChrome() {
    if (this.anchorValue !== "top") return

    const header = document.querySelector("header")
    if (!header) return

    const { bottom } = header.getBoundingClientRect()
    if (bottom > 0) this.element.style.setProperty("--toast-top", `${Math.round(bottom) + 12}px`)
  }

  show({ detail: { message, kind = "info", title, duration, action } }) {
    if (!message) return

    const toast = this.rowTarget.content.firstElementChild.cloneNode(true)
    toast.dataset.kind = kind
    this.fill(toast, "message", message)
    if (title) this.fill(toast, "title", title)
    if (action?.label && action?.href) this.link(toast, action)

    this.listFor(kind).appendChild(toast)
    this.live.push(toast)
    this.reveal(toast)

    // Oldest first, and only once the new one is in: what a reader loses to a
    // burst should be the message they have already had time to read.
    while (this.live.length > this.limitValue) this.dismiss(this.live[0])

    // An explicit 0 is a toast that stays until it is dismissed — which is why
    // every row carries a close button, not only the ones that need it.
    const life = duration === undefined || duration === null ? this.durationValue : Number(duration)
    if (life > 0) this.start(toast, life)
  }

  // Both from the close button and from anything else that wants a row gone.
  close({ currentTarget }) {
    this.dismiss(currentTarget.closest("[data-kind]"))
  }

  // Reading takes as long as it takes. Pausing on hover and on focus is what
  // keeps a timed message from being a message the reader has to race, and it
  // is the only reason the remaining time is tracked rather than the timer just
  // being restarted.
  hold({ currentTarget }) {
    const clock = this.clocks.get(currentTarget)
    if (!clock || clock.timer === null) return

    clearTimeout(clock.timer)
    this.timers.delete(clock.timer)
    clock.remaining -= Date.now() - clock.startedAt
    clock.timer = null
  }

  release({ currentTarget }) {
    const clock = this.clocks.get(currentTarget)
    if (!clock || clock.timer !== null) return

    this.start(currentTarget, clock.remaining)
  }

  dismiss(toast) {
    if (!toast || toast.dataset.dismissed === "true") return

    toast.dataset.dismissed = "true"
    const clock = this.clocks.get(toast)
    if (clock && clock.timer !== null) {
      clearTimeout(clock.timer)
      this.timers.delete(clock.timer)
    }
    this.clocks.delete(toast)
    // Out of the order now rather than on removal: the row lingers for the
    // length of its movement, and a dismissed row still counted against the
    // limit would drop a second one behind it.
    this.live = this.live.filter(row => row !== toast)
    this.hide(toast)
  }

  reveal(toast) {
    this.play(toast, [
      { opacity: 0, transform: `translateY(${this.entryOffset})` },
      { opacity: 1, transform: "translateY(0)" }
    ], 200)
  }

  // Read before cancelling so a close during entrance continues from the
  // position and opacity the reader can actually see.
  hide(toast) {
    const style = getComputedStyle(toast)
    const opacity = Number.parseFloat(style.opacity)
    const transform = style.transform === "none" ? "translateY(0)" : style.transform

    this.stopAnimation(toast)
    this.play(toast, [
      { opacity: Number.isFinite(opacity) ? opacity : 1, transform },
      { opacity: 0, transform: `translateY(${this.entryOffset})` }
    ], 160, () => toast.remove())
  }

  play(toast, keyframes, duration, after = () => {}) {
    this.stopAnimation(toast)
    if (this.reducedMotion || typeof toast.animate !== "function") {
      after()
      return
    }

    const animation = toast.animate(keyframes, {
      duration,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.animations.set(toast, animation)

    animation.addEventListener("finish", () => {
      if (this.animations.get(toast) !== animation) return

      this.animations.delete(toast)
      after()
      animation.cancel()
    }, { once: true })
  }

  stopAnimation(toast) {
    const animation = this.animations.get(toast)
    if (!animation) return

    this.animations.delete(toast)
    animation.cancel()
  }

  get entryOffset() {
    const offset = getComputedStyle(this.element).getPropertyValue("--toast-enter").trim()
    return offset || (this.anchorValue === "bottom" ? "0.375rem" : "-0.375rem")
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  // Urgency is not a style: a screen reader interrupts for the assertive region
  // and waits for the polite one, and "saved" must never interrupt anything.
  listFor(kind) {
    const urgency = kind === "error" || kind === "warning" ? "assertive" : "polite"

    return this.listTargets.find(list => list.dataset.urgency === urgency) || this.listTargets[0]
  }

  fill(toast, slot, text) {
    const element = toast.querySelector(`[data-slot=${slot}]`)
    element.textContent = text
    element.hidden = false
  }

  link(toast, { label, href, method }) {
    const anchor = toast.querySelector("[data-slot=action]")
    anchor.textContent = label
    anchor.href = href
    // Turbo turns a non-GET link into a real request; a GET is just a link.
    if (method && method.toLowerCase() !== "get") anchor.dataset.turboMethod = method
    // Taking the offer answers the toast, so the toast goes.
    anchor.addEventListener("click", () => this.dismiss(toast), { once: true })
    anchor.hidden = false
  }

  start(toast, remaining) {
    const clock = { remaining, startedAt: Date.now(), timer: null }
    clock.timer = this.schedule(() => this.dismiss(toast), remaining)
    this.clocks.set(toast, clock)
  }

  schedule(callback, delay) {
    const timer = setTimeout(() => {
      this.timers.delete(timer)
      callback()
    }, delay)

    this.timers.add(timer)

    return timer
  }

  // Turbo swaps the body on navigation, so anything still pending would fire
  // against a detached element.
  disconnect() {
    this.timers.forEach(clearTimeout)
    this.timers.clear()
    this.animations.forEach((animation) => animation.cancel())
    this.animations.clear()
    this.clocks.clear()
    this.live = []
  }
}
