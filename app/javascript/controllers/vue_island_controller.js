import { Controller } from "@hotwired/stimulus"
import { createApp } from "vue"
import registry from "islands/registry"

// The one bridge between Turbo's DOM and Vue's (ADR-0051). Nothing else in the
// application calls `createApp`.
//
// Turbo owns the page: Drive replaces the body on every navigation and a Stream
// can replace any node at any time. An app mounted and forgotten survives as a
// detached tree with live listeners, so mounting is tied to the one lifecycle
// that already tracks element identity — Stimulus connect/disconnect, which
// Turbo drives for both cases. `unmount()` also empties the element, so the
// snapshot Turbo caches holds the server's markup rather than Vue's output.
//
// An island is named rather than imported here: the registry is the list of
// what may mount, so a data attribute cannot name arbitrary code.
export default class extends Controller {
  static values = { island: String, props: { type: Object, default: {} } }

  connect() {
    const island = registry[this.islandValue]

    // A name nothing answers to is a template bug, and a silent no-op would
    // leave a reader wondering why nothing appeared. The screen still works —
    // every island is an enhancement over markup that already renders.
    if (!island) {
      console.warn(`[vue-island] no island named "${this.islandValue}"`)
      return
    }

    this.app = createApp(island, this.propsValue)
    this.app.mount(this.element)
  }

  disconnect() {
    this.app?.unmount()
    this.app = null
  }
}
