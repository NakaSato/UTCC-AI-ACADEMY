require "application_system_test_case"

# Browser evidence for the completion mark's one-shot arrival. It moves only
# when the learner reaches Summary from another step; direct, repeated, and
# reduced-motion views retain the same finished mark without decoration.
class SummaryCompletionMotionWalkTest < ApplicationSystemTestCase
  test "summary completion mark pops once unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :code)
    record_summary_mark_animations

    find("[role=tab][data-panel=summary]").click

    assert_equal({
      "duration" => 360,
      "start" => "scale(0.78) rotate(-5deg)",
      "peak" => "scale(1.08) rotate(0deg)"
    }, last_summary_mark_animation)

    count = summary_mark_animation_count
    find("[role=tab][data-panel=summary]").click
    assert_equal count, summary_mark_animation_count

    find("[role=tab][data-panel=code]").click
    reduce_motion
    find("[role=tab][data-panel=summary]").click

    assert_equal count, summary_mark_animation_count
    assert_selector "[data-summary-mark]", text: "✓", visible: true
  end

  private
    def record_summary_mark_animations
      page.execute_script <<~JS
        window.__summaryMarkAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-summary-mark]")) {
            window.__summaryMarkAnimations.push({
              duration: options.duration,
              start: keyframes[0].transform,
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

    def last_summary_mark_animation = evaluate_script("window.__summaryMarkAnimations.at(-1)")
    def summary_mark_animation_count = evaluate_script("window.__summaryMarkAnimations.length")
end
