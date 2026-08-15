require "application_system_test_case"

# Browser evidence for the user-requested assessment feedback movement. Both
# server-graded surfaces use the same controller, while reduced-motion readers
# still receive the result and no Web Animations API call.
class AssessmentFeedbackMotionWalkTest < ApplicationSystemTestCase
  test "exercise and coding results settle in unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_feedback_animations

    content = LessonContent.for("1-1")
    wrong = (content.correct_option + 1) % content.options.size
    find("[data-quiz-target=option][data-index='#{wrong}']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)
    assert_selector "[data-quiz-target=feedback][data-state=wrong]"
    assert_equal({ "target" => "quiz", "duration" => 240 }, last_feedback_animation)

    find("[role=tab][data-panel=code]").click
    click_button I18n.t("lesson.code.run", locale: :th)
    assert_selector "[data-code-task-target=console][data-state]:not([data-state=''])"
    assert_equal({ "target" => "code", "duration" => 240 }, last_feedback_animation)

    reduce_motion
    click_button I18n.t("lesson.code.reset", locale: :th)
    count = feedback_animation_count
    click_button I18n.t("lesson.code.run", locale: :th)
    assert_selector "[data-code-task-target=console][data-state]:not([data-state=''])"
    assert_equal count, feedback_animation_count
  end

  private
    def record_feedback_animations
      page.execute_script <<~JS
        window.__assessmentFeedbackAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-quiz-target~='feedback']")) {
            window.__assessmentFeedbackAnimations.push({ target: "quiz", duration: options.duration })
          }
          if (this.matches("[data-code-task-target~='console']")) {
            window.__assessmentFeedbackAnimations.push({ target: "code", duration: options.duration })
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

    def last_feedback_animation = evaluate_script("window.__assessmentFeedbackAnimations.at(-1)")
    def feedback_animation_count = evaluate_script("window.__assessmentFeedbackAnimations.length")
end
