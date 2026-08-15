import { Controller } from "@hotwired/stimulus"

// Owns the marketing header: the scrolled state, the mobile drawer, and the
// scroll spy that marks which landing-page section the nav is currently on.
export default class extends Controller {
  static targets = ["drawer", "drawerBackdrop", "drawerPanel", "navLink", "toggle"]
  static classes = ["pinned"]
  static values = { threshold: { type: Number, default: 10 } }

  connect() {
    this.pinAnimation = null
    this.navAnimations = []
    this.initialOffset = this.element.offsetTop || 0
    this.onScroll = this.onScroll.bind(this)
    this.pinned = window.scrollY > this.initialOffset + this.thresholdValue
    this.commitPinned(this.pinned)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.startSpy()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
    this.cancelPinAnimation()
    this.cancelNavAnimations()
    this.cancelDrawerAnimations()
    this.finishClose()
  }

  onScroll() {
    const pinned = window.scrollY > this.initialOffset + this.thresholdValue
    if (pinned === this.pinned) return

    this.pinned = pinned
    this.animatePinned()
  }

  animatePinned() {
    const currentShadow = getComputedStyle(this.element).boxShadow
    this.cancelPinAnimation()
    this.commitPinned(this.pinned)
    const destinationShadow = getComputedStyle(this.element).boxShadow

    if (this.reducedMotion || typeof this.element.animate !== "function") return

    const animation = this.element.animate([
      { boxShadow: currentShadow },
      { boxShadow: destinationShadow }
    ], {
      duration: this.pinned ? 200 : 150,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.pinAnimation = animation

    animation.addEventListener("finish", () => {
      if (this.pinAnimation !== animation) return

      this.pinAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelPinAnimation() {
    if (!this.pinAnimation) return

    const animation = this.pinAnimation
    this.pinAnimation = null
    animation.cancel()
  }

  commitPinned(pinned) {
    // The pinned state can be several Tailwind utilities, so add/remove rather
    // than toggle — classList.toggle only accepts one class per call.
    this.element.classList[pinned ? "add" : "remove"](...this.pinnedClasses)
    this.element.dataset.pinned = String(pinned)
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
    this.currentSection = null
    this.spyInitialized = false
    this.observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          entry.isIntersecting ? this.visible.add(entry.target) : this.visible.delete(entry.target)
        }
        this.highlight({ animate: this.spyInitialized })
        this.spyInitialized = true
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

  highlight({ animate = true } = {}) {
    let current = null
    for (const { section } of this.spied) {
      if (this.visible.has(section) && (!current || section.offsetTop < current.offsetTop)) current = section
    }

    const changed = current !== this.currentSection
    this.currentSection = current

    for (const { link, section } of this.spied) {
      const active = section === current
      link.dataset.active = active ? "true" : "false"
      active ? link.setAttribute("aria-current", "location") : link.removeAttribute("aria-current")
    }

    if (!changed) return

    this.cancelNavAnimations()
    if (animate && current) this.animateNavLinks(current)
  }

  animateNavLinks(section) {
    if (this.reducedMotion) return

    const animations = this.spied
      .filter(({ link, section: linkedSection }) => linkedSection === section && link.getClientRects().length)
      .map(({ link }) => link.animate([
        { opacity: 0.68, transform: "translateY(2px) scale(0.985)" },
        { opacity: 1, transform: "none" }
      ], {
        duration: 180,
        easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
        fill: "both"
      }))

    if (!animations.length) return

    this.navAnimations = animations
    Promise.allSettled(animations.map((animation) => animation.finished)).then(() => {
      if (this.navAnimations !== animations) return

      this.navAnimations = []
      animations.forEach((animation) => animation.cancel())
    })
  }

  cancelNavAnimations() {
    this.navAnimations?.forEach((animation) => animation.cancel())
    this.navAnimations = []
  }

  // ---- Drawer ------------------------------------------------------------
  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.hasDrawerTarget) return

    if (this.isOpen) return

    const interruptedClose = this.drawerTarget.dataset.state === "closing" && !this.drawerTarget.hidden
    const start = interruptedClose ? this.currentDrawerPosition() : {
      backdropOpacity: 0,
      panelTransform: "translateX(100%)"
    }

    this.cancelDrawerAnimations()
    this.drawerTarget.hidden = false
    this.drawerTarget.dataset.open = "true"
    this.drawerTarget.dataset.state = "open"
    this.lockScroll()
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true")

    this.playDrawerAnimations({
      backdropKeyframes: [{ opacity: start.backdropOpacity }, { opacity: 1 }],
      backdropDuration: 180,
      panelKeyframes: [{ transform: start.panelTransform }, { transform: "none" }],
      panelDuration: 240
    })

    this.drawerTarget.querySelector("a, button")?.focus()
  }

  close() {
    if (!this.hasDrawerTarget) return

    if (this.drawerTarget.hidden || this.drawerTarget.dataset.state === "closed") {
      this.finishClose()
      return
    }
    if (this.drawerTarget.dataset.state === "closing") return

    const start = this.currentDrawerPosition()

    this.cancelDrawerAnimations()
    this.drawerTarget.dataset.state = "closing"
    this.unlockScroll()
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")

    this.playDrawerAnimations({
      backdropKeyframes: [{ opacity: start.backdropOpacity }, { opacity: 0 }],
      backdropDuration: 140,
      panelKeyframes: [{ transform: start.panelTransform }, { transform: "translateX(100%)" }],
      panelDuration: 180,
      after: () => this.finishClose()
    })
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  get isOpen() {
    return this.hasDrawerTarget && this.drawerTarget.dataset.state === "open"
  }

  currentDrawerPosition() {
    return {
      backdropOpacity: Number.parseFloat(getComputedStyle(this.drawerBackdropTarget).opacity),
      panelTransform: getComputedStyle(this.drawerPanelTarget).transform
    }
  }

  playDrawerAnimations({
    backdropKeyframes,
    backdropDuration,
    panelKeyframes,
    panelDuration,
    after
  }) {
    if (this.reducedMotion || !this.canAnimateDrawer) {
      after?.()
      return
    }

    const options = { easing: "cubic-bezier(0.22, 0.9, 0.3, 1)", fill: "both" }
    const animations = [
      this.drawerBackdropTarget.animate(backdropKeyframes, { ...options, duration: backdropDuration }),
      this.drawerPanelTarget.animate(panelKeyframes, { ...options, duration: panelDuration })
    ]
    this.drawerAnimations = animations

    Promise.allSettled(animations.map((animation) => animation.finished)).then(() => {
      if (this.drawerAnimations !== animations) return

      this.drawerAnimations = null
      after?.()
      animations.forEach((animation) => animation.cancel())
    })
  }

  cancelDrawerAnimations() {
    this.drawerAnimations?.forEach((animation) => animation.cancel())
    this.drawerAnimations = null
  }

  finishClose() {
    if (!this.hasDrawerTarget) return

    this.drawerTarget.hidden = true
    this.drawerTarget.dataset.open = "false"
    this.drawerTarget.dataset.state = "closed"
    this.unlockScroll()
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  lockScroll() {
    if (this.scrollLocked) return

    this.previousBodyOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
    this.scrollLocked = true
  }

  unlockScroll() {
    if (!this.scrollLocked) return

    document.body.style.overflow = this.previousBodyOverflow || ""
    this.scrollLocked = false
  }

  get canAnimateDrawer() {
    return this.hasDrawerBackdropTarget && this.hasDrawerPanelTarget &&
      typeof this.drawerBackdropTarget.animate === "function" &&
      typeof this.drawerPanelTarget.animate === "function"
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
