import { Controller } from "@hotwired/stimulus"

// Reveals the scroll-up button after the first viewport.
export default class extends Controller {
  static values = { after: { type: Number, default: 400 } }

  connect() {
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    this.element.dataset.visible = String(window.scrollY > this.afterValue)
  }

  scrollUp() {
    window.scrollTo({ top: 0, behavior: "smooth" })
  }
}
