require "application_system_test_case"

# Browser evidence that transient toasts use the host's directional offset for
# cancellable entrance and dismissal. Message semantics, manual dismissal, and
# reduced-motion behavior remain usable without depending on CSS transitions.
class ToastMotionWalkTest < ApplicationSystemTestCase
  test "toast movement follows its anchor and reduced-motion preference" do
    sign_in_through_the_form users(:one)
    visit progress_path
    record_toast_animations

    show_toast("First message")
    assert_selector "[data-toast-row]", text: "First message"
    assert_equal({ "phase" => "enter", "duration" => 200,
                   "start_transform" => "translateY(-0.375rem)" }, toast_animations.first)

    show_toast("Second message")
    assert_selector "[data-toast-row]", count: 2
    assert_equal 2, toast_animation_count

    within find("[data-toast-row]", text: "First message") do
      find("[data-slot=close]").click
    end
    assert_no_selector "[data-toast-row]", text: "First message"
    assert_equal({ "phase" => "leave", "duration" => 160,
                   "end_transform" => "translateY(-0.375rem)" }, toast_animations.last)

    reduce_motion
    show_toast("Still message")
    assert_selector "[data-toast-row]", text: "Still message"
    assert_equal 3, toast_animation_count

    within find("[data-toast-row]", text: "Still message") do
      find("[data-slot=close]").click
    end
    assert_no_selector "[data-toast-row]", text: "Still message"
    assert_equal 3, toast_animation_count
  end

  private
    def show_toast(message)
      page.execute_script <<~JS, message
        window.dispatchEvent(new CustomEvent("toast:show", {
          detail: { message: arguments[0], kind: "info", duration: 0 }
        }))
      JS
    end

    def record_toast_animations
      page.execute_script <<~JS
        window.__toastAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-toast-row]")) {
            const entering = keyframes[0].opacity === 0
            window.__toastAnimations.push({
              phase: entering ? "enter" : "leave",
              duration: options.duration,
              ...(entering
                ? { start_transform: keyframes[0].transform }
                : { end_transform: keyframes.at(-1).transform })
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

    def toast_animations = evaluate_script("window.__toastAnimations")
    def toast_animation_count = evaluate_script("window.__toastAnimations.length")
end
