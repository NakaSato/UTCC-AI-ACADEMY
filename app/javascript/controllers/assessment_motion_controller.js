import { Controller } from "@hotwired/stimulus"

// Decoration for results that arrive without a navigation. Quiz and code-task
// controllers continue to own server grading and semantic status; they only
// dispatch the result element after rendering it. That keeps movement unable
// to delay, replace or reinterpret the answer.
export default class extends Controller {
  connect() {
    this.animations = new Map()
    this.selectionAnimation = null
  }

  disconnect() {
    this.animations.forEach((animation) => animation.cancel())
    this.animations.clear()
    this.cancelSelectionAnimation()
  }

  show(event) {
    const target = event.detail.target
    if (!(target instanceof Element)) return

    this.cancel(target)
    if (this.reducedMotion || typeof target.animate !== "function") return

    const animation = target.animate([
      { opacity: 0.45, transform: "translateY(6px) scale(0.99)" },
      { opacity: 1, transform: "translateY(0) scale(1)" }
    ], {
      duration: 240,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.remember(target, animation)
  }

  showStart(event) {
    const target = event.detail.target
    if (!(target instanceof Element)) return

    this.cancel(target)
    if (this.reducedMotion || typeof target.animate !== "function") return

    const animation = target.animate([
      { opacity: 0.72, transform: "translateX(-4px)" },
      { opacity: 1, transform: "translateX(0)" }
    ], {
      duration: 160,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.remember(target, animation)
  }

  showRows(event) {
    const targets = Array.from(event.detail.targets || []).filter((target) => target instanceof Element)
    targets.forEach((target) => this.cancel(target))
    if (this.reducedMotion) return

    targets.forEach((target, index) => {
      if (typeof target.animate !== "function") return

      const animation = target.animate([
        { opacity: 0.5, transform: "translateX(-6px)" },
        { opacity: 1, transform: "translateX(0)" }
      ], {
        duration: 260,
        delay: Math.min(index * 45, 135),
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
      })

      this.remember(target, animation)
    })
  }

  // The radio state is already applied when this small marker confirmation
  // runs. Only the latest selection moves; picking the current option does not
  // dispatch another event from the quiz controller.
  showSelection(event) {
    this.cancelSelectionAnimation()

    const target = event.detail.target
    if (!(target instanceof Element) || this.reducedMotion ||
        typeof target.animate !== "function") return

    const animation = target.animate([
      { transform: "scale(0.86)" },
      { transform: "scale(1.12)", offset: 0.58 },
      { transform: "scale(1)" }
    ], {
      duration: 200,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.selectionAnimation = animation
    animation.addEventListener("finish", () => {
      if (this.selectionAnimation !== animation) return

      this.selectionAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelSelectionAnimation() {
    this.selectionAnimation?.cancel()
    this.selectionAnimation = null
  }

  // Passing state makes the continuation link visible first. Movement is only
  // acknowledgement and cannot delay or replace the available navigation.
  showAction(event) {
    const target = event.detail.target
    if (!(target instanceof Element)) return

    this.cancel(target)
    if (this.reducedMotion || typeof target.animate !== "function") return

    const animation = target.animate([
      { opacity: 0.55, transform: "translateY(5px) scale(0.98)" },
      { opacity: 1, transform: "translateY(0) scale(1)" }
    ], {
      duration: 220,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })

    this.remember(target, animation)
  }

  remember(target, animation) {
    this.animations.set(target, animation)
    animation.addEventListener("finish", () => {
      if (this.animations.get(target) !== animation) return

      this.animations.delete(target)
      animation.cancel()
    }, { once: true })
  }

  clear(event) {
    const target = event.detail.target
    if (target instanceof Element) this.cancel(target)
  }

  clearRows(event) {
    Array.from(event.detail.targets || []).forEach((target) => {
      if (target instanceof Element) this.cancel(target)
    })
  }

  clearAction(event) {
    const target = event.detail.target
    if (target instanceof Element) this.cancel(target)
  }

  cancel(target) {
    this.animations.get(target)?.cancel()
    this.animations.delete(target)
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
