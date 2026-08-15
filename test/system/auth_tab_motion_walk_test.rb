require "application_system_test_case"

# Draft browser evidence for human QA review: auth semantics, focus, and URL
# change before the selected tab acknowledges them, while reduced motion keeps
# the same request-free switch without decoration.
class AuthTabMotionWalkTest < ApplicationSystemTestCase
  test "auth tab selection moves once and stays still when reduced" do
    visit login_path
    record_auth_tab_animations

    assert_selector "button[data-auth-tab][data-panel=login][aria-selected=true]"
    assert_empty auth_tab_animations

    register_tab.click
    assert_current_path register_path
    assert_selector "button[data-auth-tab][data-panel=register][aria-selected=true]"
    assert_selector "section[data-panel=register]:not([hidden])"
    assert_equal "user_name", evaluate_script("document.activeElement.id")
    assert_equal [
      { "duration" => 200, "start_opacity" => 0.72,
        "start_transform" => "translateY(1px) scale(0.96)",
        "overshoot_transform" => "translateY(0) scale(1.03)" }
    ], auth_tab_animations

    register_tab.click
    assert_equal 1, auth_tab_animation_count

    reduce_motion
    login_tab.click
    assert_current_path login_path
    assert_selector "button[data-auth-tab][data-panel=login][aria-selected=true]"
    assert_selector "section[data-panel=login]:not([hidden])"
    assert_equal "student_id", evaluate_script("document.activeElement.id")
    assert_equal 1, auth_tab_animation_count
  end

  private
    def login_tab = find("button[data-auth-tab][data-panel=login]")
    def register_tab = find("button[data-auth-tab][data-panel=register]")

    def record_auth_tab_animations
      page.execute_script <<~JS
        window.__authTabAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("button[data-auth-tab]")) {
            window.__authTabAnimations.push({
              duration: options.duration,
              start_opacity: keyframes[0].opacity,
              start_transform: keyframes[0].transform,
              overshoot_transform: keyframes[1].transform
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

    def auth_tab_animations = evaluate_script("window.__authTabAnimations")
    def auth_tab_animation_count = evaluate_script("window.__authTabAnimations.length")
end
