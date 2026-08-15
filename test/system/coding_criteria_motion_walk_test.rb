require "application_system_test_case"

# Browser evidence for the user-requested criterion movement. The rows animate
# only after the grading response has set their truth, and reduced motion still
# updates every row without invoking the Web Animations API.
class CodingCriteriaMotionWalkTest < ApplicationSystemTestCase
  test "coding criteria settle in with a capped stagger unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :code)
    record_criterion_animations

    click_button I18n.t("lesson.code.run", locale: :th)
    assert_selector "[data-code-task-target=console][data-state]:not([data-state=''])"

    expected = LessonContent.for("1-1").checks.each_index.map do |index|
      { "delay" => [ index * 45, 135 ].min, "duration" => 260 }
    end
    assert_equal expected, criterion_animations

    reduce_motion
    click_button I18n.t("lesson.code.reset", locale: :th)
    count = criterion_animation_count
    click_button I18n.t("lesson.code.run", locale: :th)
    assert_selector "[data-code-task-target=console][data-state]:not([data-state=''])"
    assert_equal count, criterion_animation_count
  end

  private
    def record_criterion_animations
      page.execute_script <<~JS
        window.__criterionAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-code-task-target~='check']")) {
            window.__criterionAnimations.push({
              delay: options.delay,
              duration: options.duration
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

    def criterion_animations = evaluate_script("window.__criterionAnimations")
    def criterion_animation_count = evaluate_script("window.__criterionAnimations.length")
end
