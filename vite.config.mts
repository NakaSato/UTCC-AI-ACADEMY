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
export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(),
  ],

  build: {
    // A bundle nobody can read is a bundle nobody can review after an incident.
    sourcemap: true,
  },
})
