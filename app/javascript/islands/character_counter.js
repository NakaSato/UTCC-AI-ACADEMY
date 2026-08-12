import { h, ref, onMounted, onBeforeUnmount } from "vue"

// How much of a limited field is left, counted as somebody types.
//
// The first island (ADR-0051), and the shape every other one should copy: it
// renders with `h` rather than a template, because the runtime-only build has
// no compiler and the CSP would block one; it takes its copy from the server as
// a prop, because translation belongs to the locale files and not to
// JavaScript; and it enhances a field that already works without it — the limit
// is `maxlength`, enforced by the browser and again by the model, so with
// JavaScript off nothing is lost but the count.
export default {
  props: {
    // The field this counts. An id rather than a selector: the island is
    // rendered beside its field by the same template, so the pair is
    // server-verified — `admin_proposals_test.rb` asserts they match.
    fieldId: { type: String, required: true },
    max: { type: Number, required: true },
    // Already translated, with `%{count}` still in it, because interpolation is
    // the one part the server cannot do before the number exists.
    template: { type: String, required: true },
    // Below this many remaining, the line is worth noticing.
    warnAt: { type: Number, default: 100 }
  },

  setup(props) {
    const used = ref(0)
    let field = null

    const measure = () => { used.value = field ? field.value.length : 0 }

    onMounted(() => {
      field = document.getElementById(props.fieldId)
      field?.addEventListener("input", measure)
      // A form Turbo restored from cache, or one the browser refilled, already
      // has text in it before anybody types.
      measure()
    })

    onBeforeUnmount(() => field?.removeEventListener("input", measure))

    return () => {
      const left = Math.max(props.max - used.value, 0)

      return h(
        "p",
        {
          class: [ "mt-1 text-11-5 tabular-nums", left <= props.warnAt ? "text-gold-ink" : "text-muted-3" ],
          // Polite rather than assertive: a count that interrupts a screen
          // reader on every keystroke is worse than no count at all.
          "aria-live": "polite"
        },
        props.template.replace("%{count}", String(left))
      )
    }
  }
}
