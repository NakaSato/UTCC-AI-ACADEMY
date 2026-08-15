require "application_system_test_case"

# Browser evidence for the user-requested reward movement. A real server-graded
# pass updates and moves the counter; the same event under reduced motion still
# updates its value without invoking the Web Animations API.
class RewardMotionWalkTest < ApplicationSystemTestCase
  test "a confirmed reward bumps the gems counter unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_reward_animations

    content = LessonContent.for("1-1")
    find("[data-quiz-target=option][data-index='#{content.correct_option}']").click
    click_button I18n.t("lesson.quiz.check", locale: :th)

    assert_selector "[data-rewards-target=total]", text: "+#{LearnerProgress::GEMS_PER_LEARNED}"
    assert_equal({ "duration" => 320, "peak" => "translateY(-2px) scale(1.16)" },
                 last_reward_animation)

    reduce_motion
    count = reward_animation_count
    page.execute_script <<~JS
      document.querySelector("main#main").dispatchEvent(new CustomEvent("code-task:reward", {
        bubbles: true,
        detail: { gems: #{LearnerProgress::GEMS_PER_APPLIED} }
      }))
    JS

    total = LearnerProgress::GEMS_PER_LEARNED + LearnerProgress::GEMS_PER_APPLIED
    assert_selector "[data-rewards-target=total]", text: "+#{total}"
    assert_equal count, reward_animation_count
  end

  private
    def record_reward_animations
      page.execute_script <<~JS
        window.__rewardAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-rewards-target~='total']")) {
            window.__rewardAnimations.push({
              duration: options.duration,
              peak: keyframes[1].transform
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

    def last_reward_animation = evaluate_script("window.__rewardAnimations.at(-1)")
    def reward_animation_count = evaluate_script("window.__rewardAnimations.length")
end
