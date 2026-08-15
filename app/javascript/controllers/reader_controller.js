import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content", "toc", "fontSize", "surface" ]
  static values = { storageKey: String }

  connect() {
    this.surfaceAnimation = null
    this.tocAnimation = null
    this.selectedTocHref = null
    this.settings = { width: "comfortable", fontSize: "medium", theme: "light" }
    this.restoreSettings()
    this.buildTableOfContents()
    this.applySettings()
  }

  disconnect() {
    this.cancelSurfaceAnimation()
    this.cancelTocAnimation()
  }

  decreaseFont() {
    this.setFontSize({ currentTarget: { value: this.previousFontSize } })
  }

  increaseFont() {
    this.setFontSize({ currentTarget: { value: this.nextFontSize } })
  }

  setFontSize(event) {
    const sizes = [ "small", "medium", "large" ]
    const current = sizes.indexOf(this.settings.fontSize)
    const requested = event.currentTarget?.value
    const next = requested || sizes[Math.max(0, Math.min(sizes.length - 1, current + 1))]
    const previous = this.settings.fontSize
    this.settings.fontSize = sizes.includes(next) ? next : "medium"
    this.persistAndApply(this.settings.fontSize !== previous)
  }

  setWidth(event) {
    const previous = this.settings.width
    this.settings.width = [ "narrow", "comfortable", "wide" ].includes(event.currentTarget.value) ?
      event.currentTarget.value : "comfortable"
    this.persistAndApply(this.settings.width !== previous)
  }

  toggleTheme() {
    this.settings.theme = this.settings.theme === "dark" ? "light" : "dark"
    this.persistAndApply()
  }

  get previousFontSize() {
    return { small: "small", medium: "small", large: "medium" }[this.settings.fontSize]
  }

  get nextFontSize() {
    return { small: "medium", medium: "large", large: "large" }[this.settings.fontSize]
  }

  buildTableOfContents() {
    if (!this.hasTocTarget || !this.hasContentTarget) return

    const headings = Array.from(this.contentTarget.querySelectorAll("h2, h3"))
    this.tocTarget.replaceChildren()
    if (headings.length === 0) {
      this.tocTarget.hidden = true
      return
    }

    headings.forEach((heading, index) => {
      heading.id ||= `academic-section-${index + 1}`
      const item = document.createElement("li")
      item.className = heading.tagName === "H3" ? "ml-4" : ""
      const link = document.createElement("a")
      link.href = `#${heading.id}`
      link.textContent = heading.textContent.trim()
      link.className = "text-brand-ink hover:text-brand-ink-deep"
      link.dataset.readerTocLink = "true"
      link.dataset.action = "click->reader#acknowledgeTocSelection"
      item.append(link)
      this.tocTarget.append(item)
    })
    this.tocTarget.hidden = false
  }

  acknowledgeTocSelection(event) {
    const link = event.currentTarget
    if (link.href === this.selectedTocHref || window.location.hash === link.hash) return

    this.selectedTocHref = link.href
    this.cancelTocAnimation()
    if (this.reducedMotion || typeof link.animate !== "function") return

    const animation = link.animate([
      { opacity: 0.68, transform: "translateX(3px)" },
      { opacity: 1, transform: "translateX(0)" }
    ], {
      duration: 160,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.tocAnimation = animation

    animation.addEventListener("finish", () => {
      if (this.tocAnimation !== animation) return

      this.tocAnimation = null
      animation.cancel()
    }, { once: true })
  }

  applySettings() {
    this.element.dataset.readerWidth = this.settings.width
    this.element.dataset.readerFontSize = this.settings.fontSize
    this.element.dataset.readerTheme = this.settings.theme
    if (this.hasFontSizeTarget) this.fontSizeTarget.value = this.settings.fontSize
  }

  persistAndApply(animate = true) {
    try { window.localStorage.setItem(this.storageKey, JSON.stringify(this.settings)) } catch (_) { }
    this.applySettings()
    if (animate) this.animateSurface()
  }

  animateSurface() {
    const interrupted = Boolean(this.surfaceAnimation)
    const styles = interrupted && this.hasSurfaceTarget ? getComputedStyle(this.surfaceTarget) : null
    this.cancelSurfaceAnimation()

    if (!this.hasSurfaceTarget || this.reducedMotion ||
        typeof this.surfaceTarget.animate !== "function") return

    const animation = this.surfaceTarget.animate([
      interrupted ? {
        opacity: Number(styles.opacity),
        transform: styles.transform
      } : {
        opacity: 0.82,
        transform: "translateY(3px) scale(0.997)"
      },
      { opacity: 1, transform: "none" }
    ], {
      duration: 180,
      easing: "cubic-bezier(0.22, 0.9, 0.3, 1)",
      fill: "both"
    })
    this.surfaceAnimation = animation

    animation.addEventListener("finish", () => {
      if (this.surfaceAnimation !== animation) return

      this.surfaceAnimation = null
      animation.cancel()
    }, { once: true })
  }

  cancelSurfaceAnimation() {
    if (!this.surfaceAnimation) return

    const animation = this.surfaceAnimation
    this.surfaceAnimation = null
    animation.cancel()
  }

  cancelTocAnimation() {
    if (!this.tocAnimation) return

    const animation = this.tocAnimation
    this.tocAnimation = null
    animation.cancel()
  }

  restoreSettings() {
    try {
      const saved = JSON.parse(window.localStorage.getItem(this.storageKey) || "null")
      if (saved && typeof saved === "object") this.settings = { ...this.settings, ...saved }
    } catch (_) { }
  }

  get storageKey() {
    return this.hasStorageKeyValue ? this.storageKeyValue : "academic-post-reader"
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
