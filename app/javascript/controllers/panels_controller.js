import { Controller } from "@hotwired/stimulus"

// Tabs whose panels are all already in the document, so switching is a
// show/hide rather than a navigation. Everything past the show/hide is opt-in,
// read off the tab or the panel:
//
//   tab   data-panel    which panel this tab shows (required)
//         data-path     URL to keep in the address bar
//         data-title    document title to go with it
//         data-percent  width for the `progress` target
//         data-index    ordered steps: tabs also get data-state=done|current|todo
//   panel data-panel    which tab shows it (required)
//         data-focus    focus its first field once shown
//
// Anything else can trigger a switch by carrying `data-panel` and the action —
// an in-panel "next step" button, say. The tab named by that panel stays the
// source of truth for the rest, so only the tab spells out path and title.
//
// The controller element carries `data-panel` too, so the rest of the subtree
// can react in CSS alone with `group-data-[panel=…]:`.
export default class extends Controller {
  static targets = ["tab", "panel", "progress", "replay"]

  // Triggers are sometimes real links, so the page still works without JS.
  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.dataset.panel)
  }

  show(name) {
    const tab = this.tabTargets.find((tab) => tab.dataset.panel === name)
    const index = Number(tab?.dataset.index)

    this.element.dataset.panel = name

    this.tabTargets.forEach((other) => {
      const selected = other.dataset.panel === name
      other.setAttribute("aria-selected", String(selected))

      if ("index" in other.dataset) {
        other.dataset.state =
          selected ? "current" : Number(other.dataset.index) < index ? "done" : "todo"
      }
    })

    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.panel !== name

      if (!panel.hidden && "focus" in panel.dataset) {
        panel.querySelector("input:not([type=hidden])")?.focus()
      }
    })

    if (tab?.dataset.path) history.replaceState(history.state, "", tab.dataset.path)
    if (tab?.dataset.title) document.title = tab.dataset.title

    if (this.hasProgressTarget && tab?.dataset.percent) {
      this.progressTarget.style.width = `${tab.dataset.percent}%`
    }

    this.replay()
  }

  // Rows animate in on load; arriving by tab is the same arrival, so play it
  // again. The reflow between the two writes is what restarts the animation.
  replay() {
    this.replayTargets.forEach((element) => {
      element.dataset.in = "false"
      element.offsetHeight
      element.dataset.in = "true"
    })
  }
}
