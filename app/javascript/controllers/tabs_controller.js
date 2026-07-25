import { Controller } from "@hotwired/stimulus"

// Curriculum filter tabs: click a level, show only cards carrying that level.
export default class extends Controller {
  static targets = ["tab", "item"]

  select(event) {
    const level = event.currentTarget.dataset.level

    this.tabTargets.forEach((tab) => {
      tab.setAttribute("aria-selected", String(tab.dataset.level === level))
    })

    this.itemTargets.forEach((item) => {
      const match = level === "all" || item.dataset.level === level
      item.hidden = !match
    })
  }
}
