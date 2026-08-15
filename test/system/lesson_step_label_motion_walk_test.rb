require "application_system_test_case"

# Browser evidence for the compact label beside lesson progress. Its entrance
# follows navigation direction after visibility changes; repeated and
# reduced-motion selections expose the translated label without decoration.
class LessonStepLabelMotionWalkTest < ApplicationSystemTestCase
  test "the visible step label follows navigation direction unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :theory)
    record_step_label_animations

    find("[role=tab][data-panel=code]").click
    assert_equal({ "duration" => 180, "start" => "translateY(4px)", "step" => "code" },
                 last_step_label_animation)

    finish_step_label_animations
    find("[role=tab][data-panel=theory]").click
    assert_equal({ "duration" => 180, "start" => "translateY(-4px)", "step" => "theory" },
                 last_step_label_animation)

    count = step_label_animation_count
    find("[role=tab][data-panel=theory]").click
    assert_equal count, step_label_animation_count

    reduce_motion
    find("[role=tab][data-panel=summary]").click

    assert_equal count, step_label_animation_count
    assert_selector "[data-lesson-step-label=summary]", visible: true
  end

  private
    def record_step_label_animations
      page.execute_script <<~JS
        window.__lessonStepLabelAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-lesson-step-label]")) {
            window.__lessonStepLabelAnimations.push({
              duration: options.duration,
              start: keyframes[0].transform,
              step: this.dataset.lessonStepLabel
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def finish_step_label_animations
      page.execute_script <<~JS
        document.querySelectorAll("[data-lesson-step-label]").forEach((label) => {
          label.getAnimations().forEach((animation) => animation.finish())
        })
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

    def last_step_label_animation = evaluate_script("window.__lessonStepLabelAnimations.at(-1)")
    def step_label_animation_count = evaluate_script("window.__lessonStepLabelAnimations.length")
end
