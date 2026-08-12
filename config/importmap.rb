# Pin npm packages by running ./bin/importmap

pin "application"
pin "grading"
pin "frame_recovery"
pin "toast_stream"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@tiptap/core", to: "@tiptap--core.js" # @3.22.4
pin "@tiptap/core/jsx-runtime", to: "@tiptap--core--jsx-runtime.js" # @3.22.4
pin "tiptap-jsx-runtime", to: "tiptap-jsx-runtime.js" # @3.22.4 internal runtime
pin "@tiptap/extension-blockquote", to: "@tiptap--extension-blockquote.js" # @3.22.4
pin "@tiptap/extension-bold", to: "@tiptap--extension-bold.js" # @3.22.4
pin "@tiptap/extension-code", to: "@tiptap--extension-code.js" # @3.22.4
pin "@tiptap/extension-code-block", to: "@tiptap--extension-code-block.js" # @3.22.4
pin "@tiptap/extension-document", to: "@tiptap--extension-document.js" # @3.22.4
pin "@tiptap/extension-hard-break", to: "@tiptap--extension-hard-break.js" # @3.22.4
pin "@tiptap/extension-heading", to: "@tiptap--extension-heading.js" # @3.22.4
pin "@tiptap/extension-horizontal-rule", to: "@tiptap--extension-horizontal-rule.js" # @3.22.4
pin "@tiptap/extension-italic", to: "@tiptap--extension-italic.js" # @3.22.4
pin "@tiptap/extension-link", to: "@tiptap--extension-link.js" # @3.22.4
pin "@tiptap/extension-list", to: "@tiptap--extension-list.js" # @3.22.4
pin "@tiptap/extension-paragraph", to: "@tiptap--extension-paragraph.js" # @3.22.4
pin "@tiptap/extension-strike", to: "@tiptap--extension-strike.js" # @3.22.4
pin "@tiptap/extension-text", to: "@tiptap--extension-text.js" # @3.22.4
pin "@tiptap/extension-underline", to: "@tiptap--extension-underline.js" # @3.22.4
pin "@tiptap/extensions", to: "@tiptap--extensions.js" # @3.22.4
pin "@tiptap/extension-bubble-menu", to: "@tiptap--extension-bubble-menu.js" # @3.22.4
pin "@tiptap/extension-floating-menu", to: "@tiptap--extension-floating-menu.js" # @3.22.4
pin "@tiptap/extension-mathematics", to: "@tiptap--extension-mathematics.js" # @3.22.4
pin "@tiptap/extension-image", to: "@tiptap--extension-image.js" # @3.22.4
pin "@tiptap/pm/commands", to: "@tiptap--pm--commands.js" # @3.22.4
pin "@tiptap/pm/dropcursor", to: "@tiptap--pm--dropcursor.js" # @3.22.4
pin "@tiptap/pm/gapcursor", to: "@tiptap--pm--gapcursor.js" # @3.22.4
pin "@tiptap/pm/history", to: "@tiptap--pm--history.js" # @3.22.4
pin "@tiptap/pm/keymap", to: "@tiptap--pm--keymap.js" # @3.22.4
pin "@tiptap/pm/model", to: "@tiptap--pm--model.js" # @3.22.4
pin "@tiptap/pm/schema-list", to: "@tiptap--pm--schema-list.js" # @3.22.4
pin "@tiptap/pm/state", to: "@tiptap--pm--state.js" # @3.22.4
pin "@tiptap/pm/tables", to: "@tiptap--pm--tables.js" # @3.22.4
pin "@tiptap/pm/transform", to: "@tiptap--pm--transform.js" # @3.22.4
pin "@tiptap/pm/view", to: "@tiptap--pm--view.js" # @3.22.4
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.7.5
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.7.4
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.11
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.11
pin "katex", to: "katex.js" # @0.16.22
pin "linkifyjs", to: "linkifyjs.js" # @4.3.3
pin "prosemirror-commands", to: "prosemirror-commands.js" # @1.7.1
pin "prosemirror-dropcursor", to: "prosemirror-dropcursor.js" # @1.8.3
pin "prosemirror-gapcursor", to: "prosemirror-gapcursor.js" # @1.4.1
pin "prosemirror-history", to: "prosemirror-history.js" # @1.5.0
pin "prosemirror-keymap", to: "prosemirror-keymap.js" # @1.2.3
pin "prosemirror-model", to: "prosemirror-model.js" # @1.25.11
pin "prosemirror-schema-list", to: "prosemirror-schema-list.js" # @1.5.1
pin "prosemirror-state", to: "prosemirror-state.js" # @1.4.4
pin "prosemirror-tables", to: "prosemirror-tables.js" # @1.8.1
pin "prosemirror-transform", to: "prosemirror-transform.js" # @1.12.0
pin "prosemirror-view", to: "prosemirror-view.js" # @1.42.2
pin "orderedmap", to: "orderedmap.js" # @2.1.1
pin "rope-sequence", to: "rope-sequence.js" # @1.3.4
pin "w3c-keyname", to: "w3c-keyname.js" # @2.2.8
pin "@tiptap/starter-kit", to: "@tiptap--starter-kit.js" # @3.22.4
# The runtime-only build, deliberately and permanently. `bin/importmap pin vue`
# fetches `vue.esm-browser.prod.js`, which carries the template compiler and
# builds render functions with `Function(…)` — and `script-src :self` with no
# `unsafe-eval` blocks exactly that. An island is therefore a render function,
# never a template string; ADR-0051 and `test/operations/vue_build_test.rb`.
pin "vue", to: "vue.js" # @3.5.41
pin_all_from "app/javascript/islands", under: "islands"
