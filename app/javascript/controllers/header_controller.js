import { Controller } from "@hotwired/stimulus"

// Pins the header once the page scrolls past its resting offset, mirroring the
// reference site's inline script. Also owns the mobile drawer.
export default class extends Controller {
  static targets = ["drawer"]
  static classes = ["pinned"]
  static values = { threshold: { type: Number, default: 10 } }

  connect() {
    this.initialOffset = this.element.offsetTop || 0
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    // Run once in case the page is restored already scrolled.
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    this.close()
  }

  onScroll() {
    const pinned = window.scrollY > this.initialOffset + this.thresholdValue
    // The pinned state is several Tailwind utilities, so add/remove rather than
    // toggle — classList.toggle only takes one class.
    this.element.classList[pinned ? "add" : "remove"](...this.pinnedClasses)
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.hasDrawerTarget) return
    this.drawerTarget.dataset.open = "true"
    document.body.style.overflow = "hidden"
    this.drawerTarget.querySelector("a, button")?.focus()
  }

  close() {
    if (!this.hasDrawerTarget) return
    this.drawerTarget.dataset.open = "false"
    document.body.style.overflow = ""
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  get isOpen() {
    return this.hasDrawerTarget && this.drawerTarget.dataset.open === "true"
  }
}
