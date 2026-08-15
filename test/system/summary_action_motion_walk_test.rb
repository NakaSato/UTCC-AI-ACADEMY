require "application_system_test_case"

# Browser evidence for the final action-link sequence. Both destinations stay
# real links while their decorative rise follows the earlier completion cues;
# repeated and reduced-motion arrivals remain still.
class SummaryActionMotionWalkTest < ApplicationSystemTestCase
  test "summary action links rise in sequence unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :code)
    record_summary_action_animations

    find("[role=tab][data-panel=summary]").click

    assert_equal [
      { "delay" => 180, "duration" => 260, "start" => "translateY(6px)" },
      { "delay" => 220, "duration" => 260, "start" => "translateY(6px)" }
    ], summary_action_animations

    count = summary_action_animation_count
    find("[role=tab][data-panel=summary]").click
    assert_equal count, summary_action_animation_count

    find("[role=tab][data-panel=code]").click
    reduce_motion
    find("[role=tab][data-panel=summary]").click

    assert_equal count, summary_action_animation_count
    assert_selector "a[data-summary-action]", count: 2, visible: true
  end

  private
    def record_summary_action_animations
      page.execute_script <<~JS
        window.__summaryActionAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-summary-action]")) {
            window.__summaryActionAnimations.push({
              delay: options.delay,
              duration: options.duration,
              start: keyframes[0].transform
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

    def summary_action_animations = evaluate_script("window.__summaryActionAnimations")
    def summary_action_animation_count = evaluate_script("window.__summaryActionAnimations.length")
end
