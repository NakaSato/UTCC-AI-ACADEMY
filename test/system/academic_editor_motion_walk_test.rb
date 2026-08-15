require "application_system_test_case"

# Browser evidence for editor-tool acknowledgement. Tiptap command behavior and
# synchronized content remain the source of truth; the button movement is only
# decorative feedback.
class AcademicEditorMotionWalkTest < ApplicationSystemTestCase
  test "editor toolbar acknowledges an executed command" do
    open_editor
    record_toolbar_animations

    accept_prompt("Enter a LaTeX expression", with: "E=mc^2") do
      find('[data-action="tiptap#insertMath"]').click
    end

    assert_selector '[data-tiptap-target="editor"] [data-type="inline-math"]'
    assert_equal [
      { "duration" => 160, "start_transform" => "scale(0.94)" }
    ], toolbar_animations
  end

  test "editor toolbar stays still when motion is reduced" do
    open_editor
    reduce_motion
    record_toolbar_animations

    find('[data-action="tiptap#toggleBold"]').click
    assert_empty toolbar_animations
  end

  private
    def open_editor
      sign_in_through_the_form(users(:one))
      navigate_to I18n.t("chrome.nav.writing", locale: :th)
      click_link I18n.t("academic.new", locale: :th)
    end

    def record_toolbar_animations
      page.execute_script <<~JS
        window.__editorToolbarAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("button[data-action*='tiptap#']")) {
            window.__editorToolbarAnimations.push({
              duration: options.duration,
              start_transform: keyframes[0].transform
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def reduce_motion
      page.execute_script <<~JS
        window.matchMedia = (query) => ({
          matches: query === "(prefers-reduced-motion: reduce)",
          media: query,
          addEventListener() {},
          removeEventListener() {}
        })
      JS
    end

    def toolbar_animations = evaluate_script("window.__editorToolbarAnimations")
end
