require "application_system_test_case"

# Browser evidence for the coding-task submission cue. The console's running
# state is committed before grading begins; result feedback remains separate.
class CodingRunMotionWalkTest < ApplicationSystemTestCase
  test "coding run acknowledges submission unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :code)
    record_console_animations

    click_button I18n.t("lesson.code.run", locale: :th)
    assert_selector "[data-code-task-target=console][data-state]:not([data-state=''])"
    assert_includes console_animations, {
      "duration" => 160, "start_opacity" => 0.72,
      "start_transform" => "translateX(-4px)"
    }

    reduce_motion
    count = console_animation_count
    click_button I18n.t("lesson.code.reset", locale: :th)
    click_button I18n.t("lesson.code.run", locale: :th)
    assert_selector "[data-code-task-target=console][data-state]:not([data-state=''])"
    assert_equal count, console_animation_count
  end

  private
    def record_console_animations
      page.execute_script <<~JS
        window.__codingRunAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-code-task-target=console]")) {
            window.__codingRunAnimations.push({
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

    def console_animations = evaluate_script("window.__codingRunAnimations")
    def console_animation_count = evaluate_script("window.__codingRunAnimations.length")
end
