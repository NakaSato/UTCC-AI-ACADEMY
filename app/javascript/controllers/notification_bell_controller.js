import { Controller } from "@hotwired/stimulus"

// Gives a newly unread notification one restrained piece of movement. The
// newest unread id is remembered for this browser tab, so ordinary Turbo visits
// do not make the same bell ring again; a later notification carries a new key
// and gets one turn of its own.
export default class extends Controller {
  static targets = ["icon"]
  static values = { unread: Boolean, key: String }

  connect() {
    if (!this.unreadValue || this.reducedMotion || !this.firstAppearance) return

    this.frame = requestAnimationFrame(() => this.ring())
  }

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame)
    this.animation?.cancel()
  }

  ring() {
    if (!this.iconTarget.isConnected || typeof this.iconTarget.animate !== "function") return

    this.animation = this.iconTarget.animate([
      { transform: "rotate(0deg)", transformOrigin: "top center" },
      { transform: "rotate(-13deg)", transformOrigin: "top center", offset: 0.18 },
      { transform: "rotate(11deg)", transformOrigin: "top center", offset: 0.36 },
      { transform: "rotate(-7deg)", transformOrigin: "top center", offset: 0.54 },
      { transform: "rotate(4deg)", transformOrigin: "top center", offset: 0.72 },
      { transform: "rotate(0deg)", transformOrigin: "top center" }
    ], {
      duration: 620,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)"
    })
  }

  get firstAppearance() {
    const key = `notification-bell:${this.keyValue || "older-unread"}`

    try {
      if (sessionStorage.getItem(key)) return false

      sessionStorage.setItem(key, "seen")
    } catch {
      // Storage can be unavailable in a hardened browser. Movement is optional,
      // so let the bell ring once rather than making the controller fail.
    }

    return true
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
