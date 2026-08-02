import { Controller } from "@hotwired/stimulus"
import { Editor, Node } from "@tiptap/core"
import StarterKit from "@tiptap/starter-kit"
import BubbleMenu from "@tiptap/extension-bubble-menu"
import FloatingMenu from "@tiptap/extension-floating-menu"
import Mathematics from "@tiptap/extension-mathematics"
import Image from "@tiptap/extension-image"

const Citation = Node.create({
  name: "citation",
  inline: true,
  group: "inline",
  atom: true,

  addAttributes() {
    return { key: { default: "" } }
  },

  parseHTML() {
    return [ { tag: "span[data-type='citation']" } ]
  },

  renderHTML({ node }) {
    return [ "span", { "data-type": "citation", "data-citation-key": node.attrs.key }, `[${node.attrs.key}]` ]
  }
})

const Reference = Node.create({
  name: "reference",
  group: "block",
  content: "inline*",
  defining: true,

  addAttributes() {
    return { key: { default: "" } }
  },

  parseHTML() {
    return [ { tag: "p[data-type='reference']" } ]
  },

  renderHTML({ node }) {
    return [ "p", { "data-type": "reference", "data-reference-key": node.attrs.key }, 0 ]
  }
})

export default class extends Controller {
  static targets = [ "editor", "input", "bubbleMenu", "floatingMenu", "pictureInput", "pictureAlt", "status" ]
  static values = { pictureUrl: String, readonly: Boolean }

  connect() {
    this.readonly = this.hasReadonlyValue && this.readonlyValue
    const initialContent = this.hasInputTarget ? this.inputTarget.value : this.editorTarget.innerHTML

    try {
      this.editor = new Editor({
        element: this.editorTarget,
        content: initialContent,
        editable: !this.readonly,
        extensions: this.extensions,
        onUpdate: () => this.sync()
      })
      this.editorTarget.classList.add("tiptap")
    } catch (error) {
      this.showStatus("The rich-text editor could not be loaded. Your saved content is preserved.", true)
      this.element.dataset.tiptapError = "true"
    }
  }

  disconnect() {
    this.editor?.destroy()
  }

  sync(event) {
    if (this.editor && this.hasInputTarget) {
      this.inputTarget.value = this.editor.getHTML()
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  toggleBold() {
    this.editor?.chain().focus().toggleBold().run()
  }

  toggleItalic() {
    this.editor?.chain().focus().toggleItalic().run()
  }

  toggleBulletList() {
    this.editor?.chain().focus().toggleBulletList().run()
  }

  toggleOrderedList() {
    this.editor?.chain().focus().toggleOrderedList().run()
  }

  toggleBlockquote() {
    this.editor?.chain().focus().toggleBlockquote().run()
  }

  toggleHeading() {
    this.editor?.chain().focus().toggleHeading({ level: 2 }).run()
  }

  insertCitation() {
    const key = this.promptForKey("Citation key")
    if (!key) return

    this.editor?.chain().focus().insertContent({ type: "citation", attrs: { key } }).run()
  }

  insertReference() {
    const key = this.promptForKey("Reference key")
    if (!key) return

    const details = window.prompt("Reference details")?.trim()
    if (!details) return

    this.editor?.chain().focus().insertContent({
      type: "reference",
      attrs: { key },
      content: [ { type: "text", text: `[${key}] ${details}` } ]
    }).run()
  }

  insertMath() {
    const latex = window.prompt("Enter a LaTeX expression")?.trim()
    if (!latex) return

    this.editor?.chain().focus().insertInlineMath({ latex }).run()
  }

  async importPicture() {
    if (!this.hasPictureInputTarget || !this.pictureInputTarget.files[0]) return
    if (!this.hasPictureUrlValue || !this.pictureUrlValue) {
      this.showStatus("Save the draft before importing a picture.", true)
      return
    }

    const file = this.pictureInputTarget.files[0]
    const form = new FormData()
    form.append("picture", file)
    if (this.hasPictureAltTarget) form.append("alt", this.pictureAltTarget.value)

    try {
      const response = await fetch(this.pictureUrlValue, {
        method: "POST",
        body: form,
        headers: { "X-CSRF-Token": this.csrfToken }
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.errors?.join(" ") || "The picture could not be imported.")

      this.editor?.chain().focus().setImage({ src: payload.url, alt: payload.alt }).run()
      this.pictureInputTarget.value = ""
      this.showStatus("Picture imported.")
    } catch (error) {
      this.showStatus(error.message, true)
    }
  }

  get extensions() {
    const extensions = [
      StarterKit,
      Citation,
      Reference,
      Mathematics.configure({ katexOptions: { throwOnError: false, strict: "warn" } }),
      Image.configure({ allowBase64: false })
    ]

    if (this.hasBubbleMenuTarget) {
      extensions.push(BubbleMenu.configure({ element: this.bubbleMenuTarget }))
    }
    if (this.hasFloatingMenuTarget) {
      extensions.push(FloatingMenu.configure({ element: this.floatingMenuTarget }))
    }
    return extensions
  }

  showStatus(message, error = false) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.dataset.state = error ? "error" : "success"
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }

  promptForKey(label) {
    const key = window.prompt(`${label} (letters, numbers, ., _ or -)`)?.trim()
    if (!key || !/^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$/.test(key)) {
      this.showStatus("Use a reference key with up to 32 letters, numbers, dots, underscores or hyphens.", true)
      return null
    }
    return key
  }
}
