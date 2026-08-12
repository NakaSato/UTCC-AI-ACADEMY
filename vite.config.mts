import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

// Vite builds one thing: the Vue island layer (ADR-0053). Everything else —
// Turbo, Stimulus, Tiptap, the seventeen controllers — stays on import maps and
// Propshaft, which is why `sourceCodeDir` is `app/frontend` rather than
// `app/javascript`. Two directories, two toolchains, and no file belongs to
// both.
//
// The reason this exists at all is the compiler. Vue's template compiler is
// blocked by this application's CSP (`script-src 'self'`, no `unsafe-eval`), so
// islands written against import maps had to be hand-written `h()` render
// functions. Vite compiles single-file components at build time, which puts the
// compiler in the build rather than the browser: the shipped bundle is the
// runtime alone, and `.vue` files become available without touching the policy.
export default defineConfig(({ mode }) => ({
  plugins: [
    RubyPlugin(),
    vue(),
  ],

  build: {
    // Everywhere but production. The first version of this shipped the map — a
    // 535KB file beside a 61KB bundle, served publicly, holding the island
    // sources — on the argument that a bundle nobody can read is a bundle nobody
    // can review after an incident.
    //
    // That argument needs somewhere for the map to go, and there is nowhere:
    // nothing in this application consumes source maps. There is no error
    // tracker, no upload step, and no other bundle ships one — Propshaft serves
    // the import map's files as they were written, so this would have been the
    // only map in production, nine times the size of what it explains.
    //
    // So it is off in production and on wherever somebody is actually reading
    // it. If an error tracker ever arrives, the answer is to upload the map to
    // it rather than to serve it from the origin.
    sourcemap: mode !== "production",
  },
}))
