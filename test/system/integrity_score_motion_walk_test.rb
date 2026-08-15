require "application_system_test_case"

# Browser evidence for integrity-score feedback after a new assessed-step
# incident. The score changes before decoration; theory and reduced-motion
# interactions retain the same integrity boundary without Web Animations.
class IntegrityScoreMotionWalkTest < ApplicationSystemTestCase
  test "new assessment incidents settle the changed score unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_score_animations

    assert_equal 0, score_animation_count
    trigger_context_menu
    assert_selector "[data-integrity-score]", text: "98"
    assert_equal({ "duration" => 240, "start" => "translateY(-2px) scale(1.12)",
                   "value" => "98" }, last_score_animation)

    trigger_context_menu
    assert_selector "[data-integrity-score]", text: "96"
    assert_equal 2, score_animation_count

    reduce_motion
    trigger_context_menu
    assert_selector "[data-integrity-score]", text: "94"
    assert_equal 2, score_animation_count

    find("[role=tab][data-panel=theory]").click
    trigger_context_menu
    assert_selector "[data-integrity-score]", text: "94"
    assert_equal 2, score_animation_count
  end

  private
    def trigger_context_menu
      page.execute_script <<~JS
        document.querySelector("main#main").dispatchEvent(
          new MouseEvent("contextmenu", { bubbles: true, cancelable: true })
        )
      JS
    end

    def record_score_animations
      page.execute_script <<~JS
        window.__integrityScoreAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-integrity-score]")) {
            window.__integrityScoreAnimations.push({
              duration: options.duration,
              start: keyframes[0].transform,
              value: this.textContent.trim()
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

    def last_score_animation = evaluate_script("window.__integrityScoreAnimations.at(-1)")
    def score_animation_count = evaluate_script("window.__integrityScoreAnimations.length")
end
