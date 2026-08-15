require "application_system_test_case"

# Browser evidence for integrity-meter movement after assessed-step incidents.
# Initial and restored widths stay still; reduced-motion and inactive steps
# retain the same score boundary without invoking Web Animations.
class IntegrityMeterMotionWalkTest < ApplicationSystemTestCase
  test "assessment incidents move the meter unless motion is reduced" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_meter_animations

    assert_equal 0, meter_animation_count
    trigger_context_menu
    assert_equal({ "duration" => 300, "from" => "100%", "to" => "98%" },
                 last_meter_animation)

    finish_meter_animations
    trigger_context_menu
    assert_equal({ "duration" => 300, "from" => "98%", "to" => "96%" },
                 last_meter_animation)

    finish_meter_animations
    reduce_motion
    count = meter_animation_count
    trigger_context_menu
    assert_equal count, meter_animation_count
    assert_equal "94%", meter[:style][/width:\s*([^;]+)/, 1]

    find("[role=tab][data-panel=theory]").click
    trigger_context_menu
    assert_equal count, meter_animation_count
    assert_equal "94%", meter[:style][/width:\s*([^;]+)/, 1]
  end

  private
    def meter = find("[data-integrity-meter]")

    def trigger_context_menu
      page.execute_script <<~JS
        document.querySelector("main#main").dispatchEvent(
          new MouseEvent("contextmenu", { bubbles: true, cancelable: true })
        )
      JS
    end

    def record_meter_animations
      page.execute_script <<~JS
        window.__integrityMeterAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-integrity-meter]")) {
            window.__integrityMeterAnimations.push({
              duration: options.duration,
              from: keyframes[0].width,
              to: keyframes[1].width
            })
          }
          return window.__originalElementAnimate.call(this, keyframes, options)
        }
      JS
    end

    def finish_meter_animations
      page.execute_script <<~JS
        document.querySelector("[data-integrity-meter]")
          .getAnimations()
          .forEach((animation) => animation.finish())
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

    def last_meter_animation = evaluate_script("window.__integrityMeterAnimations.at(-1)")
    def meter_animation_count = evaluate_script("window.__integrityMeterAnimations.length")
end
