require "application_system_test_case"

# Browser evidence for the sidebar's selected-step confirmation. Semantic tab
# state changes first; the destination circle then settles once, while repeated
# and reduced-motion selections remain still.
class LessonStepIndicatorMotionWalkTest < ApplicationSystemTestCase
  test "the selected step indicator settles once unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :theory)
    record_step_indicator_animations

    find("[role=tab][data-panel=code]").click
    assert_equal({
      "duration" => 240,
      "peak" => "scale(1.1)",
      "start" => "scale(0.84)",
      "step" => "code"
    }, last_step_indicator_animation)

    finish_step_indicator_animations
    find("[role=tab][data-panel=theory]").click
    assert_equal "theory", last_step_indicator_animation.fetch("step")

    count = step_indicator_animation_count
    find("[role=tab][data-panel=theory]").click
    assert_equal count, step_indicator_animation_count

    reduce_motion
    find("[role=tab][data-panel=summary]").click

    assert_equal count, step_indicator_animation_count
    assert_selector "[role=tab][data-panel=summary][aria-selected=true]"
  end

  private
    def record_step_indicator_animations
      page.execute_script <<~JS
        window.__lessonStepIndicatorAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-lesson-step-indicator]")) {
            window.__lessonStepIndicatorAnimations.push({
              duration: options.duration,
              peak: keyframes[1].transform,
              start: keyframes[0].transform,
              step: this.dataset.lessonStepIndicator
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def finish_step_indicator_animations
      page.execute_script <<~JS
        document.querySelectorAll("[data-lesson-step-indicator]").forEach((indicator) => {
          indicator.getAnimations().forEach((animation) => animation.finish())
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

    def last_step_indicator_animation = evaluate_script("window.__lessonStepIndicatorAnimations.at(-1)")
    def step_indicator_animation_count = evaluate_script("window.__lessonStepIndicatorAnimations.length")
end
