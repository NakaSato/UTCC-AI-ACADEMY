require "application_system_test_case"

# Browser evidence for integrity-verdict movement at score-band boundaries.
# Deductions inside one band stay still; translated verdict state changes before
# decoration, and reduced-motion or inactive-step events remain motionless.
class IntegrityVerdictMotionWalkTest < ApplicationSystemTestCase
  test "crossing an integrity band settles the new verdict unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_verdict_animations

    trigger_context_menu
    assert_equal "clean", main["data-band"]
    assert_equal 0, verdict_animation_count

    trigger_capture
    assert_equal "review", main["data-band"]
    assert_selector "[data-integrity-verdict]", text: I18n.t("lesson.proctor.verdict_review", locale: :th)
    assert_equal({ "band" => "review", "duration" => 220, "start" => "translateY(3px)" },
                 last_verdict_animation)

    count = verdict_animation_count
    trigger_context_menu
    assert_equal "review", main["data-band"]
    assert_equal count, verdict_animation_count

    reduce_motion
    trigger_capture
    assert_equal "risk", main["data-band"]
    assert_selector "[data-integrity-verdict]", text: I18n.t("lesson.proctor.verdict_risk", locale: :th)
    assert_equal count, verdict_animation_count

    click_button I18n.t("lesson.proctor.guard_btn", locale: :th)
    find("[role=tab][data-panel=theory]").click
    trigger_capture
    assert_equal "risk", main["data-band"]
    assert_equal count, verdict_animation_count
  end

  private
    def main = find("main#main")

    def trigger_context_menu
      page.execute_script <<~JS
        document.querySelector("main#main").dispatchEvent(
          new MouseEvent("contextmenu", { bubbles: true, cancelable: true })
        )
      JS
    end

    def trigger_capture
      page.execute_script <<~JS
        document.dispatchEvent(
          new KeyboardEvent("keydown", { key: "PrintScreen", bubbles: true, cancelable: true })
        )
      JS
    end

    def record_verdict_animations
      page.execute_script <<~JS
        window.__integrityVerdictAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-integrity-verdict]")) {
            window.__integrityVerdictAnimations.push({
              band: document.querySelector("main#main").dataset.band,
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

    def last_verdict_animation = evaluate_script("window.__integrityVerdictAnimations.at(-1)")
    def verdict_animation_count = evaluate_script("window.__integrityVerdictAnimations.length")
end
