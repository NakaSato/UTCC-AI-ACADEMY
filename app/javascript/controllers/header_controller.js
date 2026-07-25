import { Controller } from "@hotwired/stimulus"

// Owns the marketing header: the scrolled state, the mobile drawer, and the
// scroll spy that marks which landing-page section the nav is currently on.
export default class extends Controller {
  static targets = ["drawer", "navLink", "toggle"]
  static classes = ["pinned"]
  static values = { threshold: { type: Number, default: 10 } }

  connect() {
    this.initialOffset = this.element.offsetTop || 0
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    // Run once in case the page is restored already scrolled.
    this.onScroll()
    this.startSpy()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
    this.close()
  }

  onScroll() {
    const pinned = window.scrollY > this.initialOffset + this.thresholdValue
    // The pinned state is several Tailwind utilities, so add/remove rather than
    // toggle — classList.toggle only takes one class.
    this.element.classList[pinned ? "add" : "remove"](...this.pinnedClasses)
  }

  // ---- Scroll spy --------------------------------------------------------
  // Every nav link points at a section on the same page, so the active item is
  // whichever section sits in the band just below the header. Desktop and
  // drawer links share the target name; both light up for the same section.
  startSpy() {
    if (!this.hasNavLinkTarget || !("IntersectionObserver" in window)) return

    this.spied = this.navLinkTargets
      .map((link) => ({ link, section: document.getElementById(link.getAttribute("href")?.slice(1)) }))
      .filter(({ section }) => section)
    if (!this.spied.length) return

    this.visible = new Set()
    this.observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          entry.isIntersecting ? this.visible.add(entry.target) : this.visible.delete(entry.target)
        }
        this.highlight()
      },
      // A band from just under the header down to 30% of the viewport. Above
      // the first section — on the hero — nothing intersects and no item is
      // marked, which is the honest answer.
      { rootMargin: "-80px 0px -70% 0px", threshold: 0 }
    )

    for (const section of new Set(this.spied.map((entry) => entry.section))) {
      this.observer.observe(section)
    }
  }

  highlight() {
    let current = null
    for (const { section } of this.spied) {
      if (this.visible.has(section) && (!current || section.offsetTop < current.offsetTop)) current = section
    }

    for (const { link, section } of this.spied) {
      const active = section === current
      link.dataset.active = active ? "true" : "false"
      active ? link.setAttribute("aria-current", "location") : link.removeAttribute("aria-current")
    }
  }

  // ---- Drawer ------------------------------------------------------------
  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.hasDrawerTarget) return
    this.drawerTarget.dataset.open = "true"
    document.body.style.overflow = "hidden"
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true")
    this.drawerTarget.querySelector("a, button")?.focus()
  }

  close() {
    if (!this.hasDrawerTarget) return
    this.drawerTarget.dataset.open = "false"
    document.body.style.overflow = ""
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  get isOpen() {
    return this.hasDrawerTarget && this.drawerTarget.dataset.open === "true"
  }
}
