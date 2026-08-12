<script setup>
// How much of a limited field is left, counted as somebody types.
//
// The first island, and the first written as a single-file component: the same
// behavior it had as a hand-written `h()` render function, in the form Vite was
// added for. The template below is compiled at build time, so the browser
// receives render code and never a compiler — which is what keeps this inside a
// CSP with no `unsafe-eval` (ADR-0053).
//
// It takes its copy from the server as a prop, because translation belongs to
// the locale files and not to JavaScript, and it enhances a field that already
// works without it: the limit is `maxlength`, enforced by the browser and again
// by the model, so with JavaScript off nothing is lost but the count.
import { ref, computed, onMounted, onBeforeUnmount } from "vue"

const props = defineProps({
  // The field this counts. An id rather than a selector: the island is rendered
  // beside its field by the same template, so the pair is server-verified —
  // `admin_proposals_test.rb` asserts they match.
  fieldId: { type: String, required: true },
  max: { type: Number, required: true },
  // Already translated, with `%{count}` still in it, because interpolation is
  // the one part the server cannot do before the number exists.
  template: { type: String, required: true },
  // Below this many remaining, the line is worth noticing.
  warnAt: { type: Number, default: 100 }
})

const used = ref(0)
let field = null

const measure = () => { used.value = field ? field.value.length : 0 }

const left = computed(() => Math.max(props.max - used.value, 0))
const message = computed(() => props.template.replace("%{count}", String(left.value)))

onMounted(() => {
  field = document.getElementById(props.fieldId)
  field?.addEventListener("input", measure)
  // A form Turbo restored from cache, or one the browser refilled, already has
  // text in it before anybody types.
  measure()
})

onBeforeUnmount(() => field?.removeEventListener("input", measure))
</script>

<template>
  <!-- Polite rather than assertive: a count that interrupts a screen reader on
       every keystroke is worse than no count at all. Classes come from the
       token system, like every other template. -->
  <p
    class="mt-1 text-11-5 tabular-nums"
    :class="left <= warnAt ? 'text-gold-ink' : 'text-muted-3'"
    aria-live="polite"
  >{{ message }}</p>
</template>
