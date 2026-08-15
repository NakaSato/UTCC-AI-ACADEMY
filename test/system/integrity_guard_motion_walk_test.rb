require "application_system_test_case"

# Browser evidence that the integrity guard's visible state precedes one
# JavaScript entrance. Repeated guarded incidents, inactive steps, dismissal,
# and reduced motion keep the same protection without replaying movement.
class IntegrityGuardMotionWalkTest < ApplicationSystemTestCase
  test "the guard settles once when it first covers an assessed step" do
    sign_in_through_the_form users(:one)
    visit lesson_path(course: "AI1101", topic: "1-1", step: :exercise)
    record_guard_animations

    assert_equal "false", main["data-proctor-hidden"]
    assert_equal 0, guard_animation_count

    trigger_capture
    assert_equal "true", main["data-proctor-hidden"]
    assert_selector "[data-integrity-guard]", visible: true
    assert_equal [
      { "part" => "backdrop", "duration" => 180, "start_opacity" => 0 },
      { "part" => "dialog", "duration" => 260,
        "start_transform" => "translateY(8px) scale(0.98)" }
    ], guard_animations

    trigger_capture
    assert_equal 2, guard_animation_count

    dismiss_guard
    assert_equal "false", main["data-proctor-hidden"]
    assert_equal [
      { "part" => "backdrop", "duration" => 150, "start_opacity" => 1 },
      { "part" => "dialog", "duration" => 170,
        "start_transform" => "translateY(0) scale(1)" }
    ], guard_animations.drop(2)

    reduce_motion
    trigger_capture
    assert_equal "true", main["data-proctor-hidden"]
    assert_equal 4, guard_animation_count

    dismiss_guard
    find("[role=tab][data-panel=theory]").click
    trigger_capture
    assert_equal "false", main["data-proctor-hidden"]
    assert_equal 4, guard_animation_count
  end

  private
    def main = find("main#main")

    def trigger_capture
      page.execute_script <<~JS
        document.dispatchEvent(
          new KeyboardEvent("keydown", { key: "PrintScreen", bubbles: true, cancelable: true })
        )
      JS
    end

    def dismiss_guard
      click_button I18n.t("lesson.proctor.guard_btn", locale: :th)
      assert_selector "main[data-proctor-hidden=false]"
    end

    def record_guard_animations
      page.execute_script <<~JS
        window.__integrityGuardAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-integrity-guard]")) {
            window.__integrityGuardAnimations.push({
              part: "backdrop",
              duration: options.duration,
              start_opacity: keyframes[0].opacity
            })
          } else if (this.matches("[data-integrity-guard-dialog]")) {
            window.__integrityGuardAnimations.push({
              part: "dialog",
              duration: options.duration,
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

    def guard_animations = evaluate_script("window.__integrityGuardAnimations")
    def guard_animation_count = evaluate_script("window.__integrityGuardAnimations.length")
end
