import { Controller } from "@hotwired/stimulus"
import katex from "katex"

// Typeset one equation block.
//
// KaTeX has been vendored since the academic-post editor took it — the library,
// its stylesheet and twenty font files — and the lesson view never used it. A
// theory block whose copy is `\lceil 0.8\,N \rceil` was rendered as that string,
// in monospace, to every learner reaching one of the three topics that use the
// placeholder copy. This is the wiring the view's comment kept promising.
//
// Stimulus rather than a Vue island, deliberately: this is behavior attached to
// server-rendered markup and holds no state, which is the line ADR-0051
// decision 7 draws.
//
// The source is on screen before this runs and stays there if it does not —
// `katex.render` replaces the element's contents, so with JavaScript off, or if
// the library fails to load, a reader sees the LaTeX rather than an empty box.
// `throwOnError: false` matches the editor's configuration, so a malformed
// expression renders in KaTeX's error colour instead of taking the page down.
export default class extends Controller {
  static values = { source: String, display: { type: Boolean, default: true } }

  connect() {
    try {
      katex.render(this.sourceValue, this.element, {
        displayMode: this.displayValue,
        throwOnError: false,
        strict: "warn"
      })
    } catch (error) {
      // Whatever went wrong, the source is still what the server rendered.
      console.warn("[katex] could not typeset an equation block", error)
    }
  }
}
