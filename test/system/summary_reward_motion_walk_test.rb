require "application_system_test_case"

# Browser evidence for the final-step reward reveal. Arriving at Summary gives
# each reward card one short, capped stagger; reduced-motion readers get the
# same cards immediately without a Web Animations API call.
class SummaryRewardMotionWalkTest < ApplicationSystemTestCase
  test "summary reward cards settle in sequence unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :code)
    record_summary_reward_animations

    find("[role=tab][data-panel=summary]").click

    expected = LessonContent.rewards.each_index.map do |index|
      { "delay" => [ index * 45, 135 ].min, "duration" => 280 }
    end
    assert_equal expected, summary_reward_animations

    find("[role=tab][data-panel=code]").click
    reduce_motion
    count = summary_reward_animation_count
    find("[role=tab][data-panel=summary]").click

    assert_equal count, summary_reward_animation_count
    assert_selector "#lesson-panel-summary", visible: true
  end

  private
    def record_summary_reward_animations
      page.execute_script <<~JS
        window.__summaryRewardAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-summary-reward]")) {
            window.__summaryRewardAnimations.push({
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

    def summary_reward_animations = evaluate_script("window.__summaryRewardAnimations")
    def summary_reward_animation_count = evaluate_script("window.__summaryRewardAnimations.length")
end
