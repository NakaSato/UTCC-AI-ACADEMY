import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "content", "toc", "fontSize" ]
  static values = { storageKey: String }

  connect() {
    this.settings = { width: "comfortable", fontSize: "medium", theme: "light" }
    this.restoreSettings()
    this.buildTableOfContents()
    this.applySettings()
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
    this.settings.fontSize = sizes.includes(next) ? next : "medium"
    this.persistAndApply()
  }

  setWidth(event) {
    this.settings.width = [ "narrow", "comfortable", "wide" ].includes(event.currentTarget.value) ?
      event.currentTarget.value : "comfortable"
    this.persistAndApply()
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
      link.className = "text-brand hover:text-brand-deep"
      item.append(link)
      this.tocTarget.append(item)
    })
    this.tocTarget.hidden = false
  }

  applySettings() {
    this.element.dataset.readerWidth = this.settings.width
    this.element.dataset.readerFontSize = this.settings.fontSize
    this.element.dataset.readerTheme = this.settings.theme
    if (this.hasFontSizeTarget) this.fontSizeTarget.value = this.settings.fontSize
  }

  persistAndApply() {
    try { window.localStorage.setItem(this.storageKey, JSON.stringify(this.settings)) } catch (_) { }
    this.applySettings()
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
}
