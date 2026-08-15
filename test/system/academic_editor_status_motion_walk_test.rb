require "application_system_test_case"

# Browser evidence for editor validation feedback. The live message and error
# state commit before movement; repeated identical status does not replay it.
class AcademicEditorStatusMotionWalkTest < ApplicationSystemTestCase
  test "editor status acknowledges a changed validation message" do
    open_editor
    record_status_animations

    accept_prompt("Citation key", with: "bad key") do
      find('[data-action="tiptap#insertCitation"]').click
    end

    assert_selector "[data-tiptap-target=status][data-state=error]", text: /reference key/
    assert_equal [
      { "duration" => 180, "start_opacity" => 0.45,
        "start_transform" => "translateY(3px)" }
    ], status_animations

    accept_prompt("Citation key", with: "bad key") do
      find('[data-action="tiptap#insertCitation"]').click
    end
    assert_equal 1, status_animation_count
  end

  test "editor status stays still when motion is reduced" do
    open_editor
    reduce_motion
    record_status_animations

    accept_prompt("Citation key", with: "bad key") do
      find('[data-action="tiptap#insertCitation"]').click
    end

    assert_selector "[data-tiptap-target=status][data-state=error]", text: /reference key/
    assert_empty status_animations
  end

  private
    def open_editor
      sign_in_through_the_form(users(:one))
      navigate_to I18n.t("chrome.nav.writing", locale: :th)
      click_link I18n.t("academic.new", locale: :th)
    end

    def record_status_animations
      page.execute_script <<~JS
        window.__editorStatusAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-tiptap-target=status]")) {
            window.__editorStatusAnimations.push({
              duration: options.duration,
              start_opacity: keyframes[0].opacity,
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

    def status_animations = evaluate_script("window.__editorStatusAnimations")
    def status_animation_count = evaluate_script("window.__editorStatusAnimations.length")
end
