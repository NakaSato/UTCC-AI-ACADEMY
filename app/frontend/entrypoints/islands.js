import { createApp } from "vue"
import CharacterCounter from "../islands/CharacterCounter.vue"

// The one place a Vue app is created (ADR-0053, keeping ADR-0051 decision 3).
//
// The bridge used to be a Stimulus controller, which got mount and unmount for
// free from Turbo. Vite's bundle cannot import from the import map's, so the
// lifecycle is owned here instead — and it has to cover the same two cases
// Stimulus did:
//
//   * Turbo Drive replaces the whole body on navigation;
//   * a Turbo Stream replaces one node at any time, with no page event at all.
//
// A `turbo:load` listener catches the first and misses the second, so the mount
// is driven by a MutationObserver over the document instead: an island mounts
// when its element appears and unmounts when its element leaves. That is the
// same rule Stimulus applied, written out.
//
// An island is named, never imported by markup: `data-vue-island` names an entry
// in this registry and nothing else, so a template cannot reach arbitrary code.
const REGISTRY = {
  "character-counter": CharacterCounter
}

const mounted = new WeakMap()

function props(element) {
  try {
    return JSON.parse(element.dataset.vueIslandProps || "{}")
  } catch (error) {
    console.warn("[vue-island] props are not JSON", element, error)
    return {}
  }
}

function mount(element) {
  if (mounted.has(element)) return

  const island = REGISTRY[element.dataset.vueIsland]

  // A name nothing answers to is a template bug. The screen still works — every
  // island is an enhancement over markup that already renders — so this warns
  // rather than throws.
  if (!island) {
    console.warn(`[vue-island] no island named "${element.dataset.vueIsland}"`)
    return
  }

  const app = createApp(island, props(element))
  mounted.set(element, app)
  app.mount(element)
}

function unmount(element) {
  const app = mounted.get(element)
  if (!app) return

  app.unmount()
  mounted.delete(element)
}

function islandsWithin(node) {
  if (node.nodeType !== Node.ELEMENT_NODE) return []

  const found = node.matches("[data-vue-island]") ? [ node ] : []
  return found.concat(Array.from(node.querySelectorAll("[data-vue-island]")))
}

function start() {
  document.querySelectorAll("[data-vue-island]").forEach(mount)

  new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      mutation.removedNodes.forEach((node) => islandsWithin(node).forEach(unmount))
      mutation.addedNodes.forEach((node) => islandsWithin(node).forEach(mount))
    }
  }).observe(document.documentElement, { childList: true, subtree: true })
}

// Turbo caches a snapshot before it leaves. Unmounting first means the cached
// copy holds the server's markup rather than Vue's output, so a restored page
// re-mounts from the same starting point a fresh one does.
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("[data-vue-island]").forEach(unmount)
})

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", start, { once: true })
} else {
  start()
}
