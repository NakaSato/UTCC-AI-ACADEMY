require "application_system_test_case"

# Draft browser evidence for human QA review: the URL-selected landing editor
# group stays still while a manually opened group uses native disclosure motion.
class AdminLandingDisclosureMotionWalkTest < ApplicationSystemTestCase
  test "landing editor sections move only after an administrator opens them" do
    sign_in_through_the_form users(:admin)
    visit admin_path(tab: :landing, group: :hero)
    record_admin_landing_animations

    assert_selector "[data-admin-landing-group]", count: Landing.groups.size
    assert_selector "[data-admin-landing-group=hero][open]", count: 1
    assert_equal 0, admin_landing_animation_count

    group = closed_group["data-admin-landing-group"]
    closed_group.find("summary").click
    assert_selector "[data-admin-landing-group='#{group}'][open] [data-admin-landing-content]", visible: true
    assert_equal [
      { "duration" => 190, "start_opacity" => 0.45,
        "start_transform" => "translateY(-4px)" }
    ], admin_landing_animations

    find("[data-admin-landing-group='#{group}'] summary").click
    assert_no_selector "[data-admin-landing-group='#{group}'][open]"
    assert_equal 1, admin_landing_animation_count

    reduce_motion
    find("[data-admin-landing-group='#{group}'] summary").click
    assert_selector "[data-admin-landing-group='#{group}'][open] [data-admin-landing-content]", visible: true
    assert_equal 1, admin_landing_animation_count
  end

  private
    def closed_group
      find("[data-admin-landing-group]:not([open])", match: :first)
    end

    def record_admin_landing_animations
      page.execute_script <<~JS
        window.__adminLandingAnimations = []
        window.__originalElementAnimate = Element.prototype.animate
        Element.prototype.animate = function(keyframes, options) {
          if (this.matches("[data-admin-landing-content]")) {
            window.__adminLandingAnimations.push({
              duration: options.duration,
              start_opacity: keyframes[0].opacity,
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

    def admin_landing_animations = evaluate_script("window.__adminLandingAnimations")
    def admin_landing_animation_count = evaluate_script("window.__adminLandingAnimations.length")
end
