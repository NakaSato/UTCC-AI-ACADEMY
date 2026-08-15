require "application_system_test_case"

# Browser evidence for the continuation actions revealed by passing assessment
# results. Server grading makes each link available before decoration begins;
# reduced-motion readers receive the same action without Web Animations.
class AssessmentActionMotionWalkTest < ApplicationSystemTestCase
  test "passing assessment actions settle in unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_action_animations

    content = LessonContent.for("1-1")
    find("[data-quiz-target=option][data-index='#{content.correct_option}']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)

    assert_selector "[data-quiz-target~=next][data-assessment-action=quiz]:not(.hidden)"
    assert_equal({ "duration" => 220, "start" => "translateY(5px) scale(0.98)",
                   "target" => "quiz" }, last_action_animation)

    find("[role=tab][data-panel=code]").click
    fill_in "lesson_code", with: content.solution
    click_button I18n.t("lesson.code.run", locale: :th)

    assert_selector "[data-code-task-target~=finish][data-assessment-action=code]:not(.hidden)"
    assert_equal "code", last_action_animation.fetch("target")

    reduce_motion
    click_button I18n.t("lesson.code.reset", locale: :th)
    count = action_animation_count
    fill_in "lesson_code", with: content.solution
    click_button I18n.t("lesson.code.run", locale: :th)

    assert_selector "[data-code-task-target~=finish]:not(.hidden)"
    assert_equal count, action_animation_count
  end

  private
    def record_action_animations
      page.execute_script <<~JS
        window.__assessmentActionAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-assessment-action]")) {
            window.__assessmentActionAnimations.push({
              duration: options.duration,
              start: keyframes[0].transform,
              target: this.dataset.assessmentAction
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

    def last_action_animation = evaluate_script("window.__assessmentActionAnimations.at(-1)")
    def action_animation_count = evaluate_script("window.__assessmentActionAnimations.length")
end
