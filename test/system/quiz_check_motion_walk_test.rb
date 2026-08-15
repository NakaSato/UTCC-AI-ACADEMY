require "application_system_test_case"

# Browser evidence for the exercise submission cue. The check control becomes
# disabled before movement begins; grading and result feedback remain separate.
class QuizCheckMotionWalkTest < ApplicationSystemTestCase
  test "exercise check acknowledges submission" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_check_animations

    content = LessonContent.for("1-1")
    find("[data-quiz-target=option][data-index='#{content.correct_option}']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)

    assert_selector "[data-quiz-target=feedback][data-state]"
    assert_equal [
      { "duration" => 160, "start_opacity" => 0.72,
        "start_transform" => "translateX(-4px)" }
    ], check_animations
  end

  test "exercise check stays still when motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    reduce_motion
    record_check_animations

    find("[data-quiz-target=option][data-index='0']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)
    assert_selector "[data-quiz-target=feedback][data-state]"
    assert_empty check_animations
  end

  private
    def record_check_animations
      page.execute_script <<~JS
        window.__quizCheckAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-quiz-target=check]")) {
            window.__quizCheckAnimations.push({
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

    def check_animations = evaluate_script("window.__quizCheckAnimations")
end
